//go:build windows

package store

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"time"
)

// HarnessAttempt mirrors the harness_attempt table row (migration v15).
// Decision is one of: pending | approved | rejected | superseded.
// ProposedPatch is intentionally empty in Phase C; LLM patch generation is
// wired in the subsequent Phase C LLM integration step.
type HarnessAttempt struct {
	ID            string
	TaskID        string
	ReworkRound   int32
	FailureClass  string
	ObservationMD string
	ProposedPatch string
	ProposedHash  string
	Decision      string
	DecidedBy     string
	DecidedAt     *time.Time
	CreatedAt     time.Time
}

// HarnessAttemptStore provides CRUD over harness_attempt rows.
type HarnessAttemptStore struct{ db *DB }

// NewHarnessAttemptStore wraps a DB with harness-attempt-specific helpers.
func NewHarnessAttemptStore(db *DB) *HarnessAttemptStore {
	return &HarnessAttemptStore{db: db}
}

// ErrHarnessAttemptNotFound is returned by Get when no row matches the ID.
var ErrHarnessAttemptNotFound = errors.New("store: harness attempt not found")

// ErrAlreadyDecided is returned by UpdateDecision when the row is no longer pending.
var ErrAlreadyDecided = errors.New("store: harness attempt already decided")

// Insert writes a new harness_attempt row. The caller must supply a unique
// ULID in a.ID; decision is forced to "pending" regardless of the value
// passed. CreatedAt defaults to time.Now().UTC() when zero.
func (s *HarnessAttemptStore) Insert(ctx context.Context, a HarnessAttempt) error {
	if a.ID == "" || a.TaskID == "" {
		return fmt.Errorf("harness_attempt: id and task_id are required")
	}
	if a.CreatedAt.IsZero() {
		a.CreatedAt = time.Now().UTC()
	}
	_, err := s.db.write.ExecContext(ctx, `
INSERT INTO harness_attempt(
    id, task_id, rework_round, failure_class, observation_md,
    proposed_patch, proposed_hash, decision, decided_by, decided_at, created_at
) VALUES (?, ?, ?, ?, ?, ?, ?, 'pending', '', NULL, ?)`,
		a.ID, a.TaskID, a.ReworkRound, a.FailureClass, a.ObservationMD,
		a.ProposedPatch, a.ProposedHash, formatTime(a.CreatedAt))
	if err != nil {
		return fmt.Errorf("harness_attempt: insert: %w", err)
	}
	return nil
}

// Get returns a single harness attempt by ID.
// Returns ErrHarnessAttemptNotFound when no such row exists.
func (s *HarnessAttemptStore) Get(ctx context.Context, id string) (HarnessAttempt, error) {
	row := s.db.read.QueryRowContext(ctx, `
SELECT id, task_id, rework_round, failure_class, observation_md,
       proposed_patch, proposed_hash, decision,
       COALESCE(decided_by,''), decided_at, created_at
  FROM harness_attempt
 WHERE id = ?`, id)
	a, err := scanAttempt(row)
	if errors.Is(err, sql.ErrNoRows) {
		return HarnessAttempt{}, ErrHarnessAttemptNotFound
	}
	if err != nil {
		return HarnessAttempt{}, fmt.Errorf("harness_attempt: get: %w", err)
	}
	return a, nil
}

// ListPending returns up to limit attempts with decision='pending', newest first.
// limit <= 0 is treated as unbounded.
func (s *HarnessAttemptStore) ListPending(ctx context.Context, limit int) ([]HarnessAttempt, error) {
	q := `
SELECT id, task_id, rework_round, failure_class, observation_md,
       proposed_patch, proposed_hash, decision,
       COALESCE(decided_by,''), decided_at, created_at
  FROM harness_attempt
 WHERE decision = 'pending'
 ORDER BY created_at DESC, id DESC`
	if limit > 0 {
		q += fmt.Sprintf(` LIMIT %d`, limit)
	}
	return s.queryAttempts(ctx, q)
}

// ListForTask returns up to limit attempts for a task, newest first.
// limit <= 0 is treated as unbounded.
func (s *HarnessAttemptStore) ListForTask(ctx context.Context, taskID string, limit int) ([]HarnessAttempt, error) {
	q := `
SELECT id, task_id, rework_round, failure_class, observation_md,
       proposed_patch, proposed_hash, decision,
       COALESCE(decided_by,''), decided_at, created_at
  FROM harness_attempt
 WHERE task_id = ?
 ORDER BY created_at DESC, id DESC`
	if limit > 0 {
		q += fmt.Sprintf(` LIMIT %d`, limit)
	}
	rows, err := s.db.read.QueryContext(ctx, q, taskID)
	if err != nil {
		return nil, fmt.Errorf("harness_attempt: list for task: %w", err)
	}
	defer rows.Close()

	var out []HarnessAttempt
	for rows.Next() {
		a, err := scanAttempt(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, a)
	}
	return out, rows.Err()
}

