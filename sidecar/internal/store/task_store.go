package store

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"strings"

	"github.com/FleetKanban/fleetkanban/internal/task"
)

// TaskStore persists task.Task rows. All writes flow through the serialized
// write handle (DB.Write); all reads use the pooled read handle.
type TaskStore struct{ db *DB }

// NewTaskStore wraps a DB with task-specific helpers.
func NewTaskStore(db *DB) *TaskStore { return &TaskStore{db: db} }

// Create inserts a new task row. The caller supplies a fully-populated Task
// (with Status typically StatusPlanning). CreatedAt / FinishedAt / etc. are
// copied as-is; the store does not mutate them.
func (s *TaskStore) Create(ctx context.Context, t *task.Task) error {
	if err := t.Validate(); err != nil {
		return err
	}
	now := nowUTC()
	created := formatTime(t.CreatedAt)
	if created == "" {
		created = now
	}
	branchExists := 1
	if !t.BranchExists && t.Status != task.StatusPlanning && t.Status != task.StatusQueued {
		// Planning / Queued tasks have no branch materialized yet (BranchExists
		// is conceptually true). For any status past InProgress the caller's
		// BranchExists value is authoritative.
		branchExists = 0
	}
	_, err := s.db.write.ExecContext(ctx, `
INSERT INTO tasks(
    id, repository_id, goal, base_branch, branch, worktree_path,
    branch_exists, model, plan_model, review_model,
    status, finalization, error_code, error_message, session_id,
    review_feedback, rework_count, created_at, updated_at, started_at, finished_at
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
		t.ID, t.RepoID, t.Goal, t.BaseBranch, t.Branch, t.WorktreePath,
		branchExists, t.Model, t.PlanModel, t.ReviewModel,
		string(t.Status), string(t.Finalization),
		string(t.ErrorCode), t.ErrorMessage, t.SessionID, t.ReviewFeedback,
		t.ReworkCount, created, now, nullablePtr(t.StartedAt), nullablePtr(t.FinishedAt),
	)
	if err != nil {
		return fmt.Errorf("task: insert: %w", err)
	}
	return nil
}

// Get loads a task by ID.
func (s *TaskStore) Get(ctx context.Context, id string) (*task.Task, error) {
	row := s.db.read.QueryRowContext(ctx, selectTaskColumns+` WHERE id = ?`, id)
	return scanTask(row)
}

// ListFilter controls List.
type ListFilter struct {
	RepoID    string
	Statuses  []task.Status // empty = all
	Limit     int           // 0 = no limit
	Ascending bool          // false (default) = most-recently-updated first
}

// List returns tasks matching the filter, ordered by updated_at.
func (s *TaskStore) List(ctx context.Context, f ListFilter) ([]*task.Task, error) {
	var (
		where []string
		args  []any
	)
	if f.RepoID != "" {
		where = append(where, "repository_id = ?")
		args = append(args, f.RepoID)
	}
	if len(f.Statuses) > 0 {
		placeholders := make([]string, len(f.Statuses))
		for i, s := range f.Statuses {
			placeholders[i] = "?"
			args = append(args, string(s))
		}
		where = append(where, "status IN ("+strings.Join(placeholders, ",")+")")
	}

	q := selectTaskColumns
	if len(where) > 0 {
		q += " WHERE " + strings.Join(where, " AND ")
	}
	if f.Ascending {
		q += " ORDER BY updated_at ASC"
	} else {
		q += " ORDER BY updated_at DESC"
	}
	if f.Limit > 0 {
		q += fmt.Sprintf(" LIMIT %d", f.Limit)
	}

	rows, err := s.db.read.QueryContext(ctx, q, args...)
	if err != nil {
		return nil, fmt.Errorf("task: list: %w", err)
	}
	defer rows.Close()

	var out []*task.Task
	for rows.Next() {
		t, err := scanTask(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, t)
	}
	return out, rows.Err()
}

// UpdateFields overwrites the mutable fields of an existing task. It does NOT
// transition status; callers wanting a status change should use Transition.
// This method is used for updating worktree_path after creation, error info,
// branch_exists after external branch deletion detection, etc.
func (s *TaskStore) UpdateFields(ctx context.Context, t *task.Task) error {
	if err := t.Validate(); err != nil {
		return err
	}
	res, err := s.db.write.ExecContext(ctx, `
UPDATE tasks SET
    goal            = ?,
    base_branch     = ?,
    branch          = ?,
    worktree_path   = ?,
    model           = ?,
    plan_model      = ?,
    review_model    = ?,
    finalization    = ?,
    error_code      = ?,
    error_message   = ?,
    session_id      = ?,
    review_feedback = ?,
    rework_count    = ?,
    started_at      = ?,
    finished_at     = ?,
    updated_at      = ?
WHERE id = ? AND status = ?`,
		t.Goal, t.BaseBranch, t.Branch, t.WorktreePath, t.Model,
		t.PlanModel, t.ReviewModel,
		string(t.Finalization),
		string(t.ErrorCode), t.ErrorMessage, t.SessionID, t.ReviewFeedback,
		t.ReworkCount,
		nullablePtr(t.StartedAt), nullablePtr(t.FinishedAt),
		nowUTC(), t.ID, string(t.Status),
	)
	if err != nil {
		return fmt.Errorf("task: update: %w", err)
	}
	n, _ := res.RowsAffected()
	if n == 0 {
		return ErrStaleUpdate
	}
	return nil
}

// ErrStaleUpdate is returned when UpdateFields / Transition finds that the
// task's status in the DB differs from the expected one — indicating a
// concurrent modification or a stale in-memory copy.
var ErrStaleUpdate = errors.New("store: task update rejected (stale or missing)")

// Transition atomically changes the task's status from `from` to `to`,
// enforcing the state-machine rules in internal/task. It also updates
// started_at / finished_at when crossing those boundaries, so callers do
// not need to track them manually.
//
// Semantic rules enforced here:
//   - to == StatusFailed requires a non-empty ErrorCode.
//   - to == StatusDone   requires a non-empty Finalization (Keep or Merged).
//   - For every other target, error and finalization columns are cleared.
func (s *TaskStore) Transition(
	ctx context.Context,
	id string,
	from, to task.Status,
	errCode task.ErrorCode,
	errMsg string,
	finalization task.FinalizationKind,
) error {
	if !task.CanTransition(from, to) {
		return fmt.Errorf("task %s: illegal transition %s -> %s", id, from, to)
	}
	if to == task.StatusFailed && errCode == task.ErrCodeNone {
		return fmt.Errorf("task %s: failed transition requires ErrorCode", id)
	}
	if to != task.StatusFailed {
		errCode = task.ErrCodeNone
		errMsg = ""
	}
	if to == task.StatusDone && finalization == task.FinalizationNone {
		return fmt.Errorf("task %s: done transition requires Finalization", id)
	}
	if to != task.StatusDone {
		finalization = task.FinalizationNone
	}

	now := nowUTC()
	startedAt := sql.NullString{}
	finishedAt := sql.NullString{}
	clearFinished := false

	if to == task.StatusInProgress {
		// started_at is set only once, on the first queued→in_progress edge.
		startedAt = sql.NullString{String: now, Valid: true}
	}
	switch to {
	case task.StatusAIReview, task.StatusHumanReview, task.StatusDone,
		task.StatusCancelled, task.StatusAborted, task.StatusFailed:
		finishedAt = sql.NullString{String: now, Valid: true}
	case task.StatusQueued:
		// Rework: the task is being resubmitted. Clear finished_at so the
		// next completion can record a fresh timestamp, and the UI can
		// distinguish "queued awaiting pickup" from "was running earlier".
		clearFinished = true
	}

	// Build the UPDATE conditionally: we only set started_at on in_progress,
	// and only touch finished_at on the review-or-terminal edges. Writing
	// empty strings would collide with existing non-null values.
	var (
		sets []string
		args []any
	)
	sets = append(sets,
		"status = ?", "updated_at = ?",
		"error_code = ?", "error_message = ?",
		"finalization = ?",
	)
	args = append(args, string(to), now, string(errCode), errMsg, string(finalization))
	if startedAt.Valid {
		sets = append(sets, "started_at = COALESCE(started_at, ?)")
		args = append(args, startedAt.String)
	}
	if finishedAt.Valid {
		sets = append(sets, "finished_at = ?")
		args = append(args, finishedAt.String)
	} else if clearFinished {
		sets = append(sets, "finished_at = NULL")
	}

	// rework_count bookkeeping. Incremented on ai_review→queued (the
	// reviewer asked for another pass); reset to 0 on any other entry to
	// queued (user-initiated retry from human_review / failed / aborted)
	// or on arrival at a terminal status. The cap is enforced one layer
	// up in orchestrator.runAIReview; this is just the counter plumbing.
	switch {
	case to == task.StatusQueued && from == task.StatusAIReview:
		sets = append(sets, "rework_count = rework_count + 1")
	case to == task.StatusQueued:
		sets = append(sets, "rework_count = 0")
	case to == task.StatusDone || to == task.StatusCancelled || to == task.StatusFailed:
		sets = append(sets, "rework_count = 0")
	}

	args = append(args, id, string(from))

	q := "UPDATE tasks SET " + strings.Join(sets, ", ") + " WHERE id = ? AND status = ?"
	res, err := s.db.write.ExecContext(ctx, q, args...)
	if err != nil {
		return fmt.Errorf("task: transition: %w", err)
	}
	n, _ := res.RowsAffected()
	if n == 0 {
		return ErrStaleUpdate
	}
	return nil
}

// SetBranchExists updates the branch_exists flag (external deletion
// detection). A value of false means the task's branch has been removed
// outside the app.
func (s *TaskStore) SetBranchExists(ctx context.Context, id string, exists bool) error {
	v := 0
	if exists {
		v = 1
	}
	_, err := s.db.write.ExecContext(ctx,
		`UPDATE tasks SET branch_exists = ?, updated_at = ? WHERE id = ?`,
		v, nowUTC(), id)
	return err
}

// Delete removes a task row (and cascades to its events).
func (s *TaskStore) Delete(ctx context.Context, id string) error {
	_, err := s.db.write.ExecContext(ctx, `DELETE FROM tasks WHERE id = ?`, id)
	return err
}

// RecoverRunning demotes any tasks left in StatusInProgress (from a crash) to
// StatusFailed with ErrCodeInterrupted. Called once at startup. Returns the
// IDs of the recovered tasks so the caller can reap their worktrees.
//
// The whole operation runs in a single BEGIN IMMEDIATE transaction on the
// serialized write handle so that SELECT + UPDATE see a consistent snapshot
// even if the orchestrator has already begun accepting enqueues.
func (s *TaskStore) RecoverRunning(ctx context.Context) ([]string, error) {
	now := nowUTC()
	tx, err := s.db.write.BeginTx(ctx, nil)
	if err != nil {
		return nil, fmt.Errorf("task: recover begin: %w", err)
	}
	defer func() { _ = tx.Rollback() }()

	rows, err := tx.QueryContext(ctx,
		`SELECT id FROM tasks WHERE status = ?`, string(task.StatusInProgress))
	if err != nil {
		return nil, fmt.Errorf("task: recover query: %w", err)
	}
	var ids []string
	for rows.Next() {
		var id string
		if err := rows.Scan(&id); err != nil {
			_ = rows.Close()
			return nil, err
		}
		ids = append(ids, id)
	}
	_ = rows.Close()
	if err := rows.Err(); err != nil {
		return nil, err
	}

	for _, id := range ids {
		res, err := tx.ExecContext(ctx, `
UPDATE tasks SET
    status = ?,
    error_code = ?,
    error_message = ?,
    finished_at = ?,
    updated_at = ?
WHERE id = ? AND status = ?`,
			string(task.StatusFailed), string(task.ErrCodeInterrupted),
			"recovered from interrupted session",
			now, now, id, string(task.StatusInProgress),
		)
		if err != nil {
			return nil, fmt.Errorf("task: recover update %s: %w", id, err)
		}
		n, _ := res.RowsAffected()
		if n == 0 {
			return nil, fmt.Errorf("task: recover update %s: no rows affected", id)
		}
	}
	if err := tx.Commit(); err != nil {
		return nil, fmt.Errorf("task: recover commit: %w", err)
	}
	return ids, nil
}

const selectTaskColumns = `
SELECT id, repository_id, goal, base_branch, branch, worktree_path,
       branch_exists, model, plan_model, review_model,
       status, finalization, error_code, error_message, session_id,
       review_feedback, rework_count, created_at, updated_at, started_at, finished_at
  FROM tasks`

func scanTask(sc scanner) (*task.Task, error) {
	var (
		t              task.Task
		branchExists   int
		status         string
		finalization   string
		errorCode      string
		reviewFeedback string
		createdAt      string
		updatedAt      string
		startedAt      sql.NullString
		finishedAt     sql.NullString
		branch         sql.NullString
		worktree       sql.NullString
	)
	err := sc.Scan(
		&t.ID, &t.RepoID, &t.Goal, &t.BaseBranch, &branch, &worktree,
		&branchExists, &t.Model, &t.PlanModel, &t.ReviewModel,
		&status, &finalization, &errorCode, &t.ErrorMessage, &t.SessionID,
		&reviewFeedback, &t.ReworkCount, &createdAt, &updatedAt, &startedAt, &finishedAt,
	)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, fmt.Errorf("task: scan: %w", err)
	}
	if branch.Valid {
		t.Branch = branch.String
	}
	if worktree.Valid {
		t.WorktreePath = worktree.String
	}
	t.Status = task.Status(status)
	t.Finalization = task.FinalizationKind(finalization)
	t.ErrorCode = task.ErrorCode(errorCode)
	t.ReviewFeedback = reviewFeedback
	t.BranchExists = branchExists != 0

	ct, err := parseTime(createdAt)
	if err != nil {
		return nil, fmt.Errorf("task: parse created_at: %w", err)
	}
	t.CreatedAt = ct

	ut, err := parseTime(updatedAt)
	if err != nil {
		return nil, fmt.Errorf("task: parse updated_at: %w", err)
	}
	t.UpdatedAt = ut

	t.StartedAt, err = scanNullableTime(startedAt)
	if err != nil {
		return nil, fmt.Errorf("task: parse started_at: %w", err)
	}
	t.FinishedAt, err = scanNullableTime(finishedAt)
	if err != nil {
		return nil, fmt.Errorf("task: parse finished_at: %w", err)
	}
	return &t, nil
}
