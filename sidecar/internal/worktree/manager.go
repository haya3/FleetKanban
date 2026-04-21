// Package worktree wraps "git worktree" for FleetKanban's task isolation.
//
// Every task runs inside its own worktree. The primary placement is a sibling
// directory of the target repository:
//
//	<repo-parent>\.fleetkanban-worktrees\<task-id>\
//
// Sibling placement keeps the worktree on the same drive as the repo (better
// git performance, no cross-volume hardlink issues) and makes the worktree
// discoverable in Explorer. When the repo parent is not writable (e.g. the
// repo lives under `C:\Program Files\...`), the Manager falls back to a
// per-repo subdirectory under FallbackRoot:
//
//	<FallbackRoot>\<repo-hash>\<task-id>\
//
// FallbackRoot is typically %APPDATA%\FleetKanban\worktrees\. The per-repo
// hash avoids collisions when the same task id happens to exist in different
// repos (ULIDs make that unlikely, but the layout stays unambiguous).
//
// Branch naming is deterministic: every task's work branch is
// fleetkanban/<task-id>. Branches for completed/aborted tasks are intentionally
// retained so the user can pick them up in a shell or another tool; Phase 1
// never pushes, so the lifetime is entirely local.
//
// Create/Remove against the same repository are serialized through a
// per-repository mutex. This is cheaper than locking the file system (the
// spec's original intent is just to avoid overlapping `git worktree add`
// calls against one repo — cross-repo operations are fine to parallelize).
package worktree

import (
	"bufio"
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"sync"

	"github.com/haya3/fleetkanban/internal/branding"
)

// BranchPrefix is the fixed namespace under which task branches are created.
// The value is defined in internal/branding and aliased here for backwards
// compatibility with callers that reference worktree.BranchPrefix.
const BranchPrefix = branding.BranchPrefix

// SiblingDirName is the directory created next to the target repository to
// hold per-task worktrees when sibling placement is available.
const SiblingDirName = ".fleetkanban-worktrees"

// Manager creates, removes, and inspects task worktrees.
type Manager struct {
	fallbackRoot string
	gitBin       string

	mmu sync.Mutex
	mu  map[string]*sync.Mutex // key: absolute repo path (lowercase)
}

// Options configures NewManager.
type Options struct {
	// FallbackRoot is the directory used when the target repository's parent
	// is not writable and sibling placement is unavailable. Required; must
	// already exist or be creatable.
	FallbackRoot string
	// GitBin is the path to the git executable. Defaults to "git" on PATH.
	GitBin string
}

// NewManager constructs a Manager with the given fallback root. The fallback
// directory is created (and its parents) if missing.
func NewManager(opts Options) (*Manager, error) {
	if opts.FallbackRoot == "" {
		return nil, errors.New("worktree: FallbackRoot is required")
	}
	if err := os.MkdirAll(opts.FallbackRoot, 0o755); err != nil {
		return nil, fmt.Errorf("worktree: create fallback root %q: %w", opts.FallbackRoot, err)
	}
	bin := opts.GitBin
	if bin == "" {
		bin = "git"
	}
	return &Manager{
		fallbackRoot: opts.FallbackRoot,
		gitBin:       bin,
		mu:           make(map[string]*sync.Mutex),
	}, nil
}

// CreateInput describes a new worktree to materialize.
type CreateInput struct {
	// RepoPath is the absolute path to the source repository (the one that
	// owns the base branch).
	RepoPath string
	// TaskID is the task identifier; worktree dir and branch both include it.
	TaskID string
	// BaseBranch is the branch to fork from. Required; the caller is
	// responsible for validating that the branch exists.
	BaseBranch string
}

// Created describes a materialized worktree.
type Created struct {
	Path   string // absolute
	Branch string // e.g. fleetkanban/01J...
}

// Create runs `git worktree add` under the per-repo mutex. On failure, any
// partially-created files are cleaned up so the task can be retried.
func (m *Manager) Create(ctx context.Context, in CreateInput) (*Created, error) {
	if in.RepoPath == "" || in.TaskID == "" || in.BaseBranch == "" {
		return nil, errors.New("worktree: RepoPath, TaskID, BaseBranch are required")
	}
	repoAbs, err := resolveRepo(in.RepoPath)
	if err != nil {
		return nil, err
	}
	branch := BranchPrefix + in.TaskID
	root, err := m.rootFor(repoAbs)
	if err != nil {
		return nil, err
	}
	wt := filepath.Join(root, in.TaskID)

	if _, err := os.Stat(wt); err == nil {
		return nil, fmt.Errorf("worktree: path already exists: %s", wt)
	}

	unlock := m.lockRepo(repoAbs)
	defer unlock()

	if _, err := runGit(ctx, m.gitBin, repoAbs,
		"worktree", "add", wt, "-b", branch, in.BaseBranch); err != nil {
		// Clean up the empty directory git may have left behind.
		_ = os.RemoveAll(wt)
		return nil, fmt.Errorf("worktree: git worktree add: %w", err)
	}

	if err := applyLocalConfig(ctx, m.gitBin, wt); err != nil {
		// Config failure doesn't invalidate the worktree, but surface it.
		return &Created{Path: wt, Branch: branch},
			fmt.Errorf("worktree: created, but git config failed: %w", err)
	}
	return &Created{Path: wt, Branch: branch}, nil
}

