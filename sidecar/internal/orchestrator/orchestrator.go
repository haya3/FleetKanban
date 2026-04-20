package orchestrator

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log/slog"
	"os"
	"sync"
	"time"

	"github.com/oklog/ulid/v2"
	"golang.org/x/sync/semaphore"

	"github.com/FleetKanban/fleetkanban/internal/task"
	"github.com/FleetKanban/fleetkanban/internal/worktree"
)

// Config configures a new Orchestrator.
type Config struct {
	// Concurrency is the maximum number of tasks running simultaneously.
	// Defaults to 4; phase1-spec §3.3 caps it at 12.
	Concurrency int

	// EventBatchInterval is how often buffered delta events are flushed to
	// the store. Defaults to 100ms (phase1-spec §3.4).
	EventBatchInterval time.Duration

	// EventChannelBuffer is the per-task event channel capacity. Deeper
	// buffers absorb short bursts without stalling the runner's stdout
	// goroutine. Defaults to 1024.
	EventChannelBuffer int

	TaskStore    TaskRepo
	EventStore   EventRepo
	Repositories RepositoryRepo
	Worktrees    WorktreeService
	Runner       AgentRunner
	// Planner, if non-nil, is invoked on a task's first run to decompose
	// the goal into a Subtask DAG. Planner=nil means the orchestrator
	// advances through planning instantly without creating subtasks —
	// preserved for tests and environments without Copilot auth.
	Planner Planner
	// SubtaskStore persists the plan produced by Planner. Required when
	// Planner is non-nil.
	SubtaskStore SubtaskRepo
	// PlanningTimeout bounds a single planning session. Defaults to 5
	// minutes; the Planner's internal timeout stacks under this one.
	PlanningTimeout time.Duration
	// Reviewer, if non-nil, is invoked to decide whether a freshly-finished
	// task should advance to human_review (Approve) or loop back through
	// queued for a rework pass (Approve=false, Feedback set). When nil,
	// the orchestrator falls back to a time-delayed pass-through so the
	// pipeline still completes in environments without Copilot.
	Reviewer AIReviewer
	Sink     EventSink // may be nil
	// Notifier, if non-nil, is called once per task when it reaches a
	// user-actionable end state. Runs on the dispatch goroutine so the
	// implementation must be fast and non-blocking.
	Notifier Notifier
	Logger   *slog.Logger
}

// ConcurrencyMin and ConcurrencyMax clamp the runtime-adjustable concurrency
// limit. Match phase1-spec §3.3.
const (
	ConcurrencyMin = 1
	ConcurrencyMax = 12
)

// MaxReworkCount caps automatic AI-review-driven rework cycles per task.
// Once the counter (tracked on task.Task.ReworkCount, persisted in the
// tasks.rework_count column) reaches this value, further rework
// decisions from the AI Reviewer are short-circuited to human_review
// instead of self-enqueueing — the user takes over the arbitration.
// Set deliberately low (2) because each rework cycle burns a full
// Copilot session and re-planning/re-executing the subtask DAG. If the
// reviewer can't reach an approval in two passes, three more passes
// probably won't help and will just waste tokens.
const MaxReworkCount = 2

// Orchestrator is the central scheduler.
type Orchestrator struct {
	cfg Config

	log      *slog.Logger
	eventIDs ulidFactory

	rootCtx    context.Context
	rootCancel context.CancelFunc
	wg         sync.WaitGroup

	// semMu guards sem and concurrency for live reconfiguration. Keeping them
	// behind a dedicated mutex avoids contending with the per-task running map
	// lock (which is hot path on Enqueue / Cancel).
	semMu       sync.RWMutex
	sem         *semaphore.Weighted
	concurrency int

	mu      sync.Mutex
	running map[string]*runState // keyed by task ID

	// aiReviews tracks the cancel function of any AI review goroutine
	// currently running for a task. Kept separate from `running` because
	// an AI review is not a "running task" in the orchestrator's
	// concurrency-budget sense — it doesn't hold a semaphore slot — but
	// it still needs a cancellation channel so CancelTask can interrupt
	// a long-running reviewer mid-session.
	aiReviews map[string]context.CancelFunc
}

type runState struct {
	cancel      context.CancelFunc
	abortByUser bool
}

// ErrShuttingDown is returned when Enqueue is called after Shutdown.
var ErrShuttingDown = errors.New("orchestrator: shutting down")

// ErrAlreadyRunning is returned when Enqueue is called for a task that is
// already tracked as running.
var ErrAlreadyRunning = errors.New("orchestrator: task already running")

// ErrNotRunning is returned when Cancel targets an unknown task.
var ErrNotRunning = errors.New("orchestrator: task not running")

// New validates cfg and constructs an Orchestrator. The orchestrator owns a
// root context that is cancelled by Shutdown.
func New(cfg Config) (*Orchestrator, error) {
	if cfg.TaskStore == nil || cfg.EventStore == nil || cfg.Worktrees == nil ||
		cfg.Runner == nil || cfg.Repositories == nil {
		return nil, errors.New("orchestrator: TaskStore, EventStore, Repositories, Worktrees, Runner are required")
	}
	if cfg.Concurrency <= 0 {
		cfg.Concurrency = 4
	}
	if cfg.Concurrency < ConcurrencyMin {
		cfg.Concurrency = ConcurrencyMin
	}
	if cfg.Concurrency > ConcurrencyMax {
		cfg.Concurrency = ConcurrencyMax
	}
	if cfg.EventBatchInterval <= 0 {
		cfg.EventBatchInterval = 100 * time.Millisecond
	}
	if cfg.EventChannelBuffer <= 0 {
		cfg.EventChannelBuffer = 1024
	}
	if cfg.PlanningTimeout <= 0 {
		cfg.PlanningTimeout = 5 * time.Minute
	}
	if cfg.Planner != nil && cfg.SubtaskStore == nil {
		return nil, errors.New("orchestrator: SubtaskStore required when Planner is set")
	}
	if cfg.Logger == nil {
		cfg.Logger = slog.Default()
	}

	ctx, cancel := context.WithCancel(context.Background())
	return &Orchestrator{
		cfg:         cfg,
		sem:         semaphore.NewWeighted(int64(cfg.Concurrency)),
		concurrency: cfg.Concurrency,
		log:         cfg.Logger,
		rootCtx:     ctx,
		rootCancel:  cancel,
		running:     make(map[string]*runState),
		aiReviews:   make(map[string]context.CancelFunc),
	}, nil
}

// SetConcurrency changes the maximum number of tasks that may run
// simultaneously. The value is clamped to [ConcurrencyMin, ConcurrencyMax].
//
// Tasks already running are not affected. The new cap governs future
// acquisitions: lowering the limit simply reduces the number of new tasks
// admitted until in-flight tasks finish.
//
// Safe to call concurrently with Enqueue / Cancel / Shutdown.
func (o *Orchestrator) SetConcurrency(n int) int {
	if n < ConcurrencyMin {
		n = ConcurrencyMin
	}
	if n > ConcurrencyMax {
		n = ConcurrencyMax
	}
	o.semMu.Lock()
	defer o.semMu.Unlock()
	if n == o.concurrency {
		return o.concurrency
	}
	o.sem = semaphore.NewWeighted(int64(n))
	o.concurrency = n
	return n
}

