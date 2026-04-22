package retrieval

import (
	"context"
	"fmt"

	"github.com/haya3/FleetKanban/internal/ctxmem"
	"github.com/haya3/FleetKanban/internal/ctxmem/embed"
	"github.com/haya3/FleetKanban/internal/ctxmem/graph"
	"github.com/haya3/FleetKanban/internal/ctxmem/store"
)

// Searcher runs hybrid retrieval (semantic + keyword + graph-boost
// with RRF fusion) against a single repo's context memory.
type Searcher struct {
	nodes    *store.NodeStore
	vectors  *store.VectorStore
	fts      *store.FTSStore
	graph    *graph.Graph
	registry *embed.Registry
}

// New returns a Searcher bound to the provided stores and the
// embedding registry. Graph is used for the neighborhood boost step.
func New(
	nodes *store.NodeStore,
	vectors *store.VectorStore,
	fts *store.FTSStore,
	g *graph.Graph,
	reg *embed.Registry,
) *Searcher {
	return &Searcher{nodes: nodes, vectors: vectors, fts: fts, graph: g, registry: reg}
}

// Query parameters for Search.
type Query struct {
	RepoID        string
	Text          string
	Kinds         []string
	OnlyEnabled   bool
	Limit         int // per-channel cap; 0 → 20
	TopKNeighbors int // graph-boost hop expansion; 0 disables
}

// Search runs the full pipeline and returns results bucketed by
// channel plus the fused / boosted ranking. The "fused" bucket is the
// production hybrid ranking — the three raw channels are returned so
// the Search tab can render them side by side for explainability.
func (s *Searcher) Search(ctx context.Context, q Query) (ctxmem.SearchResult, error) {
	limit := q.Limit
	if limit <= 0 {
		limit = 20
	}

	out := ctxmem.SearchResult{Channels: map[string][]ctxmem.SearchHit{}}

	// Keyword (FTS5 / BM25).
	ftsHits, err := s.fts.Search(ctx, q.RepoID, q.Text, limit)
	if err != nil {
		return out, err
	}
	keywordList := make([]ScoredID, len(ftsHits))
	for i, h := range ftsHits {
		keywordList[i] = ScoredID{ID: h.NodeID, Score: h.Score}
	}

	// Semantic (vector cosine).
	provider, provErr := s.registry.Get(q.RepoID)
	var semanticList []ScoredID
	if provErr == nil {
		queryVecs, err := provider.Embed(ctx, []string{q.Text})
		if err == nil && len(queryVecs) > 0 && len(queryVecs[0]) > 0 {
			candidates, err := s.vectors.AllForRepo(ctx, q.RepoID, provider.Name())
			if err != nil {
				return out, err
			}
			ids := make([]string, len(candidates))
			vecs := make([][]float32, len(candidates))
			for i, c := range candidates {
				ids[i] = c.NodeID
				vecs[i] = c.Vector
			}
			semanticList = CosineTopK(queryVecs[0], vecs, ids, limit)
		}
	}

	// Populate channel views.
	keywordHits := s.hitsFromRanking(ctx, keywordList, "keyword", "BM25 match")
	out.Channels["keyword"] = keywordHits
	semanticHits := s.hitsFromRanking(ctx, semanticList, "semantic", "cosine similarity")
	out.Channels["semantic"] = semanticHits

	// Fuse keyword + semantic with RRF.
	fused := ReciprocalRankFusion([][]ScoredID{keywordList, semanticList}, 60)
	if len(fused) > limit {
		fused = fused[:limit]
	}

	// Graph neighborhood boost: for each top-ranked fused hit, pull
	// 1-hop neighbors and upweight any that are already in the fused
	// set (or add them with a small bonus if they are not). This is
	// the "+7pp" differentiator from the design doc.
	if q.TopKNeighbors > 0 && len(fused) > 0 {
		fused = s.applyGraphBoost(ctx, fused, q.TopKNeighbors, limit)
	}

	fusedHits := s.hitsFromRanking(ctx, fused, "fused", "RRF + neighborhood")
	out.Channels["fused"] = fusedHits

	// Deduplicate for TotalUnique.
	seen := map[string]struct{}{}
	for _, list := range [][]ctxmem.SearchHit{keywordHits, semanticHits, fusedHits} {
		for _, h := range list {
			seen[h.Node.ID] = struct{}{}
		}
	}
	out.TotalUnique = len(seen)

	return out, nil
}

func (s *Searcher) applyGraphBoost(ctx context.Context, fused []ScoredID, maxHops, limit int) []ScoredID {
	const boostWeight = 0.3 // neighborhood bonus relative to RRF contribution (~1/60 = 0.0166 per rank)
	scoreByID := map[string]float32{}
	for _, h := range fused {
		scoreByID[h.ID] = h.Score
	}
	// Fetch top-3 fused hits' neighborhoods (too many probes would
	// dilute the signal and hit the SQLite query rate).
	probeLimit := 3
	if probeLimit > len(fused) {
		probeLimit = len(fused)
	}
	for i := 0; i < probeLimit; i++ {
		neighbors, err := s.graph.Neighbors(ctx, fused[i].ID, maxHops, nil)
		if err != nil {
			continue
		}
		for _, n := range neighbors {
			scoreByID[n.ID] += boostWeight * fused[i].Score / float32(maxHops)
		}
	}
	merged := make([]ScoredID, 0, len(scoreByID))
	for id, s := range scoreByID {
		merged = append(merged, ScoredID{ID: id, Score: s})
	}
	sortByScoreDesc(merged)
	if len(merged) > limit {
		merged = merged[:limit]
	}
	return merged
}

func (s *Searcher) hitsFromRanking(ctx context.Context, ranking []ScoredID, channel, reason string) []ctxmem.SearchHit {
	if len(ranking) == 0 {
		return nil
	}
	ids := make([]string, len(ranking))
	for i, r := range ranking {
		ids[i] = r.ID
	}
	nodes, err := s.nodes.GetMany(ctx, ids)
	if err != nil {
		return nil
	}
	byID := make(map[string]ctxmem.Node, len(nodes))
	for _, n := range nodes {
		byID[n.ID] = n
	}
	out := make([]ctxmem.SearchHit, 0, len(ranking))
	for i, r := range ranking {
		n, ok := byID[r.ID]
		if !ok {
			continue
		}
		out = append(out, ctxmem.SearchHit{
			Node:    n,
			Score:   r.Score,
			Rank:    i + 1,
			Channel: channel,
			Reason:  fmt.Sprintf("%s (score=%.3f)", reason, r.Score),
		})
	}
	return out
}
