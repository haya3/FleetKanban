package worktree

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"
)

// StashResult summarises what StashUncommitted actually did so the UI
// can show a meaningful confirmation (or hide itself when there was
// nothing to stash). Message is git's own stdout — useful when the
// user later runs `git stash list` and wants to match.
type StashResult struct {
	Stashed bool
	Message string
}

// StashUncommitted runs `git stash push --include-untracked -m ...`
// in the main working tree of repoPath. Returns Stashed=false without
// error when the tree was clean (git exits with "No local changes to
// save").
//
// The label includes a timestamp so repeated stashes remain
// distinguishable in `git stash list`. --include-untracked so new
// files introduced by the user (not yet `git add`ed) are captured
// alongside modifications — otherwise the merge would still see the
// working tree as dirty.
func (m *Manager) StashUncommitted(ctx context.Context, repoPath string) (StashResult, error) {
	if repoPath == "" {
		return StashResult{}, errors.New("worktree: StashUncommitted: repoPath is required")
	}
	repoAbs, err := resolveRepo(repoPath)
	if err != nil {
		return StashResult{}, err
	}
	unlock := m.lockRepo(repoAbs)
	defer unlock()

	// Check if the tree is actually dirty first — a stash on a clean
	// tree is a no-op in git (exit 0 with "No local changes to save")
	// but we want a cleaner contract for callers.
	_, dirty, err := m.mainRepoState(ctx, repoAbs, "")
	if err != nil {
		return StashResult{}, fmt.Errorf("worktree: StashUncommitted: dirty check: %w", err)
	}
	if !dirty {
		return StashResult{Stashed: false, Message: "working tree already clean"}, nil
	}

	label := "FleetKanban pre-merge stash " + time.Now().UTC().Format("2006-01-02 15:04:05")
	out, err := runGit(ctx, m.gitBin, repoAbs,
		"stash", "push", "--include-untracked", "-m", label)
	if err != nil {
		return StashResult{}, fmt.Errorf("worktree: StashUncommitted: %w", err)
	}
	return StashResult{
		Stashed: true,
		Message: strings.TrimSpace(string(out)),
	}, nil
}
