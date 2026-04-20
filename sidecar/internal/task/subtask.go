package task

import (
	"fmt"
	"time"
)

// SubtaskStatus is the lifecycle state of a Subtask. Subtasks produced by the
// planner move pending → doing → done; failed is terminal.
type SubtaskStatus string

const (
	SubtaskPending SubtaskStatus = "pending"
	SubtaskDoing   SubtaskStatus = "doing"
	SubtaskDone    SubtaskStatus = "done"
	SubtaskFailed  SubtaskStatus = "failed"
)

// Valid returns true for any recognized SubtaskStatus.
func (s SubtaskStatus) Valid() bool {
	switch s {
	case SubtaskPending, SubtaskDoing, SubtaskDone, SubtaskFailed:
		return true
	}
	return false
}

// Subtask is one unit of the AI-generated execution plan under a parent Task.
// The parent-task linkage is CASCADE-on-delete at the DB level.
//
// AgentRole is a free-form role name assigned by the planner (e.g. "coder",
// "test-writer", "researcher") — the executor injects it into the subtask's
// Copilot session system prompt. DependsOn lists Subtask IDs within the same
// parent task that must reach SubtaskDone before this subtask may start; the
// executor topological-sorts DependsOn to schedule runs. With the Phase 1
// single-worktree constraint execution is serialised even when the DAG
// expresses independent branches — parallelism is informational for UI and
// planning, not concurrency.
type Subtask struct {
	ID        string // ULID
	TaskID    string // FK tasks.id
	Title     string
	AgentRole string // planner-invented role name; "" for legacy/manual subtasks
	DependsOn []string
	Status    SubtaskStatus
	OrderIdx  int // planner-assigned topological order; also drives UI ordering
	// CodeModel records the model actually used to execute this subtask
	// (Code stage). Empty until the executor starts running the subtask.
	CodeModel string
	// Round is the 1-based iteration counter within the parent task.
	// Round 1 is the planner's first decomposition; AI / Human REWORK
	// and User Re-run each create a fresh round at max+1, with the
	// previous round's subtasks left in place as history. The
	// orchestrator only executes subtasks belonging to the latest
	// round; the UI stacks earlier rounds above for visual context.
	Round int
	// Prompt is the concrete instruction the planner wrote for this
	// subtask — a full paragraph describing what files to touch, what
	// behaviour to implement, and what to verify. The executor's
	// BuildSubtaskPrompt folds this into the Copilot session prompt
	// so the Coder doesn't have to guess intent from a short Title.
	// Empty for legacy rows / manual subtasks; BuildSubtaskPrompt
	// falls back to the title-only template when empty.
	Prompt    string
	CreatedAt time.Time
	UpdatedAt time.Time
}

// SubtaskRunContext is the optional context the orchestrator threads
// into a subtask's prompt at execution time. These are run-time
// values (not persisted on Subtask itself) assembled fresh for each
// session so the Coder agent starts with what the Planner already
// learned and what prior subtasks produced — eliminating a very
// common class of waste where every subtask re-explores the whole
// repo from scratch.
type SubtaskRunContext struct {
	// PlanSummary is the Planner's investigation summary (from the
	// plan.summary event). Empty when no summary exists for this
	// round.
	PlanSummary string
	// PriorSummaries lists every subtask in the same round that has
	// already finished, in execution order. Each entry is a one-
	// paragraph "what I did" note the Coder can use to avoid
	// redoing or undoing prior work.
	PriorSummaries []PriorSubtaskSummary
	// IsFinalSubtask is true when this subtask is the last in the
	// round. The runner uses it to decide whether to nudge the
	// agent to run full verification (tests, build) or skip it to
	// let the final subtask cover the whole change.
	IsFinalSubtask bool
}

// PriorSubtaskSummary is one already-completed subtask's outcome
// folded into SubtaskRunContext for the next subtask's prompt.
type PriorSubtaskSummary struct {
	Title   string
	Role    string
	Summary string
}

// Validate performs invariant checks that should hold for any persisted Subtask.
func (s *Subtask) Validate() error {
	if s.ID == "" {
		return fmt.Errorf("subtask: ID is required")
	}
	if s.TaskID == "" {
		return fmt.Errorf("subtask %s: TaskID is required", s.ID)
	}
	if s.Title == "" {
		return fmt.Errorf("subtask %s: Title is required", s.ID)
	}
	if !s.Status.Valid() {
		return fmt.Errorf("subtask %s: invalid status %q", s.ID, s.Status)
	}
	for _, dep := range s.DependsOn {
		if dep == "" {
			return fmt.Errorf("subtask %s: empty dependency id", s.ID)
		}
		if dep == s.ID {
			return fmt.Errorf("subtask %s: self-dependency", s.ID)
		}
	}
	return nil
}
