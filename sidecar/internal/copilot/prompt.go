//go:build windows

package copilot

import (
	"fmt"
	"strings"
	"unicode"
	"unicode/utf8"

	"github.com/haya3/fleetkanban/internal/task"
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
	base := fmt.Sprintf(`You are a FleetKanban agent.
Working directory (cwd): %s
Goal: %s
Constraints:
  - Do not modify files outside the cwd.
  - After implementing, provide a concise summary of the changes made.`,
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
	return fmt.Sprintf(`[Review feedback — from the previous reviewer]
%s

Required steps (mandatory):
1. First check the current worktree state with git status and view relevant files.
2. Determine whether the feedback is already satisfied by the current state.
3. If already satisfied: make no additional changes and declare exactly on the final line:
   NO_CHANGE_NEEDED: <1-2 sentences explaining why the feedback is already met>
4. Only modify code if the feedback is not yet satisfied.
5. If you made changes, verify the result with git diff before finishing.`, fb)
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
	return BuildSubtaskPromptWithContext(t, sub, task.SubtaskRunContext{})
}

// BuildSubtaskPromptWithContext is BuildSubtaskPrompt's richer form.
// Orchestrator calls this after collecting plan.summary and prior
// subtask.end events so each Coder starts primed with "what we know
// about the repo" and "what the previous subtasks already built".
func BuildSubtaskPromptWithContext(t *task.Task, sub *task.Subtask, c task.SubtaskRunContext) string {
	role := SanitizeSingleLine(sub.AgentRole)
	if role == "" {
		role = "agent"
	}
	title := SanitizeSingleLine(sub.Title)

	// Planner-authored concrete instruction. Multi-line, so goes through
	// SanitizeGoal (not SingleLine) to preserve paragraph structure. Empty
	// for legacy / manual subtasks — the template handles that case with
	// the title-only fallback below.
	instruction := SanitizeGoal(sub.Prompt)

	var instructionBlock string
	if instruction != "" {
		instructionBlock = fmt.Sprintf(`

Subtask instruction (from planner — follow this precisely):
%s`, instruction)
	}

	var planBlock string
	if ps := SanitizeGoal(c.PlanSummary); ps != "" {
		planBlock = fmt.Sprintf(`

Planner's investigation summary (context — do not re-explore what's already known):
%s`, ps)
	}

	var priorBlock string
	if len(c.PriorSummaries) > 0 {
		var b strings.Builder
		b.WriteString("\n\nPrevious subtasks in this task (already done — their changes are live in the worktree):")
		for i, p := range c.PriorSummaries {
			fmt.Fprintf(&b, "\n  %d. [%s] %s\n     %s",
				i+1,
				SanitizeSingleLine(p.Role),
				SanitizeSingleLine(p.Title),
				SanitizeSingleLine(p.Summary))
		}
		priorBlock = b.String()
	}

	verificationNote := "  - If the instruction does not specify a verification step, skip running tests / builds — the final subtask verifies the whole change."
	if c.IsFinalSubtask {
		verificationNote = "  - THIS IS THE FINAL SUBTASK. Run the full verification (build, tests) the instruction specifies before declaring done."
	}

	base := fmt.Sprintf(`You are a FleetKanban %s agent.
Working directory (cwd): %s

Parent task goal: %s%s%s

Current subtask (title): %s%s

Constraints:
  - Do not modify files outside the cwd.
  - The worktree already contains any edits made by prior subtasks. Respect them; do not undo or duplicate.
%s
  - After completing this subtask, provide a concise summary of what was done in one paragraph — this is the handoff note the next subtask and the reviewer read.`,
		role,
		t.WorktreePath,
		SanitizeSingleLine(t.Goal),
		planBlock,
		priorBlock,
		title,
		instructionBlock,
		verificationNote)

	if fb := SanitizeGoal(t.ReviewFeedback); fb != "" {
		// Subtask-scoped rework note: most fields apply per-subtask, but
		// the reviewer feedback is task-wide. Include the same anti-loop
		// guidance with a subtask-scope qualifier.
		return fmt.Sprintf(`%s

%s

Note: this feedback applies to the task as a whole. Only address the parts
that fall within the scope of this subtask; skip anything unrelated.`, base, reworkBlock(fb))
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
