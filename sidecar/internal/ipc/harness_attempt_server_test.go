//go:build windows

package ipc

import (
	"path/filepath"
	"testing"
	"time"

	"github.com/oklog/ulid/v2"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"google.golang.org/protobuf/types/known/emptypb"

	pb "github.com/haya3/fleetkanban/internal/ipc/gen/fleetkanban/v1"
	"github.com/haya3/fleetkanban/internal/store"
	"github.com/haya3/fleetkanban/internal/task"
)

// openTestAttemptEnv opens a fresh SQLite file and seeds the minimal
// repository + task rows so harness_attempt.task_id FK constraints pass.
// Returns (HarnessAttemptStore, task1ID, task2ID).
func openTestAttemptEnv(t *testing.T) (*store.HarnessAttemptStore, string, string) {
	t.Helper()
	path := filepath.Join(t.TempDir(), "test.db")
	db, err := store.Open(t.Context(), store.Options{Path: path})
	require.NoError(t, err)
	t.Cleanup(func() { _ = db.Close() })

	rs := store.NewRepositoryStore(db)
	ts := store.NewTaskStore(db)

	seedRepo := func(id, name string) {
		_, err := rs.Create(t.Context(), store.RepositoryInput{
			ID: id, Path: `C:\repos\` + name, DisplayName: name,
		})
		require.NoError(t, err)
	}
	seedTask := func(id, repoID string) string {
		tk := &task.Task{
			ID: id, RepoID: repoID, Goal: "test goal",
			BaseBranch: "main", Branch: "fleetkanban/" + id,
			Model: "gpt-4.1", Status: task.StatusQueued,
			CreatedAt: time.Now().UTC(),
		}
		require.NoError(t, ts.Create(t.Context(), tk))
		return id
	}

	seedRepo("repo-srv-a", "alpha")
	seedRepo("repo-srv-b", "beta")
	t1 := seedTask("task-srv-a", "repo-srv-a")
	t2 := seedTask("task-srv-b", "repo-srv-b")

	return store.NewHarnessAttemptStore(db), t1, t2
}

func insertAttempt(t *testing.T, s *store.HarnessAttemptStore, taskID string) string {
	t.Helper()
	id := ulid.Make().String()
	require.NoError(t, s.Insert(t.Context(), store.HarnessAttempt{
		ID:            id,
		TaskID:        taskID,
		ReworkRound:   1,
		FailureClass:  "test_failure",
		ObservationMD: "some observation",
		CreatedAt:     time.Now().UTC(),
	}))
	return id
}

func TestHarnessAttemptServer_ListPending(t *testing.T) {
	s, t1, t2 := openTestAttemptEnv(t)
	srv := NewHarnessAttemptServer(s, nil)

	id1 := insertAttempt(t, s, t1)
	id2 := insertAttempt(t, s, t2)

	resp, err := srv.ListPending(t.Context(), &emptypb.Empty{})
	require.NoError(t, err)
	require.Len(t, resp.Attempts, 2)

	ids := []string{resp.Attempts[0].Id, resp.Attempts[1].Id}
	assert.ElementsMatch(t, []string{id1, id2}, ids)
}

func TestHarnessAttemptServer_ListForTask(t *testing.T) {
	s, t1, t2 := openTestAttemptEnv(t)
	srv := NewHarnessAttemptServer(s, nil)

	id := insertAttempt(t, s, t1)
	_ = insertAttempt(t, s, t2)

	resp, err := srv.ListForTask(t.Context(), &pb.ListHarnessAttemptsForTaskRequest{TaskId: t1})
	require.NoError(t, err)
	require.Len(t, resp.Attempts, 1)
	assert.Equal(t, id, resp.Attempts[0].Id)
}

func TestHarnessAttemptServer_ApproveAndRejectCycle(t *testing.T) {
	s, t1, t2 := openTestAttemptEnv(t)
	srv := NewHarnessAttemptServer(s, nil)

	approveID := insertAttempt(t, s, t1)
	rejectID := insertAttempt(t, s, t2)

	// Approve one attempt.
	approvedAttempt, err := srv.Approve(t.Context(), &pb.ApproveHarnessAttemptRequest{
		Id: approveID, DecidedBy: "alice",
	})
	require.NoError(t, err)
	assert.Equal(t, "approved", approvedAttempt.Decision)
	assert.Equal(t, "alice", approvedAttempt.DecidedBy)
	assert.NotNil(t, approvedAttempt.DecidedAt)

	// Reject the other.
	rejectedAttempt, err := srv.Reject(t.Context(), &pb.RejectHarnessAttemptRequest{
		Id: rejectID, DecidedBy: "bob",
	})
	require.NoError(t, err)
	assert.Equal(t, "rejected", rejectedAttempt.Decision)
	assert.Equal(t, "bob", rejectedAttempt.DecidedBy)

	// Both are gone from ListPending.
	pendingResp, err := srv.ListPending(t.Context(), &emptypb.Empty{})
	require.NoError(t, err)
	assert.Empty(t, pendingResp.Attempts)
}

func TestHarnessAttemptServer_Approve_AlreadyDecided(t *testing.T) {
	s, t1, _ := openTestAttemptEnv(t)
	srv := NewHarnessAttemptServer(s, nil)

	id := insertAttempt(t, s, t1)

	_, err := srv.Approve(t.Context(), &pb.ApproveHarnessAttemptRequest{Id: id, DecidedBy: "alice"})
	require.NoError(t, err)

	// Second approve on the same row must fail with FailedPrecondition.
	_, err = srv.Approve(t.Context(), &pb.ApproveHarnessAttemptRequest{Id: id, DecidedBy: "bob"})
	require.Error(t, err)
	assert.Contains(t, err.Error(), "already decided")
}