// Concurrency returns the current limit.
func (o *Orchestrator) Concurrency() int {
	o.semMu.RLock()
	defer o.semMu.RUnlock()
	return o.concurrency
}

// currentSem snapshots the live semaphore for one dispatch. Holding a direct
// reference lets a dispatcher acquire and release on the same semaphore even
// if SetConcurrency swaps it out mid-flight.
func (o *Orchestrator) currentSem() *semaphore.Weighted {
	o.semMu.RLock()
	defer o.semMu.RUnlock()
	return o.sem
}

// Enqueue schedules the task for execution. The call returns immediately
// after starting the dispatcher goroutine; use WaitIdle or Cancel to
// synchronize with the task's lifecycle.
func (o *Orchestrator) Enqueue(taskID string) error {
	if taskID == "" {
		return errors.New("orchestrator: empty taskID")
	}
	o.mu.Lock()
	if o.rootCtx.Err() != nil {
		o.mu.Unlock()
		return ErrShuttingDown
	}
	if _, ok := o.running[taskID]; ok {
		o.mu.Unlock()
		return ErrAlreadyRunning
	}
	taskCtx, cancel := context.WithCancel(o.rootCtx)
	o.running[taskID] = &runState{cancel: cancel}
	o.wg.Add(1)
	o.mu.Unlock()

	go o.dispatch(taskCtx, taskID)
	return nil
}

// Cancel requests an in-flight task to abort. The task's status transitions
// to aborted once the runner (or AI reviewer) returns. Returns ErrNotRunning
// if the task is not currently tracked by either the dispatcher or an AI
// review goroutine.
func (o *Orchestrator) Cancel(taskID string) error {
	o.mu.Lock()
	defer o.mu.Unlock()
	if rs, ok := o.running[taskID]; ok {
		rs.abortByUser = true
		rs.cancel()
		return nil
	}
	if cancel, ok := o.aiReviews[taskID]; ok {
		cancel()
		// The AI review goroutine is responsible for observing its own
		// ctx cancellation and transitioning ai_review → aborted. We do
		// not unregister here: the goroutine removes itself from the map
		// in its deferred cleanup.
		return nil
	}
	return ErrNotRunning
}

// Running reports the IDs of currently-tracked tasks (queued or in_progress).
func (o *Orchestrator) Running() []string {
	o.mu.Lock()
	defer o.mu.Unlock()
	out := make([]string, 0, len(o.running))
	for id := range o.running {
		out = append(out, id)
	}
	return out
}

// Shutdown cancels every in-flight task, waits for dispatchers to finish,
// and prevents further Enqueue calls. Blocks until all goroutines exit or
// ctx expires.
func (o *Orchestrator) Shutdown(ctx context.Context) error {
	o.rootCancel()
	done := make(chan struct{})
	go func() { o.wg.Wait(); close(done) }()
	select {
	case <-done:
		return nil
	case <-ctx.Done():
		return ctx.Err()
	}
}

// dispatch is the per-task goroutine: acquire sem, create worktree, run the
// agent, transition status, clean up.
func (o *Orchestrator) dispatch(ctx context.Context, taskID string) {
	defer o.wg.Done()
	defer o.unregister(taskID)

	log := o.log.With("task_id", taskID)

	sem := o.currentSem()
	if err := sem.Acquire(ctx, 1); err != nil {
		// Shutdown before we got a slot: drop back to queued silently.
		log.Info("orchestrator: dispatch aborted before acquire", "err", err)
		return
	}
	defer sem.Release(1)

	t, err := o.cfg.TaskStore.Get(ctx, taskID)
	if err != nil {
		log.Error("orchestrator: task lookup failed", "err", err)
		return
	}

	repoPath, err := o.cfg.Repositories.Path(ctx, t.RepoID)
	if err != nil {
		log.Error("orchestrator: repo lookup failed", "err", err)
		// Transition from queued to planning first so failTask can land on
		// the legal planning → failed edge; otherwise the task would sit
		// forever in queued (queued → failed is not a legal edge).
		if tErr := o.cfg.TaskStore.Transition(ctx, taskID,
			task.StatusQueued, task.StatusPlanning, "", "", task.FinalizationNone); tErr == nil {
			o.emitStatus(ctx, taskID, task.StatusQueued, task.StatusPlanning)
			o.failTask(ctx, taskID, task.StatusPlanning, task.ErrCodeRuntime,
				fmt.Sprintf("repo lookup: %v", err))
		}
		return
	}

	// Always re-plan when a Planner is configured. With iteration
	// history (subtasks.round), every queued→in_progress transition
	// represents either a fresh task, a user Re-run, or a REWORK
	// cycle — all three want a new round of subtasks. The previous
	// "skip plan if subtasks exist" optimisation was tied to the now-
	// retired keep-plan rework semantics. Earlier rounds remain in
	// the DB as history and are surfaced by the UI.
	planNeeded := o.cfg.Planner != nil

	// First status transition depends on the branch below. Everything past
	// this point reads t.Status to know whether the dispatcher is in the
	// planning path or the rework path, so the helpers below fail tasks
	// from whatever state t.Status is currently in.
	if planNeeded {
		if err := o.cfg.TaskStore.Transition(ctx, taskID,
			task.StatusQueued, task.StatusPlanning, "", "", task.FinalizationNone); err != nil {
			log.Error("orchestrator: queued→planning failed", "err", err)
			return
		}
		o.emitStatus(ctx, taskID, task.StatusQueued, task.StatusPlanning)
		t.Status = task.StatusPlanning
	} else {
		if err := o.cfg.TaskStore.Transition(ctx, taskID,
			task.StatusQueued, task.StatusInProgress, "", "", task.FinalizationNone); err != nil {
			log.Error("orchestrator: queued→in_progress failed", "err", err)
			return
		}
		o.emitStatus(ctx, taskID, task.StatusQueued, task.StatusInProgress)
		t.Status = task.StatusInProgress
	}
	_ = o.cfg.Repositories.TouchLastUsed(ctx, t.RepoID)

	// On first run the worktree does not yet exist; create it now. On rework
	// (human_review → queued → in_progress) the same worktree is reused so
	// the agent can iterate on the existing changes with the feedback from
	// the reviewer in hand.
	//
	// Before trusting the recorded path, we verify it still exists on disk:
	// the reaper can flip BranchExists to false, and a user / git command
	// outside the app may delete the directory between runs. In those cases
	// we refuse to silently resurrect a vanished worktree — fail with
	// interrupted so the user sees why, and avoid the Copilot runner hitting
	// a cryptic "no such file or directory" later.
	if !o.ensureWorktree(ctx, t, repoPath, log) {
		return
	}
	if err := o.cfg.TaskStore.UpdateFields(ctx, t); err != nil {
		log.Warn("orchestrator: persist worktree path failed", "err", err)
	}

	// File-system watcher: publishes EventFileChanged on the EventBroker
	// so the Files tab in task detail can refresh its diff in real time
	// while the agent works. Started after ensureWorktree so the directory
	// is guaranteed to exist; stopped on dispatch return so the runner's
	// post-completion housekeeping doesn't keep firing UI invalidations.
	watcher, werr := startWorktreeWatcher(t.ID, t.WorktreePath, o.cfg.Sink, log, &o.eventIDs)
	if werr != nil {
		log.Warn("orchestrator: file watcher start failed", "err", werr)
	}
	defer watcher.Stop()

	// Planning phase: read-only Copilot session that emits the subtask DAG.
	// Only runs when planNeeded; reworks and Planner=nil skip straight to
	// runAgent with t.Status already == StatusInProgress.
	if planNeeded {
		if !o.runPlanningPhase(ctx, t, log) {
			return
		}
	}

	outcome := o.runAgent(ctx, t, log)

	o.completeTask(taskID, outcome, log)
}

