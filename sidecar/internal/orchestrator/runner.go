// Package orchestrator schedules, executes, and fans out events for tasks.
//
// Phase 1 responsibilities:
//
//   - Enforce the configured concurrency limit (golang.org/x/sync/semaphore,
//     FIFO ordering).
//   - Materialize a git worktree per task, invoke the AgentRunner with
//     cwd = worktree, and persist the resulting event stream.
//   - Surface events to the UI via the EventSink hook so the gRPC broker can
//     stream them to the Flutter client without touching SQL.
//   - Drive task state-machine transitions (queued → in_progress →
//     human_review / failed / aborted).
//
// The orchestrator does NOT tear down worktrees on task completion. Phase 1
// defaults to "Keep" (branch preserved) and waits for the user to invoke
// Finalize explicitly with Keep / Discard (Merge lands in a later phase).
package orchestrator

import (
	"context"

	"github.com/FleetKanban/fleetkanban/internal/task"
	"github.com/FleetKanban/fleetkanban/internal/worktree"
)

// AgentRunner executes one task from start to finish inside a worktree.
//
// Implementations (initially internal/copilot.Runner) MUST:
//   - Send every observable event on `out`.
//   - Close `out` exactly once before returning.
//   - Respect ctx cancellation by terminating their child process and
//     returning promptly.
//
// Return value semantics — the orchestrator uses these to decide the next
// status:
//   - nil            → the session ended normally; task moves to human_review.
//   - ctx.Err()       → treated as either Aborted (user Cancel) or Failed
//     (timeout / shutdown), based on the orchestrator's own
//     bookkeeping.
//   - any other err   → task moves to failed(runtime).
type AgentRunner interface {
	// Run drives a single whole-task Copilot session (legacy / Planner=nil
	// path). modelUsed echoes the Code-stage model resolved inside the
	// runner so the orchestrator can record it on Task.Model when the
	// task had no explicit override.
	Run(ctx context.Context, t *task.Task, out chan<- *task.AgentEvent) (modelUsed string, err error)

	// RunSubtask drives one Copilot session scoped to sub within the parent
	// task's worktree. The agent role named on sub is injected into the
	// session's system prompt so the planner's decomposition actually
	// propagates to execution. Semantics of `out` and the return value
	// match Run; modelUsed is recorded on Subtask.CodeModel so the UI can
	// surface a per-subtask Code-stage badge.
	RunSubtask(ctx context.Context, t *task.Task, sub *task.Subtask, out chan<- *task.AgentEvent) (modelUsed string, err error)
}

// Planner decomposes a task into an ordered Subtask DAG. Implementations
// (internal/copilot.Planner in Phase 1) are read-only Copilot sessions
// that emit a topologically sorted list with DependsOn rewritten to ULID
// references so the executor can walk it directly.
//
// Plan is called once per task first-run. Reworks bypass planning and
// re-execute the existing plan. The returned modelUsed string is the
// model id that actually produced the plan — the orchestrator records
// it on Task.PlanModel so the UI can surface which model ran each
// stage. When the Planner resolves a fallback default (because t.PlanModel
// is empty) that resolved id is returned; when t.PlanModel is honoured
// verbatim it is echoed back unchanged.
type Planner interface {
	Plan(ctx context.Context, t *task.Task) (subs []*task.Subtask, modelUsed string, err error)
}

// SubtaskRepo is the slice of the subtask store the orchestrator needs
// during planning and subtask execution. CreatePlan atomically replaces
// any existing subtasks for the parent. ListByTask lets the dispatcher
// skip re-planning on reworks. Update persists per-subtask status
// transitions (pending → doing → done/failed).
type SubtaskRepo interface {
	CreatePlan(ctx context.Context, parentID string, subs []*task.Subtask) error
	ListByTask(ctx context.Context, parentID string) ([]*task.Subtask, error)
	Update(ctx context.Context, sub *task.Subtask) error
}

// TaskRepo is the slice of the task store the orchestrator needs. Defined as
// an interface so tests can substitute an in-memory mock without pulling in
// SQLite. Matches internal/store.TaskStore.
type TaskRepo interface {
	Get(ctx context.Context, id string) (*task.Task, error)
	UpdateFields(ctx context.Context, t *task.Task) error
	Transition(
		ctx context.Context,
		id string,
		from, to task.Status,
		errCode task.ErrorCode,
		errMsg string,
		finalization task.FinalizationKind,
	) error
	// SetBranchExists flips the branch_exists flag without touching any
	// other field. Used by the post-done merge path, which needs to mark
	// the branch gone after deleting it without disturbing Status or the
	// stale-update check in UpdateFields.
	SetBranchExists(ctx context.Context, id string, exists bool) error
}

