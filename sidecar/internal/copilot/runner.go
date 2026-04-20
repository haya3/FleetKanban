//go:build windows

package copilot

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"time"

	"github.com/FleetKanban/fleetkanban/internal/task"
	copilot "github.com/github/copilot-sdk/go"
)

// TaskTimeout is the maximum wall-clock a single Copilot session is allowed
// to run (phase1-spec §3.2).
const TaskTimeout = 30 * time.Minute

// MemoryInjector is the subset of ctxmem/svc.Service that the Runner
// needs for Passive prompt injection. Declared here as an interface so
// the copilot package does not import ctxmem (which would create a
// dependency cycle through app once app wires memory into runtime).
// Nil is valid — the runner falls through without prepending memory.
type MemoryInjector interface {
	BuildPassiveForRunner(ctx context.Context, repoID, prompt, taskID string) string
}

// RunnerConfig configures a Runner.
type RunnerConfig struct {
	// Model overrides the default model. Empty triggers auto-selection via
	// ListModels.
	Model string
	// Timeout overrides TaskTimeout.
	Timeout time.Duration
	// settings is wired by Runtime.NewRunner from the runtime's
	// SettingsLookup. Lower-case so callers don't set it directly —
	// the Runtime owns the lookup.
	settings SettingsLookup
	// memory is wired by Runtime.NewRunner from the runtime's Memory
	// field. Lower-case for the same reason as settings.
	memory MemoryInjector
}

// Runner executes tasks via the GitHub Copilot SDK. It implements
// orchestrator.AgentRunner.
type Runner struct {
	client   *copilot.Client
	model    string
	timeout  time.Duration
	settings SettingsLookup
	memory   MemoryInjector
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
		client:   client,
		model:    model,
		timeout:  timeout,
		settings: cfg.settings,
		memory:   cfg.memory,
	}, nil
}

