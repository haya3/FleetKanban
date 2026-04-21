//go:build windows

package copilot

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"strings"
	"time"

	"github.com/FleetKanban/fleetkanban/internal/copilot/tools"
	"github.com/FleetKanban/fleetkanban/internal/orchestrator"
	"github.com/FleetKanban/fleetkanban/internal/task"
	copilot "github.com/github/copilot-sdk/go"
)

// reviewerTimeout is the wall-clock cap on a single AI review session.
// Picked to leave headroom under orchestrator.aiReviewTimeout (5 min) so
// the review session finishes cleanly instead of being canceled by the
// outer timeout mid-message.
const reviewerTimeout = 4 * time.Minute

// approvalMarker is the exact leading token the reviewer is instructed to
// emit on the final line when it considers the diff acceptable. Parsing a
// strict marker avoids false positives from words like "approve" appearing
// inside code comments.
const approvalMarker = "APPROVE"

// reworkMarker is the leading token for rework. The remainder of the line
// (after the colon) is the feedback prepended to the next Copilot prompt.
const reworkMarker = "REWORK:"

// Reviewer is a Copilot-backed orchestrator.AIReviewer. Each Review call
// opens a short-lived single-shot session in the task's worktree, asks
// the agent to classify the diff, and parses the final line.
//
// The session intentionally does NOT have write permission to the
// worktree — review is read-only analysis. The permission handler from
// runner.go would allow write; Reviewer overrides it with a deny-writes
// policy so a misbehaving reviewer agent cannot mutate code out from
// under the user.
type Reviewer struct {
	client       *copilot.Client
	model        string
	timeout      time.Duration
	settings     SettingsLookup
	stagePrompts StagePromptLookup
	memory       MemoryInjector
}

// NewReviewer constructs a Reviewer bound to rt's SDK client. When model
// is empty the runtime's ListModels is consulted and the first preferred
// match is used.
func (r *Runtime) NewReviewer(ctx context.Context, model string) (*Reviewer, error) {
	client := r.Client()
	if client == nil {
		return nil, errors.New("copilot: runtime client not started")
	}
	if model == "" {
		resolved, err := resolveModel(ctx, client)
		if err != nil {
			return nil, err
		}
		model = resolved
	}
	r.mu.RLock()
	settings := r.cfg.Settings
	stagePrompts := r.cfg.StagePrompts
	memory := r.cfg.Memory
	r.mu.RUnlock()
	return &Reviewer{
		client:       client,
		model:        model,
		timeout:      reviewerTimeout,
		settings:     settings,
		stagePrompts: stagePrompts,
		memory:       memory,
	}, nil
}

