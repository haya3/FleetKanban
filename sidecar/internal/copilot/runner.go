//go:build windows

package copilot

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"time"

	"github.com/FleetKanban/fleetkanban/internal/copilot/tools"
	"github.com/FleetKanban/fleetkanban/internal/task"
	copilot "github.com/github/copilot-sdk/go"
)

// TaskTimeout is the maximum wall-clock a single Copilot session is allowed
// to run (phase1-spec §3.2).
const TaskTimeout = 30 * time.Minute

// MemoryInjector is the subset of ctxmem/svc.Service the copilot
// package needs for prompt injection across all three tiers. Declared
// here as an interface so the copilot package does not import ctxmem
// (which would create a dependency cycle through app). Nil is valid —
// every caller falls through to "no memory" when the injector is nil
// or returns an empty string.
//
// BuildForReviewer is a distinct method (rather than a parameterized
// BuildPassive) because Reviewer prioritises Decision / Constraint
// nodes and trims File nodes that dominate Code-stage injection but
// add little to review; splitting the two methods lets the Memory
// layer tune each tier without the copilot package having to know.
type MemoryInjector interface {
	BuildPassiveForRunner(ctx context.Context, repoID, prompt, taskID string) string
	BuildForReviewer(ctx context.Context, repoID, goal, diffSummary, taskID string) string
	BuildReactiveForRunner(ctx context.Context, repoID, query string) string
}

// SubtaskContextSnapshot is the per-run prompt + injection record the
// Runner hands to a SubtaskContextRecorder so the UI's Subtask Summary
// dialog can show exactly what the agent saw. Populated right before
// the SDK session opens; the Round-keyed store upserts on conflict so
// a rework iteration replaces the previous entry.
type SubtaskContextSnapshot struct {
	SubtaskID           string
	Round               int
	SystemPrompt        string   // SDK SystemMessage.Content
	UserPrompt          string   // SDK first MessageOptions.Prompt
	StagePromptTemplate string   // Code-stage prompt body pre-language-addendum (from charter if present, else DefaultCodePrompt)
	PlanSummary         string
	PriorSummaries      []string // already-formatted display lines
	MemoryBlock         string   // injected memory block (may be empty)
	OutputLanguage      string
}

// SubtaskContextRecorder persists a SubtaskContextSnapshot. Declared as
// an interface so the copilot package does not import store. Nil is
// valid — the runner skips recording when no recorder is wired (tests,
// legacy code paths).
type SubtaskContextRecorder interface {
	RecordSubtaskContext(ctx context.Context, snap SubtaskContextSnapshot)
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
	// contextRecorder is wired by Runtime.NewRunner from the runtime's
	// ContextRecorder field. Receives one SubtaskContextSnapshot per
	// RunSubtask call, right before the SDK session is created.
	contextRecorder SubtaskContextRecorder
	// stagePrompts is wired by Runtime.NewRunner from the runtime's
	// StagePrompts field. Resolves the Code stage system prompt from
	// the active IHR charter per session; nil or empty return falls
	// back to DefaultCodePrompt.
	stagePrompts StagePromptLookup
}

// Runner executes tasks via the GitHub Copilot SDK. It implements
// orchestrator.AgentRunner.
type Runner struct {
	client          *copilot.Client
	model           string
	timeout         time.Duration
	settings        SettingsLookup
	memory          MemoryInjector
	contextRecorder SubtaskContextRecorder
	stagePrompts    StagePromptLookup
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
		client:          client,
		model:           model,
		timeout:         timeout,
		settings:        cfg.settings,
		memory:          cfg.memory,
		contextRecorder: cfg.contextRecorder,
		stagePrompts:    cfg.stagePrompts,
	}, nil
}

// memoryBlock returns just the Passive memory string (without the trailing
// "\n" prependMemory concatenates) so callers that want to record the
// injection separately from the final prompt can do so. Returns empty
// when Memory is disabled or no injector is wired.
func (r *Runner) memoryBlock(ctx context.Context, t *task.Task) string {
	if r.memory == nil {
		return ""
	}
	return r.memory.BuildPassiveForRunner(ctx, t.RepoID, t.Goal, t.ID)
}

