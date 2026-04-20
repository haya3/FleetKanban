//go:build windows

package copilot

import (
	"fmt"
	"strings"
	"unicode"
	"unicode/utf8"

	"github.com/FleetKanban/fleetkanban/internal/task"
)

// MaxGoalRunes caps the Goal length included in the prompt. Long goals are
// almost always adversarial or accidental paste; we keep the first N runes
// and note the truncation so the model can behave consistently. The value is
// intentionally generous (2k runes ≈ a full paragraph) to avoid surprising
// legitimate users.
const MaxGoalRunes = 2000

// BuildPrompt builds the natural-language prompt for a task session. The
// Goal is sanitized (newlines folded, control characters stripped, length
// capped) before being interpolated so that arbitrary user input cannot
// smuggle escape sequences or newlines into the enclosing instructions.
// Goal occupies a single-line slot so SanitizeSingleLine is used; the
// multi-line ReviewFeedback block keeps SanitizeGoal semantics.
//
// When the task has a non-empty ReviewFeedback (populated by SubmitReview
// during a rework), the feedback is prepended so the agent can address the
// reviewer's points on the next iteration.
func BuildPrompt(t *task.Task) string {
	base := fmt.Sprintf(`あなたは FleetKanban のエージェントです。
作業ディレクトリは現在の cwd = %s。
目的: %s
制約:
  - cwd 外のファイルを変更してはいけない
  - 実装後、変更内容を簡潔に要約してください`,
		t.WorktreePath, SanitizeSingleLine(t.Goal))

	if fb := SanitizeGoal(t.ReviewFeedback); fb != "" {
		return fmt.Sprintf(`%s

%s`, base, reworkBlock(fb))
	}
	return base
}

// reworkBlock is the shared rework guidance appended to both BuildPrompt
// and BuildSubtaskPrompt when the task carries review feedback. It
// deliberately instructs the agent to verify whether the feedback is
// already satisfied before editing — a rework loop typically starts when
// the reviewer flags something that's already in the worktree and the
// agent "addresses" it by rewriting identical content, producing the
// same diff and the same reviewer complaint. Breaking that cycle is the
// point of this block.
func reworkBlock(fb string) string {
	return fmt.Sprintf(`【レビュー指摘 — 前回のレビュアーからのフィードバック】
%s

対応手順（厳守）:
1. まず git status / 関連ファイルの view で現在の worktree 状態を確認する。
2. 指摘内容がすでに現状で満たされているか判断する。
3. 満たされている場合: 追加の変更は行わず、最終行で次を厳密に宣言する:
   NO_CHANGE_NEEDED: <すでに満たされている理由を 1-2 文>
4. 満たされていない場合のみコードを修正する。
5. 修正した場合は最後に git diff で反映を確認する。`, fb)
}

// BuildSubtaskPrompt composes the prompt for one subtask session. The
// parent task's goal, sanitised review feedback (on rework), the subtask
// title and the planner-invented agent role are interpolated into a
// short instruction so the session has enough context to execute the
// specific node without re-planning.
//
// The role is deliberately not sanity-checked against a fixed set; the
// planner invents roles per task, and baking a whitelist would defeat
// that. Goal / Title / AgentRole are single-line slots and go through
// SanitizeSingleLine so a newline in any of them cannot break out of
// its slot and inject new instructions into the enclosing prompt.
func BuildSubtaskPrompt(t *task.Task, sub *task.Subtask) string {
	role := SanitizeSingleLine(sub.AgentRole)
	if role == "" {
		role = "エージェント"
	}
	title := SanitizeSingleLine(sub.Title)

	base := fmt.Sprintf(`あなたは FleetKanban の %s エージェントです。
作業ディレクトリは現在の cwd = %s。

親タスクの目的: %s

今回の subtask (title): %s

制約:
  - cwd 外のファイルを変更してはいけない
  - 他の subtask の成果物はこの worktree 内に既に存在する前提でよい
  - 完了後、この subtask で何をしたかを簡潔に要約してください`,
		role, t.WorktreePath, SanitizeSingleLine(t.Goal), title)

	if fb := SanitizeGoal(t.ReviewFeedback); fb != "" {
		// Subtask-scoped rework note: most fields apply per-subtask, but
		// the reviewer feedback is task-wide. Include the same anti-loop
		// guidance with a subtask-scope qualifier.
		return fmt.Sprintf(`%s

%s

補足: このフィードバックはタスク全体宛てです。この subtask の範囲で
対応すべき部分だけ扱い、関係ない部分はスキップしてください。`, base, reworkBlock(fb))
	}
	return base
}

// SanitizeGoal removes control characters (except TAB / LF which may appear
// in legitimate multi-line descriptions) and truncates overly long goals to
// MaxGoalRunes. Exposed for tests and for callers that want to surface the
// same string back to the UI. Use SanitizeSingleLine for fields the prompt
// treats as a single-line slot (Goal / Title / AgentRole) — preserving
// newlines in those slots lets crafted input break out of the enclosing
// instruction block.
func SanitizeGoal(s string) string {
	if !utf8.ValidString(s) {
		s = strings.ToValidUTF8(s, "")
	}
	var b strings.Builder
	b.Grow(len(s))
	for _, r := range s {
		switch {
		case r == '\t' || r == '\n':
			b.WriteRune(r)
		case unicode.IsControl(r):
			// Drop: C0 (except TAB/LF) and C1 controls.
		default:
			b.WriteRune(r)
		}
	}
	out := b.String()
	if runes := []rune(out); len(runes) > MaxGoalRunes {
		out = string(runes[:MaxGoalRunes]) + " …[truncated]"
	}
	return out
}

// SanitizeSingleLine is SanitizeGoal for slots the surrounding prompt
// treats as a single line (Goal, Title, AgentRole). CR / LF / TAB are
// folded to a single ASCII space and consecutive whitespace is collapsed
// so a crafted input like "innocent\n\n## NEW INSTRUCTION: …" can't
// terminate the enclosing instruction and start a new one. Control
// characters outside this set are dropped, length is capped, and invalid
// UTF-8 is repaired — identical policy to SanitizeGoal otherwise.
func SanitizeSingleLine(s string) string {
	if !utf8.ValidString(s) {
		s = strings.ToValidUTF8(s, "")
	}
	var b strings.Builder
	b.Grow(len(s))
	prevSpace := false
	for _, r := range s {
		switch {
		case r == '\r' || r == '\n' || r == '\t' || r == ' ':
			if !prevSpace && b.Len() > 0 {
				b.WriteByte(' ')
				prevSpace = true
			}
		case unicode.IsControl(r):
			// Drop: C0 (except the whitespace handled above) and C1.
		default:
			b.WriteRune(r)
			prevSpace = false
		}
	}
	out := strings.TrimRight(b.String(), " ")
	if runes := []rune(out); len(runes) > MaxGoalRunes {
		out = string(runes[:MaxGoalRunes]) + " …[truncated]"
	}
	return out
}
