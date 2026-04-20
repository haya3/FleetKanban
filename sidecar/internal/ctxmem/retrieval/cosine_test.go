package retrieval

import (
	"math"
	"testing"
)

// TestCosineTopK exercises the brute-force ANN with a hand-crafted
// query + 3 candidates: one parallel, one anti-parallel, one
// orthogonal. The ranking must put parallel first and orthogonal
// somewhere below anti-parallel (cos(180°) = -1 < cos(90°) = 0).
func TestCosineTopK(t *testing.T) {
	query := []float32{1, 0, 0}
	candidates := [][]float32{
		{1, 0, 0},  // parallel, cos=1
		{-1, 0, 0}, // anti-parallel, cos=-1
		{0, 1, 0},  // orthogonal, cos=0
	}
	ids := []string{"a", "b", "c"}
	hits := CosineTopK(query, candidates, ids, 3)
	if len(hits) != 3 {
		t.Fatalf("want 3 hits, got %d", len(hits))
	}
	if hits[0].ID != "a" {
		t.Errorf("want first=a, got %q", hits[0].ID)
	}
	if hits[2].ID != "b" {
		t.Errorf("want last=b, got %q", hits[2].ID)
	}
	// Parallel should score ≈ 1.0.
	if math.Abs(float64(hits[0].Score)-1.0) > 1e-5 {
		t.Errorf("parallel score should be 1, got %f", hits[0].Score)
	}
}

// TestCosineTopKLimit bounds the output to k even when many candidates
// match.
func TestCosineTopKLimit(t *testing.T) {
	query := []float32{1, 1}
	var cands [][]float32
	var ids []string
	for i := 0; i < 20; i++ {
		cands = append(cands, []float32{1, 1})
		ids = append(ids, string(rune('a'+i)))
	}
	hits := CosineTopK(query, cands, ids, 5)
	if len(hits) != 5 {
		t.Fatalf("want 5 hits, got %d", len(hits))
	}
}

// TestCosineSkipsDimMismatch — any candidate whose length differs from
// the query is silently skipped rather than returning a misleading
// zero-score hit.
func TestCosineSkipsDimMismatch(t *testing.T) {
	query := []float32{1, 0, 0}
	cands := [][]float32{
		{1, 0, 0},
		{1, 0}, // wrong dim
	}
	ids := []string{"good", "bad"}
	hits := CosineTopK(query, cands, ids, 5)
	if len(hits) != 1 {
		t.Fatalf("want 1 hit (bad dim skipped), got %d", len(hits))
	}
	if hits[0].ID != "good" {
		t.Errorf("want good, got %q", hits[0].ID)
	}
}
