//go:build windows

package copilot

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/FleetKanban/fleetkanban/internal/task"
	copilot "github.com/github/copilot-sdk/go"
)

// TaskTimeout is the maximum wall-clock a single Copilot session is allowed
// to run (phase1-spec §3.2).
const TaskTimeout = 30 * time.Minute

// RunnerConfig configures a Runner.
type RunnerConfig struct {
	// Model overrides the default model. Empty triggers auto-selection via
	// ListModels.
	Model string
	// Timeout overrides TaskTimeout.
	Timeout time.Duration
}

// Runner executes tasks via the GitHub Copilot SDK. It implements
// orchestrator.AgentRunner.
type Runner struct {
	client  *copilot.Client
	model   string
	timeout time.Duration
}

// newRunner is the internal constructor used by Runtime.NewRunner.
func newRunner(client *copilot.Client, cfg RunnerConfig) (*Runner, error) {
	timeout := cfg.Timeout
	if timeout == 0 {
		timeout = TaskTimeout
	}

	model := cfg.Model
	if model == "" {
		resolved, err := resolveModel(context.Background(), client)
		if err != nil {
			return nil, err
		}
		model = resolved
	}

	return &Runner{
		client:  client,
		model:   model,
		timeout: timeout,
	}, nil
}

// resolveModel returns the first model the Copilot CLI server advertises
// for the current account. The CLI's ListModels response order is treated
// as authoritative: baking a preference list into the binary would rot as
// models are added/retired server-side and would not match every plan tier
// (Copilot Individual / Free advertise narrower catalogs than Enterprise).
// Users who want a specific model pick one per stage in Settings; that
// override reaches the Runner via RunnerConfig.Model and bypasses this
// function entirely.
func resolveModel(ctx context.Context, client *copilot.Client) (string, error) {
	models, err := client.ListModels(ctx)
	if err != nil {
		return "", fmt.Errorf("copilot: list models: %w", err)
	}
	if len(models) == 0 {
		return "", fmt.Errorf("copilot: server advertises no models")
	}
	return models[0].ID, nil
}

// Run implements orchestrator.AgentRunner. It creates an SDK session, drives
// the agent loop, enforces the worktree write-containment invariant via the
// permission handler, and maps SDK events to task.AgentEvent.
//
// out is closed before Run returns in all cases.
func (r *Runner) Run(ctx context.Context, t *task.Task, out chan<- *task.AgentEvent) (string, error) {
	defer close(out)
	return r.driveSession(ctx, t, BuildPrompt(t), out)
}

// RunSubtask implements orchestrator.AgentRunner for subtask-scoped
// execution. The AgentRole on sub is injected via BuildSubtaskPrompt so the
// planner's role assignment propagates to the session's system context.
// out is closed before RunSubtask returns in all cases.
func (r *Runner) RunSubtask(ctx context.Context, t *task.Task, sub *task.Subtask, out chan<- *task.AgentEvent) (string, error) {
	defer close(out)
	if sub == nil {
		return "", errors.New("copilot: RunSubtask: subtask is nil")
	}
	return r.driveSession(ctx, t, BuildSubtaskPrompt(t, sub), out)
}

// driveSession is the shared session loop used by both Run and RunSubtask.
// The caller owns opening and closing `out`; driveSession only writes to it.
// The returned string is the Code-stage model actually used (t.Model when
// non-empty, else the Runner's fallback default) so the orchestrator can
// surface it on Task.Model / Subtask.CodeModel.
func (r *Runner) driveSession(ctx context.Context, t *task.Task, prompt string, out chan<- *task.AgentEvent) (string, error) {
	if t.WorktreePath == "" {
		return "", errors.New("copilot: task.WorktreePath is empty")
	}

	ctx, cancel := context.WithTimeout(ctx, r.timeout)
	defer cancel()

	model := r.model
	if t.Model != "" {
		model = t.Model
	}

	// pathEscaped captures the first write attempt outside the worktree.
	var pathEscaped string

	guardHandler, err := NewPermissionHandler(t.WorktreePath)
	if err != nil {
		return "", fmt.Errorf("copilot: runner: %w", err)
	}
	trackingHandler := func(req copilot.PermissionRequest, inv copilot.PermissionInvocation) (copilot.PermissionRequestResult, error) {
		result, handlerErr := guardHandler(req, inv)
		if result.Kind == copilot.PermissionRequestResultKindDeniedByRules &&
			req.Kind == copilot.PermissionRequestKindWrite &&
			req.FileName != nil && pathEscaped == "" {
			pathEscaped = *req.FileName
			out <- &task.AgentEvent{
				Kind: task.EventSecurityPathEscape,
				Payload: mustJSON(map[string]any{
					"reported": *req.FileName,
					"root":     t.WorktreePath,
				}),
			}
		}
		return result, handlerErr
	}

	session, err := r.client.CreateSession(ctx, &copilot.SessionConfig{
		Model:            model,
		Streaming:        true,
		WorkingDirectory: t.WorktreePath,
		SystemMessage: &copilot.SystemMessageConfig{
			Mode:    "append",
			Content: "cwd 外のファイルを変更してはいけない。",
		},
		OnPermissionRequest: trackingHandler,
	})
	if err != nil {
		return "", fmt.Errorf("copilot: create session: %w", err)
	}
	defer func() { _ = session.Disconnect() }()

	out <- &task.AgentEvent{Kind: task.EventSessionStart}

	idleCh := make(chan struct{})
	idleOnce := make(chan struct{}, 1)

	mapper := NewSessionMapper()

	sendAll := func(events []*task.AgentEvent) {
		for _, ae := range events {
			select {
			case out <- ae:
			case <-ctx.Done():
				return
			}
		}
	}

	unsubscribe := session.On(func(e copilot.SessionEvent) {
		if _, ok := e.Data.(*copilot.SessionIdleData); ok {
			sendAll(mapper.Flush())
			select {
			case idleOnce <- struct{}{}:
				close(idleCh)
			default:
			}
			return
		}
		sendAll(mapper.Map(e))
	})
	defer unsubscribe()

	if _, err := session.Send(ctx, copilot.MessageOptions{
		Prompt: prompt,
	}); err != nil {
		if pathEscaped != "" {
			return model, fmt.Errorf("copilot: path escape to %q", pathEscaped)
		}
		return model, fmt.Errorf("copilot: send: %w", err)
	}

	select {
	case <-idleCh:
		// normal completion — flush already happened in the idle handler
	case <-ctx.Done():
		_ = session.Disconnect()
		for _, ae := range mapper.Flush() {
			select {
			case out <- ae:
			default:
			}
		}
		if pathEscaped != "" {
			return model, fmt.Errorf("copilot: path escape to %q", pathEscaped)
		}
		return model, ctx.Err()
	}

	if pathEscaped != "" {
		return model, fmt.Errorf("copilot: path escape to %q", pathEscaped)
	}
	out <- &task.AgentEvent{Kind: task.EventSessionIdle}
	return model, nil
}