// RemoveMode controls whether Remove deletes the task branch alongside the
// worktree directory.
type RemoveMode int

const (
	// KeepBranch removes the worktree directory but preserves the branch.
	// This is the default "Keep" post-processing action.
	KeepBranch RemoveMode = iota
	// DeleteBranch removes both the worktree and the fleetkanban/<id> branch.
	// Used for the "Discard" action.
	DeleteBranch
)

// Remove deletes the worktree at wtPath. When mode == DeleteBranch, the
// fleetkanban/<taskID> branch is also deleted from the owning repository.
func (m *Manager) Remove(ctx context.Context, repoPath, wtPath, taskID string, mode RemoveMode) error {
	if repoPath == "" || wtPath == "" || taskID == "" {
		return errors.New("worktree: RepoPath, WtPath, TaskID are required")
	}
	repoAbs, err := resolveRepo(repoPath)
	if err != nil {
		return err
	}
	branch := BranchPrefix + taskID

	unlock := m.lockRepo(repoAbs)
	defer unlock()

	// "--force" also removes worktrees that have uncommitted changes. Phase 1
	// treats worktree contents as disposable at this point: the user has
	// either accepted the diff (Merge / Keep) or chosen to drop it (Discard).
	if _, err := runGit(ctx, m.gitBin, repoAbs,
		"worktree", "remove", "--force", wtPath); err != nil {
		// Fall back to filesystem removal + prune. This path is hit when the
		// worktree metadata is corrupt or was removed externally.
		if rmErr := os.RemoveAll(wtPath); rmErr != nil && !os.IsNotExist(rmErr) {
			return fmt.Errorf("worktree: git remove and RemoveAll both failed: %v / %w", err, rmErr)
		}
		if _, pruneErr := runGit(ctx, m.gitBin, repoAbs, "worktree", "prune"); pruneErr != nil {
			return fmt.Errorf("worktree: prune after fallback removal: %w", pruneErr)
		}
	}

	if mode == DeleteBranch {
		if _, err := runGit(ctx, m.gitBin, repoAbs, "branch", "-D", branch); err != nil {
			// Missing branch is not a hard error — the caller wanted it gone.
			if !strings.Contains(err.Error(), "not found") &&
				!strings.Contains(err.Error(), "error: branch") {
				return fmt.Errorf("worktree: delete branch %s: %w", branch, err)
			}
		}
	}
	return nil
}

// Info is one record from "git worktree list --porcelain".
type Info struct {
	Path   string
	HEAD   string
	Branch string // full refname (e.g. refs/heads/fleetkanban/01J…). Empty on detached.
}

// IsTaskBranch reports whether this worktree's branch is under BranchPrefix.
func (i Info) IsTaskBranch() bool {
	return strings.HasPrefix(i.Branch, "refs/heads/"+BranchPrefix)
}

// TaskID returns the ULID portion of a fleetkanban/ branch, or "" for other
// worktrees.
func (i Info) TaskID() string {
	const p = "refs/heads/" + BranchPrefix
	if !strings.HasPrefix(i.Branch, p) {
		return ""
	}
	return strings.TrimPrefix(i.Branch, p)
}

// List returns all worktrees registered with the repository. Includes the
// primary worktree (the repo itself).
func (m *Manager) List(ctx context.Context, repoPath string) ([]Info, error) {
	repoAbs, err := resolveRepo(repoPath)
	if err != nil {
		return nil, err
	}
	out, err := runGit(ctx, m.gitBin, repoAbs, "worktree", "list", "--porcelain")
	if err != nil {
		return nil, fmt.Errorf("worktree: list: %w", err)
	}
	return parseWorktreeList(out)
}

