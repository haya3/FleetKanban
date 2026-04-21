//go:build windows

// Package store — harness_skill_version table access.
//
// HarnessSkillStore replaces the Phase B harness artifact storage that relied
// on artifact table FK sentinels (__harness__ pseudo task/repo rows). Content
// is stored directly as TEXT, eliminating the FS file + DB row dual write.
package store

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"time"

	"github.com/oklog/ulid/v2"
)

// ErrNoSkillVersion is returned by Latest and Get when no matching row exists.
var ErrNoSkillVersion = errors.New("store: harness skill version not found")

// HarnessSkillVersion is a row in the harness_skill_version table.
// ParentID is empty for the first user-authored version; rollback and
// evolver versions set it to the source row's ID for history traversal.
type HarnessSkillVersion struct {
	ID          string
	ContentMD   string
	ContentHash string
	CreatedAt   time.Time
	CreatedBy   string // "user" | "evolver" | "rollback:<source_id>"
	ParentID    string // empty when no parent
}

// HarnessSkillStore provides CRUD over the harness_skill_version table.
type HarnessSkillStore struct{ db *DB }

// NewHarnessSkillStore wraps a DB with harness-skill-version helpers.
func NewHarnessSkillStore(db *DB) *HarnessSkillStore {
	return &HarnessSkillStore{db: db}
}

// Insert writes a new version row. For user-authored versions (CreatedBy ==
// "user" or empty), duplicate content_hash is a no-op: returns
// (existingID, false, nil) so the caller can decide whether to log the
// collision. Rollback and evolver versions (CreatedBy starts with
// "rollback:" or "evolver") always insert a new row, because the audit trail
// must record the re-application event even when content is identical.
// A ULID is minted when v.ID is empty. CreatedAt defaults to time.Now().UTC()
// when zero.
func (s *HarnessSkillStore) Insert(ctx context.Context, v HarnessSkillVersion) (id string, inserted bool, err error) {
	if v.ContentHash == "" {
		return "", false, fmt.Errorf("harness_skill_version: content_hash required")
	}
	if v.ID == "" {
		v.ID = ulid.Make().String()
	}
	if v.CreatedAt.IsZero() {
		v.CreatedAt = time.Now().UTC()
	}
	if v.CreatedBy == "" {
		v.CreatedBy = "user"
	}

	// Deduplication applies only to user-authored versions. Rollback and
	// evolver versions always produce a new row so the audit trail captures
	// the re-application event, even when the content bytes are identical
	// to a prior version.
	isUserVersion := v.CreatedBy == "user" || v.CreatedBy == "migrated"
	if isUserVersion {
		var existingID string
		qerr := s.db.read.QueryRowContext(ctx,
			`SELECT id FROM harness_skill_version WHERE content_hash = ? LIMIT 1`,
			v.ContentHash).Scan(&existingID)
		if qerr == nil {
			return existingID, false, nil
		}
		if !errors.Is(qerr, sql.ErrNoRows) {
			return "", false, fmt.Errorf("harness_skill_version: lookup existing: %w", qerr)
		}
	}

	var parentID any
	if v.ParentID != "" {
		parentID = v.ParentID
	}

	_, err = s.db.write.ExecContext(ctx, `
INSERT INTO harness_skill_version(id, content_md, content_hash, created_at, created_by, parent_id)
VALUES (?, ?, ?, ?, ?, ?)`,
		v.ID, v.ContentMD, v.ContentHash, formatTime(v.CreatedAt), v.CreatedBy, parentID)
	if err != nil {
		return "", false, fmt.Errorf("harness_skill_version: insert: %w", err)
	}
	return v.ID, true, nil
}

// Latest returns the newest row ordered by created_at DESC, id DESC.
// Returns ErrNoSkillVersion when the table is empty.
func (s *HarnessSkillStore) Latest(ctx context.Context) (HarnessSkillVersion, error) {
	row := s.db.read.QueryRowContext(ctx, `
SELECT id, content_md, content_hash, created_at, created_by, COALESCE(parent_id,'')
  FROM harness_skill_version
 ORDER BY created_at DESC, id DESC
 LIMIT 1`)
	v, err := scanSkillVersion(row)
	if errors.Is(err, sql.ErrNoRows) {
		return HarnessSkillVersion{}, ErrNoSkillVersion
	}
	if err != nil {
		return HarnessSkillVersion{}, fmt.Errorf("harness_skill_version: latest: %w", err)
	}
	return v, nil
}

// Get returns a single row by ID. Returns ErrNoSkillVersion when not found.
func (s *HarnessSkillStore) Get(ctx context.Context, id string) (HarnessSkillVersion, error) {
	row := s.db.read.QueryRowContext(ctx, `
SELECT id, content_md, content_hash, created_at, created_by, COALESCE(parent_id,'')
  FROM harness_skill_version
 WHERE id = ?`, id)
	v, err := scanSkillVersion(row)
	if errors.Is(err, sql.ErrNoRows) {
		return HarnessSkillVersion{}, ErrNoSkillVersion
	}
	if err != nil {
		return HarnessSkillVersion{}, fmt.Errorf("harness_skill_version: get: %w", err)
	}
	return v, nil
}

// List returns all rows newest-first, up to limit rows.
// limit <= 0 defaults to 100.
func (s *HarnessSkillStore) List(ctx context.Context, limit int) ([]HarnessSkillVersion, error) {
	if limit <= 0 {
		limit = 100
	}
	rows, err := s.db.read.QueryContext(ctx, `
SELECT id, content_md, content_hash, created_at, created_by, COALESCE(parent_id,'')
  FROM harness_skill_version
 ORDER BY created_at DESC, id DESC
 LIMIT ?`, limit)
	if err != nil {
		return nil, fmt.Errorf("harness_skill_version: list: %w", err)
	}
	defer rows.Close()

	var out []HarnessSkillVersion
	for rows.Next() {
		v, err := scanSkillVersion(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, v)
	}
	return out, rows.Err()
}

// ── helpers ──────────────────────────────────────────────────────────────────

func scanSkillVersion(s scanner) (HarnessSkillVersion, error) {
	var (
		v         HarnessSkillVersion
		createdAt string
	)
	if err := s.Scan(&v.ID, &v.ContentMD, &v.ContentHash, &createdAt, &v.CreatedBy, &v.ParentID); err != nil {
		return HarnessSkillVersion{}, err
	}
	t, err := parseTime(createdAt)
	if err != nil {
		return HarnessSkillVersion{}, fmt.Errorf("harness_skill_version: parse created_at: %w", err)
	}
	v.CreatedAt = t
	return v, nil
}
