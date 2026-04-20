//go:build windows

package app

import (
	"context"
	"io"
	"log/slog"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/FleetKanban/fleetkanban/internal/copilot"
	"github.com/FleetKanban/fleetkanban/internal/orchestrator"
	"github.com/FleetKanban/fleetkanban/internal/store"
	"github.com/FleetKanban/fleetkanban/internal/task"
	"github.com/FleetKanban/fleetkanban/internal/worktree"
)

// initRepo is copied in miniature from internal/worktree/manager_test.go to
// keep internal/app independent of the other package's test helpers.
func initRepo(t *testing.T, dir string) {
	t.Helper()
	run := func(args ...string) {
		cmd := exec.Command("git", args...)
		cmd.Dir = dir
		out, err := cmd.CombinedOutput()
		if err != nil {
			t.Fatalf("git %s: %v\n%s", strings.Join(args, " "), err, out)
		}
	}
	require.NoError(t, os.MkdirAll(dir, 0o755))
	run("init", "-b", "main")
	run("config", "user.email", "test@example.com")
	run("config", "user.name", "Test")
	require.NoError(t, os.WriteFile(filepath.Join(dir, "README.md"), []byte("hi"), 0o644))
	run("add", ".")
	run("commit", "-m", "seed")
}

// fakeRunner is a drop-in orchestrator.AgentRunner for integration testing.
type fakeRunner struct {
	lines []string
}

func (f *fakeRunner) Run(ctx context.Context, t *task.Task, out chan<- *task.AgentEvent) (string, task.SessionUsage, error) {
	defer close(out)
	for _, l := range f.lines {
		select {
		case <-ctx.Done():
			return "", task.SessionUsage{}, ctx.Err()
		case out <- &task.AgentEvent{Kind: task.EventAssistantDelta, Payload: l}:
		}
	}
	return "", task.SessionUsage{}, nil
}

func (f *fakeRunner) RunSubtask(ctx context.Context, t *task.Task, sub *task.Subtask, _ task.SubtaskRunContext, out chan<- *task.AgentEvent) (string, task.SessionUsage, error) {
	return f.Run(ctx, t, out)
}

// stubRuntime is a no-op CopilotRuntime for tests — always reports authenticated.
type stubRuntime struct{}

func (stubRuntime) CheckAuth(_ context.Context) (copilot.AuthStatus, error) {
	return copilot.AuthStatus{Authenticated: true}, nil
}

func (stubRuntime) BeginLogin(_ context.Context) (copilot.LoginChallenge, error) {
	return copilot.LoginChallenge{
		UserCode:        "TEST-CODE",
		VerificationURI: "https://github.com/login/device?user_code=TEST-CODE",
	}, nil
}
func (stubRuntime) CancelLogin() {}
func (stubRuntime) LoginSession() copilot.LoginSessionSnapshot {
	return copilot.LoginSessionSnapshot{State: copilot.LoginSessionIdle}
}
func (stubRuntime) LaunchLogout(_ context.Context) error { return nil }
func (stubRuntime) ReloadAuth(_ context.Context, _ string) error {
	return nil
}
func (stubRuntime) ListModels(_ context.Context) ([]copilot.Model, error) {
	return []copilot.Model{
		{ID: "claude-sonnet-4.6", Name: "Claude Sonnet 4.6", Multiplier: 1},
		{ID: "gpt-5", Name: "GPT-5", Multiplier: 0},
	}, nil
}

func newService(t *testing.T, runner orchestrator.AgentRunner) (*Service, *store.DB, string) {
	t.Helper()
	tmp := t.TempDir()
	db, err := store.Open(t.Context(), store.Options{Path: filepath.Join(tmp, "t.db")})
	require.NoError(t, err)
	wtMgr, err := worktree.NewManager(worktree.Options{FallbackRoot: filepath.Join(tmp, "worktrees")})
	require.NoError(t, err)

	orch, err := orchestrator.New(orchestrator.Config{
		TaskStore:          store.NewTaskStore(db),
		EventStore:         store.NewEventStore(db),
		Repositories:       &RepositoryAdapter{Store: store.NewRepositoryStore(db)},
		Worktrees:          wtMgr,
		Runner:             runner,
		EventBatchInterval: 10 * time.Millisecond,
		Logger:             slog.New(slog.NewTextHandler(io.Discard, nil)),
	})
	require.NoError(t, err)

	svc, err := New(Config{
		DB:           db,
		Orchestrator: orch,
		Worktrees:    wtMgr,
		Runtime:      stubRuntime{},
		Logger:       slog.New(slog.NewTextHandler(io.Discard, nil)),
	})
	require.NoError(t, err)
	t.Cleanup(func() {
		_ = svc.Shutdown(context.Background())
	})
	return svc, db, tmp
}

