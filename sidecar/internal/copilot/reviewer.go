//go:build windows

package copilot

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

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
	client  *copilot.Client
	model   string
	timeout time.Duration
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
	return &Reviewer{client: client, model: model, timeout: reviewerTimeout}, nil
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
func (r *Reviewer) Review(ctx context.Context, t *task.Task, diff, prevFeedback string, reworkCount int) (orchestrator.ReviewDecision, string, error) {
	if t.WorktreePath == "" {
		return orchestrator.ReviewDecision{}, "", errors.New("copilot: reviewer: task has no worktree")
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
		return orchestrator.ReviewDecision{}, "", fmt.Errorf("copilot: reviewer permission: %w", err)
	}
	denyWrites := func(req copilot.PermissionRequest, inv copilot.PermissionInvocation) (copilot.PermissionRequestResult, error) {
		if req.Kind == copilot.PermissionRequestKindWrite {
			return copilot.PermissionRequestResult{
				Kind: copilot.PermissionRequestResultKindDeniedByRules,
			}, nil
		}
		return guard(req, inv)
	}

	session, err := r.client.CreateSession(ctx, &copilot.SessionConfig{
		Model:            model,
		Streaming:        true,
		WorkingDirectory: t.WorktreePath,
		SystemMessage: &copilot.SystemMessageConfig{
			Mode: "replace",
			Content: "あなたはコードレビュー担当です。与えられた情報を踏まえて最終行に必ず次のいずれかを出力してください:\n" +
				approvalMarker + "\n" +
				reworkMarker + " <修正すべき点を 1-2 文で>\n" +
				"最終行以外に APPROVE / REWORK: という語句を含めないでください。迷った場合は APPROVE にし、人間レビュアーに委ねること。",
		},
		OnPermissionRequest: denyWrites,
	})
	if err != nil {
		return orchestrator.ReviewDecision{}, "", fmt.Errorf("copilot: reviewer session: %w", err)
	}
	defer func() { _ = session.Disconnect() }()

	idleCh := make(chan struct{})
	idleOnce := make(chan struct{}, 1)
	var (
		transcript strings.Builder
	)
	unsubscribe := session.On(func(e copilot.SessionEvent) {
		if _, ok := e.Data.(*copilot.SessionIdleData); ok {
			select {
			case idleOnce <- struct{}{}:
				close(idleCh)
			default:
			}
			return
		}
		if ae := MapSessionEvent(e); ae != nil &&
			ae.Kind == task.EventAssistantDelta {
			transcript.WriteString(ae.Payload)
		}
	})
	defer unsubscribe()

	prompt := buildReviewPrompt(t, diff, prevFeedback, reworkCount)
	if _, err := session.Send(ctx, copilot.MessageOptions{Prompt: prompt}); err != nil {
		return orchestrator.ReviewDecision{}, "", fmt.Errorf("copilot: reviewer send: %w", err)
	}

	select {
	case <-idleCh:
	case <-ctx.Done():
		_ = session.Disconnect()
		return orchestrator.ReviewDecision{}, "", ctx.Err()
	}

	return parseReviewDecision(transcript.String()), model, nil
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
		diff = "(空の diff — 変更なし)"
	}
	prevBlock := prevFeedback
	if strings.TrimSpace(prevBlock) == "" {
		prevBlock = "(初回レビュー)"
	}
	return fmt.Sprintf(`以下のタスクの成果物をレビューしてください。

目的: %s
ベースブランチ: %s
ブランチ: %s
これまでの rework 回数: %d

【前回のレビュー指摘】
%s

【diff】
`+"```diff"+`
%s
`+"```"+`

レビュー手順（厳守）:
1. 前回の指摘が存在する場合、view / grep 等の読み取りツールで該当ファイルの現状を確認する。
2. 指摘内容が現在のファイル内容で既に満たされていれば APPROVE。
3. 同じ指摘を繰り返さない。解釈が割れる点は APPROVE して人間レビュアーに委ねる。
4. diff に含まれない理想論より、既存の成果物が目的に合っているかを優先評価する。

出力制約（厳守）:
- 最終行は必ず %s または %s <1-2 文の具体指摘> のどちらか。
- 最終行以外の行に上記マーカーを含めない。装飾や前置きは禁止。
- 迷った場合は APPROVE。`,
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
func parseReviewDecision(transcript string) orchestrator.ReviewDecision {
	trimmed := strings.TrimSpace(transcript)
	if trimmed == "" {
		return orchestrator.ReviewDecision{Approve: true}
	}

	lines := strings.Split(trimmed, "\n")
	// Walk from the end looking for the first non-blank line.
	var finalLine string
	for i := len(lines) - 1; i >= 0; i-- {
		if ln := strings.TrimSpace(lines[i]); ln != "" {
			finalLine = ln
			break
		}
	}

	switch {
	case strings.HasPrefix(finalLine, approvalMarker):
		return orchestrator.ReviewDecision{Approve: true}
	case strings.HasPrefix(finalLine, reworkMarker):
		fb := strings.TrimSpace(strings.TrimPrefix(finalLine, reworkMarker))
		if fb == "" {
			fb = "AI Reviewer が詳細を省略して rework を指示しました"
		}
		return orchestrator.ReviewDecision{Approve: false, Feedback: fb}
	default:
		// Unstructured reply: approve so the user gets the task in
		// human_review. The ambiguous transcript would have been lost
		// under the old "fall-through to rework" behaviour too — Phase 1
		// relied on APPROVE/REWORK markers being present.
		return orchestrator.ReviewDecision{Approve: true}
	}
}