// prependMemory returns prompt with the Passive memory block prepended
// when memory injection is wired and Memory is enabled for the task's
// repo. Returns the original prompt otherwise — Memory is always
// opt-in per-repo, so a no-op is the correct behaviour for disabled repos.
func (r *Runner) prependMemory(ctx context.Context, t *task.Task, prompt string) string {
	if r.memory == nil {
		return prompt
	}
	injected := r.memory.BuildPassiveForRunner(ctx, t.RepoID, t.Goal, t.ID)
	if injected == "" {
		return prompt
	}
	return injected + "\n" + prompt
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
func (r *Runner) Run(ctx context.Context, t *task.Task, out chan<- *task.AgentEvent) (string, task.SessionUsage, error) {
	defer close(out)
	return r.driveSession(ctx, t, r.prependMemory(ctx, t, BuildPrompt(t)), out)
}

// RunSubtask implements orchestrator.AgentRunner for subtask-scoped
// execution. The AgentRole on sub is injected via BuildSubtaskPrompt so the
// planner's role assignment propagates to the session's system context.
// subCtx carries plan summary + prior subtask summaries the orchestrator
// assembled so the Coder agent has context instead of re-exploring.
// out is closed before RunSubtask returns in all cases.
func (r *Runner) RunSubtask(ctx context.Context, t *task.Task, sub *task.Subtask, subCtx task.SubtaskRunContext, out chan<- *task.AgentEvent) (string, task.SessionUsage, error) {
	defer close(out)
	if sub == nil {
		return "", task.SessionUsage{}, errors.New("copilot: RunSubtask: subtask is nil")
	}
	return r.driveSession(ctx, t, r.prependMemory(ctx, t, BuildSubtaskPromptWithContext(t, sub, subCtx)), out)
}

// driveSession is the shared session loop used by both Run and RunSubtask.
// The caller owns opening and closing `out`; driveSession only writes to it.
// The returned string is the Code-stage model actually used (t.Model when
// non-empty, else the Runner's fallback default) so the orchestrator can
// surface it on Task.Model / Subtask.CodeModel. The returned SessionUsage
// totals every assistant.usage event the SDK emitted during the session;
// the orchestrator forwards it via EventSessionUsage so the UI can render
// premium-request consumption per stage.
func (r *Runner) driveSession(ctx context.Context, t *task.Task, prompt string, out chan<- *task.AgentEvent) (string, task.SessionUsage, error) {
	if t.WorktreePath == "" {
		return "", task.SessionUsage{}, errors.New("copilot: task.WorktreePath is empty")
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
		return "", task.SessionUsage{}, fmt.Errorf("copilot: runner: %w", err)
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

	settings := agentSettingsOrEmpty(ctx, r.settings)
	systemContent := effectivePrompt(settings.CodePrompt, DefaultCodePrompt) +
		languageAddendum(settings.OutputLanguage)
	session, err := r.client.CreateSession(ctx, &copilot.SessionConfig{
		Model:            model,
		Streaming:        true,
		WorkingDirectory: t.WorktreePath,
		SystemMessage: &copilot.SystemMessageConfig{
			Mode:    "append",
			Content: systemContent,
		},
		OnPermissionRequest: trackingHandler,
	})
	if err != nil {
		return "", task.SessionUsage{}, fmt.Errorf("copilot: create session: %w", err)
	}
	defer func() { _ = session.Disconnect() }()

	out <- &task.AgentEvent{Kind: task.EventSessionStart}

	idleCh := make(chan struct{})
	idleOnce := make(chan struct{}, 1)

	mapper := NewSessionMapper()
	usage := &usageAccumulator{}

	sendAll := func(events []*task.AgentEvent) {
		for _, ae := range events {
			select {
			case out <- ae:
			case <-ctx.Done():
				return
			}
		}
	}

	sessionStart := time.Now()
	slog.Info("runner: session start",
		"task_id", t.ID,
		"model", model,
		"worktree", t.WorktreePath)

	unsubscribe := session.On(func(e copilot.SessionEvent) {
		elapsed := time.Since(sessionStart)
		switch d := e.Data.(type) {
		case *copilot.AssistantUsageData:
			usage.add(d)
			in := int64(0)
			if d.InputTokens != nil {
				in = int64(*d.InputTokens)
			}
			outTok := int64(0)
			if d.OutputTokens != nil {
				outTok = int64(*d.OutputTokens)
			}
			cost := 0.0
			if d.Cost != nil {
				cost = *d.Cost
			}
			slog.Info("runner: llm call",
				"task_id", t.ID,
				"elapsed_ms", elapsed.Milliseconds(),
				"in_tokens", in,
				"out_tokens", outTok,
				"premium", cost,
				"calls_so_far", usage.u.Calls+1)
			return
		case *copilot.SessionIdleData:
			slog.Info("runner: idle",
				"task_id", t.ID,
				"elapsed_ms", elapsed.Milliseconds(),
				"total_calls", usage.u.Calls,
				"total_premium", usage.u.PremiumRequests)
			sendAll(mapper.Flush())
			select {
			case idleOnce <- struct{}{}:
				close(idleCh)
			default:
			}
			return
		case *copilot.ToolExecutionStartData:
			slog.Info("runner: tool start",
				"task_id", t.ID,
				"elapsed_ms", elapsed.Milliseconds(),
				"tool", d.ToolName,
				"call_id", d.ToolCallID,
				"args", compactArgs(d.Arguments))
		case *copilot.ToolExecutionCompleteData:
			errStr, resStr, telStr := toolEndSummary(d, 400)
			attrs := []any{
				"task_id", t.ID,
				"elapsed_ms", elapsed.Milliseconds(),
				"call_id", d.ToolCallID,
				"ok", d.Success,
			}
			if errStr != "" {
				attrs = append(attrs, "err", errStr)
			}
			if resStr != "" {
				attrs = append(attrs, "result", resStr)
			}
			if telStr != "" {
				attrs = append(attrs, "telemetry", telStr)
			}
			slog.Info("runner: tool end", attrs...)
		case *copilot.AssistantIntentData:
			slog.Info("runner: intent",
				"task_id", t.ID,
				"elapsed_ms", elapsed.Milliseconds(),
				"intent", d.Intent)
		}
		sendAll(mapper.Map(e))
	})
	defer unsubscribe()

	if _, err := session.Send(ctx, copilot.MessageOptions{
		Prompt: prompt,
	}); err != nil {
		if pathEscaped != "" {
			return model, usage.snapshot(), fmt.Errorf("copilot: path escape to %q", pathEscaped)
		}
		return model, usage.snapshot(), fmt.Errorf("copilot: send: %w", err)
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
			return model, usage.snapshot(), fmt.Errorf("copilot: path escape to %q", pathEscaped)
		}
		return model, usage.snapshot(), ctx.Err()
	}

	if pathEscaped != "" {
		return model, usage.snapshot(), fmt.Errorf("copilot: path escape to %q", pathEscaped)
	}
	out <- &task.AgentEvent{Kind: task.EventSessionIdle}
	return model, usage.snapshot(), nil
}