// ensureWorktree verifies or creates the task's worktree. Returns false
// (and transitions the task to failed) when the worktree is unrecoverable.
func (o *Orchestrator) ensureWorktree(ctx context.Context, t *task.Task, repoPath string, log *slog.Logger) bool {
	needCreate := t.WorktreePath == "" || worktreeMissing(t.WorktreePath)
	if !needCreate && !t.BranchExists {
		o.failTask(ctx, t.ID, t.Status, task.ErrCodeInterrupted,
			fmt.Sprintf("worktree branch %s was removed externally", t.Branch))
		return false
	}
	if needCreate {
		if t.WorktreePath != "" {
			// Rework attempt against a vanished worktree — surface it
			// instead of resurrecting under a new path.
			o.failTask(ctx, t.ID, t.Status, task.ErrCodeInterrupted,
				fmt.Sprintf("worktree directory %s no longer exists", t.WorktreePath))
			return false
		}
		created, err := o.cfg.Worktrees.Create(ctx, worktree.CreateInput{
			RepoPath:   repoPath,
			TaskID:     t.ID,
			BaseBranch: t.BaseBranch,
		})
		if err != nil {
			log.Error("orchestrator: worktree create failed", "err", err)
			o.failTask(ctx, t.ID, t.Status, task.ErrCodeRuntime, fmt.Sprintf("worktree: %v", err))
			return false
		}
		t.WorktreePath = created.Path
		t.Branch = created.Branch
	}
	return true
}

// runPlanningPhase runs the planner under a bounded context, persists the
// resulting subtask DAG, and transitions the task to in_progress. Returns
// false when planning failed or was aborted (task already transitioned to
// failed / aborted on that path).
func (o *Orchestrator) runPlanningPhase(ctx context.Context, t *task.Task, log *slog.Logger) bool {
	planCtx, cancel := context.WithTimeout(ctx, o.cfg.PlanningTimeout)
	defer cancel()

	// Stream the planner's assistant.delta / tool events through the
	// consumer so the UI can live-render what the planner is "thinking"
	// while it investigates and decomposes. The planner closes eventCh
	// before returning; we wait for the consumer to drain after.
	eventCh := make(chan *task.AgentEvent, o.cfg.EventChannelBuffer)
	consumerDone := make(chan struct{})
	go func() {
		defer close(consumerDone)
		if err := o.consumeEvents(ctx, t, eventCh); err != nil {
			log.Warn("orchestrator: planning event consumer", "err", err)
		}
	}()

	subs, planModel, planSummary, planUsage, err := o.cfg.Planner.Plan(planCtx, t, eventCh)
	<-consumerDone
	// Even on error we forward whatever usage was recorded — the planner
	// may have spent budget before failing, and the user deserves to see
	// that consumption.
	o.emitUsageEvent(ctx, t, "plan", "", planUsage)
	if err != nil {
		o.mu.Lock()
		abort := false
		if rs, ok := o.running[t.ID]; ok {
			abort = rs.abortByUser
		}
		o.mu.Unlock()

		if abort {
			if tErr := o.cfg.TaskStore.Transition(ctx, t.ID,
				task.StatusPlanning, task.StatusAborted, "", "", task.FinalizationNone); tErr == nil {
				o.emitStatus(ctx, t.ID, task.StatusPlanning, task.StatusAborted)
			}
		} else {
			o.failTask(ctx, t.ID, task.StatusPlanning, task.ErrCodeRuntime,
				fmt.Sprintf("planner: %v", err))
		}
		return false
	}

	// Record which model actually ran the plan so the UI can surface it
	// as a per-stage badge on the task card. UpdateFields is best-effort:
	// a persist failure here is logged but not fatal — the plan itself
	// has already succeeded and losing the badge is non-critical.
	if planModel != "" && planModel != t.PlanModel {
		t.PlanModel = planModel
		if err := o.cfg.TaskStore.UpdateFields(ctx, t); err != nil {
			log.Warn("orchestrator: persist plan_model failed", "err", err)
		}
	}

	round, err := o.cfg.SubtaskStore.CreatePlan(ctx, t.ID, subs)
	if err != nil {
		log.Error("orchestrator: persist plan failed", "err", err)
		o.failTask(ctx, t.ID, task.StatusPlanning, task.ErrCodeRuntime,
			fmt.Sprintf("planner persist: %v", err))
		return false
	}

	// Surface the planner's investigation summary to the UI as an
	// AgentEvent. The payload is a JSON envelope carrying the round
	// number alongside the text so the UI can show the correct summary
	// on each Plan node after rework cycles produce multiple rounds —
	// previously the plain-text payload meant every Plan node surfaced
	// the latest summary, which looked identical after a Re-Run.
	if planSummary != "" {
		o.appendAuxEvent(ctx, t, &task.AgentEvent{
			Kind:    task.EventPlanSummary,
			Payload: mustJSONStr(map[string]any{"round": round, "text": planSummary}),
		})
	}

	if err := o.cfg.TaskStore.Transition(ctx, t.ID,
		task.StatusPlanning, task.StatusInProgress, "", "", task.FinalizationNone); err != nil {
		log.Error("orchestrator: planning→in_progress failed", "err", err)
		// Drop to failed explicitly. Without this the task sits in
		// planning forever: completeTask runs only after runAgent, and
		// returning from this helper with the task still in planning
		// leaves the UI spinning indefinitely.
		o.failTask(ctx, t.ID, task.StatusPlanning, task.ErrCodeRuntime,
			fmt.Sprintf("planning→in_progress: %v", err))
		return false
	}
	o.emitStatus(ctx, t.ID, task.StatusPlanning, task.StatusInProgress)
	t.Status = task.StatusInProgress
	return true
}

