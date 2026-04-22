package inject

import (
	"context"

	"github.com/haya3/FleetKanban/internal/ctxmem"
	"github.com/haya3/FleetKanban/internal/ctxmem/retrieval"
)

// BuildForReview produces the Markdown block the Reviewer session sees.
// Distinct from Passive because Reviewer's ranking priorities differ:
// Decisions and Constraints must surface first so rule violations can
// be flagged; File nodes that dominate Passive's Code-stage output add
// little to a read-only review. The query blends the task goal with a
// short diff summary so the retriever considers both "what was the
// task?" and "what actually changed?".
func (b *Builder) BuildForReview(ctx context.Context, repoID, taskGoal, diffSummary, taskID string) (ctxmem.InjectionPreview, error) {
	set, err := b.settings.Get(ctx, repoID)
	if err != nil {
		return ctxmem.InjectionPreview{Tier: "review"}, err
	}
	if !set.Enabled || b.search == nil {
		return ctxmem.InjectionPreview{Tier: "review"}, nil
	}
	query := taskGoal
	if diffSummary != "" {
		query = taskGoal + " " + diffSummary
	}
	res, err := b.search.Search(ctx, retrieval.Query{
		RepoID:        repoID,
		Text:          query,
		Kinds:         []string{ctxmem.NodeKindDecision, ctxmem.NodeKindConstraint, ctxmem.NodeKindConcept},
		OnlyEnabled:   true,
		Limit:         8,
		TopKNeighbors: set.TopKNeighbors,
	})
	if err != nil {
		return ctxmem.InjectionPreview{Tier: "review"}, err
	}
	return b.assembleReviewHits(res.Channels["fused"]), nil
}

// assembleReviewHits renders Decision / Constraint / Concept hits with
// section headings that nudge the Reviewer to treat them as authoritative
// rules rather than generic context.
func (b *Builder) assembleReviewHits(hits []ctxmem.SearchHit) ctxmem.InjectionPreview {
	if len(hits) == 0 {
		return ctxmem.InjectionPreview{Tier: "review"}
	}
	var decisions, constraints, concepts []ctxmem.SearchHit
	for _, h := range hits {
		switch h.Node.Kind {
		case ctxmem.NodeKindDecision:
			decisions = append(decisions, h)
		case ctxmem.NodeKindConstraint:
			constraints = append(constraints, h)
		default:
			concepts = append(concepts, h)
		}
	}
	md := "## Repository Memory (review)\n\n"
	var sources []ctxmem.InjectionSource
	tokens := 0
	add := func(section string, list []ctxmem.SearchHit) {
		if len(list) == 0 {
			return
		}
		md += "### " + section + "\n\n"
		for _, h := range list {
			md += "#### " + h.Node.Label + "\n"
			if h.Reason != "" {
				md += "_" + h.Reason + "_\n\n"
			}
			if h.Node.ContentMD != "" {
				md += h.Node.ContentMD
				if h.Node.ContentMD[len(h.Node.ContentMD)-1] != '\n' {
					md += "\n"
				}
				md += "\n"
			}
			sources = append(sources, ctxmem.InjectionSource{
				SourceType: "node",
				SourceRef:  h.Node.ID,
				Label:      h.Node.Label,
				Channel:    "review",
				Tokens:     int32(estimateTokens(h.Node)),
				Relevance:  h.Score,
			})
			tokens += estimateTokens(h.Node)
		}
	}
	add("Applicable Decisions", decisions)
	add("Binding Constraints", constraints)
	add("Related Concepts", concepts)
	md += "\n---\n\n"
	return ctxmem.InjectionPreview{
		SystemPrompt:    md,
		Sources:         sources,
		EstimatedTokens: int32(tokens),
		Tier:            "review",
	}
}
