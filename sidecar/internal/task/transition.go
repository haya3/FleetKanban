package task

import "fmt"

// allowedTransitions is the authoritative edge set for the task state machine.
//
// Phase 1 flow (after AI Review is implemented):
//
//	queued        ─▶ planning        (orchestrator pick-up — run AI planner)
//	queued        ─▶ cancelled       (discarded from queue)
//	planning      ─▶ in_progress     (planner succeeded; subtasks persisted)
//	planning      ─▶ failed          (planner error / JSON parse failure / timeout)
//	planning      ─▶ aborted         (user pressed stop during planning)
//	in_progress   ─▶ ai_review       (agent exit 0 — pass through AI review gate)
//	in_progress   ─▶ failed          (runtime error, path escape, timeout, interrupted)
//	in_progress   ─▶ aborted         (user pressed stop during run)
//	ai_review     ─▶ human_review    (AI review passed — automatic in Phase 1, smart in Phase 2)
//	ai_review     ─▶ failed          (AI review rejected with a definite failure)
//	ai_review     ─▶ queued          (rework: user / AI asked for another iteration)
//	human_review  ─▶ done            (Keep or Merge → Finalization set)
//	human_review  ─▶ cancelled       (Discard)
//	human_review  ─▶ queued          (rework with feedback — re-run in same worktree)
//	aborted       ─▶ done            (Keep from an aborted task)
//	aborted       ─▶ cancelled       (Discard aborted task)
//	aborted       ─▶ queued          (retry an aborted task in-place)
//	failed        ─▶ queued          (retry after a runtime / auth / timeout failure)
//
// Done and Cancelled are terminal. Failed is a "soft terminal" — normal
// pipeline flow stops there, but the user can explicitly retry it; the
// `failed → queued` edge exists for that case. IsTerminal() therefore
// still reports true for StatusFailed (normal flow stops), even though
// CanTransition(failed, queued) is true.
var allowedTransitions = map[Status]map[Status]struct{}{
	StatusQueued: {
		StatusPlanning:  {},
		StatusCancelled: {},
		// queued → in_progress is preserved for rework flows that must
		// bypass planning (human_review → queued re-runs the existing
		// worktree against the same plan; re-planning would throw away
		// the subtask graph the user approved).
		StatusInProgress: {},
	},
	StatusPlanning: {
		StatusInProgress: {},
		StatusFailed:     {},
		StatusAborted:    {},
	},
	StatusInProgress: {
		StatusAIReview: {},
		StatusFailed:   {},
		StatusAborted:  {},
	},
	StatusAIReview: {
		StatusHumanReview: {},
		StatusFailed:      {},
		StatusQueued:      {},
		// User-initiated cancel while the reviewer is running. Lands in
		// aborted (same as a cancel during in_progress) so the user can
		// subsequently Keep / Discard / rerun the task.
		StatusAborted: {},
	},
	StatusHumanReview: {
		StatusDone:      {},
		StatusCancelled: {},
		StatusQueued:    {},
	},
	StatusAborted: {
		StatusDone:      {},
		StatusCancelled: {},
		StatusQueued:    {},
	},
	StatusFailed: {
		// The user can reopen a failed task from the Kanban's "Done" column
		// via the re-run action. The sidecar clears ErrorCode / ErrorMessage
		// as part of the transition (see TaskStore.Transition).
		StatusQueued: {},
	},
}

// CanTransition reports whether from → to is a legal state-machine edge.
// Same-state transitions (from == to) are rejected: UPDATEs that do not change
// the status must not flow through the transition gate.
func CanTransition(from, to Status) bool {
	if from == to {
		return false
	}
	allowed, ok := allowedTransitions[from]
	if !ok {
		return false
	}
	_, ok = allowed[to]
	return ok
}

// Transition advances the task from its current Status to next. On illegal
// edges it returns an error and leaves the task untouched. Callers are
// responsible for setting ErrorCode / ErrorMessage when transitioning to
// StatusFailed, Finalization when transitioning to StatusDone, and for
// updating the timestamp fields.
func (t *Task) Transition(next Status) error {
	if !next.Valid() {
		return fmt.Errorf("task %s: invalid target status %q", t.ID, next)
	}
	if !CanTransition(t.Status, next) {
		return fmt.Errorf("task %s: illegal transition %s -> %s", t.ID, t.Status, next)
	}
	t.Status = next
	return nil
}