// runOutcome summarizes the agent's exit disposition.
type runOutcome struct {
	runErr      error
	abortByUser bool
}

// runAgent drives task execution. When a plan is present (planner-produced
// subtasks stored under t.ID), it walks the DAG in topological order,
// invoking Runner.RunSubtask once per node and tracking per-subtask status.
// When no plan is present it falls back to a single Runner.Run session
// (the legacy / Planner=nil path).
//
// Fail-fast: the first subtask error aborts the loop and every remaining
// pending subtask stays untouched (still pending in the store). The task
// transitions to failed via the caller's completeTask handling.
func (o *Orchestrator) runAgent(ctx context.Context, t *task.Task, log *slog.Logger) runOutcome {
	subs, err := o.listSubtasks(ctx, t.ID)
	if err != nil {
		log.Warn("orchestrator: subtask list failed, falling back to single-session", "err", err)
	}

	if len(subs) == 0 {
		return o.runSingleSession(ctx, t, log)
	}
	return o.runSubtaskLoop(ctx, t, subs, log)
}

// listSubtasks returns the latest round's subtasks in execution order,
// or an empty slice when no plan exists / no SubtaskStore is configured.
// Earlier rounds remain in the DB for UI history but are not re-run.
func (o *Orchestrator) listSubtasks(ctx context.Context, taskID string) ([]*task.Subtask, error) {
	if o.cfg.SubtaskStore == nil {
		return nil, nil
	}
	return o.cfg.SubtaskStore.ListLatestRound(ctx, taskID)
}

// runSingleSession is the pre-Phase-3 path: one Copilot session covers the
// whole task. Preserved for tasks that have no plan (Planner=nil at config
// time, or older tasks that predate planning).
func (o *Orchestrator) runSingleSession(ctx context.Context, t *task.Task, log *slog.Logger) runOutcome {
	eventCh := make(chan *task.AgentEvent, o.cfg.EventChannelBuffer)

	consumerDone := make(chan struct{})
	go func() {
		defer close(consumerDone)
		if err := o.consumeEvents(ctx, t, eventCh); err != nil {
			log.Warn("orchestrator: event consumer error", "err", err)
		}
	}()

	codeModel, codeUsage, runErr := o.cfg.Runner.Run(ctx, t, eventCh)
	<-consumerDone
	o.emitUsageEvent(ctx, t, "code", "", codeUsage)

	// Record the actual Code-stage model when the runner resolved a
	// fallback default. We only overwrite when Task.Model is empty so
	// a user-pinned override (set at CreateTask) is never clobbered.
	if codeModel != "" && t.Model == "" {
		t.Model = codeModel
		if err := o.cfg.TaskStore.UpdateFields(ctx, t); err != nil {
			log.Warn("orchestrator: persist code model failed", "err", err)
		}
	}

	o.mu.Lock()
	abort := false
	if rs, ok := o.running[t.ID]; ok {
		abort = rs.abortByUser
	}
	o.mu.Unlock()

	return runOutcome{runErr: runErr, abortByUser: abort}
}

// runSubtaskLoop walks subs in topological order (subs is already sorted
// by the planner's order_idx), runs one Copilot session per node, and
// emits subtask.start / subtask.end lifecycle events so the UI can
// group agent output by subtask.
//
// Runs serially on the parent task's single worktree — the planner DAG's
// parallelism is informational only under Phase 1's single-worktree
// constraint.
func (o *Orchestrator) runSubtaskLoop(ctx context.Context, t *task.Task, subs []*task.Subtask, log *slog.Logger) runOutcome {
	// Persisted subtask state (pending / doing / done / failed) is mutated
	// here. We hold references to the same *Subtask values returned from
	// the store so in-memory changes line up with what Update writes back.
	failed := make(map[string]bool, len(subs))

	// Fetch the latest plan.summary for this task once, so each Coder
	// session gets the Planner's investigation context as part of its
	// prompt — without this, every subtask re-explores the repo.
	planSummary := o.fetchPlanSummary(ctx, t.ID)
	// priorSummaries accumulates one entry per completed subtask so
	// the next subtask's prompt carries "what the siblings already
	// produced" — cuts down re-exploration and duplicate work.
	priorSummaries := make([]task.PriorSubtaskSummary, 0, len(subs))

	// Rework entry (ai_review → queued → in_progress) re-uses the plan the
	// user already approved, but the per-subtask statuses from the previous
	// run are now stale: done rows would be silently re-executed, and a
	// mid-loop failure from last run would have left some pending / some
	// done. Reset every status to pending so the feedback-driven rerun is
	// deterministic. First runs land here with every row already pending,
	// so the write is a no-op.
	for _, sub := range subs {
		if sub.Status != task.SubtaskPending {
			sub.Status = task.SubtaskPending
			if err := o.cfg.SubtaskStore.Update(ctx, sub); err != nil {
				log.Warn("orchestrator: reset subtask status", "id", sub.ID, "err", err)
			}
		}
	}

	for i, sub := range subs {
		// Cascade-skip subtasks whose upstreams already failed. This keeps
		// the DB state readable after a mid-loop abort: directly-impacted
		// nodes are marked failed with a dependency reason, the rest stay
		// pending.
		if hasFailedDep(sub, failed) {
			sub.Status = task.SubtaskFailed
			if err := o.cfg.SubtaskStore.Update(ctx, sub); err != nil {
				log.Warn("orchestrator: mark dependency-failed subtask", "id", sub.ID, "err", err)
			}
			o.emitSubtaskEnd(ctx, t, sub, false, "dependency failed")
			failed[sub.ID] = true
			continue
		}

		sub.Status = task.SubtaskDoing
		if err := o.cfg.SubtaskStore.Update(ctx, sub); err != nil {
			log.Warn("orchestrator: mark subtask doing", "id", sub.ID, "err", err)
		}
		o.emitSubtaskStart(ctx, t, sub)

		eventCh := make(chan *task.AgentEvent, o.cfg.EventChannelBuffer)
		consumerDone := make(chan struct{})
		go func() {
			defer close(consumerDone)
			if err := o.consumeEvents(ctx, t, eventCh); err != nil {
				log.Warn("orchestrator: subtask event consumer", "id", sub.ID, "err", err)
			}
		}()

		subCtx := task.SubtaskRunContext{
			PlanSummary:    planSummary,
			PriorSummaries: append([]task.PriorSubtaskSummary(nil), priorSummaries...),
			IsFinalSubtask: i == len(subs)-1,
		}
		codeModel, codeUsage, runErr := o.cfg.Runner.RunSubtask(ctx, t, sub, subCtx, eventCh)
		<-consumerDone
		o.emitUsageEvent(ctx, t, "code", sub.ID, codeUsage)

		// Record the Code-stage model the runner actually used on the
		// subtask so the UI can show a per-subtask badge. Populated even
		// on failure — the attempt is still worth surfacing.
		if codeModel != "" && sub.CodeModel != codeModel {
			sub.CodeModel = codeModel
		}

		if runErr != nil {
			sub.Status = task.SubtaskFailed
			if err := o.cfg.SubtaskStore.Update(ctx, sub); err != nil {
				log.Warn("orchestrator: mark subtask failed", "id", sub.ID, "err", err)
			}
			o.emitSubtaskEnd(ctx, t, sub, false, runErr.Error())

			o.mu.Lock()
			abort := false
			if rs, ok := o.running[t.ID]; ok {
				abort = rs.abortByUser
			}
			o.mu.Unlock()
			// Cascade-cancel the rest of this round so the DAG does not
			// leave stale "pending" subtasks sitting there after a user
			// Cancel. Without this cleanup the UI shows a half-run
			// round whose pending cards look identical to an active run
			// — which on top of a re-enqueued next round makes it look
			// like round 1 and round 2 are executing simultaneously.
			reason := runErr.Error()
			if abort {
				reason = "cancelled by user"
			}
			// Use a fresh context so the cleanup still persists even
			// when the outer ctx is already done (common on Cancel).
			bgCtx, bgCancel := context.WithTimeout(context.Background(), 10*time.Second)
			for _, rest := range subs[i+1:] {
				if rest.Status == task.SubtaskDone ||
					rest.Status == task.SubtaskFailed {
					continue
				}
				rest.Status = task.SubtaskFailed
				if err := o.cfg.SubtaskStore.Update(bgCtx, rest); err != nil {
					log.Warn("orchestrator: mark remaining subtask cancelled",
						"id", rest.ID, "err", err)
				}
				o.emitSubtaskEnd(bgCtx, t, rest, false, reason)
			}
			bgCancel()
			return runOutcome{runErr: runErr, abortByUser: abort}
		}

		sub.Status = task.SubtaskDone
		if err := o.cfg.SubtaskStore.Update(ctx, sub); err != nil {
			log.Warn("orchestrator: mark subtask done", "id", sub.ID, "err", err)
		}
		o.emitSubtaskEnd(ctx, t, sub, true, "")
		// Add this subtask's outcome to priorSummaries so the next
		// subtask's prompt lists it. We don't have the agent's final
		// paragraph in hand here (it streamed through eventCh and
		// landed in the events table), so the summary stays empty
		// for now; title + role alone is already enough context to
		// prevent redundant re-exploration.
		priorSummaries = append(priorSummaries, task.PriorSubtaskSummary{
			Title:   sub.Title,
			Role:    sub.AgentRole,
			Summary: "",
		})
	}

	o.mu.Lock()
	abort := false
	if rs, ok := o.running[t.ID]; ok {
		abort = rs.abortByUser
	}
	o.mu.Unlock()
	return runOutcome{runErr: nil, abortByUser: abort}
}

