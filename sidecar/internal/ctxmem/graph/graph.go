// Package graph implements closure maintenance and higher-level graph
// operations (N-hop neighbors, impact analysis, co-access expansion)
// over the ctx_node / ctx_edge / ctx_closure tables. Closure is
// rewritten atomically from the full edge set rather than incrementally
// because our repos include cycles (coAccessedWith) and BFS in Go is
// easier to reason about than recursive CTE triggers.
package graph

import (
	"context"
	"database/sql"
	"fmt"

	"github.com/haya3/fleetkanban/internal/ctxmem"
	"github.com/haya3/fleetkanban/internal/ctxmem/store"
)

// DefaultMaxDepth caps BFS traversal when RebuildClosure runs. Five
// hops is enough to discover transitive dependencies without blowing
// up row counts on dense graphs (coAccessedWith can produce stars).
const DefaultMaxDepth = 5

// Graph bundles the tables needed to maintain and query the closure.
// Callers get one from ctxmem.Service rather than constructing it
// directly so the store pair is consistent.
type Graph struct {
	nodes   *store.NodeStore
	edges   *store.EdgeStore
	closure *store.ClosureStore
	writer  *sql.DB
}

// New returns a Graph ready to operate against db and the provided
// stores. writer is the serialized write handle used for transactions
// that rewrite closure rows in bulk.
func New(nodes *store.NodeStore, edges *store.EdgeStore, closure *store.ClosureStore, writer *sql.DB) *Graph {
	return &Graph{nodes: nodes, edges: edges, closure: closure, writer: writer}
}

// Rebuild recomputes the closure for a repository from scratch. Runs
// in a single transaction: delete all closure rows for the repo,
// compute BFS from every node, insert the resulting (src, dst, depth,
// via_rel) tuples. Idempotent.
func (g *Graph) Rebuild(ctx context.Context, repoID string, maxDepth int) error {
	if maxDepth <= 0 {
		maxDepth = DefaultMaxDepth
	}

	// Snapshot edges outside the write transaction so the read query
	// doesn't contend with the concurrent DELETE.
	edges, err := g.edges.AllForRepo(ctx, repoID)
	if err != nil {
		return err
	}

	// Build adjacency: src → [(dst, rel)].
	type hop struct {
		Dst string
		Rel string
	}
	adj := make(map[string][]hop, len(edges))
	srcs := make(map[string]struct{}, len(edges))
	for _, e := range edges {
		adj[e.SrcNodeID] = append(adj[e.SrcNodeID], hop{Dst: e.DstNodeID, Rel: e.Rel})
		srcs[e.SrcNodeID] = struct{}{}
	}

	// BFS from each node that has at least one outgoing edge. Closure
	// rows record (src, dst, depth, via_rel) where via_rel is the
	// relationship of the first hop in the discovered path — that
	// lets retrieval filter neighbors by relationship without rebuilding
	// the full path.
	type discovered struct {
		dst    string
		depth  int
		viaRel string
	}
	var rows []store.ClosureRow
	for src := range srcs {
		visited := map[string]struct{}{src: {}}
		queue := []discovered{{dst: src, depth: 0, viaRel: ""}}
		for len(queue) > 0 {
			cur := queue[0]
			queue = queue[1:]
			if cur.depth >= maxDepth {
				continue
			}
			for _, h := range adj[cur.dst] {
				if _, seen := visited[h.Dst]; seen {
					continue
				}
				visited[h.Dst] = struct{}{}
				nextDepth := cur.depth + 1
				viaRel := cur.viaRel
				if viaRel == "" {
					viaRel = h.Rel
				}
				rows = append(rows, store.ClosureRow{
					RepoID:    repoID,
					SrcNodeID: src,
					DstNodeID: h.Dst,
					Depth:     nextDepth,
					ViaRel:    viaRel,
				})
				queue = append(queue, discovered{dst: h.Dst, depth: nextDepth, viaRel: viaRel})
			}
		}
	}

	tx, err := g.writer.BeginTx(ctx, nil)
	if err != nil {
		return fmt.Errorf("ctxmem/graph: begin tx: %w", err)
	}
	defer func() { _ = tx.Rollback() }()

	if err := g.closure.DeleteForRepo(ctx, tx, repoID); err != nil {
		return err
	}
	// Flush in chunks of 500 to keep the prepared-statement cache happy.
	const chunk = 500
	for i := 0; i < len(rows); i += chunk {
		end := i + chunk
		if end > len(rows) {
			end = len(rows)
		}
		if err := g.closure.BulkInsert(ctx, tx, rows[i:end]); err != nil {
			return err
		}
	}
	return tx.Commit()
}

// Neighbors returns nodes reachable from rootID within maxHops, filtered
// optionally by via_rel. Depth ordering is preserved (BFS-friendly
// layout for graph-viz and prompt injection).
func (g *Graph) Neighbors(ctx context.Context, rootID string, maxHops int, rels []string) ([]ctxmem.Node, error) {
	closureRows, err := g.closure.DescendantsByDepth(ctx, rootID, maxHops)
	if err != nil {
		return nil, err
	}
	return g.resolveRows(ctx, closureRows, rels, false)
}

// ImpactedBy returns nodes that can reach rootID within maxHops —
// the reverse closure. Used for impact analysis ("if I change X,
// what's affected").
func (g *Graph) ImpactedBy(ctx context.Context, rootID string, maxHops int, rels []string) ([]ctxmem.Node, error) {
	closureRows, err := g.closure.AncestorsByDepth(ctx, rootID, maxHops)
	if err != nil {
		return nil, err
	}
	return g.resolveRows(ctx, closureRows, rels, true)
}

func (g *Graph) resolveRows(ctx context.Context, rows []store.ClosureRow, rels []string, reverse bool) ([]ctxmem.Node, error) {
	if len(rows) == 0 {
		return nil, nil
	}
	relSet := map[string]struct{}{}
	for _, r := range rels {
		relSet[r] = struct{}{}
	}
	idSet := map[string]struct{}{}
	ids := make([]string, 0, len(rows))
	for _, r := range rows {
		if len(rels) > 0 {
			if _, ok := relSet[r.ViaRel]; !ok {
				continue
			}
		}
		var target string
		if reverse {
			target = r.SrcNodeID
		} else {
			target = r.DstNodeID
		}
		if _, seen := idSet[target]; seen {
			continue
		}
		idSet[target] = struct{}{}
		ids = append(ids, target)
	}
	if len(ids) == 0 {
		return nil, nil
	}
	return g.nodes.GetMany(ctx, ids)
}
