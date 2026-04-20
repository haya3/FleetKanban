package store

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/FleetKanban/fleetkanban/internal/task"
)

// EventStore persists AgentEvent rows. Events are append-only; there are no
// mutation APIs beyond task cascade-delete.
type EventStore struct{ db *DB }

// NewEventStore wraps a DB with event-specific helpers.
func NewEventStore(db *DB) *EventStore { return &EventStore{db: db} }

// Append inserts a single event. Callers must set Seq (per-task monotonic);
// a UNIQUE(task_id, seq) violation is returned as ErrDuplicateSeq so the
// caller can recover by re-querying the next seq.
func (s *EventStore) Append(ctx context.Context, e *task.AgentEvent) error {
	if err := e.Validate(); err != nil {
		return err
	}
	_, err := s.db.write.ExecContext(ctx, `
INSERT INTO events(id, task_id, seq, occurred_at, kind, payload)
VALUES (?, ?, ?, ?, ?, ?)`,
		e.ID, e.TaskID, e.Seq, formatTime(e.OccurredAt), string(e.Kind), e.Payload)
	if err != nil {
		if isUniqueViolation(err) {
			return ErrDuplicateSeq
		}
		return fmt.Errorf("event: insert: %w", err)
	}
	return nil
}

// ErrDuplicateSeq is returned on UNIQUE(task_id, seq) collisions.
var ErrDuplicateSeq = errors.New("store: duplicate event seq for task")

// AppendAutoSeq inserts a single event with seq assigned atomically as
// MAX(seq)+1 for the task, inside a single write transaction. Used by
// out-of-band emitters (orchestrator status events, review.submitted
// events from the service layer) that cannot safely reuse the runner's
// cached NextSeq counter because they may race with an in-flight
// consumer goroutine. Mutates e.Seq so the caller sees the assigned value.
//
// The event's ID / TaskID / Kind fields must be populated by the caller;
// OccurredAt is set to time.Now().UTC() if zero.
func (s *EventStore) AppendAutoSeq(ctx context.Context, e *task.AgentEvent) error {
	if e.TaskID == "" {
		return fmt.Errorf("event: AppendAutoSeq: TaskID required")
	}
	if e.OccurredAt.IsZero() {
		e.OccurredAt = time.Now().UTC()
	}
	tx, err := s.db.write.BeginTx(ctx, nil)
	if err != nil {
		return fmt.Errorf("event: AppendAutoSeq begin: %w", err)
	}
	defer func() { _ = tx.Rollback() }()

	var maxSeq sql.NullInt64
	if err := tx.QueryRowContext(ctx,
		`SELECT MAX(seq) FROM events WHERE task_id = ?`, e.TaskID).Scan(&maxSeq); err != nil {
		return fmt.Errorf("event: AppendAutoSeq max: %w", err)
	}
	if maxSeq.Valid {
		e.Seq = maxSeq.Int64 + 1
	} else {
		e.Seq = 1
	}
	if err := e.Validate(); err != nil {
		return err
	}
	if _, err := tx.ExecContext(ctx, `
INSERT INTO events(id, task_id, seq, occurred_at, kind, payload)
VALUES (?, ?, ?, ?, ?, ?)`,
		e.ID, e.TaskID, e.Seq, formatTime(e.OccurredAt), string(e.Kind), e.Payload); err != nil {
		if isUniqueViolation(err) {
			return ErrDuplicateSeq
		}
		return fmt.Errorf("event: AppendAutoSeq insert: %w", err)
	}
	return tx.Commit()
}

// appendBatchChunkSize is the maximum number of events bundled into one
// compound INSERT. SQLite's default SQLITE_MAX_VARIABLE_NUMBER is 32766;
// at 6 params per row this caps at ~5461 rows, but we stay well below that
// to leave headroom for future column additions and keep each statement
// compile time bounded.
const appendBatchChunkSize = 1000

// AppendBatch inserts events within a single transaction. Used by the
// streaming loop which buffers assistant.delta events every ~100ms
// (phase1-spec §3.4). On any failure the entire transaction rolls back —
// partial chunks are not visible to readers.
func (s *EventStore) AppendBatch(ctx context.Context, events []*task.AgentEvent) error {
	if len(events) == 0 {
		return nil
	}
	for _, e := range events {
		if err := e.Validate(); err != nil {
			return err
		}
	}
	tx, err := s.db.write.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer func() { _ = tx.Rollback() }()

	for start := 0; start < len(events); start += appendBatchChunkSize {
		end := min(start+appendBatchChunkSize, len(events))
		if err := appendChunk(ctx, tx, events[start:end]); err != nil {
			return err
		}
	}
	return tx.Commit()
}

