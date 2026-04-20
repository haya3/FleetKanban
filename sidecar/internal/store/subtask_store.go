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
// pass max+1 (see App service). Round defaults to 1 when not set.
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
	round := sub.Round
	if round <= 0 {
		round = 1
	}
	_, err = s.db.write.ExecContext(ctx, `
INSERT INTO subtasks(
    id, task_id, title, agent_role, depends_on, status, order_idx,
    code_model, round, prompt, created_at, updated_at
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
		sub.ID, sub.TaskID, sub.Title, sub.AgentRole, deps,
		string(sub.Status), sub.OrderIdx, sub.CodeModel, round, sub.Prompt, created, now,
	)
	if err != nil {
		return fmt.Errorf("subtask: insert: %w", err)
	}
	return nil
}

// ListByTask returns every subtask belonging to parentID across all
// rounds, ordered by round then order_idx. The UI uses this to render
// the iteration history; the orchestrator should use ListLatestRound
// to drive execution so older rounds aren't re-run.
func (s *SubtaskStore) ListByTask(ctx context.Context, parentID string) ([]*task.Subtask, error) {
	rows, err := s.db.read.QueryContext(ctx, `
SELECT id, task_id, title, agent_role, depends_on, status, order_idx,
       code_model, round, prompt, created_at, updated_at
  FROM subtasks
 WHERE task_id = ?
 ORDER BY round ASC, order_idx ASC, created_at ASC`, parentID)
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

// ListLatestRound returns subtasks belonging to the maximum round of
// parentID. Used by the orchestrator's runSubtaskLoop so each
// rework cycle only re-runs the freshly-planned subtasks instead of
// looping over every past round's history. Returns nil (not an error)
// when the parent has no subtasks at all.
func (s *SubtaskStore) ListLatestRound(ctx context.Context, parentID string) ([]*task.Subtask, error) {
	rows, err := s.db.read.QueryContext(ctx, `
SELECT id, task_id, title, agent_role, depends_on, status, order_idx,
       code_model, round, prompt, created_at, updated_at
  FROM subtasks
 WHERE task_id = ?
   AND round = (SELECT COALESCE(MAX(round), 0) FROM subtasks WHERE task_id = ?)
 ORDER BY order_idx ASC, created_at ASC`, parentID, parentID)
	if err != nil {
		return nil, fmt.Errorf("subtask: list latest round: %w", err)
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

// MaxRound returns the highest round number recorded for parentID, or
// 0 when no subtasks exist. Callers that want the next round number
// use MaxRound+1.
func (s *SubtaskStore) MaxRound(ctx context.Context, parentID string) (int, error) {
	row := s.db.read.QueryRowContext(ctx,
		`SELECT COALESCE(MAX(round), 0) FROM subtasks WHERE task_id = ?`, parentID)
	var v int
	if err := row.Scan(&v); err != nil {
		return 0, fmt.Errorf("subtask: max round: %w", err)
	}
	return v, nil
}

// Get loads a subtask by ID.
func (s *SubtaskStore) Get(ctx context.Context, id string) (*task.Subtask, error) {
	row := s.db.read.QueryRowContext(ctx, `
SELECT id, task_id, title, agent_role, depends_on, status, order_idx,
       code_model, round, prompt, created_at, updated_at
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
    prompt     = ?,
    updated_at = ?
WHERE id = ?`,
		sub.Title, sub.AgentRole, deps, string(sub.Status),
		sub.OrderIdx, sub.CodeModel, sub.Prompt, nowUTC(), sub.ID)
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

// CreatePlan atomically inserts a new round of subtasks for parentID.
// Round numbers are auto-assigned as MaxRound(parentID)+1 so previous
// rounds remain intact for history (the UI stacks them visually). All
// inserts run inside one tx so a partial plan never becomes visible.
//
// CreatedAt on each Subtask is honoured when non-zero; otherwise the tx
// timestamp is used. IDs must already be assigned (callers generate ULIDs
// before emitting the DAG so depends_on references can point at siblings).
//
// Returns the round number that was used so callers can correlate the
// new subtasks with the planning event they just emitted.
func (s *SubtaskStore) CreatePlan(ctx context.Context, parentID string, subs []*task.Subtask) (int, error) {
	if parentID == "" {
		return 0, errors.New("subtask: CreatePlan: parent task id is required")
	}
	for _, sub := range subs {
		if sub.TaskID != parentID {
			return 0, fmt.Errorf("subtask: CreatePlan: subtask %s belongs to %s, not %s",
				sub.ID, sub.TaskID, parentID)
		}
		if err := sub.Validate(); err != nil {
			return 0, err
		}
	}

	tx, err := s.db.write.BeginTx(ctx, nil)
	if err != nil {
		return 0, fmt.Errorf("subtask: CreatePlan begin: %w", err)
	}
	defer func() { _ = tx.Rollback() }()

	// Read max round inside the transaction so concurrent CreatePlan
	// calls (shouldn't happen — orchestrator dispatches per-task — but
	// be safe) get distinct round numbers.
	var maxRound int
	if err := tx.QueryRowContext(ctx,
		`SELECT COALESCE(MAX(round), 0) FROM subtasks WHERE task_id = ?`,
		parentID).Scan(&maxRound); err != nil {
		return 0, fmt.Errorf("subtask: CreatePlan max round: %w", err)
	}
	round := maxRound + 1

	now := nowUTC()
	stmt, err := tx.PrepareContext(ctx, `
INSERT INTO subtasks(
    id, task_id, title, agent_role, depends_on, status, order_idx,
    code_model, round, prompt, created_at, updated_at
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`)
	if err != nil {
		return 0, fmt.Errorf("subtask: CreatePlan prepare: %w", err)
	}
	defer stmt.Close()

	for _, sub := range subs {
		deps, err := encodeDeps(sub.DependsOn)
		if err != nil {
			return 0, err
		}
		created := formatTime(sub.CreatedAt)
		if created == "" {
			created = now
		}
		// Stamp the round on the in-memory struct so callers can
		// reflect it on subsequent Update writes (status flips
		// during execution).
		sub.Round = round
		if _, err := stmt.ExecContext(ctx,
			sub.ID, sub.TaskID, sub.Title, sub.AgentRole, deps,
			string(sub.Status), sub.OrderIdx, sub.CodeModel, round, sub.Prompt, created, now,
		); err != nil {
			return 0, fmt.Errorf("subtask: CreatePlan insert %s: %w", sub.ID, err)
		}
	}
	if err := tx.Commit(); err != nil {
		return 0, fmt.Errorf("subtask: CreatePlan commit: %w", err)
	}
	return round, nil
}

// DeleteByTask removes every subtask belonging to parentID across all
// rounds. Currently unused in the orchestrator (rework now creates a
// new round instead of wiping), but kept for cascade-from-task
// deletion paths and tests.
func (s *SubtaskStore) DeleteByTask(ctx context.Context, parentID string) (int64, error) {
	res, err := s.db.write.ExecContext(ctx,
		`DELETE FROM subtasks WHERE task_id = ?`, parentID)
	if err != nil {
		return 0, fmt.Errorf("subtask: delete by task: %w", err)
	}
	n, _ := res.RowsAffected()
	return n, nil
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
		&deps, &status, &sub.OrderIdx, &sub.CodeModel, &sub.Round, &sub.Prompt, &createdAt, &updatedAt)
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
