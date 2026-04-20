package store

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"strings"
	"time"
)

// Repository is a registered git repository that tasks can be created against.
//
// Path is stored lowercase (NTFS is case-insensitive; see phase1-spec §9.1)
// so that UNIQUE (path) collapses `C:\Foo` and `c:\foo`. Callers must pass in
// the original-case path via RepositoryInput; normalization happens at the
// store boundary.
type Repository struct {
	ID                string
	Path              string // lowercase
	DisplayName       string
	DefaultBaseBranch string
	CreatedAt         time.Time
	LastUsedAt        *time.Time
}

// RepositoryInput is the create/update payload.
type RepositoryInput struct {
	ID                string
	Path              string // will be lowercased before persisting
	DisplayName       string
	DefaultBaseBranch string
}

// ErrNotFound is returned by the store when a row lookup has no match.
var ErrNotFound = errors.New("store: not found")

// RepositoryStore persists Repository rows.
type RepositoryStore struct{ db *DB }

// NewRepositoryStore wraps a DB with repository-specific helpers.
func NewRepositoryStore(db *DB) *RepositoryStore { return &RepositoryStore{db: db} }

// Create inserts a new repository. Returns ErrDuplicatePath if the
// (case-folded) path is already registered.
func (s *RepositoryStore) Create(ctx context.Context, in RepositoryInput) (*Repository, error) {
	if in.ID == "" || in.Path == "" || in.DisplayName == "" {
		return nil, fmt.Errorf("repository: ID, Path, DisplayName are required")
	}
	lowered := strings.ToLower(in.Path)
	now := nowUTC()

	_, err := s.db.write.ExecContext(ctx, `
INSERT INTO repositories(id, path, display_name, default_base_branch, created_at, last_used_at)
VALUES (?, ?, ?, ?, ?, NULL)`,
		in.ID, lowered, in.DisplayName, in.DefaultBaseBranch, now)
	if err != nil {
		if isUniqueViolation(err) {
			return nil, ErrDuplicatePath
		}
		return nil, fmt.Errorf("repository: insert: %w", err)
	}
	return s.Get(ctx, in.ID)
}

// ErrDuplicatePath signals a UNIQUE(path) collision on create.
var ErrDuplicatePath = errors.New("store: repository path already registered")

// Get loads a single repository by ID.
func (s *RepositoryStore) Get(ctx context.Context, id string) (*Repository, error) {
	row := s.db.read.QueryRowContext(ctx, `
SELECT id, path, display_name, default_base_branch, created_at, last_used_at
  FROM repositories WHERE id = ?`, id)
	return scanRepository(row)
}

// GetByPath looks up a repository by its normalized (lowercase) path.
func (s *RepositoryStore) GetByPath(ctx context.Context, path string) (*Repository, error) {
	row := s.db.read.QueryRowContext(ctx, `
SELECT id, path, display_name, default_base_branch, created_at, last_used_at
  FROM repositories WHERE path = ?`, strings.ToLower(path))
	return scanRepository(row)
}

// List returns all repositories ordered by display name.
func (s *RepositoryStore) List(ctx context.Context) ([]*Repository, error) {
	rows, err := s.db.read.QueryContext(ctx, `
SELECT id, path, display_name, default_base_branch, created_at, last_used_at
  FROM repositories ORDER BY display_name COLLATE NOCASE`)
	if err != nil {
		return nil, fmt.Errorf("repository: list: %w", err)
	}
	defer rows.Close()

	var out []*Repository
	for rows.Next() {
		r, err := scanRepository(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, r)
	}
	return out, rows.Err()
}

// TouchLastUsed bumps last_used_at to now. Called when a task is created
// against the repository.
func (s *RepositoryStore) TouchLastUsed(ctx context.Context, id string) error {
	_, err := s.db.write.ExecContext(ctx,
		`UPDATE repositories SET last_used_at = ? WHERE id = ?`, nowUTC(), id)
	return err
}

// UpdateDefaultBaseBranch persists a user-edited default base branch.
func (s *RepositoryStore) UpdateDefaultBaseBranch(ctx context.Context, id, branch string) error {
	res, err := s.db.write.ExecContext(ctx,
		`UPDATE repositories SET default_base_branch = ? WHERE id = ?`, branch, id)
	if err != nil {
		return err
	}
	n, _ := res.RowsAffected()
	if n == 0 {
		return ErrNotFound
	}
	return nil
}

// Delete removes a repository. Fails if any task references it
// (ON DELETE RESTRICT on tasks.repository_id).
func (s *RepositoryStore) Delete(ctx context.Context, id string) error {
	_, err := s.db.write.ExecContext(ctx, `DELETE FROM repositories WHERE id = ?`, id)
	return err
}

// scanner abstracts *sql.Row and *sql.Rows for shared Scan plumbing.
type scanner interface {
	Scan(dest ...any) error
}

func scanRepository(sc scanner) (*Repository, error) {
	var (
		r        Repository
		defBr    sql.NullString
		created  string
		lastUsed sql.NullString
	)
	err := sc.Scan(&r.ID, &r.Path, &r.DisplayName, &defBr, &created, &lastUsed)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, fmt.Errorf("repository: scan: %w", err)
	}
	if defBr.Valid {
		r.DefaultBaseBranch = defBr.String
	}
	t, err := parseTime(created)
	if err != nil {
		return nil, fmt.Errorf("repository: parse created_at: %w", err)
	}
	r.CreatedAt = t
	r.LastUsedAt, err = scanNullableTime(lastUsed)
	if err != nil {
		return nil, fmt.Errorf("repository: parse last_used_at: %w", err)
	}
	return &r, nil
}

// isUniqueViolation returns true for SQLite UNIQUE constraint errors.
// modernc's driver surfaces the error as a string; matching on substring
// is the portable path.
func isUniqueViolation(err error) bool {
	if err == nil {
		return false
	}
	msg := err.Error()
	return strings.Contains(msg, "UNIQUE constraint failed") ||
		strings.Contains(msg, "constraint failed: UNIQUE")
}