// appendChunk builds a single compound INSERT covering one chunk of events.
func appendChunk(ctx context.Context, tx interface {
	ExecContext(ctx context.Context, query string, args ...any) (sql.Result, error)
}, events []*task.AgentEvent) error {
	const cols = 6
	var (
		sb   strings.Builder
		args = make([]any, 0, len(events)*cols)
	)
	sb.WriteString("INSERT INTO events(id, task_id, seq, occurred_at, kind, payload) VALUES ")
	for i, e := range events {
		if i > 0 {
			sb.WriteByte(',')
		}
		sb.WriteString("(?, ?, ?, ?, ?, ?)")
		args = append(args,
			e.ID, e.TaskID, e.Seq, formatTime(e.OccurredAt), string(e.Kind), e.Payload)
	}
	if _, err := tx.ExecContext(ctx, sb.String(), args...); err != nil {
		if isUniqueViolation(err) {
			return ErrDuplicateSeq
		}
		return fmt.Errorf("event: batch insert: %w", err)
	}
	return nil
}

// NextSeq returns the next seq number for a task. The store does not persist
// an in-memory counter — Phase 1 allocates sequentially by querying MAX(seq)
// on demand; the orchestrator is expected to cache it per task.
func (s *EventStore) NextSeq(ctx context.Context, taskID string) (int64, error) {
	var maxSeq sql.NullInt64
	err := s.db.read.QueryRowContext(ctx,
		`SELECT MAX(seq) FROM events WHERE task_id = ?`, taskID).Scan(&maxSeq)
	if err != nil {
		return 0, fmt.Errorf("event: next seq: %w", err)
	}
	if !maxSeq.Valid {
		return 1, nil
	}
	return maxSeq.Int64 + 1, nil
}

// ListByTask returns all events for a task ordered by seq.
// sinceSeq (exclusive) is useful for tail-streaming to late-attaching clients;
// pass 0 to get every event.
func (s *EventStore) ListByTask(ctx context.Context, taskID string, sinceSeq int64, limit int) ([]*task.AgentEvent, error) {
	q := `SELECT id, task_id, seq, occurred_at, kind, payload
            FROM events WHERE task_id = ? AND seq > ?
            ORDER BY seq ASC`
	args := []any{taskID, sinceSeq}
	if limit > 0 {
		q += fmt.Sprintf(" LIMIT %d", limit)
	}
	rows, err := s.db.read.QueryContext(ctx, q, args...)
	if err != nil {
		return nil, fmt.Errorf("event: list: %w", err)
	}
	defer rows.Close()

	var out []*task.AgentEvent
	for rows.Next() {
		var (
			ev task.AgentEvent
			ts string
			k  string
		)
		if err := rows.Scan(&ev.ID, &ev.TaskID, &ev.Seq, &ts, &k, &ev.Payload); err != nil {
			return nil, err
		}
		t, err := parseTime(ts)
		if err != nil {
			return nil, fmt.Errorf("event: parse occurred_at: %w", err)
		}
		ev.OccurredAt = t
		ev.Kind = task.EventKind(k)
		out = append(out, &ev)
	}
	return out, rows.Err()
}

// CountByTask returns the total number of events persisted for a task.
func (s *EventStore) CountByTask(ctx context.Context, taskID string) (int64, error) {
	var n int64
	err := s.db.read.QueryRowContext(ctx,
		`SELECT COUNT(*) FROM events WHERE task_id = ?`, taskID).Scan(&n)
	return n, err
}

// DeleteByTask removes every event belonging to taskID. Returns the number
// of rows deleted. Used by the archiver after a successful gzip write.
func (s *EventStore) DeleteByTask(ctx context.Context, taskID string) (int64, error) {
	res, err := s.db.write.ExecContext(ctx, `DELETE FROM events WHERE task_id = ?`, taskID)
	if err != nil {
		return 0, fmt.Errorf("event: delete by task: %w", err)
	}
	n, _ := res.RowsAffected()
	return n, nil
}

// IncrementalVacuum asks SQLite to reclaim pages released by prior deletions.
// Runs against the serialized write handle so it never contends with readers.
func (s *EventStore) IncrementalVacuum(ctx context.Context) error {
	if _, err := s.db.write.ExecContext(ctx, `PRAGMA incremental_vacuum`); err != nil {
		return fmt.Errorf("event: incremental_vacuum: %w", err)
	}
	return nil
}