// EventRepo is the slice of the event store the orchestrator needs.
type EventRepo interface {
	NextSeq(ctx context.Context, taskID string) (int64, error)
	Append(ctx context.Context, e *task.AgentEvent) error
	AppendBatch(ctx context.Context, events []*task.AgentEvent) error
	AppendAutoSeq(ctx context.Context, e *task.AgentEvent) error
}

// RepositoryRepo looks up the filesystem path for a repository ID.
type RepositoryRepo interface {
	Path(ctx context.Context, repoID string) (string, error)
	TouchLastUsed(ctx context.Context, repoID string) error
}

// WorktreeService creates and removes git worktrees. Matches
// internal/worktree.Manager.
type WorktreeService interface {
	Create(ctx context.Context, in worktree.CreateInput) (*worktree.Created, error)
	Remove(ctx context.Context, repoPath, wtPath, taskID string, mode worktree.RemoveMode) error
	Diff(ctx context.Context, wtPath, baseBranch string) (string, error)
	// Merge advances baseBranch so it contains the tip of fleetkanban/<taskID>
	// without disturbing any worktree's current checkout. Used by the
	// FinalizeMerge finalization path.
	Merge(ctx context.Context, repoPath, baseBranch, taskID string) (worktree.MergeResult, error)
	// DeleteBranch force-removes the branch (git branch -D). Used by the
	// post-done merge path after the fleetkanban/<id> branch has been merged
	// into base — the worktree was already torn down at Keep time, so we
	// only need to clean the branch up.
	DeleteBranch(ctx context.Context, repoPath, branch string) error
}

// ReviewDecision is the verdict produced by an AIReviewer after inspecting
// a task's diff. Approve=true advances the task to human_review; Approve=
// false saves Feedback onto the task and loops it back to queued for a
// rework pass.
type ReviewDecision struct {
	Approve  bool
	Feedback string
}

// AIReviewer inspects a completed task's diff and produces a decision.
// Phase 2 wires this to a Copilot-backed reviewer; tests can inject a
// stub that returns canned decisions.
//
// prevFeedback is the feedback the reviewer itself emitted on the
// previous ai_review cycle (empty on the first pass) so the reviewer
// can self-check whether its earlier request is already satisfied —
// this is the anti-loop hook that lets the reviewer drop repeated
// complaints about items the agent already addressed.
//
// reworkCount is the current rework counter (0 on first review);
// informational context for the reviewer's prompt. Cap enforcement
// lives in the orchestrator, not here.
//
// A nil Reviewer on the orchestrator Config means "pass-through" — the
// task is auto-advanced to human_review after a short delay, preserving
// the original Phase 1 behavior for environments without Copilot auth.
type AIReviewer interface {
	// Review returns the decision plus the model id that actually produced
	// it — the orchestrator records modelUsed on Task.ReviewModel so the
	// UI can surface which model ran the Review stage. Resolution rules
	// mirror Planner.Plan: Task.ReviewModel is honoured when non-empty,
	// otherwise the reviewer falls back to its configured default and
	// returns the resolved id.
	Review(ctx context.Context, t *task.Task, diff, prevFeedback string, reworkCount int) (decision ReviewDecision, modelUsed string, err error)
}

// EventSink receives every persisted event. Typical implementation: forward
// to the gRPC broker so Flutter subscribers see the stream. The sink MUST
// NOT block; if it cannot keep up, it should drop or spawn a goroutine.
type EventSink func(e *task.AgentEvent)

// Notification is the terminal-state summary handed to a Notifier.
type Notification struct {
	TaskID string
	Goal   string
	Status task.Status
	Err    string // empty unless Status == StatusFailed
}

// Notifier is invoked once per task when it reaches a user-actionable end
// state (human_review / done / aborted / failed). Typical implementation:
// Windows Toast. MUST NOT block; the orchestrator calls Notify synchronously
// on its dispatch goroutine.
type Notifier func(n Notification)
