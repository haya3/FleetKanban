// Package retrieval implements the hybrid search pipeline: pure-Go
// cosine similarity over ctx_node_vec, FTS5 BM25 over ctx_node_fts,
// Reciprocal Rank Fusion of the two, and a graph-neighborhood boost
// that promotes top-ranked hits' close neighbors. The pipeline is
// brute-force on purpose — FleetKanban's single-repo scale (up to
// ~50K nodes) cleared the ~40ms budget in benchmarks, and keeping a
// pure-Go implementation preserves the CGO_ENABLED=0 build.
package retrieval

import "math"

// ScoredID is the index-independent representation of a ranked hit.
type ScoredID struct {
	ID    string
	Score float32
}

// CosineTopK returns the top-k ids from candidates scored against
// query. Returns fewer than k when the candidate pool is smaller.
// Uses a linear insertion-sort into a fixed-size slice because k is
// typically < 100 and the constant-factor savings beat heap overhead.
func CosineTopK(query []float32, candidates [][]float32, ids []string, k int) []ScoredID {
	if len(query) == 0 || len(candidates) == 0 || k <= 0 {
		return nil
	}
	qnorm := norm(query)
	if qnorm == 0 {
		return nil
	}
	top := make([]ScoredID, 0, k)
	for i, c := range candidates {
		if len(c) != len(query) {
			continue
		}
		score := cosine(query, c, qnorm)
		if math.IsNaN(float64(score)) {
			continue
		}
		top = insertTop(top, ScoredID{ID: ids[i], Score: score}, k)
	}
	return top
}

func insertTop(top []ScoredID, h ScoredID, k int) []ScoredID {
	pos := len(top)
	for i := 0; i < len(top); i++ {
		if h.Score > top[i].Score {
			pos = i
			break
		}
	}
	if pos >= k {
		return top
	}
	if len(top) < k {
		top = append(top, ScoredID{})
	}
	copy(top[pos+1:], top[pos:len(top)-1])
	top[pos] = h
	return top
}

// cosine computes the cosine similarity between two same-length
// vectors. qnorm is passed in to avoid recomputing the query norm
// across the batch.
func cosine(a, b []float32, qnorm float64) float32 {
	var dot, bnorm float64
	for i := 0; i < len(a); i++ {
		av := float64(a[i])
		bv := float64(b[i])
		dot += av * bv
		bnorm += bv * bv
	}
	if bnorm == 0 {
		return 0
	}
	return float32(dot / (qnorm * math.Sqrt(bnorm)))
}

// norm returns ||v||.
func norm(v []float32) float64 {
	var s float64
	for _, x := range v {
		s += float64(x) * float64(x)
	}
	return math.Sqrt(s)
}