// IsBranchMerged reports whether branch's tip is an ancestor of base, i.e.
// every commit on branch is already reachable from base. Both arguments are
// short names (no refs/heads/ prefix).
//
// Uses `git merge-base --is-ancestor` which exits 0 for yes, 1 for no, and
// greater for unexpected errors. A nonexistent branch surfaces as a git
// error; callers should filter by BranchExists first if they want to
// distinguish "not merged" from "not present".
func (m *Manager) IsBranchMerged(ctx context.Context, repoPath, branch, base string) (bool, error) {
	if branch == "" || base == "" {
		return false, errors.New("worktree: branch and base are required")
	}
	repoAbs, err := resolveRepo(repoPath)
	if err != nil {
		return false, err
	}
	_, err = runGit(ctx, m.gitBin, repoAbs,
		"merge-base", "--is-ancestor",
		"refs/heads/"+branch, "refs/heads/"+base)
	if err == nil {
		return true, nil
	}
	var exitErr *exec.ExitError
	if errors.As(err, &exitErr) && exitErr.ExitCode() == 1 {
		return false, nil
	}
	return false, fmt.Errorf("worktree: is-ancestor %s..%s: %w", base, branch, err)
}

// DeleteBranch force-removes branch from repo using `git branch -D`. Unlike
// DeleteBranchIfMerged, this does not verify merged-ness — callers have
// explicitly asked to wipe the branch (typically the Housekeeping UI's
// "Discard" action after the user confirmed the intent). Unmerged work on
// the branch will be lost.
//
// Missing branches are treated as success so the caller doesn't have to
// race the reaper's UpdateBranchExistence pass.
func (m *Manager) DeleteBranch(ctx context.Context, repoPath, branch string) error {
	if branch == "" {
		return errors.New("worktree: branch is required")
	}
	repoAbs, err := resolveRepo(repoPath)
	if err != nil {
		return err
	}
	unlock := m.lockRepo(repoAbs)
	defer unlock()
	if _, err := runGit(ctx, m.gitBin, repoAbs, "branch", "-D", branch); err != nil {
		// Branch already gone → treat as success. Matches Remove()'s
		// tolerance of external branch deletion.
		if strings.Contains(err.Error(), "not found") ||
			strings.Contains(err.Error(), "error: branch") {
			return nil
		}
		return fmt.Errorf("worktree: branch -D %s: %w", branch, err)
	}
	return nil
}

// DeleteBranchIfMerged asks git to delete branch using `git branch -d` (the
// fast-forward-required form). It is intentionally scoped narrowly — callers
// must have verified merged-ness via IsBranchMerged first; this method does
// not force and does not fall back to `-D`. That makes git's own check a
// redundant safety net (phase1-spec §3.1).
//
// Return values:
//
//	(true, nil)   branch was deleted
//	(false, nil)  git refused (not merged to HEAD, locked, or absent); caller
//	              should treat as "leave for next pass"
//	(false, err)  unexpected failure
func (m *Manager) DeleteBranchIfMerged(ctx context.Context, repoPath, branch string) (bool, error) {
	if branch == "" {
		return false, errors.New("worktree: branch is required")
	}
	repoAbs, err := resolveRepo(repoPath)
	if err != nil {
		return false, err
	}
	unlock := m.lockRepo(repoAbs)
	defer unlock()
	if _, err := runGit(ctx, m.gitBin, repoAbs, "branch", "-d", branch); err != nil {
		var exitErr *exec.ExitError
		if errors.As(err, &exitErr) && exitErr.ExitCode() == 1 {
			return false, nil
		}
		return false, fmt.Errorf("worktree: branch -d %s: %w", branch, err)
	}
	return true, nil
}

// BranchExists reports whether a given branch name is present in the repo.
// The branch argument is the short name (no refs/heads/ prefix).
func (m *Manager) BranchExists(ctx context.Context, repoPath, branch string) (bool, error) {
	repoAbs, err := resolveRepo(repoPath)
	if err != nil {
		return false, err
	}
	_, err = runGit(ctx, m.gitBin, repoAbs,
		"show-ref", "--verify", "--quiet", "refs/heads/"+branch)
	if err == nil {
		return true, nil
	}
	var exitErr *exec.ExitError
	if errors.As(err, &exitErr) && exitErr.ExitCode() == 1 {
		return false, nil
	}
	return false, err
}

// ErrNoDefaultBranch is returned by ResolveDefaultBranch when none of the
// fallback candidates (origin/HEAD, local main, local master, current HEAD)
// resolves to a branch. Typically hit on a freshly-initialized repo with
// no commits where HEAD is still unborn.
var ErrNoDefaultBranch = errors.New("worktree: repository has no resolvable default branch")