func TestValidateGitHubToken(t *testing.T) {
	cases := []struct {
		name    string
		token   string
		wantErr bool
	}{
		{"empty is accepted as clear-signal", "", false},
		{"gho_ OAuth user access token", "gho_abcdef1234567890", false},
		{"ghu_ GitHub App user access token", "ghu_abcdef1234567890", false},
		{"github_pat_ fine-grained PAT", "github_pat_11AAAAAAA0_xyz", false},
		{"classic ghp_ PAT is rejected (SDK does not accept)", "ghp_abcdef1234567890", true},
		{"unknown prefix is rejected", "foo_abc", true},
		{"bare hex has no supported prefix", "abcdef1234567890", true},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			err := ValidateGitHubToken(tc.token)
			if tc.wantErr {
				require.Error(t, err)
				require.ErrorIs(t, err, ErrUnsupportedToken)
			} else {
				require.NoError(t, err)
			}
		})
	}
}

func TestService_EndToEnd_HappyPath(t *testing.T) {
	repoPath := filepath.Join(t.TempDir(), "repo")
	initRepo(t, repoPath)

	svc, _, _ := newService(t, &fakeRunner{lines: []string{"hello", "world"}})

	ctx := t.Context()
	repo, err := svc.RegisterRepository(ctx, RegisterRepositoryInput{
		Path: repoPath, DisplayName: "demo",
	})
	require.NoError(t, err)

	tk, err := svc.CreateTask(ctx, CreateTaskInput{
		RepositoryID: repo.ID,
		Goal:         "say hi",
	})
	require.NoError(t, err)
	assert.Equal(t, task.StatusQueued, tk.Status)
	assert.Equal(t, "main", tk.BaseBranch)

	require.NoError(t, svc.RunTask(ctx, tk.ID))

	// Poll until awaiting_review.
	deadline := time.Now().Add(3 * time.Second)
	for time.Now().Before(deadline) {
		got, err := svc.GetTask(ctx, tk.ID)
		require.NoError(t, err)
		if got.Status == task.StatusHumanReview {
			break
		}
		time.Sleep(20 * time.Millisecond)
	}
	got, err := svc.GetTask(ctx, tk.ID)
	require.NoError(t, err)
	require.Equal(t, task.StatusHumanReview, got.Status)
	assert.NotEmpty(t, got.WorktreePath)
	assert.Equal(t, "fleetkanban/"+tk.ID, got.Branch)

	events, err := svc.TaskEvents(ctx, tk.ID, 0, 0)
	require.NoError(t, err)
	require.GreaterOrEqual(t, len(events), 2)

	// Keep (default post-run): worktree gone, branch preserved.
	require.NoError(t, svc.FinalizeTask(ctx, tk.ID, orchestrator.FinalizeKeep))
	got, err = svc.GetTask(ctx, tk.ID)
	require.NoError(t, err)
	assert.Equal(t, task.StatusDone, got.Status)

	_, statErr := os.Stat(got.WorktreePath)
	assert.True(t, os.IsNotExist(statErr), "Keep must remove worktree dir")
}

func TestService_ListRepositoriesAndTasks(t *testing.T) {
	repoPath := filepath.Join(t.TempDir(), "repo")
	initRepo(t, repoPath)

	svc, _, _ := newService(t, &fakeRunner{})
	ctx := t.Context()
	repo, err := svc.RegisterRepository(ctx, RegisterRepositoryInput{
		Path: repoPath, DisplayName: "demo",
	})
	require.NoError(t, err)

	_, err = svc.CreateTask(ctx, CreateTaskInput{RepositoryID: repo.ID, Goal: "g1"})
	require.NoError(t, err)
	_, err = svc.CreateTask(ctx, CreateTaskInput{RepositoryID: repo.ID, Goal: "g2"})
	require.NoError(t, err)

	repos, err := svc.ListRepositories(ctx)
	require.NoError(t, err)
	assert.Len(t, repos, 1)

	tasks, err := svc.ListTasks(ctx, store.ListFilter{RepoID: repo.ID})
	require.NoError(t, err)
	assert.Len(t, tasks, 2)
}

