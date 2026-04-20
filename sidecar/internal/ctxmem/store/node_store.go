package store

import (
	"context"
	"database/sql"
	"fmt"
	"strings"

	"github.com/FleetKanban/fleetkanban/internal/ctxmem"
)

// NodeStore persists ctxmem.Node rows.
type NodeStore struct{ db DB }

// Create inserts a new node. ID must be set by the caller (ULIDs are
// generated at the service layer so observer / analyzer can correlate
// with task / session IDs emitted upstream).
func (s *NodeStore) Create(ctx context.Context, n ctxmem.Node) error {
	if n.ID == "" || n.RepoID == "" || n.Kind == "" || n.Label == "" || n.SourceKind == "" {
		return fmt.Errorf("%w: node requires id, repo_id, kind, label, source_kind", ctxmem.ErrInvalidArg)
	}
	attrs, err := encodeAttrs(n.Attrs)
	if err != nil {
		return err
	}
	now := nowUTC()
	created := formatTime(n.CreatedAt)
	if created == "" {
		created = now
	}
	confidence := n.Confidence
	if confidence <= 0 {
		confidence = 1.0
	}
	_, err = s.db.Write().ExecContext(ctx, `
INSERT INTO ctx_node(
    id, repo_id, kind, label, content_md, attrs_json,
    source_kind, source_task_id, source_session_id,
    confidence, enabled, pinned, created_at, updated_at
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
		n.ID, n.RepoID, n.Kind, n.Label, n.ContentMD, attrs,
		n.SourceKind, n.SourceTaskID, n.SourceSessionID,
		confidence, boolToInt(n.Enabled || !n.Pinned && n.Confidence == 0), boolToInt(n.Pinned),
		created, now,
	)
	if err != nil {
		return fmt.Errorf("ctxmem/store: insert node: %w", err)
	}
	return nil
}

// Upsert inserts or replaces a node by ID. Preserves CreatedAt on
// conflict so the Browse tab can sort by updated_at without losing the
// original ingest timestamp.
func (s *NodeStore) Upsert(ctx context.Context, n ctxmem.Node) error {
	existing, err := s.Get(ctx, n.ID)
	if err != nil && err != ctxmem.ErrNotFound {
		return err
	}
	if err == ctxmem.ErrNotFound {
		return s.Create(ctx, n)
	}
	n.CreatedAt = existing.CreatedAt
	return s.Update(ctx, n)
}

// Get fetches a node by ID. Returns ctxmem.ErrNotFound when missing.
func (s *NodeStore) Get(ctx context.Context, id string) (ctxmem.Node, error) {
	row := s.db.Read().QueryRowContext(ctx, `
SELECT id, repo_id, kind, label, content_md, attrs_json,
       source_kind, source_task_id, source_session_id,
       confidence, enabled, pinned, created_at, updated_at
  FROM ctx_node WHERE id = ?`, id)
	return scanNodeRow(row)
}

// GetMany fetches multiple nodes in a single query. Ordering is not
// preserved — callers that need a specific order should sort in Go.
func (s *NodeStore) GetMany(ctx context.Context, ids []string) ([]ctxmem.Node, error) {
	if len(ids) == 0 {
		return nil, nil
	}
	placeholders := buildPlaceholders(len(ids))
	args := make([]any, len(ids))
	for i, id := range ids {
		args[i] = id
	}
	rows, err := s.db.Read().QueryContext(ctx, `
SELECT id, repo_id, kind, label, content_md, attrs_json,
       source_kind, source_task_id, source_session_id,
       confidence, enabled, pinned, created_at, updated_at
  FROM ctx_node WHERE id IN (`+placeholders+`)`, args...)
	if err != nil {
		return nil, fmt.Errorf("ctxmem/store: get many nodes: %w", err)
	}
	defer rows.Close()
	var out []ctxmem.Node
	for rows.Next() {
		n, err := scanNodes(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, n)
	}
	return out, rows.Err()
}

// ListFilter is the filter shape used by the Browse tab.
type ListFilter struct {
	RepoID         string
	Kinds          []string
	SourceKinds    []string
	LabelContains  string
	PinnedOnly     bool
	EnabledOnly    bool
	Limit          int
	Offset         int
	SortBy         string // "updated_at" (default) | "label" | "confidence"
}

// List returns nodes matching the filter plus a total-count (pre-limit).
func (s *NodeStore) List(ctx context.Context, f ListFilter) ([]ctxmem.Node, int, error) {
	where := []string{"repo_id = ?"}
	args := []any{f.RepoID}
	if len(f.Kinds) > 0 {
		where = append(where, "kind IN ("+buildPlaceholders(len(f.Kinds))+")")
		for _, k := range f.Kinds {
			args = append(args, k)
		}
	}
	if len(f.SourceKinds) > 0 {
		where = append(where, "source_kind IN ("+buildPlaceholders(len(f.SourceKinds))+")")
		for _, k := range f.SourceKinds {
			args = append(args, k)
		}
	}
	if f.LabelContains != "" {
		where = append(where, "(label LIKE ? OR content_md LIKE ?)")
		like := "%" + f.LabelContains + "%"
		args = append(args, like, like)
	}
	if f.PinnedOnly {
		where = append(where, "pinned = 1")
	}
	if f.EnabledOnly {
		where = append(where, "enabled = 1")
	}
	whereSQL := strings.Join(where, " AND ")

	// Count
	var total int
	if err := s.db.Read().QueryRowContext(ctx,
		`SELECT COUNT(*) FROM ctx_node WHERE `+whereSQL, args...).Scan(&total); err != nil {
		return nil, 0, fmt.Errorf("ctxmem/store: count nodes: %w", err)
	}

	orderBy := "updated_at DESC"
	switch f.SortBy {
	case "label":
		orderBy = "label ASC"
	case "confidence":
		orderBy = "confidence DESC, updated_at DESC"
	}
	limit := f.Limit
	if limit <= 0 {
		limit = 200
	}

	rows, err := s.db.Read().QueryContext(ctx, `
SELECT id, repo_id, kind, label, content_md, attrs_json,
       source_kind, source_task_id, source_session_id,
       confidence, enabled, pinned, created_at, updated_at
  FROM ctx_node WHERE `+whereSQL+`
 ORDER BY `+orderBy+`
 LIMIT ? OFFSET ?`, append(args, limit, f.Offset)...)
	if err != nil {
		return nil, 0, fmt.Errorf("ctxmem/store: list nodes: %w", err)
	}
	defer rows.Close()
	var out []ctxmem.Node
	for rows.Next() {
		n, err := scanNodes(rows)
		if err != nil {
			return nil, 0, err
		}
		out = append(out, n)
	}
	return out, total, rows.Err()
}

// Update applies the full node row (label / content_md / attrs /
// enabled / pinned / confidence). Callers that want field-level patch
// semantics should fetch, mutate, and resend.
func (s *NodeStore) Update(ctx context.Context, n ctxmem.Node) error {
	attrs, err := encodeAttrs(n.Attrs)
	if err != nil {
		return err
	}
	res, err := s.db.Write().ExecContext(ctx, `
UPDATE ctx_node
   SET label = ?, content_md = ?, attrs_json = ?,
       confidence = ?, enabled = ?, pinned = ?, updated_at = ?
 WHERE id = ?`,
		n.Label, n.ContentMD, attrs,
		n.Confidence, boolToInt(n.Enabled), boolToInt(n.Pinned),
		nowUTC(), n.ID,
	)
	if err != nil {
		return fmt.Errorf("ctxmem/store: update node: %w", err)
	}
	rows, _ := res.RowsAffected()
	if rows == 0 {
		return ctxmem.ErrNotFound
	}
	return nil
}

// SetEnabled toggles the enabled flag only. Cheaper than a full Update
// when the user clicks the Browse row's switch.
func (s *NodeStore) SetEnabled(ctx context.Context, id string, enabled bool) error {
	_, err := s.db.Write().ExecContext(ctx,
		`UPDATE ctx_node SET enabled = ?, updated_at = ? WHERE id = ?`,
		boolToInt(enabled), nowUTC(), id)
	if err != nil {
		return fmt.Errorf("ctxmem/store: set enabled: %w", err)
	}
	return nil
}

// SetPinned toggles the pinned flag only.
func (s *NodeStore) SetPinned(ctx context.Context, id string, pinned bool) error {
	_, err := s.db.Write().ExecContext(ctx,
		`UPDATE ctx_node SET pinned = ?, updated_at = ? WHERE id = ?`,
		boolToInt(pinned), nowUTC(), id)
	if err != nil {
		return fmt.Errorf("ctxmem/store: set pinned: %w", err)
	}
	return nil
}

// Delete removes a node. Associated edges / vectors / facts cascade via
// the schema's FOREIGN KEY ... ON DELETE CASCADE rules; closure rows
// must be rebuilt by the caller (graph.RebuildClosure) because closure
// is not FK-linked.
func (s *NodeStore) Delete(ctx context.Context, id string) error {
	_, err := s.db.Write().ExecContext(ctx, `DELETE FROM ctx_node WHERE id = ?`, id)
	if err != nil {
		return fmt.Errorf("ctxmem/store: delete node: %w", err)
	}
	return nil
}

// FindByLabel returns the first enabled node matching (repoID, kind,
// label) exactly. Used by Promote to dedupe scratchpad entries against
// already-accepted concepts. Returns ErrNotFound when no match exists.
func (s *NodeStore) FindByLabel(ctx context.Context, repoID, kind, label string) (ctxmem.Node, error) {
	if repoID == "" || kind == "" || label == "" {
		return ctxmem.Node{}, fmt.Errorf("%w: repo_id / kind / label required", ctxmem.ErrInvalidArg)
	}
	row := s.db.Read().QueryRowContext(ctx, `
SELECT id, repo_id, kind, label, content_md, attrs_json,
       source_kind, source_task_id, source_session_id,
       confidence, enabled, pinned, created_at, updated_at
  FROM ctx_node
 WHERE repo_id = ? AND kind = ? AND label = ? AND enabled = 1
 ORDER BY updated_at DESC
 LIMIT 1`, repoID, kind, label)
	return scanNodeRow(row)
}

// CountByKind returns the per-kind count of enabled nodes for a repo,
// used by Overview. Disabled nodes are excluded to match the Browse tab
// default.
func (s *NodeStore) CountByKind(ctx context.Context, repoID string) (map[string]int32, error) {
	rows, err := s.db.Read().QueryContext(ctx, `
SELECT kind, COUNT(*) FROM ctx_node
 WHERE repo_id = ? AND enabled = 1
 GROUP BY kind`, repoID)
	if err != nil {
		return nil, fmt.Errorf("ctxmem/store: count nodes by kind: %w", err)
	}
	defer rows.Close()
	out := map[string]int32{}
	for rows.Next() {
		var kind string
		var n int32
		if err := rows.Scan(&kind, &n); err != nil {
			return nil, err
		}
		out[kind] = n
	}
	return out, rows.Err()
}

type nodeScanner interface {
	Scan(dest ...any) error
}

func scanNodeRow(row *sql.Row) (ctxmem.Node, error) {
	n, err := scanNodes(row)
	return n, translateError(err)
}

func scanNodes(s nodeScanner) (ctxmem.Node, error) {
	var (
		n            ctxmem.Node
		attrsJSON    string
		createdAt    string
		updatedAt    string
		enabled      int
		pinned       int
		confidence   float64
	)
	if err := s.Scan(
		&n.ID, &n.RepoID, &n.Kind, &n.Label, &n.ContentMD, &attrsJSON,
		&n.SourceKind, &n.SourceTaskID, &n.SourceSessionID,
		&confidence, &enabled, &pinned, &createdAt, &updatedAt,
	); err != nil {
		return ctxmem.Node{}, err
	}
	attrs, err := decodeAttrs(attrsJSON)
	if err != nil {
		return ctxmem.Node{}, err
	}
	n.Attrs = attrs
	n.Confidence = float32(confidence)
	n.Enabled = enabled == 1
	n.Pinned = pinned == 1
	n.CreatedAt = parseTime(createdAt)
	n.UpdatedAt = parseTime(updatedAt)
	return n, nil
}
