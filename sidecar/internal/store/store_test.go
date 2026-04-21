package store

import (
	"context"
	"errors"
	"fmt"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/haya3/fleetkanban/internal/task"
)

// openTestDB creates a fresh SQLite file in t.TempDir().
// Using a file (not :memory:) exercises WAL and the two-handle split.
func openTestDB(t *testing.T) *DB {
	t.Helper()
	path := filepath.Join(t.TempDir(), "test.db")
	db, err := Open(t.Context(), Options{Path: path})
	require.NoError(t, err)
	t.Cleanup(func() { _ = db.Close() })
	return db
}

func mustRepo(t *testing.T, rs *RepositoryStore, id, name string) *Repository {
	t.Helper()
	r, err := rs.Create(t.Context(), RepositoryInput{
		ID:                id,
		Path:              fmt.Sprintf(`C:\Users\x\repos\%s`, name),
		DisplayName:       name,
		DefaultBaseBranch: "main",
	})
	require.NoError(t, err)
	return r
}

func mustTask(t *testing.T, ts *TaskStore, id, repoID string) *task.Task {
	t.Helper()
	tk := &task.Task{
		ID:         id,
		RepoID:     repoID,
		Goal:       "example",
		BaseBranch: "main",
		Branch:     "fleetkanban/" + id,
		Model:      "gpt-4.1",
		Status:     task.StatusQueued,
		CreatedAt:  time.Now().UTC(),
	}
	require.NoError(t, ts.Create(t.Context(), tk))
	return tk
}

// --- RepositoryStore ---

func TestRepository_CreateGetList(t *testing.T) {
	db := openTestDB(t)
	rs := NewRepositoryStore(db)

	r := mustRepo(t, rs, "repo-01", "alpha")
	assert.Equal(t, "alpha", r.DisplayName)
	assert.Equal(t, strings.ToLower(`C:\Users\x\repos\alpha`), r.Path,
		"path must be normalized to lowercase")

	got, err := rs.Get(t.Context(), "repo-01")
	require.NoError(t, err)
	assert.Equal(t, r.ID, got.ID)

	byPath, err := rs.GetByPath(t.Context(), `C:\USERS\X\repos\alpha`)
	require.NoError(t, err)
	assert.Equal(t, r.ID, byPath.ID, "case-insensitive path lookup")

	all, err := rs.List(t.Context())
	require.NoError(t, err)
	assert.Len(t, all, 1)
}

func TestRepository_DuplicatePath(t *testing.T) {
	db := openTestDB(t)
	rs := NewRepositoryStore(db)

	_ = mustRepo(t, rs, "repo-01", "alpha")
	_, err := rs.Create(t.Context(), RepositoryInput{
		ID:          "repo-02",
		Path:        `C:\Users\x\repos\ALPHA`, // different case, same logical path
		DisplayName: "alpha-2",
	})
	require.ErrorIs(t, err, ErrDuplicatePath)
}

func TestRepository_NotFound(t *testing.T) {
	db := openTestDB(t)
	rs := NewRepositoryStore(db)

	_, err := rs.Get(t.Context(), "missing")
	assert.ErrorIs(t, err, ErrNotFound)
}

func TestRepository_TouchLastUsed(t *testing.T) {
	db := openTestDB(t)
	rs := NewRepositoryStore(db)

	r := mustRepo(t, rs, "repo-01", "alpha")
	require.Nil(t, r.LastUsedAt)

	require.NoError(t, rs.TouchLastUsed(t.Context(), r.ID))
	refreshed, err := rs.Get(t.Context(), r.ID)
	require.NoError(t, err)
	require.NotNil(t, refreshed.LastUsedAt)
}

// --- TaskStore ---

func TestTask_CreateAndGet(t *testing.T) {
	db := openTestDB(t)
	rs := NewRepositoryStore(db)
	ts := NewTaskStore(db)

	repo := mustRepo(t, rs, "repo-01", "alpha")
	tk := mustTask(t, ts, "task-01", repo.ID)

	got, err := ts.Get(t.Context(), tk.ID)
	require.NoError(t, err)
	assert.Equal(t, tk.ID, got.ID)
	assert.Equal(t, task.StatusQueued, got.Status)
	assert.Equal(t, "gpt-4.1", got.Model)
}

