// Package task defines the core Task domain model, status values, error codes,
// and the finite state machine that governs legal transitions.
//
// The package is dependency-free: no database, no filesystem, no logging.
// Higher layers (internal/store, internal/orchestrator) adapt this model
// to persistence and execution.
package task

import (
	"fmt"
	"time"
)

// Status is the lifecycle state of a Task. Kanban columns map 1:1 to primary
// statuses: planning / queued / in_progress / ai_review / human_review / done.
// See transition.go for the authoritative state machine.
type Status string

const (
	StatusPlanning    Status = "planning"     // just created; editable, not yet queued
	StatusQueued      Status = "queued"       // user pressed Run; awaiting orchestrator pick
	StatusInProgress  Status = "in_progress"  // Copilot session active
	StatusAIReview    Status = "ai_review"    // automated verification (Phase 2 populates this stage)
	StatusHumanReview Status = "human_review" // awaiting user Keep / Merge / Discard decision
	StatusDone        Status = "done"         // finalized successfully; see Task.Finalization
	StatusCancelled   Status = "cancelled"    // Discard: worktree and branch both removed
	StatusAborted     Status = "aborted"      // User aborted during InProgress; worktree and branch kept
	StatusFailed      Status = "failed"       // Runtime error
)

// Valid returns true for any recognized Status.
func (s Status) Valid() bool {
	switch s {
	case StatusPlanning, StatusQueued, StatusInProgress,
		StatusAIReview, StatusHumanReview, StatusDone,
		StatusCancelled, StatusAborted, StatusFailed:
		return true
	}
	return false
}

// IsTerminal reports whether the status represents a final state that should
// not transition further in normal flow. Aborted is intentionally non-terminal
// because the user may subsequently choose Keep (Done) / Merge (Done) / Discard (Cancelled).
func (s Status) IsTerminal() bool {
	switch s {
	case StatusDone, StatusCancelled, StatusFailed:
		return true
	}
	return false
}

// FinalizationKind records how a task that reached StatusDone was finalized.
// It is empty for any non-Done status; Done tasks MUST have one of Keep / Merged.
type FinalizationKind string

const (
	FinalizationNone   FinalizationKind = ""       // non-Done status
	FinalizationKeep   FinalizationKind = "keep"   // worktree removed, branch preserved
	FinalizationMerged FinalizationKind = "merged" // merged into the target branch; both removed
)

// Valid returns true for any recognized FinalizationKind.
func (f FinalizationKind) Valid() bool {
	switch f {
	case FinalizationNone, FinalizationKeep, FinalizationMerged:
		return true
	}
	return false
}

// ErrorCode classifies the reason a task ended in StatusFailed. Stored
// alongside Task.ErrorMessage for UI surfacing and telemetry.
type ErrorCode string

const (
	ErrCodeNone          ErrorCode = ""
	ErrCodeRuntime       ErrorCode = "runtime"        // Copilot CLI exit non-zero or unexpected error
	ErrCodeInterrupted   ErrorCode = "interrupted"    // crash recovery: was running when app crashed
	ErrCodePathEscape    ErrorCode = "path_escape"    // attempted write outside worktree
	ErrCodeMergeConflict ErrorCode = "merge_conflict" // reserved for merge operation failures
	ErrCodeTimeout       ErrorCode = "timeout"        // exceeded TaskTimeout
	ErrCodeAuth          ErrorCode = "auth"           // Copilot CLI not authenticated
	ErrCodeAIReview      ErrorCode = "ai_review"      // automated verification failed (Phase 2)
)

// Task is the full persisted state of a single agent run.
//
// A Task may outlive its execution: Status == StatusDone / StatusAborted
// tasks are retained (and their branch preserved when applicable) so the user
// can operate on them later.
type Task struct {
	ID           string // ULID, generated at creation
	RepoID       string // FK repositories.id
	Goal         string // natural-language description from user
	BaseBranch   string // branch the worktree was forked from
	Branch       string // fleetkanban/<ID> — the task's working branch
	WorktreePath string // absolute, %APPDATA%\FleetKanban\worktrees\<ID>
	Model        string // Copilot CLI model identifier, e.g. "gpt-4.1"
	// PlanModel / ReviewModel record the model actually used for the Plan
	// and Review stages respectively. Empty for tasks that never entered
	// that stage (e.g. no plan generated yet, or no AI review run). Code
	// stage uses Model (kept for backward compatibility and as the primary
	// runtime identifier for Copilot CLI invocations).
	PlanModel    string
	ReviewModel  string
	Status       Status
	Finalization FinalizationKind // set only when Status == StatusDone
	ErrorCode    ErrorCode        // set only when Status == StatusFailed
	ErrorMessage string           // human-readable diagnostic (may be empty)
	SessionID    string           // Copilot SDK session identifier
	BranchExists bool             // false once reaper detects external branch deletion
	// ReviewFeedback is the most recent feedback recorded by the reviewer
	// (human or AI). It is prepended to the next Copilot prompt when the task
	// is reworked (Human Review → queued with feedback). History of all past
	// feedbacks is retained in the events table as kind="review.submitted".
	ReviewFeedback string
	// ReworkCount is the number of AI Review → queued rework cycles the
	// task has been through since its last fresh run. Orchestrator
	// transitions increment this on ai_review→queued and reset it to 0
	// when the task enters queued from any other source (human_review
	// retry, failed retry, aborted retry) or reaches a terminal status.
	// Used by orchestrator.runAIReview to cap auto-rework at MaxReworkCount
	// so a misbehaving reviewer can't burn Copilot tokens in an infinite
	// loop; when the cap is hit the task is escalated to human_review
	// instead of being re-queued.
	ReworkCount int
	CreatedAt   time.Time
	UpdatedAt   time.Time
	StartedAt   *time.Time // first StatusInProgress entry
	FinishedAt  *time.Time // most recent human/ai_review or terminal entry (cleared on rework)
}

// Validate performs invariant checks that should hold for any persisted Task.
// Callers typically run this before UPDATE to catch programmer mistakes early.
func (t *Task) Validate() error {
	if t.ID == "" {
		return fmt.Errorf("task: ID is required")
	}
	if t.RepoID == "" {
		return fmt.Errorf("task %s: RepoID is required", t.ID)
	}
	if t.Goal == "" {
		return fmt.Errorf("task %s: Goal is required", t.ID)
	}
	if !t.Status.Valid() {
		return fmt.Errorf("task %s: invalid status %q", t.ID, t.Status)
	}
	if !t.Finalization.Valid() {
		return fmt.Errorf("task %s: invalid finalization %q", t.ID, t.Finalization)
	}
	if t.Status == StatusFailed && t.ErrorCode == ErrCodeNone {
		return fmt.Errorf("task %s: failed status requires ErrorCode", t.ID)
	}
	if t.Status != StatusFailed && t.ErrorCode != ErrCodeNone {
		return fmt.Errorf("task %s: non-failed status must not set ErrorCode (got %q)", t.ID, t.ErrorCode)
	}
	if t.Status == StatusDone && t.Finalization == FinalizationNone {
		return fmt.Errorf("task %s: done status requires Finalization", t.ID)
	}
	if t.Status != StatusDone && t.Finalization != FinalizationNone {
		return fmt.Errorf("task %s: non-done status must not set Finalization (got %q)", t.ID, t.Finalization)
	}
	return nil
}