// TestService_SubmitReview_ApproveOnHumanReviewRejected guards the bug where
// Approve on human_review used to silently wipe the task's ReviewFeedback
// before returning.
func TestService_SubmitReview_ApproveOnHumanReviewRejected(t *testing.T) {
	repoPath := filepath.Join(t.TempDir(), "repo")
	initRepo(t, repoPath)

	svc, _, _ := newService(t, &fakeRunner{lines: []string{"ok"}})
	ctx := t.Context()
	repo, err := svc.RegisterRepository(ctx, RegisterRepositoryInput{
		Path: repoPath, DisplayName: "demo",
	})
	require.NoError(t, err)
	tk, err := svc.CreateTask(ctx, CreateTaskInput{RepositoryID: repo.ID, Goal: "g"})
	require.NoError(t, err)
	require.NoError(t, svc.RunTask(ctx, tk.ID))

	// Advance to human_review via the orchestrator's pass-through AI review.
	deadline := time.Now().Add(5 * time.Second)
	for time.Now().Before(deadline) {
		got, _ := svc.GetTask(ctx, tk.ID)
		if got != nil && got.Status == task.StatusHumanReview {
			break
		}
		time.Sleep(20 * time.Millisecond)
	}
	got, err := svc.GetTask(ctx, tk.ID)
	require.NoError(t, err)
	require.Equal(t, task.StatusHumanReview, got.Status)

	// Record some feedback via a rework round-trip that we immediately
	// roll back by manually re-transitioning for test simplicity — or
	// just set it via UpdateFields directly through a rework then read.
	// Here we use SubmitReview(REWORK) to produce a realistic feedback
	// column, then advance back to human_review through another run.
	got.ReviewFeedback = "keep this feedback visible"
	require.NoError(t, store.NewTaskStore(svc.db).UpdateFields(ctx, got))

	// Approve on human_review must be rejected with InvalidArgument-ish
	// error, AND must not touch ReviewFeedback.
	err = svc.SubmitReview(ctx, tk.ID, ReviewApprove, "")
	require.Error(t, err, "approve on human_review should be rejected")

	after, err := svc.GetTask(ctx, tk.ID)
	require.NoError(t, err)
	assert.Equal(t, "keep this feedback visible", after.ReviewFeedback,
		"rejected review must not mutate ReviewFeedback")
	assert.Equal(t, task.StatusHumanReview, after.Status,
		"rejected review must not transition the task")
}

// TestService_DeleteTask_RemovesRowAndWorktree covers the happy path:
// delete a human_review task → worktree removed, task row gone.
func TestService_DeleteTask_RemovesRowAndWorktree(t *testing.T) {
	repoPath := filepath.Join(t.TempDir(), "repo")
	initRepo(t, repoPath)

	svc, _, _ := newService(t, &fakeRunner{lines: []string{"ok"}})
	ctx := t.Context()
	repo, err := svc.RegisterRepository(ctx, RegisterRepositoryInput{
		Path: repoPath, DisplayName: "demo",
	})
	require.NoError(t, err)
	tk, err := svc.CreateTask(ctx, CreateTaskInput{RepositoryID: repo.ID, Goal: "g"})
	require.NoError(t, err)
	require.NoError(t, svc.RunTask(ctx, tk.ID))

	// Wait for human_review.
	deadline := time.Now().Add(5 * time.Second)
	for time.Now().Before(deadline) {
		got, _ := svc.GetTask(ctx, tk.ID)
		if got != nil && got.Status == task.StatusHumanReview {
			break
		}
		time.Sleep(20 * time.Millisecond)
	}
	got, err := svc.GetTask(ctx, tk.ID)
	require.NoError(t, err)
	require.Equal(t, task.StatusHumanReview, got.Status)
	wtPath := got.WorktreePath
	require.NotEmpty(t, wtPath)

	// Delete.
	require.NoError(t, svc.DeleteTask(ctx, tk.ID, false))

	// Row is gone.
	_, err = svc.GetTask(ctx, tk.ID)
	require.Error(t, err)

	// Worktree directory is gone.
	_, statErr := os.Stat(wtPath)
	assert.True(t, os.IsNotExist(statErr), "DeleteTask must remove the worktree")
}

