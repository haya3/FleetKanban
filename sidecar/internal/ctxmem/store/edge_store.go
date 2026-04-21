package store

import (
	"context"
	"database/sql"
	"fmt"
	"strings"

	"github.com/haya3/fleetkanban/internal/ctxmem"
)

// EdgeStore persists ctxmem.Edge rows.
type EdgeStore struct{ db DB }

// Create inserts a new edge. The (repo_id, src, dst, rel) uniqueness
// constraint guarantees idempotence at the SQL level; callers that
// want "insert if not exists" can ignore sqlite constraint errors.
func (s *EdgeStore) Create(ctx context.Context, e ctxmem.Edge) error {
	if e.ID == "" || e.RepoID == "" || e.SrcNodeID == "" || e.DstNodeID == "" || e.Rel == "" {
		return fmt.Errorf("%w: edge requires id, repo_id, src, dst, rel", ctxmem.ErrInvalidArg)
	}
	attrs, err := encodeAttrs(e.Attrs)
	if err != nil {
		return err
	}
	created := formatTime(e.CreatedAt)
	if created == "" {
		created = nowUTC()
	}
	_, err = s.db.Write().ExecContext(ctx, `
INSERT INTO ctx_edge(
    id, repo_id, src_node_id, dst_node_id, rel, attrs_json, created_at
) VALUES (?, ?, ?, ?, ?, ?, ?)`,
		e.ID, e.RepoID, e.SrcNodeID, e.DstNodeID, e.Rel, attrs, created,
	)
	if err != nil {
		return fmt.Errorf("ctxmem/store: insert edge: %w", err)
	}
	return nil
}

// UpsertByTuple inserts an edge if the (src, dst, rel) tuple is new,
// otherwise refreshes the attrs / created_at columns. Used by the
// static analyzer when it re-runs over a repo.
func (s *EdgeStore) UpsertByTuple(ctx context.Context, e ctxmem.Edge) error {
	attrs, err := encodeAttrs(e.Attrs)
	if err != nil {
		return err
	}
	created := formatTime(e.CreatedAt)
	if created == "" {
		created = nowUTC()
	}
	_, err = s.db.Write().ExecContext(ctx, `
INSERT INTO ctx_edge(
    id, repo_id, src_node_id, dst_node_id, rel, attrs_json, created_at
) VALUES (?, ?, ?, ?, ?, ?, ?)
ON CONFLICT(repo_id, src_node_id, dst_node_id, rel) DO UPDATE SET
    attrs_json = excluded.attrs_json,
    created_at = excluded.created_at`,
		e.ID, e.RepoID, e.SrcNodeID, e.DstNodeID, e.Rel, attrs, created,
	)
	if err != nil {
		return fmt.Errorf("ctxmem/store: upsert edge: %w", err)
	}
	return nil
}

// Delete removes one edge by ID.
func (s *EdgeStore) Delete(ctx context.Context, id string) error {
	_, err := s.db.Write().ExecContext(ctx, `DELETE FROM ctx_edge WHERE id = ?`, id)
	return err
}

// EdgeFilter narrows ListEdges results.
type EdgeFilter struct {
	RepoID string
	NodeID string // incident in either direction when set
	Rels   []string
	Limit  int
	Offset int
}

// List returns edges matching the filter plus a pre-limit count.
func (s *EdgeStore) List(ctx context.Context, f EdgeFilter) ([]ctxmem.Edge, int, error) {
	where := []string{"repo_id = ?"}
	args := []any{f.RepoID}
	if f.NodeID != "" {
		where = append(where, "(src_node_id = ? OR dst_node_id = ?)")
		args = append(args, f.NodeID, f.NodeID)
	}
	if len(f.Rels) > 0 {
		where = append(where, "rel IN ("+buildPlaceholders(len(f.Rels))+")")
		for _, r := range f.Rels {
			args = append(args, r)
		}
	}
	whereSQL := strings.Join(where, " AND ")

	var total int
	if err := s.db.Read().QueryRowContext(ctx,
		`SELECT COUNT(*) FROM ctx_edge WHERE `+whereSQL, args...).Scan(&total); err != nil {
		return nil, 0, fmt.Errorf("ctxmem/store: count edges: %w", err)
	}

	limit := f.Limit
	if limit <= 0 {
		limit = 500
	}
	rows, err := s.db.Read().QueryContext(ctx, `
SELECT id, repo_id, src_node_id, dst_node_id, rel, attrs_json, created_at
  FROM ctx_edge WHERE `+whereSQL+`
 ORDER BY created_at ASC
 LIMIT ? OFFSET ?`, append(args, limit, f.Offset)...)
	if err != nil {
		return nil, 0, fmt.Errorf("ctxmem/store: list edges: %w", err)
	}
	defer rows.Close()
	var out []ctxmem.Edge
	for rows.Next() {
		e, err := scanEdge(rows)
		if err != nil {
			return nil, 0, err
		}
		out = append(out, e)
	}
	return out, total, rows.Err()
}