// Review implements orchestrator.AIReviewer. Returns Approve=true when the
// final assistant message starts with APPROVE, and Approve=false with the
// feedback text otherwise.
//
// Any SDK-level error is returned as-is; the orchestrator treats errors
// as "leave in ai_review for manual advance" rather than failing the task.
// A well-formed reply that fits neither marker falls through as APPROVE
// so ambiguous reviews escalate to human_review instead of driving yet
// another rework cycle — the rework cap upstream exists precisely so we
// don't burn Copilot tokens on borderline calls.
//
// prevFeedback is the reviewer feedback from the previous ai_review
// cycle (empty on the first pass) so the reviewer can self-check "has
// my last request been addressed?". reworkCount is the current rework
// counter used purely as context in the prompt.
func (r *Reviewer) Review(ctx context.Context, t *task.Task, diff, prevFeedback string, reworkCount int, out chan<- *task.AgentEvent) (orchestrator.ReviewDecision, string, task.SessionUsage, error) {
	defer close(out)
	if t.WorktreePath == "" {
		return orchestrator.ReviewDecision{}, "", task.SessionUsage{}, errors.New("copilot: reviewer: task has no worktree")
	}

	ctx, cancel := context.WithTimeout(ctx, r.timeout)
	defer cancel()

	// Per-task override: honour t.ReviewModel verbatim when the user
	// picked a specific Review-stage model in Settings. Otherwise fall
	// back to the Reviewer's constructor-time default (resolved from
	// ListModels at Runtime startup).
	model := t.ReviewModel
	if model == "" {
		model = r.model
	}

	// Build a deny-writes permission handler so the reviewer cannot edit
	// the worktree. Read tools (view / grep / ls) stay enabled — the new
	// prompt actively asks the reviewer to consult the current file
	// state before ruling on feedback items, which needs reads.
	guard, err := NewPermissionHandler(t.WorktreePath)
	if err != nil {
		return orchestrator.ReviewDecision{}, "", task.SessionUsage{}, fmt.Errorf("copilot: reviewer permission: %w", err)
	}
	denyWrites := func(req copilot.PermissionRequest, inv copilot.PermissionInvocation) (copilot.PermissionRequestResult, error) {
		if req.Kind == copilot.PermissionRequestKindWrite {
			return copilot.PermissionRequestResult{
				Kind: copilot.PermissionRequestResultKindDeniedByRules,
			}, nil
		}
		return guard(req, inv)
	}

	settings := agentSettingsOrEmpty(ctx, r.settings)
	systemContent := ResolveStagePrompt(r.stagePrompts, "review", DefaultReviewPrompt) + languageAddendum(settings.OutputLanguage)
	var sessionTools []copilot.Tool
	if r.memory != nil {
		sessionTools = []copilot.Tool{tools.NewSearchMemoryTool(r.memory, t.RepoID)}
	}
	session, err := r.client.CreateSession(ctx, &copilot.SessionConfig{
		Model:            model,
		Streaming:        true,
		WorkingDirectory: t.WorktreePath,
		SystemMessage: &copilot.SystemMessageConfig{
			Mode:    "replace",
			Content: systemContent,
		},
		OnPermissionRequest: denyWrites,
		Tools:               sessionTools,
	})
	if err != nil {
		return orchestrator.ReviewDecision{}, "", task.SessionUsage{}, fmt.Errorf("copilot: reviewer session: %w", err)
	}
	defer func() { _ = session.Disconnect() }()

	idleCh := make(chan struct{})
	idleOnce := make(chan struct{}, 1)
	var (
		transcript strings.Builder
	)
	usage := &usageAccumulator{}
	sessionStart := time.Now()
	slog.Info("reviewer: session start",
		"task_id", t.ID,
		"model", model,
		"worktree", t.WorktreePath)

	mapper := NewSessionMapper()
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
			slog.Info("reviewer: llm call",
				"task_id", t.ID,
				"elapsed_ms", elapsed.Milliseconds(),
				"in_tokens", in,
				"out_tokens", outTok,
				"premium", cost,
				"calls_so_far", usage.u.Calls+1)
			return
		case *copilot.SessionIdleData:
			slog.Info("reviewer: idle",
				"task_id", t.ID,
				"elapsed_ms", elapsed.Milliseconds(),
				"total_calls", usage.u.Calls,
				"total_premium", usage.u.PremiumRequests)
			select {
			case idleOnce <- struct{}{}:
				close(idleCh)
			default:
			}
			return
		case *copilot.ToolExecutionStartData:
			slog.Info("reviewer: tool start",
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
			slog.Info("reviewer: tool end", attrs...)
		case *copilot.AssistantIntentData:
			slog.Info("reviewer: intent",
				"task_id", t.ID,
				"elapsed_ms", elapsed.Milliseconds(),
				"intent", d.Intent)
		}
		// Forward every mappable SDK event to the orchestrator's event
		// channel so the UI has a chronological log of the reviewer's
		// reasoning, assistant output, and tool calls. Bracketed at
		// the orchestrator level by ai_review.start / ai_review.decision.
		for _, ae := range mapper.Map(e) {
			if ae == nil {
				continue
			}
			if ae.Kind == task.EventAssistantDelta {
				transcript.WriteString(ae.Payload)
				transcript.WriteByte('\n')
			}
			select {
			case out <- ae:
			case <-ctx.Done():
			}
		}
	})
	defer unsubscribe()

	prompt := buildReviewPrompt(t, diff, prevFeedback, reworkCount)
	if r.memory != nil {
		if mem := r.memory.BuildForReviewer(ctx, t.RepoID, t.Goal, diffSummary(diff), t.ID); mem != "" {
			// Prepended to the user prompt (not system) so a rework
			// iteration re-fetches the latest memory block instead of
			// caching a stale snapshot in the session's system slot.
			prompt = mem + "\n" + prompt
		}
	}
	if _, err := session.Send(ctx, copilot.MessageOptions{Prompt: prompt}); err != nil {
		return orchestrator.ReviewDecision{}, "", usage.snapshot(), fmt.Errorf("copilot: reviewer send: %w", err)
	}

	select {
	case <-idleCh:
	case <-ctx.Done():
		_ = session.Disconnect()
		for _, ae := range mapper.Flush() {
			select {
			case out <- ae:
			default:
			}
		}
		return orchestrator.ReviewDecision{}, "", usage.snapshot(), ctx.Err()
	}

	// Drain any partial lines still buffered in the mapper so the UI
	// doesn't lose the last few tokens of the reviewer's output.
	for _, ae := range mapper.Flush() {
		if ae.Kind == task.EventAssistantDelta {
			transcript.WriteString(ae.Payload)
			transcript.WriteByte('\n')
		}
		select {
		case out <- ae:
		case <-ctx.Done():
		}
	}
	return parseReviewDecision(transcript.String()), model, usage.snapshot(), nil
}