// ListBranches returns every short branch name under refs/heads/ in the
// given repository. The order matches `git for-each-ref --sort=-committerdate`
// (most-recently-committed first) so the UI can surface active branches at
// the top. Callers interested only in human-pickable base branches should
// filter internal branches (e.g. FleetKanban's `fleetkanban/*`) themselves.
func (m *Manager) ListBranches(ctx context.Context, repoPath string) ([]string, error) {
	repoAbs, err := resolveRepo(repoPath)
	if err != nil {
		return nil, err
	}
	out, err := runGit(ctx, m.gitBin, repoAbs,
		"for-each-ref", "--sort=-committerdate",
		"--format=%(refname:short)", "refs/heads/")
	if err != nil {
		return nil, fmt.Errorf("worktree: list branches: %w", err)
	}
	lines := strings.Split(strings.TrimRight(string(out), "\n"), "\n")
	branches := make([]string, 0, len(lines))
	for _, b := range lines {
		if b = strings.TrimSpace(b); b != "" {
			branches = append(branches, b)
		}
	}
	return branches, nil
}

// ResolveDefaultBranch picks the branch a task should fork from when the
// caller has not specified one and the repository is not user-pinned.
//
// The fallback order matches common mental models on Windows:
//
//  1. `refs/remotes/origin/HEAD` — the upstream-declared default, honored
//     for repositories cloned from a remote. Most modern clones set this
//     at clone time; user-initialized local repos typically don't.
//  2. Local `main`    — the Git 2.28+ default, also what Init() configures.
//  3. Local `master`  — legacy default still used by older local repos.
//  4. `symbolic-ref HEAD` (current branch). Catches non-standard names
//     like `trunk` or branch-per-developer setups.
//
// Returns ErrNoDefaultBranch only when all four fail (unborn HEAD on an
// empty repo). Callers should surface this to the user rather than auto-
// creating a branch — empty repos can't meaningfully host a task yet.
func (m *Manager) ResolveDefaultBranch(ctx context.Context, repoPath string) (string, error) {
	repoAbs, err := resolveRepo(repoPath)
	if err != nil {
		return "", err
	}
	// (1) origin/HEAD — silently skipped when not configured.
	out, err := runGit(ctx, m.gitBin, repoAbs,
		"symbolic-ref", "--quiet", "--short", "refs/remotes/origin/HEAD")
	if err == nil {
		ref := strings.TrimSpace(string(out))
		if name := strings.TrimPrefix(ref, "origin/"); name != "" && name != ref {
			return name, nil
		}
	}
	// (2) and (3) — well-known local defaults.
	for _, cand := range []string{"main", "master"} {
		ok, err := m.BranchExists(ctx, repoAbs, cand)
		if err != nil {
			return "", fmt.Errorf("worktree: probe %s: %w", cand, err)
		}
		if ok {
			return cand, nil
		}
	}
	// (4) HEAD — may be detached ("" from CurrentBranch) or unborn (a
	// branch name is returned but the ref doesn't exist yet because there
	// are no commits). Verify existence before returning so the caller
	// doesn't go on to `git worktree add -b new <nonexistent>`.
	cur, err := m.CurrentBranch(ctx, repoAbs)
	if err != nil {
		return "", err
	}
	if cur == "" {
		return "", ErrNoDefaultBranch
	}
	ok, err := m.BranchExists(ctx, repoAbs, cur)
	if err != nil {
		return "", fmt.Errorf("worktree: probe HEAD %s: %w", cur, err)
	}
	if !ok {
		return "", ErrNoDefaultBranch
	}
	return cur, nil
}

// GlobalConfigStatus reports whether the global git knobs FleetKanban
// depends on are set to the expected values (see phase1-spec §9.1):
//
//   - core.longpaths    must be "true"   (Windows MAX_PATH workaround)
//   - core.autocrlf     must be "false"  (avoid spurious CRLF churn)
//
// Unset values are treated as "not OK" with Value == "".
type GlobalConfigStatus struct {
	LongPathsOK  bool
	LongPathsVal string
	AutoCRLFOK   bool
	AutoCRLFVal  string
}

// OK reports whether all checked knobs are set to the required values.
func (s GlobalConfigStatus) OK() bool { return s.LongPathsOK && s.AutoCRLFOK }

// CheckGlobalConfig inspects the user's global git configuration for the
// knobs FleetKanban requires. Unset values return "" + OK=false. Callers
// typically surface a warning to the user at startup.
func (m *Manager) CheckGlobalConfig(ctx context.Context) (GlobalConfigStatus, error) {
	longpaths, err := getGlobalConfig(ctx, m.gitBin, "core.longpaths")
	if err != nil {
		return GlobalConfigStatus{}, err
	}
	autocrlf, err := getGlobalConfig(ctx, m.gitBin, "core.autocrlf")
	if err != nil {
		return GlobalConfigStatus{}, err
	}
	return GlobalConfigStatus{
		LongPathsOK:  strings.EqualFold(longpaths, "true"),
		LongPathsVal: longpaths,
		AutoCRLFOK:   strings.EqualFold(autocrlf, "false"),
		AutoCRLFVal:  autocrlf,
	}, nil
}