// TestService_DeleteTaskBranch_RemovesBranchOnKeepFinalized exercises the
// Housekeeping-UI flow: a finalized Done task whose worktree is gone but
// whose branch survives (Keep default). DeleteTaskBranch must remove the
// branch and mark BranchExists=false; the task row itself stays.
func TestService_DeleteTaskBranch_RemovesBranchOnKeepFinalized(t *testing.T) {
	repoPath := filepath.Join(t.TempDir(), "repo")
	initRepo(t, repoPath)

	svc, _, _ := newService(t, &fakeRunner{lines: []string{"ok"}})
	ctx := t.Context()
	repo, err := svc.RegisterRepository(ctx, RegisterRepositoryInput{
		Path: repoPath, DisplayName: "demo",
	})
	require.NoError(t, err)
	tk, err := svc.CreateTask(ctx, CreateTaskInput{RepositoryID: repo.ID, Goal: "g"})
	require.NoError(t, err)
	require.NoError(t, svc.RunTask(ctx, tk.ID))

	deadline := time.Now().Add(5 * time.Second)
	for time.Now().Before(deadline) {
		got, _ := svc.GetTask(ctx, tk.ID)
		if got != nil && got.Status == task.StatusHumanReview {
			break
		}
		time.Sleep(20 * time.Millisecond)
	}
	// Keep finalize → Done with branch preserved.
	require.NoError(t, svc.FinalizeTask(ctx, tk.ID, orchestrator.FinalizeKeep))

	got, err := svc.GetTask(ctx, tk.ID)
	require.NoError(t, err)
	require.Equal(t, task.StatusDone, got.Status)
	require.True(t, got.BranchExists)
	branch := got.Branch

	require.NoError(t, svc.DeleteTaskBranch(ctx, tk.ID))

	got2, err := svc.GetTask(ctx, tk.ID)
	require.NoError(t, err, "task row must survive branch deletion")
	assert.Equal(t, task.StatusDone, got2.Status)
	assert.False(t, got2.BranchExists, "BranchExists must flip to false")
	assert.Equal(t, branch, got2.Branch, "branch name is preserved for audit")

	// Branch gone from git as well — verify directly with a plumbing
	// command so the test doesn't depend on a test-only accessor.
	cmd := exec.CommandContext(ctx, "git",
		"show-ref", "--verify", "--quiet", "refs/heads/"+branch)
	cmd.Dir = repoPath
	runErr := cmd.Run()
	assert.Error(t, runErr, "branch must be gone from the repo")
}

// TestService_DeleteTaskBranch_RejectsRunning guards the status gate: only
// Done/Aborted tasks are valid targets.
func TestService_DeleteTaskBranch_RejectsRunning(t *testing.T) {
	repoPath := filepath.Join(t.TempDir(), "repo")
	initRepo(t, repoPath)

	svc, _, _ := newService(t, &fakeRunner{lines: []string{"ok"}})
	ctx := t.Context()
	repo, err := svc.RegisterRepository(ctx, RegisterRepositoryInput{
		Path: repoPath, DisplayName: "demo",
	})
	require.NoError(t, err)
	tk, err := svc.CreateTask(ctx, CreateTaskInput{RepositoryID: repo.ID, Goal: "g"})
	require.NoError(t, err)
	// task is in a non-terminal state — DeleteTaskBranch must refuse.
	err = svc.DeleteTaskBranch(ctx, tk.ID)
	require.Error(t, err)
	assert.Contains(t, err.Error(), "use FinalizeTask or DeleteTask instead")
}

// TestService_DeleteTask_RejectsInProgress guards the ErrTaskStillRunning
// gate so an accidental UI click doesn't orphan a running Copilot session.
func TestService_DeleteTask_RejectsInProgress(t *testing.T) {
	repoPath := filepath.Join(t.TempDir(), "repo")
	initRepo(t, repoPath)

	// A long-lived runner that blocks until its ctx is cancelled so the
	// task stays in_progress for the duration of this test.
	blocker := func(ctx context.Context, _ *task.Task, out chan<- *task.AgentEvent) error {
		defer close(out)
		<-ctx.Done()
		return ctx.Err()
	}

	svc, _, _ := newService(t, runnerFn(blocker))
	ctx := t.Context()
	repo, err := svc.RegisterRepository(ctx, RegisterRepositoryInput{
		Path: repoPath, DisplayName: "demo",
	})
	require.NoError(t, err)
	tk, err := svc.CreateTask(ctx, CreateTaskInput{RepositoryID: repo.ID, Goal: "g"})
	require.NoError(t, err)
	require.NoError(t, svc.RunTask(ctx, tk.ID))

	// Wait for in_progress.
	deadline := time.Now().Add(3 * time.Second)
	for time.Now().Before(deadline) {
		got, _ := svc.GetTask(ctx, tk.ID)
		if got != nil && got.Status == task.StatusInProgress {
			break
		}
		time.Sleep(20 * time.Millisecond)
	}

	// Delete must be rejected with ErrTaskStillRunning.
	err = svc.DeleteTask(ctx, tk.ID, false)
	assert.ErrorIs(t, err, ErrTaskStillRunning)

	// Task row should still exist.
	_, err = svc.GetTask(ctx, tk.ID)
	assert.NoError(t, err)
}