// fetchPlanSummary returns the latest plan.summary text for taskID,
// or empty string when the task has no plan.summary event yet (first
// run before Planner emits one, or task from before the plan-summary
// feature existed). Best-effort — a DB glitch just means the Coder
// doesn't get the context boost, not that execution fails.
//
// Post-2026-04 the payload is JSON `{"round":N,"text":"..."}`; legacy
// rows carry the raw text, which we preserve via a decode-with-fallback.
func (o *Orchestrator) fetchPlanSummary(ctx context.Context, taskID string) string {
	events, err := o.cfg.EventStore.ListByTask(ctx, taskID, 0, 0)
	if err != nil {
		return ""
	}
	latest := ""
	for _, e := range events {
		if e.Kind == task.EventPlanSummary {
			latest = decodePlanSummaryText(e.Payload)
		}
	}
	return latest
}

// decodePlanSummaryText extracts the human-readable text from a
// plan.summary event payload. Handles both the current JSON
// `{"round":N,"text":"..."}` shape and the legacy raw-string shape.
func decodePlanSummaryText(payload string) string {
	if payload == "" {
		return ""
	}
	var m map[string]any
	if err := json.Unmarshal([]byte(payload), &m); err == nil {
		if s, ok := m["text"].(string); ok {
			return s
		}
	}
	return payload
}

func hasFailedDep(sub *task.Subtask, failed map[string]bool) bool {
	for _, dep := range sub.DependsOn {
		if failed[dep] {
			return true
		}
	}
	return false
}

func (o *Orchestrator) emitSubtaskStart(ctx context.Context, t *task.Task, sub *task.Subtask) {
	ev := &task.AgentEvent{
		Kind: task.EventSubtaskStart,
		Payload: mustJSONStr(map[string]any{
			"subtask_id": sub.ID,
			"title":      sub.Title,
			"agent_role": sub.AgentRole,
		}),
	}
	o.appendAuxEvent(ctx, t, ev)
}

func (o *Orchestrator) emitSubtaskEnd(ctx context.Context, t *task.Task, sub *task.Subtask, ok bool, errMsg string) {
	payload := map[string]any{
		"subtask_id": sub.ID,
		"ok":         ok,
	}
	if errMsg != "" {
		payload["err"] = errMsg
	}
	ev := &task.AgentEvent{
		Kind:    task.EventSubtaskEnd,
		Payload: mustJSONStr(payload),
	}
	o.appendAuxEvent(ctx, t, ev)
}

// emitUsageEvent persists a session.usage event with the per-stage
// totals collected from one Copilot session. Skipped when usage is
// zero-valued (the session never reached an LLM call) so the event
// stream isn't cluttered with empty rows. SubtaskID is empty for
// plan / review stages.
func (o *Orchestrator) emitUsageEvent(ctx context.Context, t *task.Task, stage, subtaskID string, u task.SessionUsage) {
	if u.IsZero() {
		return
	}
	payload := map[string]any{
		"stage":             stage,
		"model":             u.Model,
		"premium_requests":  u.PremiumRequests,
		"input_tokens":      u.InputTokens,
		"output_tokens":     u.OutputTokens,
		"cache_read_tokens": u.CacheReadTokens,
		"duration_ms":       u.DurationMs,
		"calls":             u.Calls,
	}
	if subtaskID != "" {
		payload["subtask_id"] = subtaskID
	}
	o.appendAuxEvent(ctx, t, &task.AgentEvent{
		Kind:    task.EventSessionUsage,
		Payload: mustJSONStr(payload),
	})
}

// appendAuxEvent persists an orchestrator-emitted event (subtask lifecycle,
// status snapshots) with an auto-assigned sequence number and forwards it
// to the sink. Non-delta events are written directly rather than funnelled
// through the batching consumer so they land atomically even across the
// gap between subtask session channels.
func (o *Orchestrator) appendAuxEvent(ctx context.Context, t *task.Task, ev *task.AgentEvent) {
	if ev.ID == "" {
		ev.ID = o.eventIDs.next()
	}
	if ev.OccurredAt.IsZero() {
		ev.OccurredAt = time.Now().UTC()
	}
	ev.TaskID = t.ID
	if err := o.cfg.EventStore.AppendAutoSeq(ctx, ev); err != nil {
		o.log.Warn("orchestrator: aux event append", "task", t.ID, "kind", ev.Kind, "err", err)
		return
	}
	if o.cfg.Sink != nil {
		o.cfg.Sink(ev)
	}
}