func TestTask_List_FilterByStatus(t *testing.T) {
	db := openTestDB(t)
	rs := NewRepositoryStore(db)
	ts := NewTaskStore(db)

	repo := mustRepo(t, rs, "repo-01", "alpha")
	_ = mustTask(t, ts, "task-p", repo.ID)
	running := mustTask(t, ts, "task-r", repo.ID)
	require.NoError(t, ts.Transition(t.Context(), running.ID,
		task.StatusQueued, task.StatusInProgress, "", "", task.FinalizationNone))

	queued, err := ts.List(t.Context(), ListFilter{Statuses: []task.Status{task.StatusQueued}})
	require.NoError(t, err)
	require.Len(t, queued, 1)
	assert.Equal(t, "task-p", queued[0].ID)

	both, err := ts.List(t.Context(), ListFilter{})
	require.NoError(t, err)
	assert.Len(t, both, 2)
}

func TestTask_Transition_Legal(t *testing.T) {
	db := openTestDB(t)
	rs := NewRepositoryStore(db)
	ts := NewTaskStore(db)

	repo := mustRepo(t, rs, "repo-01", "alpha")
	tk := mustTask(t, ts, "task-01", repo.ID)

	ctx := t.Context()
	require.NoError(t, ts.Transition(ctx, tk.ID,
		task.StatusQueued, task.StatusInProgress, "", "", task.FinalizationNone))
	got, err := ts.Get(ctx, tk.ID)
	require.NoError(t, err)
	require.NotNil(t, got.StartedAt, "started_at must be set on queued→in_progress")

	require.NoError(t, ts.Transition(ctx, tk.ID,
		task.StatusInProgress, task.StatusAIReview, "", "", task.FinalizationNone))
	got, err = ts.Get(ctx, tk.ID)
	require.NoError(t, err)
	require.NotNil(t, got.FinishedAt, "finished_at must be set on in_progress→ai_review")

	require.NoError(t, ts.Transition(ctx, tk.ID,
		task.StatusAIReview, task.StatusHumanReview, "", "", task.FinalizationNone))

	require.NoError(t, ts.Transition(ctx, tk.ID,
		task.StatusHumanReview, task.StatusDone, "", "", task.FinalizationKeep))
	got, err = ts.Get(ctx, tk.ID)
	require.NoError(t, err)
	assert.Equal(t, task.FinalizationKeep, got.Finalization)
}

func TestTask_Transition_Illegal(t *testing.T) {
	db := openTestDB(t)
	rs := NewRepositoryStore(db)
	ts := NewTaskStore(db)

	repo := mustRepo(t, rs, "repo-01", "alpha")
	tk := mustTask(t, ts, "task-01", repo.ID)

	err := ts.Transition(t.Context(), tk.ID,
		task.StatusQueued, task.StatusDone, "", "", task.FinalizationKeep)
	require.Error(t, err, "queued→done must be rejected")
}

