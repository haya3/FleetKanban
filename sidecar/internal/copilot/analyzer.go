//go:build windows

package copilot

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"strings"
	"time"

	copilot "github.com/github/copilot-sdk/go"

	"github.com/FleetKanban/fleetkanban/internal/task"
)

// analyzerTimeout caps one repo-analysis session. Repos can be large
// enough that file reads add up; five minutes gives the model room to
// walk the tree without burning an unbounded amount of tokens.
const analyzerTimeout = 5 * time.Minute

// Analyzer runs a one-shot Copilot session against a raw directory
// (not a worktree) and returns the final assistant transcript. Unlike
// Planner, Analyzer is used for repo understanding — it reads the
// filesystem read-only and emits a structured summary the ctxmem
// analyzer package parses into scratchpad entries.
type Analyzer struct {
	client   *copilot.Client
	model    string
	timeout  time.Duration
	settings SettingsLookup
}

// NewAnalyzer constructs an Analyzer. When model is empty the
// runtime's first advertised model is used (same rule as Runner /
// Planner / Reviewer).
func (r *Runtime) NewAnalyzer(ctx context.Context, model string) (*Analyzer, error) {
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
	r.mu.RUnlock()
	return &Analyzer{
		client:   client,
		model:    model,
		timeout:  analyzerTimeout,
		settings: settings,
	}, nil
}

// Analyze runs a read-only Copilot session in repoPath with prompt as
// the user message and returns the assistant's final transcript.
//
// overrideModel lets callers bypass the Analyzer's default model for a
// specific run (e.g. the user picked a cheaper model in Settings for
// the analyzer). Empty string uses the default.
//
// progress is called synchronously from the SDK event loop whenever a
// tool invocation starts or the model takes another LLM turn. The
// caller is expected to be fast (typically pushing to a broker);
// blocking here stalls the session. Nil is accepted.
func (a *Analyzer) Analyze(ctx context.Context, repoPath, overrideModel, prompt string, progress func(string)) (string, error) {
	if repoPath == "" {
		return "", errors.New("copilot: analyzer: repoPath is empty")
	}
	if prompt == "" {
		return "", errors.New("copilot: analyzer: prompt is empty")
	}

	ctx, cancel := context.WithTimeout(ctx, a.timeout)
	defer cancel()

	model := overrideModel
	if model == "" {
		model = a.model
	}

	// Deny all writes. The analyzer must not mutate the repo — users
	// keep a registered repo they trust, and the analyzer prompt never
	// asks for edits. A misbehaving model attempting one gets rejected
	// at the SDK permission boundary rather than corrupting files.
	denyWrites := func(req copilot.PermissionRequest, _ copilot.PermissionInvocation) (copilot.PermissionRequestResult, error) {
		if req.Kind == copilot.PermissionRequestKindWrite {
			return copilot.PermissionRequestResult{
				Kind: copilot.PermissionRequestResultKindDeniedByRules,
			}, nil
		}
		return copilot.PermissionRequestResult{
			Kind: copilot.PermissionRequestResultKindApproved,
		}, nil
	}

	settings := agentSettingsOrEmpty(ctx, a.settings)
	systemContent := analyzerSystemPrompt + languageAddendum(settings.OutputLanguage)

	session, err := a.client.CreateSession(ctx, &copilot.SessionConfig{
		Model:            model,
		Streaming:        true,
		WorkingDirectory: repoPath,
		SystemMessage: &copilot.SystemMessageConfig{
			Mode:    "replace",
			Content: systemContent,
		},
		OnPermissionRequest: denyWrites,
	})
	if err != nil {
		return "", fmt.Errorf("copilot: analyzer session: %w", err)
	}
	defer func() { _ = session.Disconnect() }()

	idleCh := make(chan struct{})
	idleOnce := make(chan struct{}, 1)
	var transcript strings.Builder

	sessionStart := time.Now()
	slog.Info("analyzer: session start",
		"repo", repoPath, "model", model)

	unsubscribe := session.On(func(e copilot.SessionEvent) {
		elapsed := time.Since(sessionStart)
		switch d := e.Data.(type) {
		case *copilot.SessionIdleData:
			slog.Info("analyzer: idle",
				"repo", repoPath, "elapsed_ms", elapsed.Milliseconds())
			select {
			case idleOnce <- struct{}{}:
				close(idleCh)
			default:
			}
			return
		case *copilot.AssistantUsageData:
			in := int64(0)
			if d.InputTokens != nil {
				in = int64(*d.InputTokens)
			}
			outTok := int64(0)
			if d.OutputTokens != nil {
				outTok = int64(*d.OutputTokens)
			}
			slog.Info("analyzer: llm call",
				"repo", repoPath,
				"elapsed_ms", elapsed.Milliseconds(),
				"in_tokens", in, "out_tokens", outTok)
			if progress != nil {
				progress(fmt.Sprintf("LLM turn — %d in / %d out tokens", in, outTok))
			}
		case *copilot.ToolExecutionStartData:
			args := compactArgs(d.Arguments, 400)
			slog.Info("analyzer: tool start",
				"repo", repoPath,
				"tool", d.ToolName,
				"call_id", d.ToolCallID,
				"args", args)
			if progress != nil {
				progress(fmt.Sprintf("tool %s — %s", d.ToolName, args))
			}
		case *copilot.ToolExecutionCompleteData:
			errStr, _, _ := toolEndSummary(d, 200)
			attrs := []any{
				"repo", repoPath, "call_id", d.ToolCallID, "ok", d.Success,
			}
			if errStr != "" {
				attrs = append(attrs, "err", errStr)
			}
			slog.Info("analyzer: tool end", attrs...)
			if !d.Success && progress != nil {
				progress(fmt.Sprintf("tool error: %s", errStr))
			}
		case *copilot.AssistantIntentData:
			if progress != nil {
				progress(fmt.Sprintf("intent: %s", d.Intent))
			}
		}
		if raw := MapSessionEvent(e); raw != nil && raw.Kind == task.EventAssistantDelta {
			transcript.WriteString(raw.Payload)
		}
	})
	defer unsubscribe()

	if _, err := session.Send(ctx, copilot.MessageOptions{Prompt: prompt}); err != nil {
		return "", fmt.Errorf("copilot: analyzer send: %w", err)
	}

	select {
	case <-idleCh:
	case <-ctx.Done():
		_ = session.Disconnect()
		return "", ctx.Err()
	}

	return transcript.String(), nil
}