// mustJSONStr mirrors copilot.mustJSON — local helper so the orchestrator
// package doesn't pull an import of internal/copilot.
func mustJSONStr(v any) string {
	b, err := json.Marshal(v)
	if err != nil {
		panic("orchestrator: JSON encode: " + err.Error())
	}
	return string(b)
}

// consumeEvents reads events from ch, assigning sequence numbers and
// batching deltas (phase1-spec §3.4) before writing them to the event
// store and notifying the UI sink.
func (o *Orchestrator) consumeEvents(ctx context.Context, t *task.Task, ch <-chan *task.AgentEvent) error {
	seq, err := o.cfg.EventStore.NextSeq(ctx, t.ID)
	if err != nil {
		return fmt.Errorf("next seq: %w", err)
	}
	ticker := time.NewTicker(o.cfg.EventBatchInterval)
	defer ticker.Stop()

	var batch []*task.AgentEvent
	flush := func() error {
		if len(batch) == 0 {
			return nil
		}
		if err := o.cfg.EventStore.AppendBatch(ctx, batch); err != nil {
			return fmt.Errorf("append batch (%d events): %w", len(batch), err)
		}
		if o.cfg.Sink != nil {
			for _, e := range batch {
				o.cfg.Sink(e)
			}
		}
		batch = batch[:0]
		return nil
	}

	for {
		select {
		case ev, ok := <-ch:
			if !ok {
				return flush()
			}
			if ev.ID == "" {
				ev.ID = o.eventIDs.next()
			}
			if ev.OccurredAt.IsZero() {
				ev.OccurredAt = time.Now().UTC()
			}
			ev.TaskID = t.ID
			ev.Seq = seq
			seq++
			batch = append(batch, ev)
			// Non-delta events are typically low-volume and low-latency
			// critical (tool.start / session.idle etc.). Flush promptly.
			if ev.Kind != task.EventAssistantDelta &&
				ev.Kind != task.EventAssistantReasoningDelta {
				if err := flush(); err != nil {
					return err
				}
			}
		case <-ticker.C:
			if err := flush(); err != nil {
				return err
			}
		case <-ctx.Done():
			// Drain anything already queued before bailing out so the user
			// sees the events that landed just before Cancel.
			_ = flush()
			return ctx.Err()
		}
	}
}

// completeTask maps the runner outcome to a final state transition.
//
// Normal-exit path goes through ai_review first: in_progress → ai_review.
// Phase 1's AI review is a pass-through — a short-lived goroutine advances
// ai_review → human_review after aiReviewPassThroughDelay so the column
// is visible to the user without blocking the runner. Phase 2 will replace
// the pass-through with a real Copilot-driven verification session.
func (o *Orchestrator) completeTask(taskID string, o2 runOutcome, log *slog.Logger) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	var final task.Status
	var errMsg string

	switch {
	case o2.abortByUser:
		// User-initiated cancel takes precedence over whatever the runner
		// reported: even if the runner swallowed ctx and returned nil,
		// Phase 1 considers the task Aborted, not Done.
		if err := o.cfg.TaskStore.Transition(ctx, taskID,
			task.StatusInProgress, task.StatusAborted, "", "", task.FinalizationNone); err != nil {
			log.Error("orchestrator: in_progress→aborted failed", "err", err)
			return
		}
		o.emitStatus(ctx, taskID, task.StatusInProgress, task.StatusAborted)
		final = task.StatusAborted
	case o2.runErr == nil:
		if err := o.cfg.TaskStore.Transition(ctx, taskID,
			task.StatusInProgress, task.StatusAIReview, "", "", task.FinalizationNone); err != nil {
			log.Error("orchestrator: in_progress→ai_review failed", "err", err)
			return
		}
		o.emitStatus(ctx, taskID, task.StatusInProgress, task.StatusAIReview)
		// Kick off the AI review in the background so the dispatch
		// goroutine can return its semaphore slot immediately. Using
		// rootCtx lets Shutdown cancel pending reviews cleanly.
		o.wg.Add(1)
		go o.runAIReview(taskID, log)
		final = task.StatusAIReview
	case errors.Is(o2.runErr, context.DeadlineExceeded):
		o.failTask(ctx, taskID, task.StatusInProgress, task.ErrCodeTimeout, o2.runErr.Error())
		final = task.StatusFailed
		errMsg = o2.runErr.Error()
	default:
		o.failTask(ctx, taskID, task.StatusInProgress, task.ErrCodeRuntime, o2.runErr.Error())
		final = task.StatusFailed
		errMsg = o2.runErr.Error()
	}

	o.notify(ctx, taskID, final, errMsg, log)
}

// aiReviewPassThroughDelay is how long a task lingers in ai_review when no
// Reviewer is configured. Long enough that the UI clearly shows the column
// transition, short enough that users don't wait on ceremony.
const aiReviewPassThroughDelay = 1500 * time.Millisecond

// aiReviewTimeout caps how long a Copilot-backed review is allowed to run.
// A reviewer hitting the timeout leaves the task in ai_review for manual
// advance — failing the task over a slow reviewer would be too aggressive.
const aiReviewTimeout = 5 * time.Minute

