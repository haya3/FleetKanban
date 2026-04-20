// Package inject builds the Markdown blocks that ctxmem prepends to
// Copilot prompts. Three tiers are supported:
//
//   - Passive: assembled once at session start from the task goal. Uses
//     the hybrid search pipeline seeded with the goal to pull the most
//     relevant nodes + their 1-hop graph neighborhood.
//   - Reactive: responds to the agent's search_memory tool call (if
//     the Copilot SDK supports tool registration).
//   - Active: appended between steps based on what files the agent
//     just touched (when the SDK exposes a prepareStep-style hook).
//
// Only Passive is implemented end-to-end in this phase; Reactive /
// Active are scaffolded so the integration can extend them without
// touching callers.
package inject

import (
	"context"
	"fmt"
	"strings"

	"github.com/FleetKanban/fleetkanban/internal/ctxmem"
	"github.com/FleetKanban/fleetkanban/internal/ctxmem/retrieval"
	"github.com/FleetKanban/fleetkanban/internal/ctxmem/store"
)

// Builder assembles injection blocks. Fields are the stores /
// services it queries during assembly.
type Builder struct {
	settings *store.SettingsStore
	nodes    *store.NodeStore
	facts    *store.FactStore
	search   *retrieval.Searcher
}

// New returns a Builder.
func New(settings *store.SettingsStore, nodes *store.NodeStore, facts *store.FactStore, searcher *retrieval.Searcher) *Builder {
	return &Builder{settings: settings, nodes: nodes, facts: facts, search: searcher}
}

// PassiveRequest carries the per-session inputs. RawPrompt is the task
// goal (natural language). TaskID is optional — when present, the
// assembler can look up prior review feedback / subtask context in
// later iterations.
type PassiveRequest struct {
	RepoID    string
	RawPrompt string
	TaskID    string
}

// BuildPassive returns the Markdown block to prepend to the session
// prompt. Empty string + nil sources when Memory is disabled for the
// repo or no relevant entries surface. Callers should always call
// even when unsure — the short-circuit avoids useless work.
func (b *Builder) BuildPassive(ctx context.Context, req PassiveRequest) (ctxmem.InjectionPreview, error) {
	set, err := b.settings.Get(ctx, req.RepoID)
	if err != nil {
		return ctxmem.InjectionPreview{Tier: "passive"}, err
	}
	if !set.Enabled {
		return ctxmem.InjectionPreview{Tier: "passive"}, nil
	}

	// Always include pinned nodes regardless of the query ranking.
	pinned, _, err := b.nodes.List(ctx, store.ListFilter{
		RepoID:      req.RepoID,
		PinnedOnly:  true,
		EnabledOnly: true,
		Limit:       20,
	})
	if err != nil {
		return ctxmem.InjectionPreview{Tier: "passive"}, err
	}

	// Hybrid search seeded with the task prompt.
	var searchHits []ctxmem.SearchHit
	if b.search != nil {
		res, err := b.search.Search(ctx, retrieval.Query{
			RepoID:        req.RepoID,
			Text:          req.RawPrompt,
			OnlyEnabled:   true,
			Limit:         12,
			TopKNeighbors: set.TopKNeighbors,
		})
		if err == nil {
			searchHits = res.Channels["fused"]
		}
	}

	// Assemble in Markdown. Token budget is hard-limited by truncating
	// the tail of searchHits; pinned always survives.
	var md strings.Builder
	var sources []ctxmem.InjectionSource
	tokens := 0

	md.WriteString("## Repository Memory\n\n")
	md.WriteString("The following context was retrieved from the FleetKanban memory store. ")
	md.WriteString("Treat pinned items as authoritative; other items are best-effort hints.\n\n")

	if len(pinned) > 0 {
		md.WriteString("### Pinned\n\n")
		for _, n := range pinned {
			addNodeSection(&md, n, "pinned")
			sources = append(sources, ctxmem.InjectionSource{
				SourceType: "node",
				SourceRef:  n.ID,
				Label:      n.Label,
				Channel:    "passive",
				Tokens:     int32(estimateTokens(n)),
				Relevance:  1.0,
			})
			tokens += estimateTokens(n)
		}
	}

	if len(searchHits) > 0 {
		md.WriteString("### Related\n\n")
		for _, h := range searchHits {
			if tokens >= set.PassiveTokenBudget {
				break
			}
			addNodeSection(&md, h.Node, h.Reason)
			sources = append(sources, ctxmem.InjectionSource{
				SourceType: "node",
				SourceRef:  h.Node.ID,
				Label:      h.Node.Label,
				Channel:    "passive",
				Tokens:     int32(estimateTokens(h.Node)),
				Relevance:  h.Score,
			})
			tokens += estimateTokens(h.Node)
		}
	}

	// Temporal facts anchored on pinned / top-ranked nodes.
	subjectSet := map[string]struct{}{}
	for _, n := range pinned {
		subjectSet[n.ID] = struct{}{}
	}
	for _, h := range searchHits {
		subjectSet[h.Node.ID] = struct{}{}
	}
	if len(subjectSet) > 0 {
		md.WriteString("### Active Facts\n\n")
		factsShown := 0
		for nodeID := range subjectSet {
			facts, _, err := b.facts.List(ctx, store.FactFilter{
				RepoID:         req.RepoID,
				SubjectNodeID:  nodeID,
				IncludeExpired: false,
				Limit:          3,
			})
			if err != nil {
				continue
			}
			for _, f := range facts {
				if tokens >= set.PassiveTokenBudget {
					break
				}
				fmt.Fprintf(&md, "- %s %s (since %s)\n",
					f.Predicate, f.ObjectText, f.ValidFrom.Format("2006-01-02"))
				sources = append(sources, ctxmem.InjectionSource{
					SourceType: "fact",
					SourceRef:  f.ID,
					Label:      f.Predicate + " " + f.ObjectText,
					Channel:    "passive",
					Tokens:     10,
					Relevance:  0.7,
				})
				tokens += 10
				factsShown++
			}
		}
		if factsShown == 0 {
			md.WriteString("- _no active facts linked to the related items above_\n")
		}
	}

	md.WriteString("\n---\n\n")

	return ctxmem.InjectionPreview{
		SystemPrompt:    md.String(),
		Sources:         sources,
		EstimatedTokens: int32(tokens),
		Tier:            "passive",
	}, nil
}

// addNodeSection appends the standard node block used across all
// tiers. reason is rendered in italics to mark why it was included.
func addNodeSection(b *strings.Builder, n ctxmem.Node, reason string) {
	fmt.Fprintf(b, "#### %s — %s\n", n.Kind, n.Label)
	if reason != "" {
		fmt.Fprintf(b, "_%s_\n\n", reason)
	}
	if n.ContentMD != "" {
		b.WriteString(n.ContentMD)
		if !strings.HasSuffix(n.ContentMD, "\n") {
			b.WriteString("\n")
		}
		b.WriteString("\n")
	}
}

// estimateTokens is a coarse token count (≈ 4 characters per token).
// We don't ship a tokenizer to avoid dragging in tiktoken / llama.cpp
// — the estimate is only used to decide when to truncate.
func estimateTokens(n ctxmem.Node) int {
	return (len(n.Label) + len(n.ContentMD)) / 4
}