func TestTask_Transition_ReworkCount(t *testing.T) {
	db := openTestDB(t)
	rs := NewRepositoryStore(db)
	ts := NewTaskStore(db)

	repo := mustRepo(t, rs, "repo-01", "alpha")
	tk := mustTask(t, ts, "task-01", repo.ID)

	ctx := t.Context()
	// Drive through the pipeline: queued → in_progress → ai_review.
	require.NoError(t, ts.Transition(ctx, tk.ID,
		task.StatusQueued, task.StatusInProgress, "", "", task.FinalizationNone))
	require.NoError(t, ts.Transition(ctx, tk.ID,
		task.StatusInProgress, task.StatusAIReview, "", "", task.FinalizationNone))

	got, err := ts.Get(ctx, tk.ID)
	require.NoError(t, err)
	assert.Equal(t, 0, got.ReworkCount, "initial ai_review arrival must not increment")

	// ai_review → queued → increment to 1.
	require.NoError(t, ts.Transition(ctx, tk.ID,
		task.StatusAIReview, task.StatusQueued, "", "", task.FinalizationNone))
	got, _ = ts.Get(ctx, tk.ID)
	assert.Equal(t, 1, got.ReworkCount)

	// Another rework cycle → 2.
	require.NoError(t, ts.Transition(ctx, tk.ID,
		task.StatusQueued, task.StatusInProgress, "", "", task.FinalizationNone))
	require.NoError(t, ts.Transition(ctx, tk.ID,
		task.StatusInProgress, task.StatusAIReview, "", "", task.FinalizationNone))
	require.NoError(t, ts.Transition(ctx, tk.ID,
		task.StatusAIReview, task.StatusQueued, "", "", task.FinalizationNone))
	got, _ = ts.Get(ctx, tk.ID)
	assert.Equal(t, 2, got.ReworkCount, "second ai_review rework must increment to 2")

	// human_review → queued (user-initiated rework) must reset to 0.
	// First advance to human_review to set up the transition.
	require.NoError(t, ts.Transition(ctx, tk.ID,
		task.StatusQueued, task.StatusInProgress, "", "", task.FinalizationNone))
	require.NoError(t, ts.Transition(ctx, tk.ID,
		task.StatusInProgress, task.StatusAIReview, "", "", task.FinalizationNone))
	require.NoError(t, ts.Transition(ctx, tk.ID,
		task.StatusAIReview, task.StatusHumanReview, "", "", task.FinalizationNone))
	require.NoError(t, ts.Transition(ctx, tk.ID,
		task.StatusHumanReview, task.StatusQueued, "", "", task.FinalizationNone))
	got, _ = ts.Get(ctx, tk.ID)
	assert.Equal(t, 0, got.ReworkCount, "user rework path must reset the counter")

	// Arriving at a terminal status also resets, so a future retry from
	// `failed` doesn't inherit leftover rework history.
	require.NoError(t, ts.Transition(ctx, tk.ID,
		task.StatusQueued, task.StatusInProgress, "", "", task.FinalizationNone))
	require.NoError(t, ts.Transition(ctx, tk.ID,
		task.StatusInProgress, task.StatusAIReview, "", "", task.FinalizationNone))
	require.NoError(t, ts.Transition(ctx, tk.ID,
		task.StatusAIReview, task.StatusQueued, "", "", task.FinalizationNone))
	got, _ = ts.Get(ctx, tk.ID)
	assert.Equal(t, 1, got.ReworkCount, "sanity: incremented once pre-terminal")
	// Walk to failed via in_progress.
	require.NoError(t, ts.Transition(ctx, tk.ID,
		task.StatusQueued, task.StatusInProgress, "", "", task.FinalizationNone))
	require.NoError(t, ts.Transition(ctx, tk.ID,
		task.StatusInProgress, task.StatusFailed, task.ErrCodeRuntime, "test", task.FinalizationNone))
	got, _ = ts.Get(ctx, tk.ID)
	assert.Equal(t, 0, got.ReworkCount, "terminal arrival must reset")
}

func TestTask_Transition_Stale(t *testing.T) {
	db := openTestDB(t)
	rs := NewRepositoryStore(db)
	ts := NewTaskStore(db)

	repo := mustRepo(t, rs, "repo-01", "alpha")
	tk := mustTask(t, ts, "task-01", repo.ID)

	ctx := t.Context()
	require.NoError(t, ts.Transition(ctx, tk.ID,
		task.StatusQueued, task.StatusInProgress, "", "", task.FinalizationNone))

	// Re-running the same transition must now fail as stale (status != queued).
	err := ts.Transition(ctx, tk.ID,
		task.StatusQueued, task.StatusInProgress, "", "", task.FinalizationNone)
	require.ErrorIs(t, err, ErrStaleUpdate)
}