// buildSessionTools assembles the Copilot SDK tool list for a session.
// Currently only exposes search_memory, wired to the runner's injector
// so the agent can pull Decision / Constraint nodes on demand. Nil
// injector → no tools (tests, Memory-off repos).
func (r *Runner) buildSessionTools(repoID string) []copilot.Tool {
	if r.memory == nil {
		return nil
	}
	return []copilot.Tool{
		tools.NewSearchMemoryTool(r.memory, repoID),
	}
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
	settings := agentSettingsOrEmpty(ctx, r.settings)
	systemContent := ResolveStagePrompt(r.stagePrompts, "code", DefaultCodePrompt) + languageAddendum(settings.OutputLanguage)
	return r.driveSession(ctx, t, systemContent, r.prependMemory(ctx, t, BuildPrompt(t)), out)
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
	settings := agentSettingsOrEmpty(ctx, r.settings)
	codePromptBody := ResolveStagePrompt(r.stagePrompts, "code", DefaultCodePrompt)
	systemContent := codePromptBody + languageAddendum(settings.OutputLanguage)
	memBlock := r.memoryBlock(ctx, t)
	basePrompt := BuildSubtaskPromptWithContext(t, sub, subCtx)
	userPrompt := basePrompt
	if memBlock != "" {
		userPrompt = memBlock + "\n" + basePrompt
	}
	r.recordSubtaskContext(ctx, sub, systemContent, userPrompt, memBlock, codePromptBody, subCtx, settings)
	return r.driveSession(ctx, t, systemContent, userPrompt, out)
}

// recordSubtaskContext hands the assembled prompt ingredients to the
// configured recorder, if any. Failures are logged but do not block
// execution — the session must proceed even if the snapshot can't be
// persisted (we prefer a missing UI entry over a cancelled task).
func (r *Runner) recordSubtaskContext(
	ctx context.Context,
	sub *task.Subtask,
	systemContent, userPrompt, memBlock, stageTemplate string,
	subCtx task.SubtaskRunContext,
	settings AgentSettings,
) {
	if r.contextRecorder == nil {
		return
	}
	priors := make([]string, 0, len(subCtx.PriorSummaries))
	for _, p := range subCtx.PriorSummaries {
		priors = append(priors, fmt.Sprintf("[%s] %s — %s", p.Role, p.Title, p.Summary))
	}
	round := sub.Round
	if round <= 0 {
		round = 1
	}
	r.contextRecorder.RecordSubtaskContext(ctx, SubtaskContextSnapshot{
		SubtaskID:           sub.ID,
		Round:               round,
		SystemPrompt:        systemContent,
		UserPrompt:          userPrompt,
		StagePromptTemplate: stageTemplate,
		PlanSummary:         subCtx.PlanSummary,
		PriorSummaries:      priors,
		MemoryBlock:         memBlock,
		OutputLanguage:      settings.OutputLanguage,
	})
}

// driveSession is the shared session loop used by both Run and RunSubtask.
// The caller owns opening and closing `out`; driveSession only writes to it.
// The returned string is the Code-stage model actually used (t.Model when
// non-empty, else the Runner's fallback default) so the orchestrator can
// surface it on Task.Model / Subtask.CodeModel. The returned SessionUsage
// totals every assistant.usage event the SDK emitted during the session;
// the orchestrator forwards it via EventSessionUsage so the UI can render
// premium-request consumption per stage.
//
// systemContent is injected into the SDK session's SystemMessage slot
// (append mode), prompt is sent as the first MessageOptions.Prompt.
// Both are caller-supplied so Run / RunSubtask can record them in the
// subtask context snapshot before the session is created.
func (r *Runner) driveSession(ctx context.Context, t *task.Task, systemContent, prompt string, out chan<- *task.AgentEvent) (string, task.SessionUsage, error) {
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

	sessionTools := r.buildSessionTools(t.RepoID)
	session, err := r.client.CreateSession(ctx, &copilot.SessionConfig{
		Model:            model,
		Streaming:        true,
		WorkingDirectory: t.WorktreePath,
		SystemMessage: &copilot.SystemMessageConfig{
			Mode:    "append",
			Content: systemContent,
		},
		OnPermissionRequest: trackingHandler,
		Tools:               sessionTools,
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