// runnerFn adapts a function to orchestrator.AgentRunner for tests.
type runnerFn func(ctx context.Context, t *task.Task, out chan<- *task.AgentEvent) error

func (f runnerFn) Run(ctx context.Context, t *task.Task, out chan<- *task.AgentEvent) (string, task.SessionUsage, error) {
	return "", task.SessionUsage{}, f(ctx, t, out)
}

func (f runnerFn) RunSubtask(ctx context.Context, t *task.Task, _ *task.Subtask, _ task.SubtaskRunContext, out chan<- *task.AgentEvent) (string, task.SessionUsage, error) {
	return "", task.SessionUsage{}, f(ctx, t, out)
}

// TestService_SubmitReview_ReworkFlowsFeedbackToNextPrompt guards the full
// Human Review → queued → in_progress → ... rework cycle.
func TestService_SubmitReview_ReworkFlowsFeedbackToNextPrompt(t *testing.T) {
	repoPath := filepath.Join(t.TempDir(), "repo")
	initRepo(t, repoPath)

	svc, _, _ := newService(t, &fakeRunner{lines: []string{"ok"}})
	ctx := t.Context()
	repo, err := svc.RegisterRepository(ctx, RegisterRepositoryInput{
		Path: repoPath, DisplayName: "demo",
	})
	require.NoError(t, err)
	tk, err := svc.CreateTask(ctx, CreateTaskInput{RepositoryID: repo.ID, Goal: "g"})
	require.NoError(t, err)
	require.NoError(t, svc.RunTask(ctx, tk.ID))

	// Wait for human_review.
	deadline := time.Now().Add(5 * time.Second)
	for time.Now().Before(deadline) {
		got, _ := svc.GetTask(ctx, tk.ID)
		if got != nil && got.Status == task.StatusHumanReview {
			break
		}
		time.Sleep(20 * time.Millisecond)
	}

	// Rework with feedback: task should transition to queued and the
	// feedback must appear on the row before the orchestrator re-Enqueues.
	require.NoError(t, svc.SubmitReview(ctx, tk.ID, ReviewRework, "please fix tests"))

	// The orchestrator auto-enqueues; wait for the next human_review cycle.
	deadline = time.Now().Add(5 * time.Second)
	for time.Now().Before(deadline) {
		got, _ := svc.GetTask(ctx, tk.ID)
		if got != nil && got.Status == task.StatusHumanReview {
			break
		}
		time.Sleep(20 * time.Millisecond)
	}
	after, err := svc.GetTask(ctx, tk.ID)
	require.NoError(t, err)
	assert.Equal(t, task.StatusHumanReview, after.Status,
		"rework should re-run and land back in human_review")
	assert.Equal(t, "please fix tests", after.ReviewFeedback)
}

// RegisterRepository must leave DefaultBaseBranch empty (auto-detect mode).
// Pre-fix, registration captured HEAD and pinned it unconditionally, which
// caused CreateTask failures after branch renames (master → main).
func TestService_RegisterRepository_LeavesDefaultBranchEmpty(t *testing.T) {
	repoPath := filepath.Join(t.TempDir(), "repo")
	initRepo(t, repoPath)

	svc, _, _ := newService(t, &fakeRunner{})
	ctx := t.Context()
	repo, err := svc.RegisterRepository(ctx, RegisterRepositoryInput{
		Path: repoPath, DisplayName: "demo",
	})
	require.NoError(t, err)
	assert.Empty(t, repo.DefaultBaseBranch,
		"new registrations must start in auto-detect mode")
}

func TestService_UpdateDefaultBaseBranch_PinAndClear(t *testing.T) {
	repoPath := filepath.Join(t.TempDir(), "repo")
	initRepo(t, repoPath)

	svc, _, _ := newService(t, &fakeRunner{})
	ctx := t.Context()
	repo, err := svc.RegisterRepository(ctx, RegisterRepositoryInput{
		Path: repoPath, DisplayName: "demo",
	})
	require.NoError(t, err)

	// Pin main → stored.
	updated, err := svc.UpdateDefaultBaseBranch(ctx, repo.ID, "main")
	require.NoError(t, err)
	assert.Equal(t, "main", updated.DefaultBaseBranch)

	// Clear → stored as empty (back to auto-detect).
	cleared, err := svc.UpdateDefaultBaseBranch(ctx, repo.ID, "")
	require.NoError(t, err)
	assert.Empty(t, cleared.DefaultBaseBranch)
}

