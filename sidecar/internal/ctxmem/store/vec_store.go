package store

import (
	"context"
	"encoding/binary"
	"fmt"
	"math"

	"github.com/FleetKanban/fleetkanban/internal/ctxmem"
)

// VectorStore persists ctxmem.Vector rows. Vectors are encoded as
// little-endian packed float32 BLOBs; retrieval reads them into a
// []float32 for in-Go cosine similarity. The package is intentionally
// independent of the retrieval package so tests can exercise the
// encode / decode path without pulling the search pipeline.
type VectorStore struct{ db DB }

// Upsert writes or replaces the vector for a node. Node's primary key
// is node_id so a ctx_node delete cascades here automatically.
func (s *VectorStore) Upsert(ctx context.Context, v ctxmem.Vector) error {
	if v.NodeID == "" || v.Model == "" || len(v.Vector) == 0 {
		return fmt.Errorf("%w: vector requires node_id, model, values", ctxmem.ErrInvalidArg)
	}
	if v.Dim > 0 && v.Dim != len(v.Vector) {
		return fmt.Errorf("%w: dim=%d != len(vector)=%d",
			ctxmem.ErrDimMismatch, v.Dim, len(v.Vector))
	}
	blob := encodeVector(v.Vector)
	_, err := s.db.Write().ExecContext(ctx, `
INSERT INTO ctx_node_vec(node_id, model, dim, vector, created_at)
 VALUES (?, ?, ?, ?, ?)
ON CONFLICT(node_id) DO UPDATE SET
    model      = excluded.model,
    dim        = excluded.dim,
    vector     = excluded.vector,
    created_at = excluded.created_at`,
		v.NodeID, v.Model, len(v.Vector), blob, nowUTC())
	if err != nil {
		return fmt.Errorf("ctxmem/store: upsert vector: %w", err)
	}
	return nil
}

// Delete removes the vector for a node (rare — FK cascade handles most
// cases; only used by explicit vector-rebuild flows).
func (s *VectorStore) Delete(ctx context.Context, nodeID string) error {
	_, err := s.db.Write().ExecContext(ctx, `DELETE FROM ctx_node_vec WHERE node_id = ?`, nodeID)
	return err
}

// CandidateRow is the projection returned by AllForRepo — it joins
// ctx_node_vec to ctx_node so retrieval can filter by enabled /
// repository without a second query.
type CandidateRow struct {
	NodeID string
	Vector []float32
}

// AllForRepo returns every enabled node's vector for a repo, filtered
// by model. Returns an empty slice (not an error) when no vectors
// exist. The vector pipeline is brute-force cosine, so this is the hot
// path when the Search tab is used; callers should cache the returned
// slice per-query.
func (s *VectorStore) AllForRepo(ctx context.Context, repoID, model string) ([]CandidateRow, error) {
	rows, err := s.db.Read().QueryContext(ctx, `
SELECT v.node_id, v.dim, v.vector
  FROM ctx_node_vec v
  JOIN ctx_node n ON n.id = v.node_id
 WHERE n.repo_id = ?
   AND n.enabled = 1
   AND v.model   = ?`, repoID, model)
	if err != nil {
		return nil, fmt.Errorf("ctxmem/store: vectors for repo: %w", err)
	}
	defer rows.Close()
	var out []CandidateRow
	for rows.Next() {
		var (
			c    CandidateRow
			dim  int
			blob []byte
		)
		if err := rows.Scan(&c.NodeID, &dim, &blob); err != nil {
			return nil, err
		}
		c.Vector = decodeVector(blob, dim)
		out = append(out, c)
	}
	return out, rows.Err()
}

// Get fetches one vector by node ID.
func (s *VectorStore) Get(ctx context.Context, nodeID string) (ctxmem.Vector, error) {
	var (
		v    ctxmem.Vector
		blob []byte
	)
	var createdAt string
	err := s.db.Read().QueryRowContext(ctx, `
SELECT node_id, model, dim, vector, created_at
  FROM ctx_node_vec WHERE node_id = ?`, nodeID).Scan(
		&v.NodeID, &v.Model, &v.Dim, &blob, &createdAt)
	if err != nil {
		return ctxmem.Vector{}, translateError(err)
	}
	v.Vector = decodeVector(blob, v.Dim)
	v.CreatedAt = parseTime(createdAt)
	return v, nil
}

// CountAndDim returns (count, dim, total bytes) across all vectors for
// a repo. Used by Overview.
func (s *VectorStore) CountAndDim(ctx context.Context, repoID string) (count, dim int32, bytes int64, err error) {
	err = s.db.Read().QueryRowContext(ctx, `
SELECT COUNT(*), COALESCE(MAX(dim), 0), COALESCE(SUM(length(vector)), 0)
  FROM ctx_node_vec v
  JOIN ctx_node n ON n.id = v.node_id
 WHERE n.repo_id = ?`, repoID).Scan(&count, &dim, &bytes)
	if err != nil {
		return 0, 0, 0, fmt.Errorf("ctxmem/store: vector stats: %w", err)
	}
	return
}

// encodeVector packs a []float32 into a little-endian BLOB.
func encodeVector(v []float32) []byte {
	out := make([]byte, 4*len(v))
	for i, x := range v {
		binary.LittleEndian.PutUint32(out[i*4:], math.Float32bits(x))
	}
	return out
}

// decodeVector unpacks a BLOB back into a []float32. dim drives the
// expected length so a partial read surfaces as a shorter slice (the
// caller then rejects the row at score time).
func decodeVector(blob []byte, dim int) []float32 {
	if dim <= 0 {
		dim = len(blob) / 4
	}
	if len(blob) < 4*dim {
		dim = len(blob) / 4
	}
	out := make([]float32, dim)
	for i := 0; i < dim; i++ {
		bits := binary.LittleEndian.Uint32(blob[i*4:])
		out[i] = math.Float32frombits(bits)
	}
	return out
}
