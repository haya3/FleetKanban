package store

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"time"
)

// Artifact is a row in the artifact table. Path is relative to the task's
// run root (<DataDir>/runs/<taskID>/); joining with the task_run_root
// row's root_path yields the absolute filesystem path.
//
// SubtaskID is empty when stage is 'plan' | 'review' | 'harness' (i.e.
// task-scoped) and populated when stage is 'code' | 'attempt'.
type Artifact struct {
	ID          string
	TaskID      string
	SubtaskID   string
	Stage       string
	Path        string
	Kind        string
	ContentHash string
	SizeBytes   int64
	AttrsJSON   string
	CreatedAt   time.Time
}

// ArtifactStore is the DB-side half of the NLAH file-backed state module.
// Filesystem writes live in internal/runstate; this type knows nothing
// about bytes on disk — only the index rows that let the UI enumerate
// what was written without walking the tree.
type ArtifactStore struct{ db *DB }

// NewArtifactStore wraps a DB with artifact-specific helpers.
func NewArtifactStore(db *DB) *ArtifactStore { return &ArtifactStore{db: db} }

// ErrArtifactNotFound is returned by Get when no row matches the ID.
var ErrArtifactNotFound = errors.New("store: artifact not found")

// InsertIfNew inserts a new artifact row. Returns (id, true) when a new
// row is written, or (existingID, false) when (task_id, path, content_hash)
// collides — in the latter case the caller can safely skip the filesystem
// write because identical content already exists on disk.
//
// Callers own ID generation (runstate.Writer assigns a ULID before
// calling). CreatedAt defaults to time.Now().UTC() when zero.
func (s *ArtifactStore) InsertIfNew(ctx context.Context, a Artifact) (string, bool, error) {
	if a.ID == "" || a.TaskID == "" || a.Stage == "" || a.Path == "" || a.Kind == "" || a.ContentHash == "" {
		return "", false, fmt.Errorf("artifact: missing required field")
	}
	if a.AttrsJSON == "" {
		a.AttrsJSON = "{}"
	}
	if a.CreatedAt.IsZero() {
		a.CreatedAt = time.Now().UTC()
	}

	// Fast-path: check for existing row first so we don't allocate a new
	// ULID on a no-op write (keeps logs quieter under heavy idempotent
	// retry loops).
	var existingID string
	err := s.db.read.QueryRowContext(ctx,
		`SELECT id FROM artifact WHERE task_id = ? AND path = ? AND content_hash = ?`,
		a.TaskID, a.Path, a.ContentHash).Scan(&existingID)
	if err == nil {
		return existingID, false, nil
	}
	if !errors.Is(err, sql.ErrNoRows) {
		return "", false, fmt.Errorf("artifact: lookup existing: %w", err)
	}

	var subtaskID any
	if a.SubtaskID != "" {
		subtaskID = a.SubtaskID
	}

	if _, err := s.db.write.ExecContext(ctx, `
INSERT INTO artifact(id, task_id, subtask_id, stage, path, kind,
                     content_hash, size_bytes, attrs_json, created_at)
VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
		a.ID, a.TaskID, subtaskID, a.Stage, a.Path, a.Kind,
		a.ContentHash, a.SizeBytes, a.AttrsJSON, formatTime(a.CreatedAt)); err != nil {
		// Lost a race — another goroutine inserted the same (task, path, hash).
		// Look the winner up and report it so the caller still sees a usable ID.
		if isUniqueViolation(err) {
			if qerr := s.db.read.QueryRowContext(ctx,
				`SELECT id FROM artifact WHERE task_id = ? AND path = ? AND content_hash = ?`,
				a.TaskID, a.Path, a.ContentHash).Scan(&existingID); qerr == nil {
				return existingID, false, nil
			}
		}
		return "", false, fmt.Errorf("artifact: insert: %w", err)
	}
	return a.ID, true, nil
}

// List returns artifacts for a task, newest first. When stage is non-empty
// results are filtered to that stage. limit <= 0 is treated as unbounded.
func (s *ArtifactStore) List(ctx context.Context, taskID, stage string, limit int) ([]Artifact, error) {
	q := `SELECT id, task_id, COALESCE(subtask_id,''), stage, path, kind,
	             content_hash, size_bytes, attrs_json, created_at
	        FROM artifact
	       WHERE task_id = ?`
	args := []any{taskID}
	if stage != "" {
		q += ` AND stage = ?`
		args = append(args, stage)
	}
	q += ` ORDER BY created_at DESC, id DESC`
	if limit > 0 {
		q += fmt.Sprintf(` LIMIT %d`, limit)
	}
	rows, err := s.db.read.QueryContext(ctx, q, args...)
	if err != nil {
		return nil, fmt.Errorf("artifact: list: %w", err)
	}
	defer rows.Close()

	var out []Artifact
	for rows.Next() {
		var a Artifact
		var ts string
		if err := rows.Scan(&a.ID, &a.TaskID, &a.SubtaskID, &a.Stage,
			&a.Path, &a.Kind, &a.ContentHash, &a.SizeBytes, &a.AttrsJSON, &ts); err != nil {
			return nil, err
		}
		t, err := parseTime(ts)
		if err != nil {
			return nil, fmt.Errorf("artifact: parse created_at: %w", err)
		}
		a.CreatedAt = t
		out = append(out, a)
	}
	return out, rows.Err()
}

// ListPage is List with offset-based pagination. Returns up to pageSize
// rows starting at offset, plus the next offset that should be supplied
// as the next page's starting cursor. nextOffset == -1 signals the end
// of the result set.
//
// Offset pagination is adequate here because artifact rows per task are
// typically small (< 1000) and the order key (created_at DESC, id DESC)
// is stable across inserts — late-arriving artifacts land at offset 0
// on subsequent calls, so a paged reader naturally re-observes them
// only if they explicitly restart from offset 0.
func (s *ArtifactStore) ListPage(ctx context.Context, taskID, stage string, offset, pageSize int) (rows []Artifact, nextOffset int, err error) {
	if pageSize <= 0 {
		pageSize = 500
	}
	if offset < 0 {
		offset = 0
	}
	q := `SELECT id, task_id, COALESCE(subtask_id,''), stage, path, kind,
	             content_hash, size_bytes, attrs_json, created_at
	        FROM artifact
	       WHERE task_id = ?`
	args := []any{taskID}
	if stage != "" {
		q += ` AND stage = ?`
		args = append(args, stage)
	}
	q += ` ORDER BY created_at DESC, id DESC`
	// Request one extra row to detect whether a next page exists without a
	// separate COUNT(*) query.
	q += fmt.Sprintf(` LIMIT %d OFFSET %d`, pageSize+1, offset)

	qRows, err := s.db.read.QueryContext(ctx, q, args...)
	if err != nil {
		return nil, -1, fmt.Errorf("artifact: list page: %w", err)
	}
	defer qRows.Close()

	for qRows.Next() {
		var a Artifact
		var ts string
		if err := qRows.Scan(&a.ID, &a.TaskID, &a.SubtaskID, &a.Stage,
			&a.Path, &a.Kind, &a.ContentHash, &a.SizeBytes, &a.AttrsJSON, &ts); err != nil {
			return nil, -1, err
		}
		t, err := parseTime(ts)
		if err != nil {
			return nil, -1, fmt.Errorf("artifact: parse created_at: %w", err)
		}
		a.CreatedAt = t
		rows = append(rows, a)
	}
	if err := qRows.Err(); err != nil {
		return nil, -1, err
	}

	if len(rows) > pageSize {
		return rows[:pageSize], offset + pageSize, nil
	}
	return rows, -1, nil
}

// Get returns a single artifact by ID. Returns ErrArtifactNotFound when
// no such row exists.
func (s *ArtifactStore) Get(ctx context.Context, id string) (Artifact, error) {
	var (
		a  Artifact
		ts string
	)
	err := s.db.read.QueryRowContext(ctx, `
SELECT id, task_id, COALESCE(subtask_id,''), stage, path, kind,
       content_hash, size_bytes, attrs_json, created_at
  FROM artifact WHERE id = ?`, id).Scan(&a.ID, &a.TaskID, &a.SubtaskID,
		&a.Stage, &a.Path, &a.Kind, &a.ContentHash, &a.SizeBytes, &a.AttrsJSON, &ts)
	if errors.Is(err, sql.ErrNoRows) {
		return Artifact{}, ErrArtifactNotFound
	}
	if err != nil {
		return Artifact{}, fmt.Errorf("artifact: get: %w", err)
	}
	t, err := parseTime(ts)
	if err != nil {
		return Artifact{}, fmt.Errorf("artifact: parse created_at: %w", err)
	}
	a.CreatedAt = t
	return a, nil
}

// UpsertTaskRunRoot records (or overwrites) the absolute filesystem path
// where task's run/ directory lives. Called once by runstate.InitTaskDir.
func (s *ArtifactStore) UpsertTaskRunRoot(ctx context.Context, taskID, rootPath string) error {
	if taskID == "" || rootPath == "" {
		return fmt.Errorf("artifact: UpsertTaskRunRoot: taskID and rootPath required")
	}
	_, err := s.db.write.ExecContext(ctx, `
INSERT INTO task_run_root(task_id, root_path, created_at)
VALUES (?, ?, ?)
ON CONFLICT(task_id) DO UPDATE SET root_path = excluded.root_path`,
		taskID, rootPath, nowUTC())
	if err != nil {
		return fmt.Errorf("artifact: upsert task_run_root: %w", err)
	}
	return nil
}

// TaskRunRoot returns the absolute run directory path for a task. Returns
// an empty string with nil error when no row exists (the caller treats
// this as "not yet initialised" rather than a hard failure).
func (s *ArtifactStore) TaskRunRoot(ctx context.Context, taskID string) (string, error) {
	var root string
	err := s.db.read.QueryRowContext(ctx,
		`SELECT root_path FROM task_run_root WHERE task_id = ?`, taskID).Scan(&root)
	if errors.Is(err, sql.ErrNoRows) {
		return "", nil
	}
	if err != nil {
		return "", fmt.Errorf("artifact: task_run_root get: %w", err)
	}
	return root, nil
}