// diffSummary condenses a unified diff to the first ~240 chars of
// non-hunk-header content so BuildForReviewer's hybrid search has a
// signal beyond the task goal without paying the full-diff embedding
// cost. Falls back to an empty string for empty diffs; the review
// stage then retrieves memory on goal alone.
func diffSummary(diff string) string {
	if diff == "" {
		return ""
	}
	lines := strings.Split(diff, "\n")
	var b strings.Builder
	for _, ln := range lines {
		if ln == "" || strings.HasPrefix(ln, "@@") || strings.HasPrefix(ln, "+++") || strings.HasPrefix(ln, "---") || strings.HasPrefix(ln, "diff ") || strings.HasPrefix(ln, "index ") {
			continue
		}
		if len(ln) > 0 && (ln[0] == '+' || ln[0] == '-') {
			b.WriteString(ln[1:])
			b.WriteByte(' ')
		}
		if b.Len() > 240 {
			break
		}
	}
	out := strings.TrimSpace(b.String())
	if len(out) > 240 {
		out = out[:240]
	}
	return out
}

// buildReviewPrompt constructs the review request. The diff is wrapped in
// a fenced block so the agent can reason about it without confusing diff
// headers for instructions. Diff content is not sanitized — it is the
// user's own source, and the agent is running with deny-writes anyway.
//
// prevFeedback (may be empty) is the feedback the reviewer emitted on
// the previous cycle — surfaced so the reviewer can check whether its
// prior request is now satisfied before re-issuing it. reworkCount is
// informational context; cap enforcement lives in the orchestrator.
func buildReviewPrompt(t *task.Task, diff, prevFeedback string, reworkCount int) string {
	if diff == "" {
		diff = "(empty diff — no changes)"
	}
	prevBlock := prevFeedback
	if strings.TrimSpace(prevBlock) == "" {
		prevBlock = "(initial review)"
	}
	return fmt.Sprintf(`Please review the output of the following task.

Goal: %s
Base branch: %s
Branch: %s
Rework iterations so far: %d

[Previous review feedback]
%s

[diff]
`+"```diff"+`
%s
`+"```"+`

Review procedure (mandatory):
1. If previous feedback exists, use read tools (view, grep, etc.) to check the current state of the relevant files.
2. If the previous feedback is already satisfied by the current file contents, respond with APPROVE.
3. Do not repeat the same feedback. For ambiguous points, choose APPROVE and defer to the human reviewer.
4. Prioritise whether the existing output meets the goal over ideals not reflected in the diff.

Output constraints (mandatory):
- The final line must be exactly %s or %s <1-2 specific sentences of feedback>.
- Do not include either marker on any line other than the final line. No preamble or decoration.
- When in doubt, choose APPROVE.`,
		SanitizeSingleLine(t.Goal), t.BaseBranch, t.Branch, reworkCount,
		prevBlock, diff, approvalMarker, reworkMarker)
}

// parseReviewDecision inspects the reviewer's transcript and classifies
// it. The contract is "the final non-empty line starts with APPROVE or
// REWORK:". Anything else — including an empty transcript — falls
// through to APPROVE so ambiguous output lets the human reviewer take
// over rather than triggering another automated rework cycle. This
// pairs with the orchestrator's rework cap: ambiguity → escalation, not
// wasted Copilot spins.
//
// Everything in the transcript BEFORE the decision line is captured as
// Summary so the UI can show the reviewer's rationale (what was
// checked, findings) on the AI Review card — without this, an APPROVE
// with no feedback would render as an empty card.
func parseReviewDecision(transcript string) orchestrator.ReviewDecision {
	trimmed := strings.TrimSpace(transcript)
	if trimmed == "" {
		return orchestrator.ReviewDecision{Approve: true}
	}

	lines := strings.Split(trimmed, "\n")
	// Walk from the end looking for the first non-blank line.
	finalIdx := -1
	var finalLine string
	for i := len(lines) - 1; i >= 0; i-- {
		if ln := strings.TrimSpace(lines[i]); ln != "" {
			finalLine = ln
			finalIdx = i
			break
		}
	}

	summary := ""
	if finalIdx > 0 {
		summary = strings.TrimSpace(strings.Join(lines[:finalIdx], "\n"))
	}

	switch {
	case strings.HasPrefix(finalLine, approvalMarker):
		return orchestrator.ReviewDecision{Approve: true, Summary: summary}
	case strings.HasPrefix(finalLine, reworkMarker):
		fb := strings.TrimSpace(strings.TrimPrefix(finalLine, reworkMarker))
		if fb == "" {
			fb = "AI Reviewer requested rework without providing details"
		}
		return orchestrator.ReviewDecision{Approve: false, Feedback: fb, Summary: summary}
	default:
		// Unstructured reply: approve so the user gets the task in
		// human_review. The ambiguous transcript would have been lost
		// under the old "fall-through to rework" behaviour too — Phase 1
		// relied on APPROVE/REWORK markers being present. Keep the
		// whole text as the summary so the user at least sees what
		// the reviewer said.
		return orchestrator.ReviewDecision{Approve: true, Summary: trimmed}
	}
}