func TestTask_Transition_FailedRequiresErrorCode(t *testing.T) {
	db := openTestDB(t)
	rs := NewRepositoryStore(db)
	ts := NewTaskStore(db)

	repo := mustRepo(t, rs, "repo-01", "alpha")
	tk := mustTask(t, ts, "task-01", repo.ID)
	ctx := t.Context()
	require.NoError(t, ts.Transition(ctx, tk.ID,
		task.StatusQueued, task.StatusInProgress, "", "", task.FinalizationNone))

	err := ts.Transition(ctx, tk.ID,
		task.StatusInProgress, task.StatusFailed, "", "", task.FinalizationNone)
	require.Error(t, err, "failed without error code must be rejected")

	require.NoError(t, ts.Transition(ctx, tk.ID,
		task.StatusInProgress, task.StatusFailed,
		task.ErrCodeRuntime, "exit 1", task.FinalizationNone))
	got, err := ts.Get(ctx, tk.ID)
	require.NoError(t, err)
	assert.Equal(t, task.StatusFailed, got.Status)
	assert.Equal(t, task.ErrCodeRuntime, got.ErrorCode)
	assert.Equal(t, "exit 1", got.ErrorMessage)
}

func TestTask_Transition_DoneRequiresFinalization(t *testing.T) {
	db := openTestDB(t)
	rs := NewRepositoryStore(db)
	ts := NewTaskStore(db)

	repo := mustRepo(t, rs, "repo-01", "alpha")
	tk := mustTask(t, ts, "task-01", repo.ID)
	ctx := t.Context()
	require.NoError(t, ts.Transition(ctx, tk.ID,
		task.StatusQueued, task.StatusInProgress, "", "", task.FinalizationNone))
	require.NoError(t, ts.Transition(ctx, tk.ID,
		task.StatusInProgress, task.StatusAIReview, "", "", task.FinalizationNone))
	require.NoError(t, ts.Transition(ctx, tk.ID,
		task.StatusAIReview, task.StatusHumanReview, "", "", task.FinalizationNone))

	err := ts.Transition(ctx, tk.ID,
		task.StatusHumanReview, task.StatusDone, "", "", task.FinalizationNone)
	require.Error(t, err, "done without finalization must be rejected")

	require.NoError(t, ts.Transition(ctx, tk.ID,
		task.StatusHumanReview, task.StatusDone, "", "", task.FinalizationMerged))
	got, err := ts.Get(ctx, tk.ID)
	require.NoError(t, err)
	assert.Equal(t, task.StatusDone, got.Status)
	assert.Equal(t, task.FinalizationMerged, got.Finalization)
}

func TestTask_RecoverRunning(t *testing.T) {
	db := openTestDB(t)
	rs := NewRepositoryStore(db)
	ts := NewTaskStore(db)

	repo := mustRepo(t, rs, "repo-01", "alpha")
	ctx := t.Context()

	for _, id := range []string{"t-a", "t-b"} {
		tk := mustTask(t, ts, id, repo.ID)
		require.NoError(t, ts.Transition(ctx, tk.ID,
			task.StatusQueued, task.StatusInProgress, "", "", task.FinalizationNone))
	}

	ids, err := ts.RecoverRunning(ctx)
	require.NoError(t, err)
	assert.ElementsMatch(t, []string{"t-a", "t-b"}, ids)

	for _, id := range ids {
		got, err := ts.Get(ctx, id)
		require.NoError(t, err)
		assert.Equal(t, task.StatusFailed, got.Status)
		assert.Equal(t, task.ErrCodeInterrupted, got.ErrorCode)
	}
}

// --- EventStore ---

func TestEvent_AppendAndList(t *testing.T) {
	db := openTestDB(t)
	rs := NewRepositoryStore(db)
	ts := NewTaskStore(db)
	es := NewEventStore(db)

	repo := mustRepo(t, rs, "repo-01", "alpha")
	tk := mustTask(t, ts, "task-01", repo.ID)
	ctx := t.Context()

	require.NoError(t, es.Append(ctx, &task.AgentEvent{
		ID: "evt-1", TaskID: tk.ID, Seq: 1,
		Kind: task.EventSessionStart, OccurredAt: time.Now().UTC(),
	}))
	require.NoError(t, es.Append(ctx, &task.AgentEvent{
		ID: "evt-2", TaskID: tk.ID, Seq: 2,
		Kind: task.EventAssistantDelta, Payload: "hi", OccurredAt: time.Now().UTC(),
	}))

	events, err := es.ListByTask(ctx, tk.ID, 0, 0)
	require.NoError(t, err)
	require.Len(t, events, 2)
	assert.Equal(t, int64(1), events[0].Seq)
	assert.Equal(t, int64(2), events[1].Seq)
	assert.Equal(t, task.EventAssistantDelta, events[1].Kind)

	sinceFirst, err := es.ListByTask(ctx, tk.ID, 1, 0)
	require.NoError(t, err)
	require.Len(t, sinceFirst, 1)
	assert.Equal(t, "evt-2", sinceFirst[0].ID)

	n, err := es.CountByTask(ctx, tk.ID)
	require.NoError(t, err)
	assert.Equal(t, int64(2), n)
}