// getGlobalConfig returns the global value for key, or "" if unset.
// `git config --global --get` exits 1 when the key is absent; we map that
// to an empty string rather than propagating it as an error.
func getGlobalConfig(ctx context.Context, gitBin, key string) (string, error) {
	cmd := exec.CommandContext(ctx, gitBin, "config", "--global", "--get", key)
	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr
	if err := cmd.Run(); err != nil {
		var exitErr *exec.ExitError
		if errors.As(err, &exitErr) && exitErr.ExitCode() == 1 {
			return "", nil
		}
		return "", fmt.Errorf("git config --global --get %s: %w: %s",
			key, err, strings.TrimSpace(stderr.String()))
	}
	return strings.TrimSpace(stdout.String()), nil
}

// IsGitRepo reports whether repoPath is the working tree of a git
// repository. A directory that does not exist, or exists but is not a git
// worktree, returns (false, nil) — errors are reserved for genuine I/O
// problems.
func (m *Manager) IsGitRepo(ctx context.Context, repoPath string) (bool, error) {
	repoAbs, err := resolveRepo(repoPath)
	if err != nil {
		return false, err
	}
	if _, err := os.Stat(repoAbs); err != nil {
		if os.IsNotExist(err) {
			return false, nil
		}
		return false, err
	}
	_, err = runGit(ctx, m.gitBin, repoAbs,
		"rev-parse", "--is-inside-work-tree")
	if err != nil {
		var exitErr *exec.ExitError
		if errors.As(err, &exitErr) {
			return false, nil
		}
		return false, err
	}
	return true, nil
}

// Init runs `git init` (with `--initial-branch=main` where supported) so a
// plain directory can be upgraded to a git repo inline. The caller is
// responsible for any post-init housekeeping such as creating an initial
// commit — Init returns as soon as git reports success.
func (m *Manager) Init(ctx context.Context, repoPath string) error {
	if repoPath == "" {
		return errors.New("worktree: Init requires a path")
	}
	repoAbs, err := resolveRepo(repoPath)
	if err != nil {
		return err
	}
	if err := os.MkdirAll(repoAbs, 0o755); err != nil {
		return fmt.Errorf("worktree: create init target: %w", err)
	}
	// --initial-branch is Git 2.28+; every supported Windows install (spec
	// calls out 2.45+) honours it. The flag avoids the user seeing the
	// "master → main default" warning.
	if _, err := runGit(ctx, m.gitBin, repoAbs,
		"init", "--initial-branch=main"); err != nil {
		return fmt.Errorf("worktree: git init: %w", err)
	}
	return nil
}

// HasCommits reports whether repoPath has at least one commit reachable
// from HEAD. Returns (false, nil) for unborn HEAD (freshly-initialized
// repositories) — that is a legitimate state for a registered repo, not
// an error. Callers should treat a false result as "no base branch yet;
// prompt the user to seed one" rather than propagating an error.
func (m *Manager) HasCommits(ctx context.Context, repoPath string) (bool, error) {
	repoAbs, err := resolveRepo(repoPath)
	if err != nil {
		return false, err
	}
	// `rev-parse --verify HEAD` exits 0 when HEAD resolves to a commit and
	// 128 when HEAD is unborn ("fatal: needed a single revision"). Some
	// older Git builds return exit 1 on unset refs, so we tolerate both.
	_, err = runGit(ctx, m.gitBin, repoAbs, "rev-parse", "--verify", "--quiet", "HEAD")
	if err == nil {
		return true, nil
	}
	var exitErr *exec.ExitError
	if errors.As(err, &exitErr) {
		return false, nil
	}
	return false, err
}

