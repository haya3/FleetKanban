package worktree

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"strings"
)

// MergeResult reports what Merge actually did so the caller can surface the
// distinction in UI copy (e.g. "fast-forwarded" vs "merged with conflicts
// avoided"). NoOp covers the case where sourceBranch is already reachable
// from baseBranch — no ref changes, no working-tree refresh.
type MergeResult int

const (
	MergeNoOp        MergeResult = iota // source already merged
	MergeFastForward                    // base advanced to source (no new commit)
	MergeCommitNoFF                     // new --no-ff merge commit was created
)

// Merge updates baseBranch so it contains the tip of fleetkanban/<taskID> in
// repoPath, without disrupting the user's current checkout. Two strategies
// are used:
//
//   - Fast-forward: when baseBranch is an ancestor of the task branch,
//     `git update-ref` advances baseBranch directly. No new commit.
//   - --no-ff merge: when the two have diverged, a merge commit is built
//     via `git merge-tree --write-tree` + `git commit-tree`, then the ref
//     is advanced. Requires git 2.38+.
//
// The fleetkanban/<taskID> branch is left intact — the orchestrator is free
// to delete it after the merge as part of its cleanup.
//
// Preconditions:
//   - Both baseBranch and fleetkanban/<taskID> must exist.
//   - If baseBranch is the checked-out branch of the main repo and the
//     working tree is dirty, Merge refuses. Callers should prompt the
//     user to commit or stash first.
//   - merge-tree conflicts abort the merge before any ref is touched.
//
// Postconditions:
//   - baseBranch advanced in the ref store.
//   - If baseBranch was checked out in the main repo with a clean tree,
//     the working tree is refreshed via `git reset --hard` so Explorer /
//     IDE views match the new ref.
func (m *Manager) Merge(ctx context.Context, repoPath, baseBranch, taskID string) (MergeResult, error) {
	if repoPath == "" || baseBranch == "" || taskID == "" {
		return MergeNoOp, errors.New("worktree: Merge: repoPath, baseBranch, taskID are required")
	}
	repoAbs, err := resolveRepo(repoPath)
	if err != nil {
		return MergeNoOp, err
	}
	source := BranchPrefix + taskID

	unlock := m.lockRepo(repoAbs)
	defer unlock()

	baseSha, err := revParse(ctx, m.gitBin, repoAbs, "refs/heads/"+baseBranch)
	if err != nil {
		return MergeNoOp, fmt.Errorf("worktree: Merge: base branch %q not found: %w", baseBranch, err)
	}
	sourceSha, err := revParse(ctx, m.gitBin, repoAbs, "refs/heads/"+source)
	if err != nil {
		return MergeNoOp, fmt.Errorf("worktree: Merge: source branch %q not found: %w", source, err)
	}

	if baseSha == sourceSha {
		return MergeNoOp, nil
	}

	// sourceIsAncestor → base already contains source, nothing to do.
	sourceMerged, err := isAncestor(ctx, m.gitBin, repoAbs, sourceSha, baseSha)
	if err != nil {
		return MergeNoOp, fmt.Errorf("worktree: Merge: ancestry check: %w", err)
	}
	if sourceMerged {
		return MergeNoOp, nil
	}

	onBase, dirty, err := m.mainRepoState(ctx, repoAbs, baseBranch)
	if err != nil {
		return MergeNoOp, fmt.Errorf("worktree: Merge: main repo state: %w", err)
	}
	if onBase && dirty {
		return MergeNoOp, fmt.Errorf("worktree: Merge: base branch %q is checked out in the main repository with uncommitted changes; commit or stash first", baseBranch)
	}

	ffOK, err := isAncestor(ctx, m.gitBin, repoAbs, baseSha, sourceSha)
	if err != nil {
		return MergeNoOp, fmt.Errorf("worktree: Merge: ancestry check: %w", err)
	}

	var result MergeResult
	if ffOK {
		if _, err := runGit(ctx, m.gitBin, repoAbs,
			"update-ref", "refs/heads/"+baseBranch, sourceSha, baseSha); err != nil {
			return MergeNoOp, fmt.Errorf("worktree: Merge: fast-forward update-ref: %w", err)
		}
		result = MergeFastForward
	} else {
		tree, mergeErr := mergeTreeWrite(ctx, m.gitBin, repoAbs, baseSha, sourceSha)
		if mergeErr != nil {
			return MergeNoOp, mergeErr
		}
		msg := fmt.Sprintf("Merge branch '%s' into %s", source, baseBranch)
		commit, err := commitTree(ctx, m.gitBin, repoAbs, tree,
			[]string{baseSha, sourceSha}, msg)
		if err != nil {
			return MergeNoOp, fmt.Errorf("worktree: Merge: commit-tree: %w", err)
		}
		if _, err := runGit(ctx, m.gitBin, repoAbs,
			"update-ref", "refs/heads/"+baseBranch, commit, baseSha); err != nil {
			return MergeNoOp, fmt.Errorf("worktree: Merge: update-ref: %w", err)
		}
		result = MergeCommitNoFF
	}

	if onBase {
		// HEAD is a symbolic ref to baseBranch; after the update-ref, HEAD
		// already resolves to the new commit. `reset --hard HEAD` realigns
		// index and working tree without touching the ref again.
		if _, err := runGit(ctx, m.gitBin, repoAbs, "reset", "--hard", "HEAD"); err != nil {
			return result, fmt.Errorf("worktree: Merge: refresh main working tree: %w", err)
		}
	}
	return result, nil
}