// OutEdges returns all edges where nodeID is the src.
func (s *EdgeStore) OutEdges(ctx context.Context, nodeID string) ([]ctxmem.Edge, error) {
	rows, err := s.db.Read().QueryContext(ctx, `
SELECT id, repo_id, src_node_id, dst_node_id, rel, attrs_json, created_at
  FROM ctx_edge WHERE src_node_id = ?
 ORDER BY created_at ASC`, nodeID)
	if err != nil {
		return nil, fmt.Errorf("ctxmem/store: out edges: %w", err)
	}
	defer rows.Close()
	var out []ctxmem.Edge
	for rows.Next() {
		e, err := scanEdge(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, e)
	}
	return out, rows.Err()
}

// InEdges returns all edges where nodeID is the dst.
func (s *EdgeStore) InEdges(ctx context.Context, nodeID string) ([]ctxmem.Edge, error) {
	rows, err := s.db.Read().QueryContext(ctx, `
SELECT id, repo_id, src_node_id, dst_node_id, rel, attrs_json, created_at
  FROM ctx_edge WHERE dst_node_id = ?
 ORDER BY created_at ASC`, nodeID)
	if err != nil {
		return nil, fmt.Errorf("ctxmem/store: in edges: %w", err)
	}
	defer rows.Close()
	var out []ctxmem.Edge
	for rows.Next() {
		e, err := scanEdge(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, e)
	}
	return out, rows.Err()
}

// CountByRel returns per-rel edge counts for a repo.
func (s *EdgeStore) CountByRel(ctx context.Context, repoID string) (map[string]int32, error) {
	rows, err := s.db.Read().QueryContext(ctx, `
SELECT rel, COUNT(*) FROM ctx_edge
 WHERE repo_id = ? GROUP BY rel`, repoID)
	if err != nil {
		return nil, fmt.Errorf("ctxmem/store: count edges by rel: %w", err)
	}
	defer rows.Close()
	out := map[string]int32{}
	for rows.Next() {
		var rel string
		var n int32
		if err := rows.Scan(&rel, &n); err != nil {
			return nil, err
		}
		out[rel] = n
	}
	return out, rows.Err()
}

// AllForRepo returns every edge for a repo. Used by graph.RebuildClosure
// which needs the full edge set to do BFS in memory.
func (s *EdgeStore) AllForRepo(ctx context.Context, repoID string) ([]ctxmem.Edge, error) {
	rows, err := s.db.Read().QueryContext(ctx, `
SELECT id, repo_id, src_node_id, dst_node_id, rel, attrs_json, created_at
  FROM ctx_edge WHERE repo_id = ?`, repoID)
	if err != nil {
		return nil, fmt.Errorf("ctxmem/store: all edges: %w", err)
	}
	defer rows.Close()
	var out []ctxmem.Edge
	for rows.Next() {
		e, err := scanEdge(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, e)
	}
	return out, rows.Err()
}

type edgeScanner interface {
	Scan(dest ...any) error
}

func scanEdge(s edgeScanner) (ctxmem.Edge, error) {
	var (
		e         ctxmem.Edge
		attrsJSON string
		createdAt string
	)
	if err := s.Scan(
		&e.ID, &e.RepoID, &e.SrcNodeID, &e.DstNodeID, &e.Rel, &attrsJSON, &createdAt,
	); err != nil {
		return ctxmem.Edge{}, err
	}
	attrs, err := decodeAttrs(attrsJSON)
	if err != nil {
		return ctxmem.Edge{}, err
	}
	e.Attrs = attrs
	e.CreatedAt = parseTime(createdAt)
	return e, nil
}

// GetByID fetches one edge by ID. Returns ErrNotFound when missing.
func (s *EdgeStore) GetByID(ctx context.Context, id string) (ctxmem.Edge, error) {
	row := s.db.Read().QueryRowContext(ctx, `
SELECT id, repo_id, src_node_id, dst_node_id, rel, attrs_json, created_at
  FROM ctx_edge WHERE id = ?`, id)
	e, err := scanEdge(row)
	if err != nil {
		if err == sql.ErrNoRows {
			return ctxmem.Edge{}, ctxmem.ErrNotFound
		}
		return ctxmem.Edge{}, err
	}
	return e, nil
}
