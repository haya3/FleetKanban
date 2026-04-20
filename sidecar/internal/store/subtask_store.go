package store

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"

	"github.com/FleetKanban/fleetkanban/internal/task"
)

// SubtaskStore persists task.Subtask rows. Same read/write split as TaskStore.
type SubtaskStore struct{ db *DB }

// NewSubtaskStore wraps a DB with subtask-specific helpers.
func NewSubtaskStore(db *DB) *SubtaskStore { return &SubtaskStore{db: db} }

// Create inserts a new subtask row. OrderIdx is honored as-is; callers
// wanting "append at end" semantics should look up the current max and
// pass max+1 (see App service).
func (s *SubtaskStore) Create(ctx context.Context, sub *task.Subtask) error {
	if err := sub.Validate(); err != nil {
		return err
	}
	now := nowUTC()
	created := formatTime(sub.CreatedAt)
	if created == "" {
		created = now
	}
	deps, err := encodeDeps(sub.DependsOn)
	if err != nil {
		return err
	}
	_, err = s.db.write.ExecContext(ctx, `
INSERT INTO subtasks(
    id, task_id, title, agent_role, depends_on, status, order_idx,
    code_model, created_at, updated_at
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
		sub.ID, sub.TaskID, sub.Title, sub.AgentRole, deps,
		string(sub.Status), sub.OrderIdx, sub.CodeModel, created, now,
	)
	if err != nil {
		return fmt.Errorf("subtask: insert: %w", err)
	}
	return nil
}

// ListByTask returns every subtask belonging to parentID, ordered by
// order_idx ascending (created_at as tiebreaker).
func (s *SubtaskStore) ListByTask(ctx context.Context, parentID string) ([]*task.Subtask, error) {
	rows, err := s.db.read.QueryContext(ctx, `
SELECT id, task_id, title, agent_role, depends_on, status, order_idx,
       code_model, created_at, updated_at
  FROM subtasks
 WHERE task_id = ?
 ORDER BY order_idx ASC, created_at ASC`, parentID)
	if err != nil {
		return nil, fmt.Errorf("subtask: list: %w", err)
	}
	defer rows.Close()

	var out []*task.Subtask
	for rows.Next() {
		sub, err := scanSubtask(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, sub)
	}
	return out, rows.Err()
}

// Get loads a subtask by ID.
func (s *SubtaskStore) Get(ctx context.Context, id string) (*task.Subtask, error) {
	row := s.db.read.QueryRowContext(ctx, `
SELECT id, task_id, title, agent_role, depends_on, status, order_idx,
       code_model, created_at, updated_at
  FROM subtasks WHERE id = ?`, id)
	return scanSubtask(row)
}

// Update overwrites the mutable fields of an existing subtask.
func (s *SubtaskStore) Update(ctx context.Context, sub *task.Subtask) error {
	if err := sub.Validate(); err != nil {
		return err
	}
	deps, err := encodeDeps(sub.DependsOn)
	if err != nil {
		return err
	}
	res, err := s.db.write.ExecContext(ctx, `
UPDATE subtasks SET
    title      = ?,
    agent_role = ?,
    depends_on = ?,
    status     = ?,
    order_idx  = ?,
    code_model = ?,
    updated_at = ?
WHERE id = ?`,
		sub.Title, sub.AgentRole, deps, string(sub.Status),
		sub.OrderIdx, sub.CodeModel, nowUTC(), sub.ID)
	if err != nil {
		return fmt.Errorf("subtask: update: %w", err)
	}
	n, _ := res.RowsAffected()
	if n == 0 {
		return ErrNotFound
	}
	return nil
}

// Delete removes a subtask row.
func (s *SubtaskStore) Delete(ctx context.Context, id string) error {
	res, err := s.db.write.ExecContext(ctx,
		`DELETE FROM subtasks WHERE id = ?`, id)
	if err != nil {
		return fmt.Errorf("subtask: delete: %w", err)
	}
	n, _ := res.RowsAffected()
	if n == 0 {
		return ErrNotFound
	}
	return nil
}

// Reorder sets order_idx for each given subtask id as its position in the
// slice (0-based). Runs inside a single transaction so the UI either sees
// the new ordering in full or not at all. Rejects ids that don't belong to
// parentID, preventing cross-task shuffles from a compromised client.
func (s *SubtaskStore) Reorder(ctx context.Context, parentID string, ids []string) error {
	if parentID == "" {
		return errors.New("subtask: reorder: task_id is required")
	}
	tx, err := s.db.write.BeginTx(ctx, nil)
	if err != nil {
		return fmt.Errorf("subtask: reorder begin: %w", err)
	}
	defer func() { _ = tx.Rollback() }()

	now := nowUTC()
	for i, id := range ids {
		res, err := tx.ExecContext(ctx, `
UPDATE subtasks SET order_idx = ?, updated_at = ?
 WHERE id = ? AND task_id = ?`, i, now, id, parentID)
		if err != nil {
			return fmt.Errorf("subtask: reorder %s: %w", id, err)
		}
		n, _ := res.RowsAffected()
		if n == 0 {
			return fmt.Errorf("subtask: reorder: %s not found under task %s", id, parentID)
		}
	}
	return tx.Commit()
}

// CreatePlan atomically replaces the plan for parentID with subs. Existing
// subtasks under the parent are deleted first so the planner can be retried
// without accumulating stale nodes; all inserts then run inside one tx so
// a partial plan never becomes visible.
//
// CreatedAt on each Subtask is honoured when non-zero; otherwise the tx
// timestamp is used. IDs must already be assigned (callers generate ULIDs
// before emitting the DAG so depends_on references can point at siblings).
func (s *SubtaskStore) CreatePlan(ctx context.Context, parentID string, subs []*task.Subtask) error {
	if parentID == "" {
		return errors.New("subtask: CreatePlan: parent task id is required")
	}
	for _, sub := range subs {
		if sub.TaskID != parentID {
			return fmt.Errorf("subtask: CreatePlan: subtask %s belongs to %s, not %s",
				sub.ID, sub.TaskID, parentID)
		}
		if err := sub.Validate(); err != nil {
			return err
		}
	}

	tx, err := s.db.write.BeginTx(ctx, nil)
	if err != nil {
		return fmt.Errorf("subtask: CreatePlan begin: %w", err)
	}
	defer func() { _ = tx.Rollback() }()

	if _, err := tx.ExecContext(ctx,
		`DELETE FROM subtasks WHERE task_id = ?`, parentID); err != nil {
		return fmt.Errorf("subtask: CreatePlan clear: %w", err)
	}

	now := nowUTC()
	stmt, err := tx.PrepareContext(ctx, `
INSERT INTO subtasks(
    id, task_id, title, agent_role, depends_on, status, order_idx,
    code_model, created_at, updated_at
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`)
	if err != nil {
		return fmt.Errorf("subtask: CreatePlan prepare: %w", err)
	}
	defer stmt.Close()

	for _, sub := range subs {
		deps, err := encodeDeps(sub.DependsOn)
		if err != nil {
			return err
		}
		created := formatTime(sub.CreatedAt)
		if created == "" {
			created = now
		}
		if _, err := stmt.ExecContext(ctx,
			sub.ID, sub.TaskID, sub.Title, sub.AgentRole, deps,
			string(sub.Status), sub.OrderIdx, sub.CodeModel, created, now,
		); err != nil {
			return fmt.Errorf("subtask: CreatePlan insert %s: %w", sub.ID, err)
		}
	}
	return tx.Commit()
}

// MaxOrderIdx returns the maximum order_idx for a parent task, or -1 if no
// subtasks exist. Used by CreateSubtask's "append at end" behavior.
func (s *SubtaskStore) MaxOrderIdx(ctx context.Context, parentID string) (int, error) {
	row := s.db.read.QueryRowContext(ctx,
		`SELECT COALESCE(MAX(order_idx), -1) FROM subtasks WHERE task_id = ?`, parentID)
	var v int
	if err := row.Scan(&v); err != nil {
		return 0, fmt.Errorf("subtask: max order: %w", err)
	}
	return v, nil
}

func scanSubtask(sc scanner) (*task.Subtask, error) {
	var (
		sub       task.Subtask
		deps      string
		status    string
		createdAt string
		updatedAt string
	)
	err := sc.Scan(&sub.ID, &sub.TaskID, &sub.Title, &sub.AgentRole,
		&deps, &status, &sub.OrderIdx, &sub.CodeModel, &createdAt, &updatedAt)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, fmt.Errorf("subtask: scan: %w", err)
	}
	sub.Status = task.SubtaskStatus(status)
	if sub.DependsOn, err = decodeDeps(deps); err != nil {
		return nil, fmt.Errorf("subtask: scan depends_on: %w", err)
	}
	if ct, perr := parseTime(createdAt); perr == nil {
		sub.CreatedAt = ct
	}
	if ut, perr := parseTime(updatedAt); perr == nil {
		sub.UpdatedAt = ut
	}
	return &sub, nil
}

// encodeDeps serialises a dependency list as a JSON array. A nil/empty slice
// becomes "[]" so the stored value is never NULL and the schema can enforce
// NOT NULL on depends_on.
func encodeDeps(deps []string) (string, error) {
	if len(deps) == 0 {
		return "[]", nil
	}
	b, err := json.Marshal(deps)
	if err != nil {
		return "", fmt.Errorf("subtask: encode depends_on: %w", err)
	}
	return string(b), nil
}

// decodeDeps parses a JSON-encoded dependency list. The empty string and
// "[]" both decode to nil (no dependencies).
func decodeDeps(raw string) ([]string, error) {
	if raw == "" || raw == "[]" {
		return nil, nil
	}
	var out []string
	if err := json.Unmarshal([]byte(raw), &out); err != nil {
		return nil, err
	}
	return out, nil
}