func TestEvent_AppendAutoSeq_AssignsNextFreeSeq(t *testing.T) {
	db := openTestDB(t)
	rs := NewRepositoryStore(db)
	ts := NewTaskStore(db)
	es := NewEventStore(db)

	repo := mustRepo(t, rs, "repo-01", "alpha")
	tk := mustTask(t, ts, "task-01", repo.ID)
	ctx := t.Context()

	// Seed two events via the manual-seq path.
	require.NoError(t, es.Append(ctx, &task.AgentEvent{
		ID: "evt-1", TaskID: tk.ID, Seq: 1,
		Kind: task.EventSessionStart, OccurredAt: time.Now().UTC(),
	}))
	require.NoError(t, es.Append(ctx, &task.AgentEvent{
		ID: "evt-2", TaskID: tk.ID, Seq: 2,
		Kind: task.EventAssistantDelta, OccurredAt: time.Now().UTC(),
	}))

	// AppendAutoSeq should pick seq=3 based on MAX(seq) + 1.
	ev := &task.AgentEvent{
		ID: "evt-3", TaskID: tk.ID,
		Kind: task.EventStatus, Payload: `{"from":"queued","to":"in_progress"}`,
	}
	require.NoError(t, es.AppendAutoSeq(ctx, ev))
	assert.Equal(t, int64(3), ev.Seq)
	assert.False(t, ev.OccurredAt.IsZero(), "OccurredAt should be filled in")

	listed, err := es.ListByTask(ctx, tk.ID, 0, 0)
	require.NoError(t, err)
	require.Len(t, listed, 3)
	assert.Equal(t, int64(3), listed[2].Seq)
	assert.Equal(t, task.EventStatus, listed[2].Kind)
}

func TestEvent_AppendAutoSeq_FirstEventGetsSeq1(t *testing.T) {
	db := openTestDB(t)
	rs := NewRepositoryStore(db)
	ts := NewTaskStore(db)
	es := NewEventStore(db)

	repo := mustRepo(t, rs, "repo-01", "alpha")
	tk := mustTask(t, ts, "task-01", repo.ID)

	ev := &task.AgentEvent{
		ID: "evt-1", TaskID: tk.ID, Kind: task.EventStatus,
	}
	require.NoError(t, es.AppendAutoSeq(t.Context(), ev))
	assert.Equal(t, int64(1), ev.Seq)
}

func TestEvent_AppendDuplicateSeq(t *testing.T) {
	db := openTestDB(t)
	rs := NewRepositoryStore(db)
	ts := NewTaskStore(db)
	es := NewEventStore(db)

	repo := mustRepo(t, rs, "repo-01", "alpha")
	tk := mustTask(t, ts, "task-01", repo.ID)
	ctx := t.Context()

	require.NoError(t, es.Append(ctx, &task.AgentEvent{
		ID: "e1", TaskID: tk.ID, Seq: 1,
		Kind: task.EventSessionStart, OccurredAt: time.Now().UTC(),
	}))
	err := es.Append(ctx, &task.AgentEvent{
		ID: "e2", TaskID: tk.ID, Seq: 1, // same seq
		Kind: task.EventAssistantDelta, OccurredAt: time.Now().UTC(),
	})
	require.ErrorIs(t, err, ErrDuplicateSeq)
}

