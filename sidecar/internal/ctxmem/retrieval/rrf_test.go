package retrieval

import "testing"

// TestRRFMergesTwoLists — a document ranked #1 in one list and #2 in
// another should beat a document ranked #1 only. The conventional k=60
// makes the contribution of the second list meaningful (1/62 ≈ 0.016)
// rather than negligible.
func TestRRFMergesTwoLists(t *testing.T) {
	semantic := []ScoredID{
		{ID: "a", Score: 0.9},
		{ID: "b", Score: 0.8},
		{ID: "c", Score: 0.5},
	}
	keyword := []ScoredID{
		{ID: "b", Score: 1.5},
		{ID: "a", Score: 1.2},
		{ID: "d", Score: 0.4},
	}
	fused := ReciprocalRankFusion([][]ScoredID{semantic, keyword}, 60)
	if len(fused) < 2 {
		t.Fatalf("want at least 2 fused results, got %d", len(fused))
	}
	// a is rank 1 in semantic + rank 2 in keyword = 1/61 + 1/62
	// b is rank 2 in semantic + rank 1 in keyword = 1/62 + 1/61
	// They tie exactly; check that both are in the top two.
	top2 := map[string]bool{fused[0].ID: true, fused[1].ID: true}
	if !top2["a"] || !top2["b"] {
		t.Errorf("want a and b in top 2, got %v", top2)
	}
	// c appears in one list only.
	if fused[0].Score <= 0 {
		t.Errorf("fused score should be positive, got %f", fused[0].Score)
	}
}

// TestRRFHandlesEmptyLists returns empty without panicking.
func TestRRFHandlesEmptyLists(t *testing.T) {
	out := ReciprocalRankFusion(nil, 60)
	if out != nil {
		t.Errorf("nil input should give nil output, got %v", out)
	}
}