// CreateInitialCommit seeds an unborn-HEAD repository with an empty root
// commit so `git worktree add` (which requires a committish) can succeed.
// The commit is placed on whatever branch HEAD currently points at — for
// repos bootstrapped via Manager.Init that is `main`; for user-created
// empty repos it honours their `init.defaultBranch`.
//
// The author is hard-coded to FleetKanban so the commit succeeds even when
// the user has not configured global user.name / user.email, and so the
// commit is clearly attributable if the user later inspects `git log`.
// Returns an error if the repository already has commits (caller must
// verify via HasCommits first).
func (m *Manager) CreateInitialCommit(ctx context.Context, repoPath string) error {
	repoAbs, err := resolveRepo(repoPath)
	if err != nil {
		return err
	}
	unlock := m.lockRepo(repoAbs)
	defer unlock()
	has, err := m.HasCommits(ctx, repoAbs)
	if err != nil {
		return fmt.Errorf("worktree: probe HEAD: %w", err)
	}
	if has {
		return errors.New("worktree: repository already has commits")
	}
	if _, err := runGit(ctx, m.gitBin, repoAbs,
		"-c", "user.name=FleetKanban",
		"-c", "user.email=fleetkanban@local",
		"commit", "--allow-empty",
		"-m", "FleetKanban: initial commit"); err != nil {
		return fmt.Errorf("worktree: create initial commit: %w", err)
	}
	return nil
}

// CurrentBranch returns the short branch name that HEAD points to inside
// repoPath. For a detached HEAD the returned name is empty.
func (m *Manager) CurrentBranch(ctx context.Context, repoPath string) (string, error) {
	repoAbs, err := resolveRepo(repoPath)
	if err != nil {
		return "", err
	}
	out, err := runGit(ctx, m.gitBin, repoAbs, "symbolic-ref", "--quiet", "--short", "HEAD")
	if err != nil {
		var exitErr *exec.ExitError
		// Detached HEAD → exit 1 with empty output. That's not an error at
		// this layer.
		if errors.As(err, &exitErr) && exitErr.ExitCode() == 1 {
			return "", nil
		}
		return "", err
	}
	return strings.TrimSpace(string(out)), nil
}

// ErrWorktreeMissing is returned by Diff when the target worktree directory
// no longer exists on disk. Callers that have the task's recorded branch name
// should fall back to DiffBranch against the main repository, which continues
// to host the branch as long as finalization did not delete it.
var ErrWorktreeMissing = errors.New("worktree: worktree directory no longer exists on disk")

// Diff returns a unified diff of the working tree against the merge-base
// of HEAD and baseBranch, executed inside wtPath. The returned string is
// suitable for diff2html rendering.
//
// IMPORTANT: we deliberately diff against the merge-base (not the
// 3-dot `base...HEAD` form) so the result includes uncommitted changes —
// the agent typically edits files without committing, and 3-dot would
// silently report an empty diff for those tasks. Comparing against
// merge-base also excludes base-branch commits made after the task
// branch was created, so we still get the same "show only what this
// task changed" semantics as 3-dot for committed work.
//
// UNTRACKED FILES: `git diff <commit>` only inspects tracked files, so
// brand-new files the agent created without `git add` would otherwise
// vanish from the UI until Finalize Keep auto-commits them. We run
// `git add --intent-to-add --all` first so new files show up as
// full-content additions. --intent-to-add only records an empty
// blob in the index; no content is actually staged, so the
// subsequent commit (on Finalize) behaves identically to not having
// run it.
//
// --no-color keeps the output parser-friendly regardless of user config.
//
// If wtPath does not exist on disk (user deleted it, or Finalize already
// removed it while the task row still references the path) the function
// returns ErrWorktreeMissing so callers can fall back to DiffBranch.
func (m *Manager) Diff(ctx context.Context, wtPath, baseBranch string) (string, error) {
	if wtPath == "" || baseBranch == "" {
		return "", errors.New("worktree: wtPath and baseBranch are required")
	}
	abs, err := resolveRepo(wtPath)
	if err != nil {
		return "", err
	}
	if _, statErr := os.Stat(abs); os.IsNotExist(statErr) {
		return "", ErrWorktreeMissing
	}

	// Mark untracked files as intent-to-add so `git diff` emits them.
	// Best-effort: failures here are logged internally by git but
	// shouldn't abort the diff (the worst case is we miss a few new
	// files in the UI, which is strictly better than erroring out).
	_, _ = runGit(ctx, m.gitBin, abs, "add", "--intent-to-add", "--all")

	mb, err := mergeBase(ctx, m.gitBin, abs, baseBranch, "HEAD")
	if err != nil {
		// Fall back to 2-dot diff against baseBranch when merge-base
		// fails (typically: baseBranch ref no longer exists, or HEAD
		// is detached without ancestry). 2-dot at least surfaces
		// uncommitted changes for the common case.
		out, derr := runGit(ctx, m.gitBin, abs,
			"diff", "--no-color", baseBranch)
		if derr != nil {
			return "", fmt.Errorf("worktree: diff (merge-base failed: %v): %w", err, derr)
		}
		return string(out), nil
	}
	out, err := runGit(ctx, m.gitBin, abs,
		"diff", "--no-color", mb)
	if err != nil {
		return "", fmt.Errorf("worktree: diff: %w", err)
	}
	return string(out), nil
}

