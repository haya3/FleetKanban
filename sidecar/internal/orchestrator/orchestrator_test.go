package orchestrator

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"os"
	"path/filepath"
	"sync"
	"sync/atomic"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/haya3/fleetkanban/internal/task"
	"github.com/haya3/fleetkanban/internal/worktree"
)

// --- In-memory fakes -------------------------------------------------------

type fakeTaskStore struct {
	mu      sync.Mutex
	tasks   map[string]*task.Task
	history map[string][]task.Status // taskID → ordered status list
}

func newFakeTaskStore() *fakeTaskStore {
	return &fakeTaskStore{
		tasks:   map[string]*task.Task{},
		history: map[string][]task.Status{},
	}
}

func (s *fakeTaskStore) insert(t *task.Task) {
	s.mu.Lock()
	defer s.mu.Unlock()
	cp := *t
	s.tasks[t.ID] = &cp
	s.history[t.ID] = append(s.history[t.ID], t.Status)
}

func (s *fakeTaskStore) Get(_ context.Context, id string) (*task.Task, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	t, ok := s.tasks[id]
	if !ok {
		return nil, fmt.Errorf("task %s not found", id)
	}
	cp := *t
	return &cp, nil
}

func (s *fakeTaskStore) UpdateFields(_ context.Context, t *task.Task) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	existing, ok := s.tasks[t.ID]
	if !ok {
		return fmt.Errorf("task %s not found", t.ID)
	}
	if existing.Status != t.Status {
		return fmt.Errorf("status mismatch: have %s want %s", existing.Status, t.Status)
	}
	cp := *t
	s.tasks[t.ID] = &cp
	return nil
}

func (s *fakeTaskStore) Transition(_ context.Context, id string, from, to task.Status, code task.ErrorCode, msg string, finalization task.FinalizationKind) error {
	if !task.CanTransition(from, to) {
		return fmt.Errorf("illegal transition %s → %s", from, to)
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	t, ok := s.tasks[id]
	if !ok {
		return fmt.Errorf("task %s not found", id)
	}
	if t.Status != from {
		return fmt.Errorf("stale: have %s expected %s", t.Status, from)
	}
	t.Status = to
	t.ErrorCode = code
	t.ErrorMessage = msg
	t.Finalization = finalization
	// Mirror TaskStore.Transition's rework_count bookkeeping so
	// cap-enforcement tests see the same counter the real store would
	// produce — the orchestrator's cap check reads t.ReworkCount via Get.
	switch {
	case to == task.StatusQueued && from == task.StatusAIReview:
		t.ReworkCount++
	case to == task.StatusQueued:
		t.ReworkCount = 0
	case to == task.StatusDone || to == task.StatusCancelled || to == task.StatusFailed:
		t.ReworkCount = 0
	}
	s.history[id] = append(s.history[id], to)
	return nil
}

func (s *fakeTaskStore) SetBranchExists(_ context.Context, id string, exists bool) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	t, ok := s.tasks[id]
	if !ok {
		return fmt.Errorf("task %s not found", id)
	}
	t.BranchExists = exists
	return nil
}

func (s *fakeTaskStore) statuses(id string) []task.Status {
	s.mu.Lock()
	defer s.mu.Unlock()
	out := make([]task.Status, len(s.history[id]))
	copy(out, s.history[id])
	return out
}

type fakeEventStore struct {
	mu     sync.Mutex
	events map[string][]*task.AgentEvent
}

func newFakeEventStore() *fakeEventStore {
	return &fakeEventStore{events: map[string][]*task.AgentEvent{}}
}

func (s *fakeEventStore) NextSeq(_ context.Context, id string) (int64, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	return int64(len(s.events[id]) + 1), nil
}

func (s *fakeEventStore) Append(_ context.Context, e *task.AgentEvent) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.events[e.TaskID] = append(s.events[e.TaskID], e)
	return nil
}

func (s *fakeEventStore) AppendBatch(_ context.Context, evs []*task.AgentEvent) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	for _, e := range evs {
		s.events[e.TaskID] = append(s.events[e.TaskID], e)
	}
	return nil
}

func (s *fakeEventStore) AppendAutoSeq(_ context.Context, e *task.AgentEvent) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	e.Seq = int64(len(s.events[e.TaskID]) + 1)
	s.events[e.TaskID] = append(s.events[e.TaskID], e)
	return nil
}

func (s *fakeEventStore) ListByTask(_ context.Context, id string, sinceSeq int64, limit int) ([]*task.AgentEvent, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	out := make([]*task.AgentEvent, 0, len(s.events[id]))
	for _, e := range s.events[id] {
		if e.Seq <= sinceSeq {
			continue
		}
		cp := *e
		out = append(out, &cp)
		if limit > 0 && len(out) >= limit {
			break
		}
	}
	return out, nil
}