// analyzerSystemPrompt is the system message attached to every
// analyzer session. It's intentionally terse — the detailed format
// instructions live in the user prompt (from ctxmem/analyzer) so the
// user can edit the task-level prompt without changing the system
// directive.
const analyzerSystemPrompt = "You are a code auditor reading an existing repository. " +
	"Follow the user prompt exactly. Do not modify any files. " +
	"Prefer concise, evidence-based summaries over speculation. " +
	"Return structured JSON when the user asks for it."

// SummarizeTask runs a short read-only session in the worktree of a
// completed task and returns a 1-2 sentence Decision summary. The
// LLM is told to return exactly "none" for trivial work so the
// observer can filter without regex.
//
// Intentionally shares the Analyzer struct rather than a dedicated
// type: the session configuration (read-only, deny writes, system
// prompt) is identical; only the user prompt differs.
func (a *Analyzer) SummarizeTask(ctx context.Context, worktreePath, overrideModel, goal string, files []string) (string, error) {
	prompt := buildSummaryPrompt(worktreePath, goal, files)
	return a.Analyze(ctx, worktreePath, overrideModel, prompt, nil)
}

// buildSummaryPrompt composes the Decision-summary user message. The
// LLM is asked to self-assess whether the change reflects something
// worth persisting as a Decision, and return structured JSON so the
// Go side can filter on the self-reported confidence.
func buildSummaryPrompt(worktreePath, goal string, files []string) string {
	var b strings.Builder
	b.WriteString("A FleetKanban task just completed inside this worktree:\n\n  ")
	b.WriteString(worktreePath)
	b.WriteString("\n\nOriginal goal:\n  ")
	b.WriteString(goal)
	b.WriteString("\n\nFiles the agent touched:\n")
	shown := files
	if len(shown) > 20 {
		shown = shown[:20]
	}
	for _, f := range shown {
		b.WriteString("  - ")
		b.WriteString(f)
		b.WriteString("\n")
	}
	b.WriteString(`
Your job: decide whether this change embodies a lasting architectural decision, coding convention, or constraint that a future developer should see as repository-bound memory.

Respond with a SINGLE JSON object (no prose outside it):

{
  "worth_remembering": true | false,
  "confidence":        0.0 to 1.0,
  "label":             "short title (under 60 chars, no timestamps, no task ids)",
  "summary":           "1-2 sentence description of the decision / pattern / constraint",
  "reasoning":         "why this crossed / failed the worth_remembering bar"
}

Set worth_remembering=TRUE ONLY when the change:
  - adopts or abandons a library / framework / protocol
  - introduces or removes a binding architectural constraint
  - establishes a naming / structural / error-handling convention the rest of the repo will follow
  - encodes a non-obvious design choice with visible impact on other files

Set worth_remembering=FALSE when the change is any of:
  - bug fix without design implications
  - typo / formatting / lint / auto-generated code updates
  - version bump / dependency-only edit
  - test additions for existing behaviour
  - rename / move without semantic change
  - generic "improved X" wording with no specific convention

Confidence must reflect your certainty: sub-0.7 values will be filtered out. Read files with the view tool when the goal+file list is ambiguous. Do not pad the summary with filler — if you cannot state a concrete convention in under 2 sentences, it probably isn't worth remembering.`)
	return b.String()
}