// DiffBranch returns a unified diff of branch against the merge-base of
// branch and baseBranch, executed from the main repository at repoPath
// (not a worktree). Used as the fallback when a task's worktree has
// already been removed but its branch is still present in the repository
// (Keep / Merge finalization, or external worktree cleanup).
//
// Operates purely on refs — there is no working tree to read uncommitted
// changes from, so the result reflects only what was committed before
// the worktree was torn down. This is why orchestrator.Finalize auto-
// commits any pending changes on the task branch right before removing
// the worktree (see commitPending below): without that step, agents that
// never committed would surface an empty diff after Keep.
func (m *Manager) DiffBranch(ctx context.Context, repoPath, baseBranch, branch string) (string, error) {
	if repoPath == "" || baseBranch == "" || branch == "" {
		return "", errors.New("worktree: repoPath, baseBranch and branch are required")
	}
	repoAbs, err := resolveRepo(repoPath)
	if err != nil {
		return "", err
	}
	mb, err := mergeBase(ctx, m.gitBin, repoAbs, baseBranch, branch)
	if err != nil {
		out, derr := runGit(ctx, m.gitBin, repoAbs,
			"diff", "--no-color", baseBranch, branch)
		if derr != nil {
			return "", fmt.Errorf("worktree: diff-branch (merge-base failed: %v): %w", err, derr)
		}
		return string(out), nil
	}
	out, err := runGit(ctx, m.gitBin, repoAbs,
		"diff", "--no-color", mb, branch)
	if err != nil {
		return "", fmt.Errorf("worktree: diff-branch: %w", err)
	}
	return string(out), nil
}

// mergeBase returns the merge-base SHA of two refs, used by Diff and
// DiffBranch to anchor diffs at "the point where this branch diverged
// from base" so post-divergence base commits don't pollute the result.
func mergeBase(ctx context.Context, gitBin, dir, a, b string) (string, error) {
	out, err := runGit(ctx, gitBin, dir, "merge-base", a, b)
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(string(out)), nil
}

// CommitPending stages every change in the worktree and creates a commit
// with the given message. No-op when the working tree is clean. Used by
// orchestrator.Finalize so Keep / Merge tasks always have committed work
// to surface (in DiffBranch and Merge respectively) even when the agent
// never ran `git commit` itself.
//
// Returns true when a commit was actually created so callers can decide
// whether to log/event the auto-commit.
func (m *Manager) CommitPending(ctx context.Context, wtPath, message string) (bool, error) {
	if wtPath == "" {
		return false, errors.New("worktree: wtPath is required")
	}
	abs, err := resolveRepo(wtPath)
	if err != nil {
		return false, err
	}
	if _, statErr := os.Stat(abs); os.IsNotExist(statErr) {
		return false, ErrWorktreeMissing
	}
	// Quick check: if there are no changes (committed or otherwise),
	// bail before touching the repo. `git status --porcelain` prints
	// one line per change and nothing when clean.
	st, err := runGit(ctx, m.gitBin, abs, "status", "--porcelain")
	if err != nil {
		return false, fmt.Errorf("worktree: status: %w", err)
	}
	if strings.TrimSpace(string(st)) == "" {
		return false, nil
	}
	if _, err := runGit(ctx, m.gitBin, abs, "add", "-A"); err != nil {
		return false, fmt.Errorf("worktree: add: %w", err)
	}
	if message == "" {
		message = "FleetKanban: auto-commit pending changes"
	}
	// Commit with --allow-empty-message guard via -m, and configure
	// author/committer locally so users without global git identity
	// (or worktrees explicitly stripped of one) still succeed.
	if _, err := runGit(ctx, m.gitBin, abs,
		"-c", "user.name=FleetKanban",
		"-c", "user.email=fleetkanban@local",
		"commit", "-m", message); err != nil {
		return false, fmt.Errorf("worktree: commit: %w", err)
	}
	return true, nil
}

// rootFor returns the directory under which the next worktree for repoAbs
// should be created. The primary choice is a sibling `.fleetkanban-worktrees`
// folder next to the repo — this keeps the worktree on the same drive and
// makes it visible to the user. When that directory cannot be created
// (typically a permission error on locations like `C:\Program Files\...`),
// the Manager falls back to a per-repo subdirectory under FallbackRoot.
//
// The "primary" directory is created eagerly because `git worktree add`
// requires the worktree's parent to exist before it runs.
func (m *Manager) rootFor(repoAbs string) (string, error) {
	primary := filepath.Join(filepath.Dir(repoAbs), SiblingDirName)
	if err := os.MkdirAll(primary, 0o755); err == nil {
		return primary, nil
	}
	fb := filepath.Join(m.fallbackRoot, repoHash(repoAbs))
	if err := os.MkdirAll(fb, 0o755); err != nil {
		return "", fmt.Errorf("worktree: create fallback root: %w", err)
	}
	return fb, nil
}