// runAIReview advances a task out of the ai_review state. When the Config
// has a Reviewer, the reviewer's ReviewDecision drives the transition:
// Approve → human_review, Reject/Rework → queued with feedback saved (the
// orchestrator automatically re-enqueues so the worktree is reworked
// without user interaction). When Reviewer is nil, falls back to the
// timed pass-through so the pipeline still completes.
//
// The goroutine registers its cancel function in `aiReviews` for the
// duration of the review so CancelTask can interrupt a long-running
// Copilot session instead of waiting for the 5-minute timeout.
//
// Runs on its own goroutine so it doesn't hold the dispatch semaphore.
func (o *Orchestrator) runAIReview(taskID string, log *slog.Logger) {
	defer o.wg.Done()

	if o.cfg.Reviewer == nil {
		o.passThroughAIReview(taskID, log)
		return
	}

	ctx, cancel := context.WithTimeout(o.rootCtx, aiReviewTimeout)
	defer cancel()

	o.mu.Lock()
	o.aiReviews[taskID] = cancel
	o.mu.Unlock()
	defer func() {
		o.mu.Lock()
		delete(o.aiReviews, taskID)
		o.mu.Unlock()
	}()

	t, err := o.cfg.TaskStore.Get(ctx, taskID)
	if err != nil {
		log.Warn("orchestrator: ai_review lookup failed", "err", err)
		return
	}
	// A user may have clicked Rework / Cancel during the review window;
	// skip silently when the status has already moved on.
	if t.Status != task.StatusAIReview {
		return
	}

	diff, err := o.cfg.Worktrees.Diff(ctx, t.WorktreePath, t.BaseBranch)
	if err != nil {
		log.Warn("orchestrator: ai_review diff failed", "err", err)
		return // leave in ai_review; user can advance manually
	}

	// Bracket the reviewer session so the UI can show the reviewer's
	// reasoning / tool calls in the Review stage detail as a proper
	// log — events between ai_review.start and ai_review.decision
	// belong to the Review phase of this round. Round is derived from
	// the latest subtask round so it always matches the DAG node the
	// user clicks.
	reviewRound := 1
	if o.cfg.SubtaskStore != nil {
		if subs, lErr := o.cfg.SubtaskStore.ListLatestRound(ctx, t.ID); lErr == nil && len(subs) > 0 {
			if subs[0].Round > 0 {
				reviewRound = subs[0].Round
			}
		}
	}
	o.appendAuxEvent(ctx, t, &task.AgentEvent{
		Kind: task.EventAIReviewStart,
		Payload: mustJSONStr(map[string]any{
			"round": reviewRound,
			"model": t.ReviewModel,
		}),
	})

	// Stream reviewer events through a dedicated consumer so they land
	// in the events table alongside planner / runner events. Without
	// this, the Review stage detail dialog has nothing to show.
	eventCh := make(chan *task.AgentEvent, o.cfg.EventChannelBuffer)
	consumerDone := make(chan struct{})
	go func() {
		defer close(consumerDone)
		if err := o.consumeEvents(ctx, t, eventCh); err != nil {
			log.Warn("orchestrator: reviewer event consumer", "err", err)
		}
	}()

	// Pass the task's current ReviewFeedback (set by the previous rework
	// cycle, empty on first review) as prevFeedback. The reviewer uses it
	// to self-check whether its last complaint is already addressed, which
	// breaks the "reviewer keeps flagging items the agent already did"
	// loop.
	decision, reviewModel, reviewUsage, err := o.cfg.Reviewer.Review(ctx, t, diff, t.ReviewFeedback, t.ReworkCount, eventCh)
	<-consumerDone
	o.emitUsageEvent(ctx, t, "review", "", reviewUsage)
	if err != nil {
		// A user-initiated Cancel flows through as a ctx cancel here.
		// Distinguish it from a real reviewer error: on cancel, advance
		// the task to aborted so the UI reflects the action. Other errors
		// (SDK failure, reviewer bug) leave the task in ai_review so the
		// user can intervene.
		if errors.Is(err, context.Canceled) || ctx.Err() != nil {
			// Use a fresh background context for the transition — the
			// parent ctx is already done.
			bg, bgCancel := context.WithTimeout(context.Background(), 10*time.Second)
			defer bgCancel()
			if tErr := o.cfg.TaskStore.Transition(bg, taskID,
				task.StatusAIReview, task.StatusAborted, "", "", task.FinalizationNone); tErr != nil {
				log.Warn("orchestrator: ai_review→aborted (cancel) failed", "err", tErr)
				return
			}
			o.emitStatus(bg, taskID, task.StatusAIReview, task.StatusAborted)
			o.notify(bg, taskID, task.StatusAborted, "", log)
			return
		}
		log.Warn("orchestrator: reviewer errored", "err", err)
		return // leave in ai_review; user can advance manually
	}

	// Record which model actually reviewed so the UI can surface the
	// Review-stage badge. Like the plan_model write above, this is
	// best-effort: the review result is already in hand, losing the
	// badge is cosmetic.
	if reviewModel != "" && reviewModel != t.ReviewModel {
		t.ReviewModel = reviewModel
		if err := o.cfg.TaskStore.UpdateFields(ctx, t); err != nil {
			log.Warn("orchestrator: persist review_model failed", "err", err)
		}
	}

	if decision.Approve {
		// Emit before transitioning so the event seq lands ahead of
		// the status event for cleaner UI ordering.
		o.emitAIReviewDecision(ctx, t, decision, t.ReworkCount, reviewModel)
		if err := o.cfg.TaskStore.Transition(ctx, taskID,
			task.StatusAIReview, task.StatusHumanReview, "", "", task.FinalizationNone); err != nil {
			log.Warn("orchestrator: ai_review→human_review failed", "err", err)
			return
		}
		o.emitStatus(ctx, taskID, task.StatusAIReview, task.StatusHumanReview)
		o.notify(ctx, taskID, task.StatusHumanReview, "", log)
		return
	}

	// Cap enforcement: a misbehaving reviewer that keeps flagging the
	// same (phantom) issue will otherwise loop ai_review→queued forever.
	// After MaxReworkCount auto-reworks we hand the task to the user
	// rather than burn another Copilot iteration — the feedback records
	// the escalation reason so it's clear in the Review pane.
	if t.ReworkCount >= MaxReworkCount {
		feedback := decision.Feedback
		if feedback == "" {
			feedback = "(no details)"
		}
		t.ReviewFeedback = fmt.Sprintf(
			"AI Reviewer requested rework %d times without converging; deferring to user judgement.\n\nLatest feedback:\n%s",
			t.ReworkCount, feedback)
		if err := o.cfg.TaskStore.UpdateFields(ctx, t); err != nil {
			log.Warn("orchestrator: ai_review cap feedback persist failed", "err", err)
		}
		if err := o.cfg.TaskStore.Transition(ctx, taskID,
			task.StatusAIReview, task.StatusHumanReview, "", "", task.FinalizationNone); err != nil {
			log.Warn("orchestrator: ai_review→human_review (rework cap) failed", "err", err)
			return
		}
		o.emitStatus(ctx, taskID, task.StatusAIReview, task.StatusHumanReview)
		o.notify(ctx, taskID, task.StatusHumanReview, "", log)
		return
	}

	// Rework path: persist the reviewer's feedback onto the task so the
	// next BuildPrompt() prepends it, then transition ai_review → queued
	// and self-enqueue. A missing Feedback string is replaced by a
	// neutral placeholder so the agent still sees some rework context.
	feedback := decision.Feedback
	if feedback == "" {
		feedback = "Automatic rework instruction from AI Reviewer (no details)"
	}
	t.ReviewFeedback = feedback
	if err := o.cfg.TaskStore.UpdateFields(ctx, t); err != nil {
		log.Warn("orchestrator: ai_review feedback persist failed", "err", err)
		return
	}

	// Persist the AI Reviewer's verdict as an event so the UI can show
	// past feedback when the user clicks a subtask, even after several
	// rework cycles. Task.ReviewFeedback only retains the latest verdict.
	o.emitAIReviewDecision(ctx, t, decision, t.ReworkCount, reviewModel)

	// AI rework re-plans on the next dispatch (planNeeded is now
	// always true when a Planner is configured). The previous round's
	// subtasks stay in the DB for UI history; CreatePlan inserts a new
	// round at max+1 so the rework is visually distinct.

	if err := o.cfg.TaskStore.Transition(ctx, taskID,
		task.StatusAIReview, task.StatusQueued, "", "", task.FinalizationNone); err != nil {
		log.Warn("orchestrator: ai_review→queued failed", "err", err)
		return
	}
	o.emitStatus(ctx, taskID, task.StatusAIReview, task.StatusQueued)
	if err := o.Enqueue(taskID); err != nil && !errors.Is(err, ErrAlreadyRunning) {
		log.Warn("orchestrator: ai_review rework enqueue failed", "err", err)
	}
}

