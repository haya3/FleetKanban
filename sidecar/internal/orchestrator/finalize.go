package orchestrator

import (
	"context"
	"errors"
	"fmt"

	"github.com/FleetKanban/fleetkanban/internal/task"
	"github.com/FleetKanban/fleetkanban/internal/worktree"
)

// Finalization is the post-run action the user picks from the review gate.
type Finalization int

const (
	// FinalizeKeep removes the worktree but preserves fleetkanban/<id>.
	// Default post-run action (phase1-spec §2).
	FinalizeKeep Finalization = iota
	// FinalizeDiscard removes both the worktree and the branch.
	FinalizeDiscard
	// FinalizeMerge advances the task's base branch so it contains the tip
	// of fleetkanban/<id> (fast-forward when possible, otherwise a --no-ff
	// merge commit), then removes the worktree and the task branch.
	// Requires the main repository's working tree to be clean if it is
	// currently on the base branch; merge conflicts abort the operation.
	FinalizeMerge
)

// Finalize applies the user's post-run choice. Valid starting states are
// human_review (after a normal exit), aborted (after Cancel), and done
// with Finalization == Keep (a delayed merge: the worktree is gone but
// the fleetkanban/<id> branch is still around, so the user can promote it
// into base on their own schedule).
//
// The orchestrator does not hold a lock across the git worktree operation:
// the worktree manager's per-repo mutex provides the real serialization.
// We do, however, require the task not be actively InProgress — that case is
// Cancel's job, not Finalize's.
func (o *Orchestrator) Finalize(ctx context.Context, taskID string, action Finalization) error {
	if taskID == "" {
		return errors.New("orchestrator: empty taskID")
	}

	o.mu.Lock()
	_, busy := o.running[taskID]
	o.mu.Unlock()
	if busy {
		return fmt.Errorf("orchestrator: task %s is still running; cancel it first", taskID)
	}

	t, err := o.cfg.TaskStore.Get(ctx, taskID)
	if err != nil {
		return fmt.Errorf("orchestrator: finalize lookup: %w", err)
	}

	// Post-done merge: the task already finished via Keep, so the worktree
	// has been torn down and Status is already Done. Only Merge makes sense
	// here — Keep is a no-op, and Discard's branch-deletion is what
	// DeleteTaskBranch exists for. Route into the dedicated path that
	// skips the worktree.Remove + state transition (Status stays Done) and
	// just advances the ref + flips Finalization to Merged.
	if t.Status == task.StatusDone && t.Finalization == task.FinalizationKeep {
		if action != FinalizeMerge {
			return fmt.Errorf("orchestrator: task %s is already done; only Merge is valid (got %d)", taskID, action)
		}
		return o.finalizeDoneMerge(ctx, t)
	}

	switch t.Status {
	case task.StatusHumanReview, task.StatusAborted:
	default:
		return fmt.Errorf("orchestrator: cannot finalize task in status %s", t.Status)
	}

	if t.WorktreePath == "" || t.Branch == "" {
		return fmt.Errorf("orchestrator: task %s has no worktree to finalize", taskID)
	}
	repoPath, err := o.cfg.Repositories.Path(ctx, t.RepoID)
	if err != nil {
		return fmt.Errorf("orchestrator: repo lookup: %w", err)
	}

	// Auto-commit any pending changes on the task branch before we tear
	// down the worktree. Required for Keep (so DiffBranch can show the
	// agent's edits afterwards) and for Merge (so there's something
	// substantive to advance base to). Skipped for Discard since the
	// branch is going away anyway. Failures fall through to a warning —
	// finalization should not be blocked by an auto-commit issue when
	// the user has explicitly chosen Keep / Merge.
	if action == FinalizeKeep || action == FinalizeMerge {
		if _, ccErr := o.cfg.Worktrees.CommitPending(ctx, t.WorktreePath,
			fmt.Sprintf("FleetKanban: finalize %s", t.ID)); ccErr != nil {
			o.log.Warn("orchestrator: finalize auto-commit", "task", taskID, "err", ccErr)
		}
	}

	var wtMode worktree.RemoveMode
	var nextStatus task.Status
	var finalization task.FinalizationKind
	switch action {
	case FinalizeKeep:
		wtMode = worktree.KeepBranch
		nextStatus = task.StatusDone
		finalization = task.FinalizationKeep
	case FinalizeDiscard:
		wtMode = worktree.DeleteBranch
		nextStatus = task.StatusCancelled
		finalization = task.FinalizationNone
	case FinalizeMerge:
		if t.BaseBranch == "" {
			return fmt.Errorf("orchestrator: task %s has no recorded base branch; cannot merge", taskID)
		}
		// Merge first; any failure here (missing branches, dirty base tree,
		// merge conflict) leaves refs untouched so the user can retry or
		// fall back to Keep.
		if _, err := o.cfg.Worktrees.Merge(ctx, repoPath, t.BaseBranch, taskID); err != nil {
			return fmt.Errorf("orchestrator: merge: %w", err)
		}
		// Merged branches can be removed safely — the commits live on in
		// base. DeleteBranch also removes the worktree directory in one
		// serialized operation.
		wtMode = worktree.DeleteBranch
		nextStatus = task.StatusDone
		finalization = task.FinalizationMerged
	default:
		return fmt.Errorf("orchestrator: unknown finalization %d", action)
	}

	if err := o.cfg.Worktrees.Remove(ctx, repoPath, t.WorktreePath, taskID, wtMode); err != nil {
		return fmt.Errorf("orchestrator: remove worktree: %w", err)
	}

	if err := o.cfg.TaskStore.Transition(ctx, taskID, t.Status, nextStatus, "", "", finalization); err != nil {
		return fmt.Errorf("orchestrator: finalize transition: %w", err)
	}
	o.emitStatus(ctx, taskID, t.Status, nextStatus)
	return nil
}

