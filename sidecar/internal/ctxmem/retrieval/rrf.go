package retrieval

// ReciprocalRankFusion merges multiple ranked lists into a single
// ranking via RRF with the conventional k=60 constant. This is the
// deduplicating step in the hybrid pipeline — semantic and keyword
// lists may each score the same node under different units, and RRF
// converts both to a rank-based contribution before summing.
//
// Reference: Cormack, Clarke & Büttcher 2009, "Reciprocal Rank Fusion
// outperforms Condorcet and individual Rank Learning Methods".
func ReciprocalRankFusion(lists [][]ScoredID, k int) []ScoredID {
	if k <= 0 {
		k = 60
	}
	if len(lists) == 0 {
		return nil
	}
	scores := map[string]float32{}
	for _, list := range lists {
		for rank, hit := range list {
			scores[hit.ID] += 1.0 / float32(k+rank+1)
		}
	}
	fused := make([]ScoredID, 0, len(scores))
	for id, s := range scores {
		fused = append(fused, ScoredID{ID: id, Score: s})
	}
	sortByScoreDesc(fused)
	return fused
}

// sortByScoreDesc sorts fused hits in-place by score descending.
// Implemented inline to avoid importing sort in a hot path — small n
// means insertion sort is fastest.
func sortByScoreDesc(hits []ScoredID) {
	for i := 1; i < len(hits); i++ {
		for j := i; j > 0 && hits[j].Score > hits[j-1].Score; j-- {
			hits[j], hits[j-1] = hits[j-1], hits[j]
		}
	}
}