func (s *fakeEventStore) forTask(id string) []*task.AgentEvent {
	s.mu.Lock()
	defer s.mu.Unlock()
	out := make([]*task.AgentEvent, len(s.events[id]))
	copy(out, s.events[id])
	return out
}

type fakeRepos struct{ path string }

func (r *fakeRepos) Path(context.Context, string) (string, error) { return r.path, nil }
func (r *fakeRepos) TouchLastUsed(context.Context, string) error  { return nil }

type fakeWorktrees struct {
	mu       sync.Mutex
	created  map[string]*worktree.Created
	removed  []string
	createFn func(context.Context, worktree.CreateInput) (*worktree.Created, error)
}

func (w *fakeWorktrees) Create(ctx context.Context, in worktree.CreateInput) (*worktree.Created, error) {
	if w.createFn != nil {
		return w.createFn(ctx, in)
	}
	w.mu.Lock()
	defer w.mu.Unlock()
	c := &worktree.Created{
		Path:   `C:\tmp\wt\` + in.TaskID,
		Branch: "fleetkanban/" + in.TaskID,
	}
	if w.created == nil {
		w.created = map[string]*worktree.Created{}
	}
	w.created[in.TaskID] = c
	return c, nil
}

func (w *fakeWorktrees) Remove(_ context.Context, _, _, id string, _ worktree.RemoveMode) error {
	w.mu.Lock()
	defer w.mu.Unlock()
	w.removed = append(w.removed, id)
	return nil
}

func (w *fakeWorktrees) Diff(_ context.Context, _, _ string) (string, error) {
	// Tests that don't set a Reviewer never call Diff; returning empty is
	// a sufficient stub. Reviewer-driven tests can substitute their own
	// fakeWorktrees with a richer Diff method if needed.
	return "", nil
}

func (w *fakeWorktrees) Merge(_ context.Context, _, _, _ string) (worktree.MergeResult, error) {
	// Merge tests run against the real Manager (see merge_test.go); the
	// fake stays a quiet stub that pretends a fast-forward happened.
	return worktree.MergeFastForward, nil
}

func (w *fakeWorktrees) DeleteBranch(_ context.Context, _, _ string) error {
	// The post-done merge path calls this after a successful Merge. Branch
	// deletion tests run against the real Manager; the fake is a quiet stub.
	return nil
}

func (w *fakeWorktrees) CommitPending(_ context.Context, _, _ string) (bool, error) {
	// Finalize Keep / Merge auto-commits pending agent edits before tearing
	// the worktree down. Tests that don't write to a real worktree have
	// nothing to commit, so the fake unconditionally reports a no-op.
	return false, nil
}

type runnerFn func(ctx context.Context, t *task.Task, out chan<- *task.AgentEvent) error

func (f runnerFn) Run(ctx context.Context, t *task.Task, out chan<- *task.AgentEvent) (string, task.SessionUsage, error) {
	return "", task.SessionUsage{}, f(ctx, t, out)
}

func (f runnerFn) RunSubtask(ctx context.Context, t *task.Task, _ *task.Subtask, _ task.SubtaskRunContext, out chan<- *task.AgentEvent) (string, task.SessionUsage, error) {
	return "", task.SessionUsage{}, f(ctx, t, out)
}

// subtaskRunnerFn splits Run and RunSubtask so tests can assert per-subtask
// dispatch. Run delegates to runFn (covering the single-session fallback);
// RunSubtask delegates to subFn.
type subtaskRunnerFn struct {
	runFn func(ctx context.Context, t *task.Task, out chan<- *task.AgentEvent) error
	subFn func(ctx context.Context, t *task.Task, sub *task.Subtask, out chan<- *task.AgentEvent) error
}

func (f subtaskRunnerFn) Run(ctx context.Context, t *task.Task, out chan<- *task.AgentEvent) (string, task.SessionUsage, error) {
	return "", task.SessionUsage{}, f.runFn(ctx, t, out)
}

func (f subtaskRunnerFn) RunSubtask(ctx context.Context, t *task.Task, sub *task.Subtask, _ task.SubtaskRunContext, out chan<- *task.AgentEvent) (string, task.SessionUsage, error) {
	return "", task.SessionUsage{}, f.subFn(ctx, t, sub, out)
}

// fakeSubtaskStore is the orchestrator-side slice of SubtaskRepo. Holds
// subtasks in a flat map keyed by id; ListByTask filters by parent.
type fakeSubtaskStore struct {
	mu     sync.Mutex
	byID   map[string]*task.Subtask
	byTask map[string][]string // parent task id → ordered subtask ids
}

func newFakeSubtaskStore() *fakeSubtaskStore {
	return &fakeSubtaskStore{
		byID:   map[string]*task.Subtask{},
		byTask: map[string][]string{},
	}
}

func (s *fakeSubtaskStore) seed(subs ...*task.Subtask) {
	s.mu.Lock()
	defer s.mu.Unlock()
	for _, sub := range subs {
		cp := *sub
		s.byID[sub.ID] = &cp
		s.byTask[sub.TaskID] = append(s.byTask[sub.TaskID], sub.ID)
	}
}

func (s *fakeSubtaskStore) CreatePlan(_ context.Context, parentID string, subs []*task.Subtask) (int, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	// Find current max round so the new plan picks max+1; matches the
	// real store's iteration-history semantics. Unlike the real store,
	// previous rounds stay in the map for tests that want to assert
	// the full history.
	maxRound := 0
	for _, id := range s.byTask[parentID] {
		if existing, ok := s.byID[id]; ok && existing.Round > maxRound {
			maxRound = existing.Round
		}
	}
	round := maxRound + 1
	for _, sub := range subs {
		sub.Round = round
		s.byID[sub.ID] = sub
		s.byTask[parentID] = append(s.byTask[parentID], sub.ID)
	}
	return round, nil
}

func (s *fakeSubtaskStore) ListByTask(_ context.Context, parentID string) ([]*task.Subtask, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	ids := s.byTask[parentID]
	out := make([]*task.Subtask, 0, len(ids))
	for _, id := range ids {
		cp := *s.byID[id]
		out = append(out, &cp)
	}
	return out, nil
}

// ListLatestRound mirrors the real store: returns subtasks belonging
// to the maximum round only. Empty when the parent has no subtasks.
func (s *fakeSubtaskStore) ListLatestRound(_ context.Context, parentID string) ([]*task.Subtask, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	ids := s.byTask[parentID]
	maxRound := 0
	for _, id := range ids {
		if sub, ok := s.byID[id]; ok && sub.Round > maxRound {
			maxRound = sub.Round
		}
	}
	out := make([]*task.Subtask, 0, len(ids))
	for _, id := range ids {
		sub, ok := s.byID[id]
		if !ok {
			continue
		}
		// Round 0 (legacy seed) treated as round 1 for backward
		// compatibility with tests that don't set Round explicitly.
		effective := sub.Round
		if effective == 0 {
			effective = 1
		}
		if effective != maxRound && (maxRound != 0 || effective != 1) {
			continue
		}
		cp := *sub
		out = append(out, &cp)
	}
	return out, nil
}

func (s *fakeSubtaskStore) DeleteByTask(_ context.Context, parentID string) (int64, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	ids := s.byTask[parentID]
	for _, id := range ids {
		delete(s.byID, id)
	}
	delete(s.byTask, parentID)
	return int64(len(ids)), nil
}

func (s *fakeSubtaskStore) Update(_ context.Context, sub *task.Subtask) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	if _, ok := s.byID[sub.ID]; !ok {
		return fmt.Errorf("subtask %s not found", sub.ID)
	}
	cp := *sub
	s.byID[sub.ID] = &cp
	return nil
}

func (s *fakeSubtaskStore) snapshot(parentID string) []*task.Subtask {
	subs, _ := s.ListByTask(context.Background(), parentID)
	return subs
}

// --- Helpers ---------------------------------------------------------------

func discardLogger() *slog.Logger {
	return slog.New(slog.NewTextHandler(io.Discard, nil))
}

// alwaysReworkReviewer implements AIReviewer and always demands rework.
// Useful for exercising the rework loop / cap-enforcement path.
type alwaysReworkReviewer struct {
	mu    sync.Mutex
	calls int
}

func (r *alwaysReworkReviewer) Review(_ context.Context, _ *task.Task, _, _ string, _ int, out chan<- *task.AgentEvent) (ReviewDecision, string, task.SessionUsage, error) {
	defer close(out)
	r.mu.Lock()
	defer r.mu.Unlock()
	r.calls++
	return ReviewDecision{Approve: false, Feedback: "same rework feedback from reviewer"}, "test-model", task.SessionUsage{}, nil
}

func (r *alwaysReworkReviewer) callCount() int {
	r.mu.Lock()
	defer r.mu.Unlock()
	return r.calls
}

func newOrchWithReviewer(t *testing.T, ts *fakeTaskStore, es *fakeEventStore, wt *fakeWorktrees, r AgentRunner, reviewer AIReviewer) *Orchestrator {
	t.Helper()
	o, err := New(Config{
		Concurrency:        4,
		EventBatchInterval: 10 * time.Millisecond,
		TaskStore:          ts,
		EventStore:         es,
		Repositories:       &fakeRepos{path: `C:\repo`},
		Worktrees:          wt,
		Runner:             r,
		Reviewer:           reviewer,
		Logger:             discardLogger(),
	})
	require.NoError(t, err)
	t.Cleanup(func() { _ = o.Shutdown(context.Background()) })
	return o
}

func newOrch(t *testing.T, ts *fakeTaskStore, es *fakeEventStore, wt *fakeWorktrees, r AgentRunner, concurrency int) *Orchestrator {
	t.Helper()
	o, err := New(Config{
		Concurrency:        concurrency,
		EventBatchInterval: 10 * time.Millisecond,
		TaskStore:          ts,
		EventStore:         es,
		Repositories:       &fakeRepos{path: `C:\repo`},
		Worktrees:          wt,
		Runner:             r,
		Logger:             discardLogger(),
	})
	require.NoError(t, err)
	t.Cleanup(func() { _ = o.Shutdown(context.Background()) })
	return o
}

func newOrchWithSubtasks(t *testing.T, ts *fakeTaskStore, es *fakeEventStore, wt *fakeWorktrees, ss *fakeSubtaskStore, r AgentRunner, concurrency int) *Orchestrator {
	t.Helper()
	o, err := New(Config{
		Concurrency:        concurrency,
		EventBatchInterval: 10 * time.Millisecond,
		TaskStore:          ts,
		EventStore:         es,
		Repositories:       &fakeRepos{path: `C:\repo`},
		Worktrees:          wt,
		Runner:             r,
		SubtaskStore:       ss,
		Logger:             discardLogger(),
	})
	require.NoError(t, err)
	t.Cleanup(func() { _ = o.Shutdown(context.Background()) })
	return o
}

func seedPending(ts *fakeTaskStore, id string) {
	ts.insert(&task.Task{
		ID:         id,
		RepoID:     "repo-1",
		Goal:       "do a thing",
		BaseBranch: "main",
		Status:     task.StatusQueued,
		CreatedAt:  time.Now().UTC(),
	})
}

// --- Tests -----------------------------------------------------------------

func TestOrchestrator_HappyPath(t *testing.T) {
	ts := newFakeTaskStore()
	es := newFakeEventStore()
	wt := &fakeWorktrees{}
	seedPending(ts, "t1")

	run := runnerFn(func(ctx context.Context, tk *task.Task, out chan<- *task.AgentEvent) error {
		defer close(out)
		out <- &task.AgentEvent{Kind: task.EventSessionStart}
		out <- &task.AgentEvent{Kind: task.EventAssistantDelta, Payload: "hello"}
		out <- &task.AgentEvent{Kind: task.EventSessionIdle}
		return nil
	})

	o := newOrch(t, ts, es, wt, run, 4)
	require.NoError(t, o.Enqueue("t1"))

	waitFor(t, 5*time.Second, func() bool {
		statuses := ts.statuses("t1")
		return len(statuses) >= 4 && statuses[len(statuses)-1] == task.StatusHumanReview
	})

	assert.Equal(t,
		[]task.Status{task.StatusQueued, task.StatusInProgress, task.StatusAIReview, task.StatusHumanReview},
		ts.statuses("t1"))

	// Runner emits 3 events (session.start, assistant.delta, session.idle).
	// Orchestrator also emits kind="status" events on each transition; filter
	// them out so the assertion focuses on runner-produced output.
	events := es.forTask("t1")
	runnerEvents := make([]*task.AgentEvent, 0, 3)
	for _, e := range events {
		if e.Kind != task.EventStatus {
			runnerEvents = append(runnerEvents, e)
		}
	}
	require.Len(t, runnerEvents, 3)
	assert.Equal(t, task.EventSessionStart, runnerEvents[0].Kind)
	assert.Equal(t, task.EventAssistantDelta, runnerEvents[1].Kind)
	assert.Equal(t, task.EventSessionIdle, runnerEvents[2].Kind)
}

func TestOrchestrator_Cancel_SetsAborted(t *testing.T) {
	ts := newFakeTaskStore()
	es := newFakeEventStore()
	wt := &fakeWorktrees{}
	seedPending(ts, "t1")

	started := make(chan struct{})
	run := runnerFn(func(ctx context.Context, tk *task.Task, out chan<- *task.AgentEvent) error {
		defer close(out)
		close(started)
		<-ctx.Done()
		return ctx.Err()
	})

	o := newOrch(t, ts, es, wt, run, 4)
	require.NoError(t, o.Enqueue("t1"))

	select {
	case <-started:
	case <-time.After(2 * time.Second):
		t.Fatal("runner did not start in time")
	}
	require.NoError(t, o.Cancel("t1"))

	waitFor(t, 2*time.Second, func() bool {
		statuses := ts.statuses("t1")
		return len(statuses) > 0 && statuses[len(statuses)-1] == task.StatusAborted
	})
}

func TestOrchestrator_RunnerError_SetsFailed(t *testing.T) {
	ts := newFakeTaskStore()
	es := newFakeEventStore()
	wt := &fakeWorktrees{}
	seedPending(ts, "t1")

	run := runnerFn(func(ctx context.Context, tk *task.Task, out chan<- *task.AgentEvent) error {
		defer close(out)
		return errors.New("copilot exploded")
	})

	o := newOrch(t, ts, es, wt, run, 4)
	require.NoError(t, o.Enqueue("t1"))

	waitFor(t, 2*time.Second, func() bool {
		return lastStatus(ts, "t1") == task.StatusFailed
	})
	got, err := ts.Get(context.Background(), "t1")
	require.NoError(t, err)
	assert.Equal(t, task.ErrCodeRuntime, got.ErrorCode)
	assert.Contains(t, got.ErrorMessage, "copilot exploded")
}

func TestOrchestrator_WorktreeCreateFail_SetsFailed(t *testing.T) {
	ts := newFakeTaskStore()
	es := newFakeEventStore()
	wt := &fakeWorktrees{
		createFn: func(context.Context, worktree.CreateInput) (*worktree.Created, error) {
			return nil, errors.New("disk full")
		},
	}
	seedPending(ts, "t1")

	// Runner should never be invoked, but supply a passthrough.
	run := runnerFn(func(_ context.Context, _ *task.Task, out chan<- *task.AgentEvent) error {
		close(out)
		return nil
	})

	o := newOrch(t, ts, es, wt, run, 4)
	require.NoError(t, o.Enqueue("t1"))

	waitFor(t, 2*time.Second, func() bool {
		return lastStatus(ts, "t1") == task.StatusFailed
	})
	got, _ := ts.Get(context.Background(), "t1")
	assert.Equal(t, task.ErrCodeRuntime, got.ErrorCode)
	assert.Contains(t, got.ErrorMessage, "disk full")
}

func TestOrchestrator_ConcurrencyLimit(t *testing.T) {
	ts := newFakeTaskStore()
	es := newFakeEventStore()
	wt := &fakeWorktrees{}

	const n = 5
	const limit = 2
	for i := 0; i < n; i++ {
		seedPending(ts, fmt.Sprintf("t%d", i))
	}

	var running atomic.Int32
	var peak atomic.Int32
	proceed := make(chan struct{})

	run := runnerFn(func(ctx context.Context, _ *task.Task, out chan<- *task.AgentEvent) error {
		defer close(out)
		cur := running.Add(1)
		for {
			old := peak.Load()
			if cur <= old || peak.CompareAndSwap(old, cur) {
				break
			}
		}
		<-proceed
		running.Add(-1)
		return nil
	})

	o := newOrch(t, ts, es, wt, run, limit)
	for i := 0; i < n; i++ {
		require.NoError(t, o.Enqueue(fmt.Sprintf("t%d", i)))
	}

	// Give the dispatchers time to saturate the semaphore.
	waitFor(t, 2*time.Second, func() bool { return peak.Load() == int32(limit) })
	close(proceed)

	waitFor(t, 3*time.Second, func() bool {
		for i := 0; i < n; i++ {
			if lastStatus(ts, fmt.Sprintf("t%d", i)) != task.StatusHumanReview {
				return false
			}
		}
		return true
	})
	assert.LessOrEqual(t, int(peak.Load()), limit, "concurrency must not exceed configured limit")
}

func TestOrchestrator_Finalize_Keep(t *testing.T) {
	ts := newFakeTaskStore()
	es := newFakeEventStore()
	wt := &fakeWorktrees{}
	seedPending(ts, "t1")

	run := runnerFn(func(_ context.Context, _ *task.Task, out chan<- *task.AgentEvent) error {
		close(out)
		return nil
	})
	o := newOrch(t, ts, es, wt, run, 4)
	require.NoError(t, o.Enqueue("t1"))
	waitFor(t, 2*time.Second, func() bool { return lastStatus(ts, "t1") == task.StatusHumanReview })

	require.NoError(t, o.Finalize(context.Background(), "t1", FinalizeKeep))
	assert.Equal(t, task.StatusDone, lastStatus(ts, "t1"))
	assert.Contains(t, wt.removed, "t1")
}

func TestOrchestrator_Finalize_Discard(t *testing.T) {
	ts := newFakeTaskStore()
	es := newFakeEventStore()
	wt := &fakeWorktrees{}
	seedPending(ts, "t1")

	run := runnerFn(func(_ context.Context, _ *task.Task, out chan<- *task.AgentEvent) error {
		close(out)
		return nil
	})
	o := newOrch(t, ts, es, wt, run, 4)
	require.NoError(t, o.Enqueue("t1"))
	waitFor(t, 2*time.Second, func() bool { return lastStatus(ts, "t1") == task.StatusHumanReview })

	require.NoError(t, o.Finalize(context.Background(), "t1", FinalizeDiscard))
	assert.Equal(t, task.StatusCancelled, lastStatus(ts, "t1"))
}

func TestOrchestrator_Finalize_RejectsRunning(t *testing.T) {
	ts := newFakeTaskStore()
	es := newFakeEventStore()
	wt := &fakeWorktrees{}
	seedPending(ts, "t1")

	started := make(chan struct{})
	block := make(chan struct{})
	run := runnerFn(func(ctx context.Context, _ *task.Task, out chan<- *task.AgentEvent) error {
		defer close(out)
		close(started)
		<-block
		return nil
	})
	o := newOrch(t, ts, es, wt, run, 4)
	require.NoError(t, o.Enqueue("t1"))
	<-started

	err := o.Finalize(context.Background(), "t1", FinalizeKeep)
	require.Error(t, err, "Finalize must reject a running task")

	close(block)
}

func TestOrchestrator_EnqueueDuplicate(t *testing.T) {
	ts := newFakeTaskStore()
	es := newFakeEventStore()
	wt := &fakeWorktrees{}
	seedPending(ts, "t1")

	block := make(chan struct{})
	run := runnerFn(func(_ context.Context, _ *task.Task, out chan<- *task.AgentEvent) error {
		defer close(out)
		<-block
		return nil
	})
	o := newOrch(t, ts, es, wt, run, 4)
	require.NoError(t, o.Enqueue("t1"))

	err := o.Enqueue("t1")
	assert.ErrorIs(t, err, ErrAlreadyRunning)

	close(block)
}

func TestOrchestrator_ShutdownCancelsRunning(t *testing.T) {
	ts := newFakeTaskStore()
	es := newFakeEventStore()
	wt := &fakeWorktrees{}
	seedPending(ts, "t1")

	started := make(chan struct{})
	run := runnerFn(func(ctx context.Context, _ *task.Task, out chan<- *task.AgentEvent) error {
		defer close(out)
		close(started)
		<-ctx.Done()
		return ctx.Err()
	})
	o := newOrch(t, ts, es, wt, run, 4)
	require.NoError(t, o.Enqueue("t1"))
	<-started

	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()
	require.NoError(t, o.Shutdown(ctx))

	// After shutdown, status should be one of {running, aborted, failed}.
	// Running status lingers because the cancel wasn't "by user"; orchestrator
	// treats context cancellation without abortByUser as failed(runtime)
	// only if runner returns non-context error. The runner returned ctx.Err()
	// so we fall into the abortByUser == false branch → failed via fallthrough.
	last := lastStatus(ts, "t1")
	assert.Contains(t, []task.Status{task.StatusFailed, task.StatusInProgress}, last)
}

// --- Utilities -------------------------------------------------------------

func lastStatus(ts *fakeTaskStore, id string) task.Status {
	h := ts.statuses(id)
	if len(h) == 0 {
		return ""
	}
	return h[len(h)-1]
}

// waitFor polls the predicate up to deadline, failing the test if it never
// becomes true. Used to avoid sleep-based flakes.
func waitFor(t *testing.T, deadline time.Duration, cond func() bool) {
	t.Helper()
	end := time.Now().Add(deadline)
	for time.Now().Before(end) {
		if cond() {
			return
		}
		time.Sleep(10 * time.Millisecond)
	}
	t.Fatalf("condition not met within %s", deadline)
}

func TestOrchestrator_AIReview_CapsReworkAtMax(t *testing.T) {
	ts := newFakeTaskStore()
	es := newFakeEventStore()
	// The rework loop re-enters dispatch with t.WorktreePath already set;
	// ensureWorktree()'s worktreeMissing check is backed by os.Stat, so
	// the fake needs to create a real directory. Otherwise the 2nd cycle
	// fails with "worktree directory no longer exists" before reviewer
	// gets called a second time.
	wtRoot := t.TempDir()
	wt := &fakeWorktrees{
		createFn: func(_ context.Context, in worktree.CreateInput) (*worktree.Created, error) {
			p := filepath.Join(wtRoot, in.TaskID)
			if err := os.MkdirAll(p, 0o755); err != nil {
				return nil, err
			}
			return &worktree.Created{Path: p, Branch: "fleetkanban/" + in.TaskID}, nil
		},
	}
	ts.insert(&task.Task{
		ID:           "t1",
		RepoID:       "repo-1",
		Goal:         "loop me",
		BaseBranch:   "main",
		Status:       task.StatusQueued,
		BranchExists: true, // rework cycles need this true so ensureWorktree
		// doesn't short-circuit on the 2nd iteration with
		// "branch removed externally"
		CreatedAt: time.Now().UTC(),
	})

	// Trivial single-session runner — every in_progress cycle exits cleanly.
	run := runnerFn(func(_ context.Context, _ *task.Task, out chan<- *task.AgentEvent) error {
		defer close(out)
		return nil
	})

	reviewer := &alwaysReworkReviewer{}
	o := newOrchWithReviewer(t, ts, es, wt, run, reviewer)
	require.NoError(t, o.Enqueue("t1"))

	// After MaxReworkCount auto-reworks, the next ai_review must escalate
	// to human_review (not back to queued). Terminal-enough for the test.
	// Poll with diagnostics so a stuck cycle surfaces useful context on
	// failure rather than a bare "condition not met".
	deadline := time.Now().Add(30 * time.Second)
	for time.Now().Before(deadline) {
		if lastStatus(ts, "t1") == task.StatusHumanReview {
			break
		}
		time.Sleep(50 * time.Millisecond)
	}
	if lastStatus(ts, "t1") != task.StatusHumanReview {
		t.Fatalf("cap never escalated to human_review within 30s. history=%v reviewer_calls=%d",
			ts.statuses("t1"), reviewer.callCount())
	}

	got, err := ts.Get(context.Background(), "t1")
	require.NoError(t, err)
	// On the escalation transition the store resets the counter's
	// increment path (from was ai_review, to was human_review — neither
	// branch touches rework_count), so the recorded value is the one
	// that tripped the cap.
	assert.GreaterOrEqual(t, got.ReworkCount, MaxReworkCount,
		"task must have been reworked at least MaxReworkCount times before escalation")
	assert.Contains(t, got.ReviewFeedback, "without converging",
		"escalation feedback must explain why the user is being pulled in")

	// Reviewer must have been called exactly MaxReworkCount + 1 times
	// (the +1 is the decisive call that hits the cap). Further rework
	// iterations must not happen.
	assert.Equal(t, MaxReworkCount+1, reviewer.callCount(),
		"reviewer should be called exactly once per ai_review, including the cap-hitting one")

	// The ai_review.decision event stream must contain exactly one entry
	// with rework_cap_reached=true — the terminal verdict that tripped
	// the cap. Earlier decisions (regular rework loops) must keep the
	// flag at false so the UI can render the escalation distinctively.
	var capReachedCount, totalDecisions int
	for _, ev := range es.forTask("t1") {
		if ev.Kind != task.EventAIReviewDecision {
			continue
		}
		totalDecisions++
		var payload struct {
			ReworkCapReached bool `json:"rework_cap_reached"`
		}
		require.NoError(t, json.Unmarshal([]byte(ev.Payload), &payload))
		if payload.ReworkCapReached {
			capReachedCount++
		}
	}
	assert.Equal(t, 1, capReachedCount,
		"exactly one ai_review.decision must carry rework_cap_reached=true")
	assert.GreaterOrEqual(t, totalDecisions, MaxReworkCount,
		"every reviewer call must emit an ai_review.decision event")
}

func TestOrchestrator_SubtaskLoop_RunsInOrder(t *testing.T) {
	ts := newFakeTaskStore()
	es := newFakeEventStore()
	wt := &fakeWorktrees{}
	ss := newFakeSubtaskStore()
	seedPending(ts, "t1")
	ss.seed(
		&task.Subtask{ID: "s1", TaskID: "t1", Title: "design", AgentRole: "planner", Status: task.SubtaskPending, OrderIdx: 0},
		&task.Subtask{ID: "s2", TaskID: "t1", Title: "build", AgentRole: "coder", DependsOn: []string{"s1"}, Status: task.SubtaskPending, OrderIdx: 1},
		&task.Subtask{ID: "s3", TaskID: "t1", Title: "test", AgentRole: "tester", DependsOn: []string{"s2"}, Status: task.SubtaskPending, OrderIdx: 2},
	)

	var (
		mu           sync.Mutex
		observedSubs []string
	)
	runner := subtaskRunnerFn{
		runFn: func(_ context.Context, _ *task.Task, out chan<- *task.AgentEvent) error {
			close(out)
			return errors.New("single-session path should not be taken when subtasks exist")
		},
		subFn: func(_ context.Context, _ *task.Task, sub *task.Subtask, out chan<- *task.AgentEvent) error {
			defer close(out)
			mu.Lock()
			observedSubs = append(observedSubs, sub.ID)
			mu.Unlock()
			out <- &task.AgentEvent{Kind: task.EventAssistantDelta, Payload: sub.Title + " done"}
			return nil
		},
	}

	o := newOrchWithSubtasks(t, ts, es, wt, ss, runner, 4)
	require.NoError(t, o.Enqueue("t1"))

	waitFor(t, 5*time.Second, func() bool {
		return lastStatus(ts, "t1") == task.StatusHumanReview
	})

	mu.Lock()
	defer mu.Unlock()
	assert.Equal(t, []string{"s1", "s2", "s3"}, observedSubs,
		"runner must see subtasks in topological (order_idx) order")

	for _, sub := range ss.snapshot("t1") {
		assert.Equal(t, task.SubtaskDone, sub.Status, "subtask %s not done", sub.ID)
	}

	// Lifecycle events land on the parent task's event stream.
	kinds := map[task.EventKind]int{}
	for _, ev := range es.forTask("t1") {
		kinds[ev.Kind]++
	}
	assert.Equal(t, 3, kinds[task.EventSubtaskStart], "one start per subtask")
	assert.Equal(t, 3, kinds[task.EventSubtaskEnd], "one end per subtask")
}

func TestOrchestrator_SubtaskLoop_ReworkResetsStaleStatuses(t *testing.T) {
	ts := newFakeTaskStore()
	es := newFakeEventStore()
	wt := &fakeWorktrees{}
	ss := newFakeSubtaskStore()
	seedPending(ts, "t1")
	// Mimic the post-previous-run state: two done, one failed. Rework must
	// reset every status to pending before the executor loops, otherwise
	// done nodes silently skip and the review feedback never lands.
	ss.seed(
		&task.Subtask{ID: "s1", TaskID: "t1", Title: "design", AgentRole: "planner", Status: task.SubtaskDone, OrderIdx: 0},
		&task.Subtask{ID: "s2", TaskID: "t1", Title: "build", AgentRole: "coder", DependsOn: []string{"s1"}, Status: task.SubtaskFailed, OrderIdx: 1},
		&task.Subtask{ID: "s3", TaskID: "t1", Title: "test", AgentRole: "tester", DependsOn: []string{"s2"}, Status: task.SubtaskPending, OrderIdx: 2},
	)

	var (
		mu  sync.Mutex
		ran []string
	)
	runner := subtaskRunnerFn{
		runFn: func(_ context.Context, _ *task.Task, out chan<- *task.AgentEvent) error {
			close(out)
			return nil
		},
		subFn: func(_ context.Context, _ *task.Task, sub *task.Subtask, out chan<- *task.AgentEvent) error {
			defer close(out)
			mu.Lock()
			ran = append(ran, sub.ID)
			mu.Unlock()
			return nil
		},
	}

	o := newOrchWithSubtasks(t, ts, es, wt, ss, runner, 4)
	require.NoError(t, o.Enqueue("t1"))

	waitFor(t, 5*time.Second, func() bool {
		return lastStatus(ts, "t1") == task.StatusHumanReview
	})

	mu.Lock()
	defer mu.Unlock()
	assert.Equal(t, []string{"s1", "s2", "s3"}, ran,
		"rework must re-execute every subtask, not skip done/failed rows")
}

func TestOrchestrator_SubtaskLoop_CascadeOnFailure(t *testing.T) {
	ts := newFakeTaskStore()
	es := newFakeEventStore()
	wt := &fakeWorktrees{}
	ss := newFakeSubtaskStore()
	seedPending(ts, "t1")
	ss.seed(
		&task.Subtask{ID: "s1", TaskID: "t1", Title: "design", AgentRole: "planner", Status: task.SubtaskPending, OrderIdx: 0},
		&task.Subtask{ID: "s2", TaskID: "t1", Title: "build", AgentRole: "coder", DependsOn: []string{"s1"}, Status: task.SubtaskPending, OrderIdx: 1},
		&task.Subtask{ID: "s3", TaskID: "t1", Title: "unrelated", AgentRole: "docs", Status: task.SubtaskPending, OrderIdx: 2},
	)

	runner := subtaskRunnerFn{
		runFn: func(_ context.Context, _ *task.Task, out chan<- *task.AgentEvent) error {
			close(out)
			return nil
		},
		subFn: func(_ context.Context, _ *task.Task, sub *task.Subtask, out chan<- *task.AgentEvent) error {
			defer close(out)
			if sub.ID == "s1" {
				return errors.New("boom")
			}
			return nil
		},
	}

	o := newOrchWithSubtasks(t, ts, es, wt, ss, runner, 4)
	require.NoError(t, o.Enqueue("t1"))

	waitFor(t, 5*time.Second, func() bool {
		return lastStatus(ts, "t1") == task.StatusFailed
	})

	snap := ss.snapshot("t1")
	byID := map[string]*task.Subtask{}
	for _, s := range snap {
		byID[s.ID] = s
	}
	assert.Equal(t, task.SubtaskFailed, byID["s1"].Status, "s1 failed directly")
	// s3 has no dependency on s1 but — since we're fail-fast on first
	// error — it never ran. Either `pending` (untouched) or `failed`
	// (cascade) is acceptable; we assert it's not done.
	assert.NotEqual(t, task.SubtaskDone, byID["s3"].Status, "s3 must not be done after fail-fast abort")
}