// emitAIReviewDecision persists an ai_review.decision event with the
// reviewer's verdict + feedback so the UI can show past AI feedback
// for any rework cycle. Best-effort — failures are logged and swallowed
// because the review transition itself is already the source of truth.
func (o *Orchestrator) emitAIReviewDecision(ctx context.Context, t *task.Task, decision ReviewDecision, reworkCount int, model string) {
	// round lets the UI attach each decision to the matching AI Review
	// node in the subtask DAG. Derived from the latest-round subtasks so
	// it stays accurate even after the task has looped through rework
	// cycles.
	round := 1
	if o.cfg.SubtaskStore != nil {
		if subs, err := o.cfg.SubtaskStore.ListLatestRound(ctx, t.ID); err == nil && len(subs) > 0 {
			round = subs[0].Round
			if round < 1 {
				round = 1
			}
		}
	}
	payload := map[string]any{
		"approve":      decision.Approve,
		"feedback":     decision.Feedback,
		"summary":      decision.Summary,
		"rework_count": reworkCount,
		"round":        round,
		"model":        model,
	}
	o.appendAuxEvent(ctx, t, &task.AgentEvent{
		Kind:    task.EventAIReviewDecision,
		Payload: mustJSONStr(payload),
	})
}

// passThroughAIReview is the fallback when no Reviewer is configured. It
// waits a short while and then advances ai_review → human_review so the
// user can finalize manually. Registers a cancel function in aiReviews so
// CancelTask can interrupt the wait (the task lands in ai_review until
// the fallback path in service.CancelTask or the next user action moves
// it onward).
func (o *Orchestrator) passThroughAIReview(taskID string, log *slog.Logger) {
	waitCtx, cancel := context.WithCancel(o.rootCtx)
	defer cancel()

	o.mu.Lock()
	o.aiReviews[taskID] = cancel
	o.mu.Unlock()
	defer func() {
		o.mu.Lock()
		delete(o.aiReviews, taskID)
		o.mu.Unlock()
	}()

	select {
	case <-time.After(aiReviewPassThroughDelay):
	case <-waitCtx.Done():
		// Canceled by user or shutdown — skip the auto-advance so the
		// caller (service.CancelTask fallback) decides the final state.
		return
	}

	ctx, bgCancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer bgCancel()

	t, err := o.cfg.TaskStore.Get(ctx, taskID)
	if err != nil {
		log.Warn("orchestrator: ai_review pass-through lookup failed", "err", err)
		return
	}
	if t.Status != task.StatusAIReview {
		return
	}
	if err := o.cfg.TaskStore.Transition(ctx, taskID,
		task.StatusAIReview, task.StatusHumanReview, "", "", task.FinalizationNone); err != nil {
		log.Warn("orchestrator: ai_review→human_review failed", "err", err)
		return
	}
	o.emitStatus(ctx, taskID, task.StatusAIReview, task.StatusHumanReview)
	o.notify(ctx, taskID, task.StatusHumanReview, "", log)
}

// notify dispatches the configured Notifier (if any) with the task's final
// state. Lookup failures are logged but never block the dispatch path.
func (o *Orchestrator) notify(ctx context.Context, taskID string, status task.Status, errMsg string, log *slog.Logger) {
	if o.cfg.Notifier == nil {
		return
	}
	t, err := o.cfg.TaskStore.Get(ctx, taskID)
	if err != nil {
		log.Warn("orchestrator: notify lookup failed", "err", err)
		return
	}
	defer func() {
		if r := recover(); r != nil {
			log.Warn("orchestrator: notifier panicked", "recover", r)
		}
	}()
	o.cfg.Notifier(Notification{
		TaskID: t.ID,
		Goal:   t.Goal,
		Status: status,
		Err:    errMsg,
	})
}

func (o *Orchestrator) failTask(ctx context.Context, taskID string, from task.Status, code task.ErrorCode, msg string) {
	if err := o.cfg.TaskStore.Transition(ctx, taskID, from, task.StatusFailed, code, msg, task.FinalizationNone); err != nil {
		o.log.Error("orchestrator: transition to failed failed",
			"task_id", taskID, "from", from, "code", code, "err", err)
		return
	}
	o.emitStatus(ctx, taskID, from, task.StatusFailed)
}

// emitStatus appends a kind="status" event for a task transition and
// forwards it via the Sink. The UI's WatchEvents subscriber refetches the
// tasks list when it sees this kind, so the Kanban stays live without the
// user having to press "Refresh".
//
// AppendAutoSeq computes the next seq atomically inside the write
// transaction, avoiding a race with the runner's consumeEvents goroutine
// (which uses a cached NextSeq counter and could otherwise collide with
// an out-of-band status write).
//
// Best-effort: any failure is logged and swallowed; the transition itself
// is the source of truth.
func (o *Orchestrator) emitStatus(ctx context.Context, taskID string, from, to task.Status) {
	ev := &task.AgentEvent{
		ID:      o.eventIDs.next(),
		TaskID:  taskID,
		Kind:    task.EventStatus,
		Payload: fmt.Sprintf(`{"from":%q,"to":%q}`, from, to),
	}
	if err := o.cfg.EventStore.AppendAutoSeq(ctx, ev); err != nil {
		o.log.Warn("orchestrator: status event append", "task", taskID, "err", err)
		return
	}
	if o.cfg.Sink != nil {
		o.cfg.Sink(ev)
	}
}

// worktreeMissing reports whether the given path is absent on disk. Used
// by dispatch to refuse silently resurrecting a worktree that was deleted
// externally (reaper, git, user) while the task sat in review.
func worktreeMissing(p string) bool {
	if p == "" {
		return true
	}
	_, err := os.Stat(p)
	return os.IsNotExist(err)
}

func (o *Orchestrator) unregister(taskID string) {
	o.mu.Lock()
	delete(o.running, taskID)
	o.mu.Unlock()
}

// ulidFactory serializes ULID generation so events can be produced from many
// goroutines without a shared entropy source race.
type ulidFactory struct {
	mu sync.Mutex
}

func (f *ulidFactory) next() string {
	f.mu.Lock()
	defer f.mu.Unlock()
	return ulid.Make().String()
}
