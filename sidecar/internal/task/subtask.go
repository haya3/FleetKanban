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
	CreatedAt time.Time
	UpdatedAt time.Time
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