// UpdateProposedPatch fills the LLM-generated unified diff on a pending
// row. Leaves the row pending — user approval flips it to 'approved'.
// Returns ErrAlreadyDecided when the row is no longer 'pending' (a user
// may have rejected/approved between Insert and the async Evolver
// finishing its generation). Returns ErrHarnessAttemptNotFound when no
// row matches id.
func (s *HarnessAttemptStore) UpdateProposedPatch(ctx context.Context, id, patch, patchHash string) error {
	if id == "" {
		return fmt.Errorf("harness_attempt: id is required")
	}
	res, err := s.db.write.ExecContext(ctx, `
UPDATE harness_attempt
   SET proposed_patch = ?,
       proposed_hash  = ?
 WHERE id = ? AND decision = 'pending'`,
		patch, patchHash, id)
	if err != nil {
		return fmt.Errorf("harness_attempt: update proposed patch: %w", err)
	}
	n, err := res.RowsAffected()
	if err != nil {
		return fmt.Errorf("harness_attempt: rows affected: %w", err)
	}
	if n == 0 {
		// Distinguish missing vs already-decided with a secondary read.
		if _, getErr := s.Get(ctx, id); errors.Is(getErr, ErrHarnessAttemptNotFound) {
			return ErrHarnessAttemptNotFound
		} else if getErr != nil {
			return fmt.Errorf("harness_attempt: lookup after no-op update: %w", getErr)
		}
		return ErrAlreadyDecided
	}
	return nil
}

// UpdateDecision transitions a pending attempt to the given decision and
// records the deciding principal. Returns the updated row.
// Returns ErrAlreadyDecided if the row is not currently 'pending'.
// Returns ErrHarnessAttemptNotFound if no row matches id.
func (s *HarnessAttemptStore) UpdateDecision(ctx context.Context, id, decision, decidedBy string) (HarnessAttempt, error) {
	now := time.Now().UTC()
	res, err := s.db.write.ExecContext(ctx, `
UPDATE harness_attempt
   SET decision   = ?,
       decided_by = ?,
       decided_at = ?
 WHERE id = ? AND decision = 'pending'`,
		decision, decidedBy, formatTime(now), id)
	if err != nil {
		return HarnessAttempt{}, fmt.Errorf("harness_attempt: update decision: %w", err)
	}

	n, err := res.RowsAffected()
	if err != nil {
		return HarnessAttempt{}, fmt.Errorf("harness_attempt: rows affected: %w", err)
	}
	if n == 0 {
		// Either the row doesn't exist or it is already decided.
		// Distinguish the two cases with a secondary read.
		existing, getErr := s.Get(ctx, id)
		if errors.Is(getErr, ErrHarnessAttemptNotFound) {
			return HarnessAttempt{}, ErrHarnessAttemptNotFound
		}
		if getErr != nil {
			return HarnessAttempt{}, fmt.Errorf("harness_attempt: lookup after no-op update: %w", getErr)
		}
		// Row exists but decision != 'pending'.
		_ = existing
		return HarnessAttempt{}, ErrAlreadyDecided
	}

	return s.Get(ctx, id)
}

// ── helpers ──────────────────────────────────────────────────────────────────

// queryAttempts executes a SELECT that returns harness_attempt columns and
// scans all rows into a slice.
func (s *HarnessAttemptStore) queryAttempts(ctx context.Context, q string) ([]HarnessAttempt, error) {
	rows, err := s.db.read.QueryContext(ctx, q)
	if err != nil {
		return nil, fmt.Errorf("harness_attempt: query: %w", err)
	}
	defer rows.Close()

	var out []HarnessAttempt
	for rows.Next() {
		a, err := scanAttempt(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, a)
	}
	return out, rows.Err()
}

func scanAttempt(s scanner) (HarnessAttempt, error) {
	var (
		a         HarnessAttempt
		decidedAt sql.NullString
		createdAt string
	)
	if err := s.Scan(
		&a.ID, &a.TaskID, &a.ReworkRound, &a.FailureClass, &a.ObservationMD,
		&a.ProposedPatch, &a.ProposedHash, &a.Decision,
		&a.DecidedBy, &decidedAt, &createdAt,
	); err != nil {
		return HarnessAttempt{}, err
	}
	t, err := parseTime(createdAt)
	if err != nil {
		return HarnessAttempt{}, fmt.Errorf("harness_attempt: parse created_at: %w", err)
	}
	a.CreatedAt = t

	dt, err := scanNullableTime(decidedAt)
	if err != nil {
		return HarnessAttempt{}, fmt.Errorf("harness_attempt: parse decided_at: %w", err)
	}
	a.DecidedAt = dt
	return a, nil
}