// repoHash derives a stable short identifier from a repository path so the
// fallback layout can keep each repo's worktrees in their own subtree. The
// path is lowercased first — NTFS is case-insensitive, so two equivalent
// paths should map to the same hash.
func repoHash(repoAbs string) string {
	sum := sha256.Sum256([]byte(strings.ToLower(repoAbs)))
	return hex.EncodeToString(sum[:8])
}

// lockRepo returns a per-repo mutex acquisition. The returned func releases
// the lock when called exactly once.
func (m *Manager) lockRepo(repoAbs string) func() {
	key := strings.ToLower(repoAbs)
	m.mmu.Lock()
	mu, ok := m.mu[key]
	if !ok {
		mu = &sync.Mutex{}
		m.mu[key] = mu
	}
	m.mmu.Unlock()
	mu.Lock()
	return mu.Unlock
}

// resolveRepo returns the absolute, cleaned form of a repo path. It does not
// normalize case — the file system is the source of truth.
func resolveRepo(p string) (string, error) {
	abs, err := filepath.Abs(p)
	if err != nil {
		return "", fmt.Errorf("worktree: abs %q: %w", p, err)
	}
	return filepath.Clean(abs), nil
}

// runGit runs `git <args...>` with cwd = repoAbs and captures stdout.
// On non-zero exit the returned error includes the stderr text.
//
// The environment is forced to LC_ALL=C / LANG=C so stderr stays in English
// regardless of the user's Windows display language. Callers that
// string-match against git output (e.g. Remove's "not found" detection
// for the `branch -D` fallback) would otherwise miss localized messages
// and surface a false failure.
func runGit(ctx context.Context, gitBin, repoAbs string, args ...string) ([]byte, error) {
	cmd := exec.CommandContext(ctx, gitBin, args...)
	cmd.Dir = repoAbs
	cmd.Env = append(os.Environ(), "LC_ALL=C", "LANG=C")
	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr
	if err := cmd.Run(); err != nil {
		return nil, fmt.Errorf("git %s: %w: %s",
			strings.Join(args, " "), err, strings.TrimSpace(stderr.String()))
	}
	return stdout.Bytes(), nil
}

// applyLocalConfig applies the per-worktree Git tweaks from phase1-spec §9.2.
// Failures are accumulated into a single error so we know which knob was not
// honored (older Git versions don't know fsmonitor, for instance).
func applyLocalConfig(ctx context.Context, gitBin, wt string) error {
	settings := [][2]string{
		{"core.longpaths", "true"},
		{"core.autocrlf", "false"},
		{"core.symlinks", "false"},
		{"core.fscache", "true"},
		{"core.preloadindex", "true"},
		{"gc.auto", "0"},
	}
	var firstErr error
	for _, s := range settings {
		if _, err := runGit(ctx, gitBin, wt, "config", "--local", s[0], s[1]); err != nil {
			if firstErr == nil {
				firstErr = fmt.Errorf("config %s=%s: %w", s[0], s[1], err)
			}
		}
	}
	// fsmonitor is Git 2.37+; swallow failures rather than annoy old setups.
	_, _ = runGit(ctx, gitBin, wt, "config", "--local", "core.fsmonitor", "true")
	return firstErr
}

// parseWorktreeList parses the output of `git worktree list --porcelain`.
// Each record is terminated by a blank line. A record has at most one of:
//
//	worktree <path>
//	HEAD <sha>
//	branch <refname>
//	detached
//	bare
func parseWorktreeList(data []byte) ([]Info, error) {
	var (
		out     []Info
		current Info
		started bool
	)
	push := func() {
		if started {
			out = append(out, current)
		}
		current = Info{}
		started = false
	}
	sc := bufio.NewScanner(bytes.NewReader(data))
	for sc.Scan() {
		line := sc.Text()
		if line == "" {
			push()
			continue
		}
		started = true
		parts := strings.SplitN(line, " ", 2)
		switch parts[0] {
		case "worktree":
			if len(parts) == 2 {
				current.Path = parts[1]
			}
		case "HEAD":
			if len(parts) == 2 {
				current.HEAD = parts[1]
			}
		case "branch":
			if len(parts) == 2 {
				current.Branch = parts[1]
			}
		}
	}
	push()
	return out, sc.Err()
}
