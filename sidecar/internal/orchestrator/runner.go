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

	"github.com/haya3/fleetkanban/internal/task"
	"github.com/haya3/fleetkanban/internal/worktree"
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
	// task had no explicit override. usage carries the session's total
	// premium-request / token / duration aggregate (zero-valued when
	// the session emitted no usage events, e.g. aborted before first
	// LLM call) so the orchestrator can publish an EventSessionUsage
	// for the UI's per-stage cost display.
	Run(ctx context.Context, t *task.Task, out chan<- *task.AgentEvent) (modelUsed string, usage task.SessionUsage, err error)

	// RunSubtask drives one Copilot session scoped to sub within the parent
	// task's worktree. The agent role named on sub is injected into the
	// session's system prompt so the planner's decomposition actually
	// propagates to execution. subCtx carries the plan summary + prior
	// subtask summaries the orchestrator assembled so the runner can
	// hand the Coder agent context instead of making it re-explore the
	// repo from scratch. Semantics of `out` and the return value
	// match Run; modelUsed is recorded on Subtask.CodeModel so the UI can
	// surface a per-subtask Code-stage badge. usage is the same SessionUsage
	// shape Run returns.
	RunSubtask(ctx context.Context, t *task.Task, sub *task.Subtask, subCtx task.SubtaskRunContext, out chan<- *task.AgentEvent) (modelUsed string, usage task.SessionUsage, err error)
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
	// Plan returns the decomposed DAG, the model id that produced it, a
	// short human-readable summary of the planner's investigation
	// findings + decomposition rationale, and the planning session's
	// usage totals. The summary is surfaced via a `plan.summary`
	// AgentEvent so the UI can show users WHAT the planner looked at
	// and WHY this shape was chosen. usage feeds the per-stage cost
	// display via EventSessionUsage. Empty summary is allowed (soft
	// warning) so a planner that forgot the summary block still
	// yields a usable DAG.
	//
	// Streaming contract (mirrors AgentRunner.Run): implementations
	// MUST forward assistant.delta / assistant.reasoning.delta /
	// tool.start / tool.end events on `out` as the SDK emits them so
	// the UI can live-render the planner's "thinking". `out` is
	// closed by the implementation before returning.
	Plan(ctx context.Context, t *task.Task, out chan<- *task.AgentEvent) (subs []*task.Subtask, modelUsed string, summary string, usage task.SessionUsage, err error)
}

// SubtaskRepo is the slice of the subtask store the orchestrator needs
// during planning and subtask execution. CreatePlan atomically replaces
// any existing subtasks for the parent. ListByTask lets the dispatcher
// skip re-planning on reworks. Update persists per-subtask status
// transitions (pending → doing → done/failed).
type SubtaskRepo interface {
	// CreatePlan inserts the new round of subtasks and returns the
	// round number that was assigned (max+1, atomic in the store).
	// Previous rounds are preserved as history.
	CreatePlan(ctx context.Context, parentID string, subs []*task.Subtask) (int, error)
	// ListLatestRound returns subtasks belonging to the highest round
	// for parentID. The orchestrator drives execution off this so each
	// rework cycle only runs the freshly-planned subtasks.
	ListLatestRound(ctx context.Context, parentID string) ([]*task.Subtask, error)
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
	// ListByTask returns events for taskID with seq > sinceSeq,
	// capped at limit (0 = no cap). Used by the orchestrator to
	// reconstruct plan.summary and prior-subtask context before
	// kicking off each Code session.
	ListByTask(ctx context.Context, taskID string, sinceSeq int64, limit int) ([]*task.AgentEvent, error)
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
	// CommitPending stages and commits any pending changes in the worktree.
	// Used by Finalize Keep / Merge so the task branch always has the
	// agent's edits captured as commits before the worktree is torn down —
	// without this step, agents that never ran `git commit` themselves
	// would leave the post-finalize branch (and DiffBranch result) empty.
	// Returns true when a commit was actually created.
	CommitPending(ctx context.Context, wtPath, message string) (bool, error)
}

// ReviewDecision is the verdict produced by an AIReviewer after inspecting
// a task's diff. Approve=true advances the task to human_review; Approve=
// false saves Feedback onto the task and loops it back to queued for a
// rework pass. Summary is the reviewer's pre-decision rationale (what
// was checked, findings) — captured so the UI can show WHY the
// reviewer approved / rejected even when Feedback is empty.
type ReviewDecision struct {
	Approve  bool
	Feedback string
	Summary  string
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
	// Review returns the decision, the model id that actually produced
	// it, and the review session's usage totals. modelUsed is recorded
	// on Task.ReviewModel so the UI can surface which model ran the
	// Review stage; usage is forwarded as EventSessionUsage so the
	// per-stage cost display has Review numbers too. Resolution rules
	// mirror Planner.Plan.
	//
	// Streaming contract (mirrors AgentRunner.Run): implementations
	// MUST forward assistant.delta / assistant.reasoning.delta /
	// tool.start / tool.end events on `out` as the SDK emits them so
	// the UI can live-render the reviewer's "thinking" — without this
	// path the Review tab in the stage detail dialog has nothing to
	// show. `out` is closed by the implementation before returning.
	Review(ctx context.Context, t *task.Task, diff, prevFeedback string, reworkCount int, out chan<- *task.AgentEvent) (decision ReviewDecision, modelUsed string, usage task.SessionUsage, err error)
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
