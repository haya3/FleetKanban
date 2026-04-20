package store

import (
	"context"
	"database/sql"
	"fmt"
)

// ClosureStore persists ctx_closure rows. Closure is a redundant
// projection of ctx_edge — it stores (src, dst, depth, via_rel) for
// every directed path up to the configured max hop count. graph.Rebuild
// writes the full closure atomically; this store provides the low-level
// read / write primitives it uses.
type ClosureStore struct{ db DB }

// ClosureRow is one row in ctx_closure.
type ClosureRow struct {
	RepoID    string
	SrcNodeID string
	DstNodeID string
	Depth     int
	ViaRel    string
}

// DeleteForRepo wipes all closure rows for a repo. Used before
// RebuildForRepo to ensure the rewrite is authoritative.
func (s *ClosureStore) DeleteForRepo(ctx context.Context, tx *sql.Tx, repoID string) error {
	_, err := tx.ExecContext(ctx, `DELETE FROM ctx_closure WHERE repo_id = ?`, repoID)
	if err != nil {
		return fmt.Errorf("ctxmem/store: clear closure: %w", err)
	}
	return nil
}

// BulkInsert writes a batch of closure rows within an existing tx. The
// graph.RebuildClosure helper buffers its BFS output and flushes in
// chunks of 500 to keep SQLite's statement argument limit in check.
func (s *ClosureStore) BulkInsert(ctx context.Context, tx *sql.Tx, rows []ClosureRow) error {
	if len(rows) == 0 {
		return nil
	}
	stmt, err := tx.PrepareContext(ctx, `
INSERT OR IGNORE INTO ctx_closure(repo_id, src_node_id, dst_node_id, depth, via_rel)
 VALUES (?, ?, ?, ?, ?)`)
	if err != nil {
		return fmt.Errorf("ctxmem/store: prepare closure insert: %w", err)
	}
	defer stmt.Close()
	for _, r := range rows {
		if _, err := stmt.ExecContext(ctx, r.RepoID, r.SrcNodeID, r.DstNodeID, r.Depth, r.ViaRel); err != nil {
			return fmt.Errorf("ctxmem/store: insert closure row: %w", err)
		}
	}
	return nil
}

// DescendantsByDepth returns every node reachable from srcID within
// maxDepth hops, grouped by depth for BFS-style expansion.
func (s *ClosureStore) DescendantsByDepth(ctx context.Context, srcID string, maxDepth int) ([]ClosureRow, error) {
	if maxDepth <= 0 {
		maxDepth = 3
	}
	rows, err := s.db.Read().QueryContext(ctx, `
SELECT repo_id, src_node_id, dst_node_id, depth, via_rel
  FROM ctx_closure
 WHERE src_node_id = ? AND depth <= ?
 ORDER BY depth ASC`, srcID, maxDepth)
	if err != nil {
		return nil, fmt.Errorf("ctxmem/store: closure descendants: %w", err)
	}
	defer rows.Close()
	var out []ClosureRow
	for rows.Next() {
		var r ClosureRow
		if err := rows.Scan(&r.RepoID, &r.SrcNodeID, &r.DstNodeID, &r.Depth, &r.ViaRel); err != nil {
			return nil, err
		}
		out = append(out, r)
	}
	return out, rows.Err()
}

// AncestorsByDepth returns every node that can reach dstID within
// maxDepth hops (reverse traversal), used by impact analysis.
func (s *ClosureStore) AncestorsByDepth(ctx context.Context, dstID string, maxDepth int) ([]ClosureRow, error) {
	if maxDepth <= 0 {
		maxDepth = 3
	}
	rows, err := s.db.Read().QueryContext(ctx, `
SELECT repo_id, src_node_id, dst_node_id, depth, via_rel
  FROM ctx_closure
 WHERE dst_node_id = ? AND depth <= ?
 ORDER BY depth ASC`, dstID, maxDepth)
	if err != nil {
		return nil, fmt.Errorf("ctxmem/store: closure ancestors: %w", err)
	}
	defer rows.Close()
	var out []ClosureRow
	for rows.Next() {
		var r ClosureRow
		if err := rows.Scan(&r.RepoID, &r.SrcNodeID, &r.DstNodeID, &r.Depth, &r.ViaRel); err != nil {
			return nil, err
		}
		out = append(out, r)
	}
	return out, rows.Err()
}