// finalizeDoneMerge handles the "already done, but let's merge after all"
// case. The task reached Done via FinalizationKeep, so the worktree is
// already gone and Status must stay Done — the state machine has no
// done → done edge. Instead we advance the ref in-place, delete the
// fleetkanban/<id> branch, and flip Finalization from Keep to Merged via
// UpdateFields (which writes under WHERE status = Done, satisfying the
// store's stale-check). BranchExists is cleared separately because
// UpdateFields does not touch that column.
func (o *Orchestrator) finalizeDoneMerge(ctx context.Context, t *task.Task) error {
	if !t.BranchExists || t.Branch == "" {
		return fmt.Errorf("orchestrator: task %s branch is already gone; nothing to merge", t.ID)
	}
	if t.BaseBranch == "" {
		return fmt.Errorf("orchestrator: task %s has no recorded base branch; cannot merge", t.ID)
	}
	repoPath, err := o.cfg.Repositories.Path(ctx, t.RepoID)
	if err != nil {
		return fmt.Errorf("orchestrator: repo lookup: %w", err)
	}
	// Merge first. Any failure (missing refs, dirty base tree, conflicts)
	// leaves everything untouched so the user can resolve and retry.
	if _, err := o.cfg.Worktrees.Merge(ctx, repoPath, t.BaseBranch, t.ID); err != nil {
		return fmt.Errorf("orchestrator: merge: %w", err)
	}
	if err := o.cfg.Worktrees.DeleteBranch(ctx, repoPath, t.Branch); err != nil {
		return fmt.Errorf("orchestrator: delete merged branch: %w", err)
	}
	t.Finalization = task.FinalizationMerged
	if err := o.cfg.TaskStore.UpdateFields(ctx, t); err != nil {
		return fmt.Errorf("orchestrator: update finalization: %w", err)
	}
	if err := o.cfg.TaskStore.SetBranchExists(ctx, t.ID, false); err != nil {
		// Branch is already gone from git; a DB error here leaves the row
		// briefly stale but the reaper's branch-existence sweep will fix
		// it on the next pass.
		return fmt.Errorf("orchestrator: clear branch_exists: %w", err)
	}
	return nil
}