func TestService_UpdateDefaultBaseBranch_RejectsMissingBranch(t *testing.T) {
	repoPath := filepath.Join(t.TempDir(), "repo")
	initRepo(t, repoPath)

	svc, _, _ := newService(t, &fakeRunner{})
	ctx := t.Context()
	repo, err := svc.RegisterRepository(ctx, RegisterRepositoryInput{
		Path: repoPath, DisplayName: "demo",
	})
	require.NoError(t, err)

	_, err = svc.UpdateDefaultBaseBranch(ctx, repo.ID, "master")
	require.Error(t, err, "pinning a non-existent branch must fail at update time, not CreateTask time")
	assert.Contains(t, err.Error(), "master")
}

// Pinned branch that doesn't exist must fail CreateTask loudly naming the
// stale pin — guards the bug that motivated option 4.
func TestService_CreateTask_PinnedBranchMissingReturnsClearError(t *testing.T) {
	repoPath := filepath.Join(t.TempDir(), "repo")
	initRepo(t, repoPath)

	svc, db, _ := newService(t, &fakeRunner{})
	ctx := t.Context()
	repo, err := svc.RegisterRepository(ctx, RegisterRepositoryInput{
		Path: repoPath, DisplayName: "demo",
	})
	require.NoError(t, err)

	// Simulate a legacy row: pin the repo to a branch that doesn't exist.
	// Can't go through UpdateDefaultBaseBranch (it validates), so write the
	// pin directly to the store.
	require.NoError(t, store.NewRepositoryStore(db).UpdateDefaultBaseBranch(ctx, repo.ID, "master"))

	_, err = svc.CreateTask(ctx, CreateTaskInput{RepositoryID: repo.ID, Goal: "g"})
	require.Error(t, err)
	assert.Contains(t, err.Error(), "master")
	assert.Contains(t, err.Error(), "pinned")
}

func TestService_ListBranches_FiltersFleetkanbanAndHoistsDefault(t *testing.T) {
	repoPath := filepath.Join(t.TempDir(), "repo")
	initRepo(t, repoPath)
	ctx := context.Background()
	run := func(args ...string) {
		cmd := exec.CommandContext(ctx, "git", args...)
		cmd.Dir = repoPath
		out, err := cmd.CombinedOutput()
		if err != nil {
			t.Fatalf("git %s: %v\n%s", strings.Join(args, " "), err, out)
		}
	}
	run("branch", "develop")
	run("branch", "fleetkanban/01J000000000000000000000XX") // internal — must be filtered

	svc, _, _ := newService(t, &fakeRunner{})
	repo, err := svc.RegisterRepository(ctx, RegisterRepositoryInput{
		Path: repoPath, DisplayName: "demo",
	})
	require.NoError(t, err)

	bl, err := svc.ListBranches(ctx, repo.ID)
	require.NoError(t, err)

	assert.Equal(t, "main", bl.DefaultBranch)
	assert.NotContains(t, bl.Branches, "fleetkanban/01J000000000000000000000XX",
		"fleetkanban/* task branches must be filtered out")
	require.NotEmpty(t, bl.Branches)
	assert.Equal(t, "main", bl.Branches[0],
		"auto-detected default must be hoisted to the front")
	assert.Contains(t, bl.Branches, "develop")
}

// CreateTask with an unpinned repo must succeed via auto-detect even though
// we no longer persist the HEAD branch at registration time.
func TestService_CreateTask_AutoDetectsDefaultBranchWhenUnpinned(t *testing.T) {
	repoPath := filepath.Join(t.TempDir(), "repo")
	initRepo(t, repoPath)

	svc, _, _ := newService(t, &fakeRunner{})
	ctx := t.Context()
	repo, err := svc.RegisterRepository(ctx, RegisterRepositoryInput{
		Path: repoPath, DisplayName: "demo",
	})
	require.NoError(t, err)

	tk, err := svc.CreateTask(ctx, CreateTaskInput{RepositoryID: repo.ID, Goal: "g"})
	require.NoError(t, err)
	assert.Equal(t, "main", tk.BaseBranch,
		"unpinned repos should resolve to main via auto-detect")
}
