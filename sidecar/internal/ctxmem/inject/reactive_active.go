package inject

import (
	"context"

	"github.com/haya3/FleetKanban/internal/ctxmem"
	"github.com/haya3/FleetKanban/internal/ctxmem/retrieval"
)

// BuildReactive handles the search_memory tool invocation. The agent
// supplies a free-form query; we run the full hybrid pipeline and
// return the same Markdown block shape Passive uses, so the LLM's
// rendering logic is consistent across tiers.
//
// Wiring into the Copilot SDK depends on whether session-side tool
// registration is exposed — see analyzer / runner comments for the
// state of that investigation.
func (b *Builder) BuildReactive(ctx context.Context, repoID, query string) (ctxmem.InjectionPreview, error) {
	set, err := b.settings.Get(ctx, repoID)
	if err != nil {
		return ctxmem.InjectionPreview{Tier: "reactive"}, err
	}
	if !set.Enabled || b.search == nil {
		return ctxmem.InjectionPreview{Tier: "reactive"}, nil
	}
	res, err := b.search.Search(ctx, retrieval.Query{
		RepoID:        repoID,
		Text:          query,
		OnlyEnabled:   true,
		Limit:         8,
		TopKNeighbors: set.TopKNeighbors,
	})
	if err != nil {
		return ctxmem.InjectionPreview{Tier: "reactive"}, err
	}
	return b.assembleHitsOnly(res.Channels["fused"], "reactive"), nil
}

// BuildActive handles between-step injection. lastToolCall is whatever
// event kind the agent just emitted ("tool.end"); affectedFiles is the
// set of files referenced in that call. We look up each file as a
// Node, expand 1-hop neighbors, and emit a tight block the session
// can absorb between steps.
func (b *Builder) BuildActive(ctx context.Context, repoID string, affectedFiles []string) (ctxmem.InjectionPreview, error) {
	set, err := b.settings.Get(ctx, repoID)
	if err != nil {
		return ctxmem.InjectionPreview{Tier: "active"}, err
	}
	if !set.Enabled || b.search == nil || len(affectedFiles) == 0 {
		return ctxmem.InjectionPreview{Tier: "active"}, nil
	}
	// Assemble a coarse query: join filenames so the BM25 channel
	// catches File nodes whose label or content contains the paths.
	joined := ""
	for i, f := range affectedFiles {
		if i > 0 {
			joined += " "
		}
		joined += f
	}
	res, err := b.search.Search(ctx, retrieval.Query{
		RepoID:        repoID,
		Text:          joined,
		OnlyEnabled:   true,
		Limit:         6,
		TopKNeighbors: set.TopKNeighbors,
	})
	if err != nil {
		return ctxmem.InjectionPreview{Tier: "active"}, err
	}
	return b.assembleHitsOnly(res.Channels["fused"], "active"), nil
}

// assembleHitsOnly renders a Markdown block for reactive / active
// tiers. The shape mirrors Passive's "Related" section without pinned
// / facts — those are one-per-session and redundant at reactive /
// active firing rate.
func (b *Builder) assembleHitsOnly(hits []ctxmem.SearchHit, tier string) ctxmem.InjectionPreview {
	if len(hits) == 0 {
		return ctxmem.InjectionPreview{Tier: tier}
	}
	var md = "## Repository Memory (" + tier + ")\n\n"
	var sources []ctxmem.InjectionSource
	tokens := 0
	for _, h := range hits {
		// Simple "#### Kind — Label" block inline; keeping this
		// self-contained avoids importing strings.Builder sharers.
		md += "#### " + h.Node.Kind + " — " + h.Node.Label + "\n"
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
			Channel:    tier,
			Tokens:     int32(estimateTokens(h.Node)),
			Relevance:  h.Score,
		})
		tokens += estimateTokens(h.Node)
	}
	md += "\n---\n\n"
	return ctxmem.InjectionPreview{
		SystemPrompt:    md,
		Sources:         sources,
		EstimatedTokens: int32(tokens),
		Tier:            tier,
	}
}