// mainRepoState reports whether the main repository at repoAbs is on
// baseBranch and whether its working tree or index is dirty.
func (m *Manager) mainRepoState(ctx context.Context, repoAbs, baseBranch string) (onBase, dirty bool, err error) {
	cur, err := m.CurrentBranch(ctx, repoAbs)
	if err != nil {
		return false, false, err
	}
	onBase = (cur == baseBranch)
	out, err := runGit(ctx, m.gitBin, repoAbs, "status", "--porcelain")
	if err != nil {
		return false, false, err
	}
	dirty = len(bytes.TrimSpace(out)) > 0
	return onBase, dirty, nil
}

func revParse(ctx context.Context, gitBin, repoAbs, ref string) (string, error) {
	out, err := runGit(ctx, gitBin, repoAbs, "rev-parse", "--verify", "--quiet", ref)
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(string(out)), nil
}

// isAncestor reports whether ancestor is reachable from descendant — i.e.
// `git merge-base --is-ancestor <ancestor> <descendant>`. Accepts either
// ref names or commit SHAs.
func isAncestor(ctx context.Context, gitBin, repoAbs, ancestor, descendant string) (bool, error) {
	_, err := runGit(ctx, gitBin, repoAbs,
		"merge-base", "--is-ancestor", ancestor, descendant)
	if err == nil {
		return true, nil
	}
	var exitErr *exec.ExitError
	if errors.As(err, &exitErr) && exitErr.ExitCode() == 1 {
		return false, nil
	}
	return false, err
}

// mergeTreeWrite builds the merged tree for base + source without touching
// any working tree. On conflict git exits 1 and we surface a descriptive
// error so the caller can tell the user to merge manually.
func mergeTreeWrite(ctx context.Context, gitBin, repoAbs, base, source string) (string, error) {
	cmd := exec.CommandContext(ctx, gitBin, "merge-tree", "--write-tree", base, source)
	cmd.Dir = repoAbs
	cmd.Env = append(os.Environ(), "LC_ALL=C", "LANG=C")
	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr
	if err := cmd.Run(); err != nil {
		var exitErr *exec.ExitError
		if errors.As(err, &exitErr) && exitErr.ExitCode() == 1 {
			// Conflict: stdout carries the tree SHA, then a blank line, then
			// conflicted-path listings. Trim to the path listings for the
			// user-facing error.
			text := strings.TrimSpace(stdout.String())
			if idx := strings.Index(text, "\n\n"); idx >= 0 {
				text = strings.TrimSpace(text[idx+2:])
			}
			if text == "" {
				text = strings.TrimSpace(stderr.String())
			}
			return "", fmt.Errorf("worktree: Merge: merge conflict — resolve manually:\n%s", text)
		}
		return "", fmt.Errorf("worktree: Merge: merge-tree: %w: %s",
			err, strings.TrimSpace(stderr.String()))
	}
	lines := strings.Split(strings.TrimSpace(stdout.String()), "\n")
	if len(lines) == 0 || len(lines[0]) < 40 {
		return "", fmt.Errorf("worktree: Merge: merge-tree unexpected output: %q", stdout.String())
	}
	return lines[0], nil
}

// commitTree writes a merge commit with the given tree, parents, and
// message. Author/committer identity is the same synthetic FleetKanban
// signature used by InitRepo's bootstrap commit — user.name/email don't
// need to be globally configured for this to work.
func commitTree(ctx context.Context, gitBin, repoAbs, tree string, parents []string, msg string) (string, error) {
	args := []string{
		"-c", "user.name=FleetKanban",
		"-c", "user.email=fleetkanban@local",
		"commit-tree", tree,
	}
	for _, p := range parents {
		args = append(args, "-p", p)
	}
	args = append(args, "-m", msg)
	out, err := runGit(ctx, gitBin, repoAbs, args...)
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(string(out)), nil
}
