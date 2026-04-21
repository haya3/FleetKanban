//go:build windows

package store

import (
	"testing"
	"time"

	"github.com/oklog/ulid/v2"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// seedAttemptTask creates the minimal repository + task rows required to
// satisfy harness_attempt.task_id FK constraints, returning the task ID.
func seedAttemptTask(t *testing.T, db *DB, label string) string {
	t.Helper()
	rs := NewRepositoryStore(db)
	ts := NewTaskStore(db)
	repoID := "repo-ha-" + label
	taskID := "task-ha-" + label
	mustRepo(t, rs, repoID, "repo-"+label)
	mustTask(t, ts, taskID, repoID)
	return taskID
}

// mustAttempt inserts a harness attempt and returns its ID.
func mustAttempt(t *testing.T, has *HarnessAttemptStore, taskID, failureClass string) string {
	t.Helper()
	id := ulid.Make().String()
	err := has.Insert(t.Context(), HarnessAttempt{
		ID:            id,
		TaskID:        taskID,
		ReworkRound:   1,
		FailureClass:  failureClass,
		ObservationMD: "observed: " + failureClass,
		CreatedAt:     time.Now().UTC(),
	})
	require.NoError(t, err)
	return id
}

func TestHarnessAttempt_InsertAndGet(t *testing.T) {
	db := openTestDB(t)
	has := NewHarnessAttemptStore(db)
	taskID := seedAttemptTask(t, db, "iga")

	id := mustAttempt(t, has, taskID, "compile_error")

	got, err := has.Get(t.Context(), id)
	require.NoError(t, err)
	assert.Equal(t, id, got.ID)
	assert.Equal(t, taskID, got.TaskID)
	assert.Equal(t, "pending", got.Decision)
	assert.Equal(t, "compile_error", got.FailureClass)
	assert.Nil(t, got.DecidedAt)
}

func TestHarnessAttempt_Get_NotFound(t *testing.T) {
	db := openTestDB(t)
	has := NewHarnessAttemptStore(db)

	_, err := has.Get(t.Context(), "nonexistent")
	require.ErrorIs(t, err, ErrHarnessAttemptNotFound)
}

func TestHarnessAttempt_ListPending_AppearsAndDisappears(t *testing.T) {
	db := openTestDB(t)
	has := NewHarnessAttemptStore(db)
	taskID := seedAttemptTask(t, db, "lpad")

	id1 := mustAttempt(t, has, taskID, "compile_error")
	id2 := mustAttempt(t, has, taskID, "test_failure")

	pending, err := has.ListPending(t.Context(), 100)
	require.NoError(t, err)
	assert.Len(t, pending, 2)

	// Approve id1 — it must vanish from ListPending.
	_, err = has.UpdateDecision(t.Context(), id1, "approved", "tester")
	require.NoError(t, err)

	pending, err = has.ListPending(t.Context(), 100)
	require.NoError(t, err)
	require.Len(t, pending, 1)
	assert.Equal(t, id2, pending[0].ID)
}

func TestHarnessAttempt_ListForTask(t *testing.T) {
	db := openTestDB(t)
	has := NewHarnessAttemptStore(db)
	taskAlpha := seedAttemptTask(t, db, "alpha")
	taskBeta := seedAttemptTask(t, db, "beta")

	idA := mustAttempt(t, has, taskAlpha, "compile_error")
	_ = mustAttempt(t, has, taskBeta, "test_failure") // different task

	rows, err := has.ListForTask(t.Context(), taskAlpha, 100)
	require.NoError(t, err)
	require.Len(t, rows, 1)
	assert.Equal(t, idA, rows[0].ID)
}

func TestHarnessAttempt_UpdateDecision_Approved(t *testing.T) {
	db := openTestDB(t)
	has := NewHarnessAttemptStore(db)
	taskID := seedAttemptTask(t, db, "uda")

	id := mustAttempt(t, has, taskID, "timeout")

	updated, err := has.UpdateDecision(t.Context(), id, "approved", "alice")
	require.NoError(t, err)
	assert.Equal(t, "approved", updated.Decision)
	assert.Equal(t, "alice", updated.DecidedBy)
	assert.NotNil(t, updated.DecidedAt)
}

func TestHarnessAttempt_UpdateDecision_ErrAlreadyDecided(t *testing.T) {
	db := openTestDB(t)
	has := NewHarnessAttemptStore(db)
	taskID := seedAttemptTask(t, db, "udad")

	id := mustAttempt(t, has, taskID, "timeout")

	_, err := has.UpdateDecision(t.Context(), id, "approved", "alice")
	require.NoError(t, err)

	// Second call on the same row must return ErrAlreadyDecided.
	_, err = has.UpdateDecision(t.Context(), id, "rejected", "bob")
	require.ErrorIs(t, err, ErrAlreadyDecided)
}

func TestHarnessAttempt_UpdateDecision_NotFound(t *testing.T) {
	db := openTestDB(t)
	has := NewHarnessAttemptStore(db)

	_, err := has.UpdateDecision(t.Context(), "nonexistent", "approved", "alice")
	require.ErrorIs(t, err, ErrHarnessAttemptNotFound)
}