func TestEvent_NextSeq(t *testing.T) {
	db := openTestDB(t)
	rs := NewRepositoryStore(db)
	ts := NewTaskStore(db)
	es := NewEventStore(db)

	repo := mustRepo(t, rs, "repo-01", "alpha")
	tk := mustTask(t, ts, "task-01", repo.ID)
	ctx := t.Context()

	next, err := es.NextSeq(ctx, tk.ID)
	require.NoError(t, err)
	assert.Equal(t, int64(1), next, "empty task starts at seq 1")

	require.NoError(t, es.Append(ctx, &task.AgentEvent{
		ID: "e1", TaskID: tk.ID, Seq: 1,
		Kind: task.EventSessionStart, OccurredAt: time.Now().UTC(),
	}))
	next, err = es.NextSeq(ctx, tk.ID)
	require.NoError(t, err)
	assert.Equal(t, int64(2), next)
}

func TestEvent_AppendBatch(t *testing.T) {
	db := openTestDB(t)
	rs := NewRepositoryStore(db)
	ts := NewTaskStore(db)
	es := NewEventStore(db)

	repo := mustRepo(t, rs, "repo-01", "alpha")
	tk := mustTask(t, ts, "task-01", repo.ID)
	ctx := t.Context()

	const n = 250
	batch := make([]*task.AgentEvent, n)
	now := time.Now().UTC()
	for i := 0; i < n; i++ {
		batch[i] = &task.AgentEvent{
			ID:         fmt.Sprintf("evt-%04d", i),
			TaskID:     tk.ID,
			Seq:        int64(i + 1),
			Kind:       task.EventAssistantDelta,
			Payload:    "chunk",
			OccurredAt: now,
		}
	}
	require.NoError(t, es.AppendBatch(ctx, batch))

	count, err := es.CountByTask(ctx, tk.ID)
	require.NoError(t, err)
	assert.Equal(t, int64(n), count)
}

func TestEvent_AppendBatch_RollsBackOnDuplicate(t *testing.T) {
	db := openTestDB(t)
	rs := NewRepositoryStore(db)
	ts := NewTaskStore(db)
	es := NewEventStore(db)

	repo := mustRepo(t, rs, "repo-01", "alpha")
	tk := mustTask(t, ts, "task-01", repo.ID)
	ctx := t.Context()

	require.NoError(t, es.Append(ctx, &task.AgentEvent{
		ID: "pre", TaskID: tk.ID, Seq: 5,
		Kind: task.EventSessionStart, OccurredAt: time.Now().UTC(),
	}))

	// Second entry collides on (task_id, seq=5).
	batch := []*task.AgentEvent{
		{ID: "b1", TaskID: tk.ID, Seq: 6, Kind: task.EventAssistantDelta, OccurredAt: time.Now().UTC()},
		{ID: "b2", TaskID: tk.ID, Seq: 5, Kind: task.EventAssistantDelta, OccurredAt: time.Now().UTC()},
	}
	err := es.AppendBatch(ctx, batch)
	if !errors.Is(err, ErrDuplicateSeq) {
		t.Fatalf("expected ErrDuplicateSeq, got %v", err)
	}

	// Ensure the good row in the batch was rolled back.
	count, err := es.CountByTask(ctx, tk.ID)
	require.NoError(t, err)
	assert.Equal(t, int64(1), count, "batch must be atomic")
}

// --- schema / open ---

func TestOpen_MigrationsIdempotent(t *testing.T) {
	path := filepath.Join(t.TempDir(), "reopen.db")
	ctx := context.Background()

	db1, err := Open(ctx, Options{Path: path})
	require.NoError(t, err)
	require.NoError(t, db1.Close())

	db2, err := Open(ctx, Options{Path: path})
	require.NoError(t, err)
	t.Cleanup(func() { _ = db2.Close() })

	// re-open must preserve data
	rs := NewRepositoryStore(db2)
	_, err = rs.Create(ctx, RepositoryInput{
		ID: "r", Path: `C:\x`, DisplayName: "x",
	})
	require.NoError(t, err)
}

func TestOpen_MissingPath(t *testing.T) {
	_, err := Open(context.Background(), Options{})
	require.Error(t, err)
}
