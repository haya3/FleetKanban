package worktree

import (
	"context"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// initRepo creates a minimal git repository in dir with one commit on main.
func initRepo(t *testing.T, dir string) {
	t.Helper()
	ctx := t.Context()

	run := func(args ...string) {
		cmd := exec.CommandContext(ctx, "git", args...)
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
	require.NoError(t, os.WriteFile(filepath.Join(dir, "README.md"), []byte("# test\n"), 0o644))
	run("add", ".")
	run("commit", "-m", "initial")
}

func newManager(t *testing.T) *Manager {
	t.Helper()
	root := t.TempDir()
	m, err := NewManager(Options{FallbackRoot: filepath.Join(root, "worktrees")})
	require.NoError(t, err)
	return m
}

func TestManager_CreateAndRemove_KeepBranch(t *testing.T) {
	repo := filepath.Join(t.TempDir(), "repo")
	initRepo(t, repo)
	m := newManager(t)
	ctx := t.Context()

	taskID := "01J00000000000000000000001"
	c, err := m.Create(ctx, CreateInput{
		RepoPath: repo, TaskID: taskID, BaseBranch: "main",
	})
	require.NoError(t, err)
	assert.Equal(t, "fleetkanban/"+taskID, c.Branch)

	// Worktree dir must exist and contain the initial commit files.
	_, err = os.Stat(filepath.Join(c.Path, "README.md"))
	require.NoError(t, err)

	// Branch must be visible in the repo's branch list.
	exists, err := m.BranchExists(ctx, repo, "fleetkanban/"+taskID)
	require.NoError(t, err)
	assert.True(t, exists)

	// Remove with KeepBranch: dir gone, branch kept.
	require.NoError(t, m.Remove(ctx, repo, c.Path, taskID, KeepBranch))
	_, statErr := os.Stat(c.Path)
	assert.True(t, os.IsNotExist(statErr), "worktree dir must be gone")

	exists, err = m.BranchExists(ctx, repo, "fleetkanban/"+taskID)
	require.NoError(t, err)
	assert.True(t, exists, "branch must be preserved with KeepBranch")
}

func TestManager_CreateAndRemove_DeleteBranch(t *testing.T) {
	repo := filepath.Join(t.TempDir(), "repo")
	initRepo(t, repo)
	m := newManager(t)
	ctx := t.Context()

	taskID := "01J00000000000000000000002"
	c, err := m.Create(ctx, CreateInput{
		RepoPath: repo, TaskID: taskID, BaseBranch: "main",
	})
	require.NoError(t, err)

	require.NoError(t, m.Remove(ctx, repo, c.Path, taskID, DeleteBranch))

	exists, err := m.BranchExists(ctx, repo, "fleetkanban/"+taskID)
	require.NoError(t, err)
	assert.False(t, exists, "branch must be deleted with DeleteBranch")
}

func TestManager_Create_RejectsExistingPath(t *testing.T) {
	repo := filepath.Join(t.TempDir(), "repo")
	initRepo(t, repo)
	m := newManager(t)
	ctx := t.Context()

	taskID := "01J00000000000000000000003"
	_, err := m.Create(ctx, CreateInput{
		RepoPath: repo, TaskID: taskID, BaseBranch: "main",
	})
	require.NoError(t, err)

	// Second create for the same task ID collides.
	_, err = m.Create(ctx, CreateInput{
		RepoPath: repo, TaskID: taskID, BaseBranch: "main",
	})
	assert.Error(t, err)
}

func TestManager_Create_RejectsMissingBranch(t *testing.T) {
	repo := filepath.Join(t.TempDir(), "repo")
	initRepo(t, repo)
	m := newManager(t)
	ctx := t.Context()

	_, err := m.Create(ctx, CreateInput{
		RepoPath: repo, TaskID: "x", BaseBranch: "does-not-exist",
	})
	assert.Error(t, err)
}

func TestManager_List_IncludesTaskWorktrees(t *testing.T) {
	repo := filepath.Join(t.TempDir(), "repo")
	initRepo(t, repo)
	m := newManager(t)
	ctx := t.Context()

	a := "01J00000000000000000000A"
	b := "01J00000000000000000000B"
	_, err := m.Create(ctx, CreateInput{RepoPath: repo, TaskID: a, BaseBranch: "main"})
	require.NoError(t, err)
	_, err = m.Create(ctx, CreateInput{RepoPath: repo, TaskID: b, BaseBranch: "main"})
	require.NoError(t, err)

	list, err := m.List(ctx, repo)
	require.NoError(t, err)
	var taskIDs []string
	for _, info := range list {
		if info.IsTaskBranch() {
			taskIDs = append(taskIDs, info.TaskID())
		}
	}
	assert.ElementsMatch(t, []string{a, b}, taskIDs)
}

func TestManager_BranchExists_FalseWhenMissing(t *testing.T) {
	repo := filepath.Join(t.TempDir(), "repo")
	initRepo(t, repo)
	m := newManager(t)

	exists, err := m.BranchExists(t.Context(), repo, "nope")
	require.NoError(t, err)
	assert.False(t, exists)
}

func TestManager_CurrentBranch(t *testing.T) {
	repo := filepath.Join(t.TempDir(), "repo")
	initRepo(t, repo)
	m := newManager(t)

	b, err := m.CurrentBranch(t.Context(), repo)
	require.NoError(t, err)
	assert.Equal(t, "main", b)
}

func TestParseWorktreeList(t *testing.T) {
	// Sample output matching the porcelain format documented in git-worktree(1).
	raw := []byte(`worktree C:/repo
HEAD 0123456789abcdef0123456789abcdef01234567
branch refs/heads/main

worktree C:/wt/01J00
HEAD abcdefabcdefabcdefabcdefabcdefabcdefabcd
branch refs/heads/fleetkanban/01J00

worktree C:/detached
HEAD ffffffffffffffffffffffffffffffffffffffff
detached
`)
	list, err := parseWorktreeList(raw)
	require.NoError(t, err)
	require.Len(t, list, 3)

	assert.Equal(t, "C:/repo", list[0].Path)
	assert.Equal(t, "refs/heads/main", list[0].Branch)
	assert.False(t, list[0].IsTaskBranch())

	assert.True(t, list[1].IsTaskBranch())
	assert.Equal(t, "01J00", list[1].TaskID())

	assert.Empty(t, list[2].Branch, "detached worktree reports no branch")
}

func TestResolveRepo_CleansRelative(t *testing.T) {
	abs, err := resolveRepo(".")
	require.NoError(t, err)
	assert.True(t, filepath.IsAbs(abs))
}

func TestApplyLocalConfig(t *testing.T) {
	repo := filepath.Join(t.TempDir(), "repo")
	initRepo(t, repo)
	m := newManager(t)
	ctx := t.Context()

	c, err := m.Create(ctx, CreateInput{
		RepoPath: repo, TaskID: "cfg", BaseBranch: "main",
	})
	require.NoError(t, err)

	// Verify one of the keys was applied to the worktree's local config.
	cmd := exec.CommandContext(ctx, "git", "config", "--local", "--get", "core.autocrlf")
	cmd.Dir = c.Path
	out, err := cmd.Output()
	require.NoError(t, err)
	assert.Equal(t, "false", strings.TrimSpace(string(out)))

	// gc.auto must be 0 to avoid background GC holding worktree files open.
	cmd = exec.CommandContext(ctx, "git", "config", "--local", "--get", "gc.auto")
	cmd.Dir = c.Path
	out, err = cmd.Output()
	require.NoError(t, err)
	assert.Equal(t, "0", strings.TrimSpace(string(out)))
}

func TestResolveDefaultBranch_PrefersOriginHEAD(t *testing.T) {
	// Simulate a clone: the worktree has `origin/HEAD → origin/trunk` even
	// though the local default happens to also be `main`. Auto-detect should
	// prefer the upstream-declared branch over the local convention.
	repo := filepath.Join(t.TempDir(), "repo")
	initRepo(t, repo)
	ctx := t.Context()
	run := func(args ...string) {
		cmd := exec.CommandContext(ctx, "git", args...)
		cmd.Dir = repo
		out, err := cmd.CombinedOutput()
		if err != nil {
			t.Fatalf("git %s: %v\n%s", strings.Join(args, " "), err, out)
		}
	}
	// Create a `trunk` branch and wire up a fake "origin" whose HEAD points
	// at it. git doesn't require origin to be reachable for symbolic-ref to
	// report it, which keeps this test hermetic.
	run("branch", "trunk")
	run("update-ref", "refs/remotes/origin/trunk", "refs/heads/trunk")
	run("symbolic-ref", "refs/remotes/origin/HEAD", "refs/remotes/origin/trunk")

	m := newManager(t)
	br, err := m.ResolveDefaultBranch(ctx, repo)
	require.NoError(t, err)
	assert.Equal(t, "trunk", br)
}

func TestResolveDefaultBranch_FallsBackToMain(t *testing.T) {
	// No origin configured, HEAD is main. Picks main.
	repo := filepath.Join(t.TempDir(), "repo")
	initRepo(t, repo)

	m := newManager(t)
	br, err := m.ResolveDefaultBranch(t.Context(), repo)
	require.NoError(t, err)
	assert.Equal(t, "main", br)
}

func TestResolveDefaultBranch_FallsBackToMaster(t *testing.T) {
	// Repo whose HEAD branch is `master`; no main, no origin. Picks master.
	repo := filepath.Join(t.TempDir(), "repo")
	ctx := t.Context()
	run := func(args ...string) {
		cmd := exec.CommandContext(ctx, "git", args...)
		cmd.Dir = repo
		out, err := cmd.CombinedOutput()
		if err != nil {
			t.Fatalf("git %s: %v\n%s", strings.Join(args, " "), err, out)
		}
	}
	require.NoError(t, os.MkdirAll(repo, 0o755))
	run("init", "-b", "master")
	run("config", "user.email", "test@example.com")
	run("config", "user.name", "Test")
	require.NoError(t, os.WriteFile(filepath.Join(repo, "README.md"), []byte("# master\n"), 0o644))
	run("add", ".")
	run("commit", "-m", "initial")

	m := newManager(t)
	br, err := m.ResolveDefaultBranch(ctx, repo)
	require.NoError(t, err)
	assert.Equal(t, "master", br)
}

func TestHasCommits(t *testing.T) {
	// Populated repo → HasCommits returns true.
	populated := filepath.Join(t.TempDir(), "repo")
	initRepo(t, populated)
	m := newManager(t)
	ctx := t.Context()

	has, err := m.HasCommits(ctx, populated)
	require.NoError(t, err)
	assert.True(t, has, "HasCommits should be true for repo with initial commit")

	// Freshly `git init`'d repo (no commits) → HasCommits returns false,
	// not an error. This is the whole reason HasCommits exists: it is the
	// precondition the Settings UI uses to decide whether to show the
	// "Create initial commit" action.
	empty := filepath.Join(t.TempDir(), "empty")
	require.NoError(t, os.MkdirAll(empty, 0o755))
	cmd := exec.CommandContext(ctx, "git", "init", "-b", "main")
	cmd.Dir = empty
	out, err := cmd.CombinedOutput()
	require.NoError(t, err, string(out))

	has, err = m.HasCommits(ctx, empty)
	require.NoError(t, err)
	assert.False(t, has, "HasCommits should be false for unborn HEAD")
}

func TestCreateInitialCommit_SeedsUnbornRepo(t *testing.T) {
	// Freshly-init'd repo: CreateInitialCommit should land a single empty
	// commit on main, flipping HasCommits to true and letting
	// ResolveDefaultBranch return "main" without the caller setting
	// global user.name / user.email first.
	repo := filepath.Join(t.TempDir(), "repo")
	ctx := t.Context()
	require.NoError(t, os.MkdirAll(repo, 0o755))
	cmd := exec.CommandContext(ctx, "git", "init", "-b", "main")
	cmd.Dir = repo
	out, err := cmd.CombinedOutput()
	require.NoError(t, err, string(out))

	m := newManager(t)
	require.NoError(t, m.CreateInitialCommit(ctx, repo))

	has, err := m.HasCommits(ctx, repo)
	require.NoError(t, err)
	assert.True(t, has)

	br, err := m.ResolveDefaultBranch(ctx, repo)
	require.NoError(t, err)
	assert.Equal(t, "main", br)

	// Author should be the hardcoded FleetKanban identity so the commit
	// succeeds without global git config. Verify via `git log -1 --format`.
	logCmd := exec.CommandContext(ctx, "git", "log", "-1", "--format=%an <%ae>")
	logCmd.Dir = repo
	logOut, err := logCmd.Output()
	require.NoError(t, err)
	assert.Contains(t, strings.TrimSpace(string(logOut)), "FleetKanban")
}

func TestCreateInitialCommit_RejectsPopulatedRepo(t *testing.T) {
	// Repo already has commits → CreateInitialCommit refuses rather than
	// silently adding a second empty commit. The app layer translates this
	// into FailedPrecondition so a stale UI button becomes a no-op with a
	// refresh nudge, not an accidental commit.
	repo := filepath.Join(t.TempDir(), "repo")
	initRepo(t, repo)

	m := newManager(t)
	err := m.CreateInitialCommit(t.Context(), repo)
	require.Error(t, err)
	assert.Contains(t, err.Error(), "already has commits")
}

func TestResolveDefaultBranch_UnbornHEAD(t *testing.T) {
	// Freshly-init'd repo with no commits yet: no branches exist, HEAD is
	// unborn. Auto-detect should surface ErrNoDefaultBranch so the caller
	// can tell the user the repo isn't ready to host a task.
	repo := filepath.Join(t.TempDir(), "repo")
	ctx := t.Context()
	require.NoError(t, os.MkdirAll(repo, 0o755))
	cmd := exec.CommandContext(ctx, "git", "init", "-b", "main")
	cmd.Dir = repo
	out, err := cmd.CombinedOutput()
	require.NoError(t, err, string(out))

	m := newManager(t)
	_, err = m.ResolveDefaultBranch(ctx, repo)
	require.Error(t, err)
	assert.ErrorIs(t, err, ErrNoDefaultBranch)
}

func TestListBranches_ReturnsAllLocalBranches(t *testing.T) {
	repo := filepath.Join(t.TempDir(), "repo")
	initRepo(t, repo)
	ctx := t.Context()
	run := func(args ...string) {
		cmd := exec.CommandContext(ctx, "git", args...)
		cmd.Dir = repo
		out, err := cmd.CombinedOutput()
		if err != nil {
			t.Fatalf("git %s: %v\n%s", strings.Join(args, " "), err, out)
		}
	}
	run("branch", "develop")
	run("branch", "feature/a")
	run("branch", "fleetkanban/abc123")

	m := newManager(t)
	got, err := m.ListBranches(ctx, repo)
	require.NoError(t, err)
	// All four branches are returned raw — filtering of fleetkanban/* is the
	// app layer's responsibility, not worktree's.
	assert.ElementsMatch(t, []string{"main", "develop", "feature/a", "fleetkanban/abc123"}, got)
}

func TestIsBranchMerged_TrueWhenAtSameCommit(t *testing.T) {
	// A freshly-created task branch points at main's tip, so it's trivially
	// merged (every commit reachable from the branch is also reachable from
	// main).
	repo := filepath.Join(t.TempDir(), "repo")
	initRepo(t, repo)
	m := newManager(t)
	ctx := t.Context()

	taskID := "01MERGED000000000000000001"
	_, err := m.Create(ctx, CreateInput{
		RepoPath: repo, TaskID: taskID, BaseBranch: "main",
	})
	require.NoError(t, err)

	ok, err := m.IsBranchMerged(ctx, repo, "fleetkanban/"+taskID, "main")
	require.NoError(t, err)
	assert.True(t, ok)
}

func TestIsBranchMerged_FalseWhenAhead(t *testing.T) {
	repo := filepath.Join(t.TempDir(), "repo")
	initRepo(t, repo)
	m := newManager(t)
	ctx := t.Context()

	taskID := "01MERGED000000000000000002"
	c, err := m.Create(ctx, CreateInput{
		RepoPath: repo, TaskID: taskID, BaseBranch: "main",
	})
	require.NoError(t, err)

	// Add a commit in the task worktree so the branch is ahead of main.
	run := func(dir string, args ...string) {
		t.Helper()
		cmd := exec.CommandContext(ctx, "git", args...)
		cmd.Dir = dir
		out, rerr := cmd.CombinedOutput()
		if rerr != nil {
			t.Fatalf("git %s: %v\n%s", strings.Join(args, " "), rerr, out)
		}
	}
	require.NoError(t, os.WriteFile(filepath.Join(c.Path, "new.txt"), []byte("x"), 0o644))
	run(c.Path, "add", ".")
	run(c.Path, "commit", "-m", "ahead")

	ok, err := m.IsBranchMerged(ctx, repo, c.Branch, "main")
	require.NoError(t, err)
	assert.False(t, ok, "branch ahead of main must not be reported as merged")
}

func TestDeleteBranchIfMerged_SucceedsAtSameCommit(t *testing.T) {
	repo := filepath.Join(t.TempDir(), "repo")
	initRepo(t, repo)
	m := newManager(t)
	ctx := t.Context()

	taskID := "01DELETE000000000000000001"
	c, err := m.Create(ctx, CreateInput{
		RepoPath: repo, TaskID: taskID, BaseBranch: "main",
	})
	require.NoError(t, err)
	// The worktree dir holds a checkout of the branch; git refuses to delete
	// a branch that is checked out anywhere. Remove the worktree dir first.
	require.NoError(t, m.Remove(ctx, repo, c.Path, taskID, KeepBranch))

	deleted, err := m.DeleteBranchIfMerged(ctx, repo, c.Branch)
	require.NoError(t, err)
	assert.True(t, deleted)

	exists, err := m.BranchExists(ctx, repo, c.Branch)
	require.NoError(t, err)
	assert.False(t, exists)
}

func TestDeleteBranchIfMerged_RefusesAhead(t *testing.T) {
	// Even though the caller is expected to have verified merged-ness first,
	// `git branch -d` provides redundant safety. This test exercises that
	// secondary check in isolation.
	repo := filepath.Join(t.TempDir(), "repo")
	initRepo(t, repo)
	m := newManager(t)
	ctx := t.Context()

	taskID := "01DELETE000000000000000002"
	c, err := m.Create(ctx, CreateInput{
		RepoPath: repo, TaskID: taskID, BaseBranch: "main",
	})
	require.NoError(t, err)

	run := func(dir string, args ...string) {
		t.Helper()
		cmd := exec.CommandContext(ctx, "git", args...)
		cmd.Dir = dir
		out, rerr := cmd.CombinedOutput()
		if rerr != nil {
			t.Fatalf("git %s: %v\n%s", strings.Join(args, " "), rerr, out)
		}
	}
	require.NoError(t, os.WriteFile(filepath.Join(c.Path, "ahead.txt"), []byte("x"), 0o644))
	run(c.Path, "add", ".")
	run(c.Path, "commit", "-m", "ahead")
	require.NoError(t, m.Remove(ctx, repo, c.Path, taskID, KeepBranch))

	deleted, err := m.DeleteBranchIfMerged(ctx, repo, c.Branch)
	require.NoError(t, err, "git refusal must not bubble up as an error")
	assert.False(t, deleted, "unmerged branch must not be deleted")

	exists, err := m.BranchExists(ctx, repo, c.Branch)
	require.NoError(t, err)
	assert.True(t, exists, "branch must survive the refused -d")
}

func TestDeleteBranch_ForceDeletesEvenWhenAhead(t *testing.T) {
	// Unlike DeleteBranchIfMerged, DeleteBranch must succeed on unmerged
	// branches — the user has explicitly chosen to discard the work.
	repo := filepath.Join(t.TempDir(), "repo")
	initRepo(t, repo)
	m := newManager(t)
	ctx := t.Context()

	taskID := "01FORCE0000000000000000001"
	c, err := m.Create(ctx, CreateInput{
		RepoPath: repo, TaskID: taskID, BaseBranch: "main",
	})
	require.NoError(t, err)

	run := func(dir string, args ...string) {
		t.Helper()
		cmd := exec.CommandContext(ctx, "git", args...)
		cmd.Dir = dir
		out, rerr := cmd.CombinedOutput()
		if rerr != nil {
			t.Fatalf("git %s: %v\n%s", strings.Join(args, " "), rerr, out)
		}
	}
	require.NoError(t, os.WriteFile(filepath.Join(c.Path, "ahead.txt"), []byte("x"), 0o644))
	run(c.Path, "add", ".")
	run(c.Path, "commit", "-m", "ahead")
	require.NoError(t, m.Remove(ctx, repo, c.Path, taskID, KeepBranch))

	require.NoError(t, m.DeleteBranch(ctx, repo, c.Branch))

	exists, err := m.BranchExists(ctx, repo, c.Branch)
	require.NoError(t, err)
	assert.False(t, exists, "unmerged branch must be force-deleted by DeleteBranch")
}

func TestDeleteBranch_MissingBranchTreatedAsSuccess(t *testing.T) {
	repo := filepath.Join(t.TempDir(), "repo")
	initRepo(t, repo)
	m := newManager(t)

	// Branch was never created → git returns "not found" → helper swallows it.
	require.NoError(t, m.DeleteBranch(t.Context(), repo, "fleetkanban/never-was"))
}

// When the worktree directory has been removed (e.g. after Finalize Keep
// cleared the checkout but preserved the branch), Diff must return
// ErrWorktreeMissing so callers can fall back to DiffBranch instead of
// surfacing a raw chdir error from git.
func TestManager_Diff_ReturnsErrWorktreeMissing(t *testing.T) {
	repo := filepath.Join(t.TempDir(), "repo")
	initRepo(t, repo)
	m := newManager(t)
	ctx := t.Context()

	taskID := "01J0000000000000000000DIFF"
	c, err := m.Create(ctx, CreateInput{RepoPath: repo, TaskID: taskID, BaseBranch: "main"})
	require.NoError(t, err)
	require.NoError(t, m.Remove(ctx, repo, c.Path, taskID, KeepBranch))

	_, err = m.Diff(ctx, c.Path, "main")
	require.Error(t, err)
	assert.ErrorIs(t, err, ErrWorktreeMissing)
}

// DiffBranch runs from the main repository and must still produce a
// unified diff after the task's worktree has been removed (KeepBranch
// path). This is the fallback that lets completed tasks' Files pane keep
// working.
func TestManager_DiffBranch_WorksAfterWorktreeRemoved(t *testing.T) {
	repo := filepath.Join(t.TempDir(), "repo")
	initRepo(t, repo)
	m := newManager(t)
	ctx := t.Context()

	taskID := "01J00000000000000000000DBR"
	c, err := m.Create(ctx, CreateInput{RepoPath: repo, TaskID: taskID, BaseBranch: "main"})
	require.NoError(t, err)

	// Commit a change on the task branch inside the worktree so there is
	// something to diff against main.
	require.NoError(t, os.WriteFile(filepath.Join(c.Path, "added.txt"), []byte("hello\n"), 0o644))
	runInDir := func(dir string, args ...string) {
		cmd := exec.CommandContext(ctx, "git", args...)
		cmd.Dir = dir
		out, cerr := cmd.CombinedOutput()
		require.NoError(t, cerr, string(out))
	}
	runInDir(c.Path, "add", ".")
	runInDir(c.Path, "-c", "user.email=t@x", "-c", "user.name=T", "commit", "-m", "add")

	// Simulate Finalize Keep: worktree dir removed, branch preserved.
	require.NoError(t, m.Remove(ctx, repo, c.Path, taskID, KeepBranch))

	diff, err := m.DiffBranch(ctx, repo, "main", c.Branch)
	require.NoError(t, err)
	assert.Contains(t, diff, "added.txt")
	assert.Contains(t, diff, "+hello")
}

// Keep the context import used if future tests drop t.Context().
var _ = context.Background
