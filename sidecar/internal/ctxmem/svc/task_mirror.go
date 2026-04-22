package svc

import (
	"context"
	"fmt"
	"strings"

	"github.com/haya3/FleetKanban/internal/ctxmem"
	"github.com/haya3/FleetKanban/internal/ctxmem/retrieval"
)

// IngestTaskAsNode mirrors a finalized Task into ctx_node with
// Kind="Task" so it joins the hybrid search index and becomes a
// suggestion candidate for the next task's new-task dialog. Using
// the existing ctx_node / ctx_node_vec / ctx_node_fts infrastructure
// avoids a parallel embedding store and makes Task → Decision edges
// automatically benefit from graph-boost retrieval.
//
// Idempotent: node ID is derived from taskID so re-ingesting the same
// task upserts in place. Called by the orchestrator on the disabled →
// Done (Keep or Merge) transition; on-cancel / on-discard do not mirror
// so abandoned drafts never leak into search.
func (s *Service) IngestTaskAsNode(ctx context.Context, repoID, taskID, goal, summary string) (ctxmem.Node, error) {
	if repoID == "" || taskID == "" {
		return ctxmem.Node{}, fmt.Errorf("%w: repo_id and task_id required", ctxmem.ErrInvalidArg)
	}
	label := strings.TrimSpace(goal)
	if label == "" {
		label = "task " + taskID
	}
	if len(label) > 140 {
		label = label[:140] + "…"
	}
	var content strings.Builder
	content.WriteString("**Goal:** ")
	content.WriteString(goal)
	if summary != "" {
		content.WriteString("\n\n**Summary:**\n")
		content.WriteString(summary)
	}
	n := ctxmem.Node{
		ID:           "task:" + taskID,
		RepoID:       repoID,
		Kind:         ctxmem.NodeKindTask,
		Label:        label,
		ContentMD:    content.String(),
		SourceKind:   ctxmem.SourceSessionSummary,
		SourceTaskID: taskID,
		Enabled:      true,
		Confidence:   1.0,
	}
	if err := s.Stores.Nodes.Upsert(ctx, n); err != nil {
		return ctxmem.Node{}, err
	}
	// Best-effort embedding — Memory may be disabled or the provider
	// unreachable, but we keep the node so a later RebuildEmbeddings
	// picks it up. Failing the finalize flow over an Ollama hiccup is
	// the wrong trade-off.
	if provider, err := s.Registry.Get(repoID); err == nil {
		if vecs, err := provider.Embed(ctx, []string{embedText(n)}); err == nil && len(vecs) > 0 && len(vecs[0]) > 0 {
			_ = s.Stores.Vectors.Upsert(ctx, ctxmem.Vector{
				NodeID: n.ID,
				Model:  provider.Name(),
				Dim:    len(vecs[0]),
				Vector: vecs[0],
			})
		}
	}
	s.publish("node", "create", n.ID, repoID)
	return n, nil
}

// SuggestForNewTask runs hybrid retrieval against Task + Decision +
// Constraint nodes using the draft goal as the query. Returned hits
// are bucketed by kind so the UI can render three discrete sections
// instead of a single mixed list. Returns an empty bundle (not an
// error) when Memory is disabled or the draft goal is blank — the
// UI treats an empty bundle as "nothing to show" which is the correct
// zero state.
func (s *Service) SuggestForNewTask(ctx context.Context, repoID, draftGoal string, limit int) (ctxmem.SuggestionBundle, error) {
	if repoID == "" {
		return ctxmem.SuggestionBundle{}, fmt.Errorf("%w: repo_id required", ctxmem.ErrInvalidArg)
	}
	draftGoal = strings.TrimSpace(draftGoal)
	if draftGoal == "" {
		return ctxmem.SuggestionBundle{}, nil
	}
	if limit <= 0 {
		limit = 5
	}
	set, err := s.Stores.Settings.Get(ctx, repoID)
	if err != nil {
		return ctxmem.SuggestionBundle{}, err
	}
	if !set.Enabled {
		return ctxmem.SuggestionBundle{}, nil
	}
	res, err := s.Search.Search(ctx, retrieval.Query{
		RepoID:        repoID,
		Text:          draftGoal,
		Kinds:         []string{ctxmem.NodeKindTask, ctxmem.NodeKindDecision, ctxmem.NodeKindConstraint},
		OnlyEnabled:   true,
		Limit:         limit * 3, // 3 buckets share the fused list — give each room
		TopKNeighbors: set.TopKNeighbors,
	})
	if err != nil {
		return ctxmem.SuggestionBundle{}, err
	}
	out := ctxmem.SuggestionBundle{}
	for _, h := range res.Channels["fused"] {
		switch h.Node.Kind {
		case ctxmem.NodeKindTask:
			if len(out.SimilarTasks) >= limit {
				continue
			}
			out.SimilarTasks = append(out.SimilarTasks, ctxmem.TaskSuggestion{
				NodeID:       h.Node.ID,
				Label:        h.Node.Label,
				SummaryMD:    h.Node.ContentMD,
				Score:        h.Score,
				SourceTaskID: h.Node.SourceTaskID,
			})
		case ctxmem.NodeKindDecision:
			if len(out.RelatedDecisions) >= limit {
				continue
			}
			out.RelatedDecisions = append(out.RelatedDecisions, ctxmem.NodeSummary{
				NodeID:    h.Node.ID,
				Kind:      h.Node.Kind,
				Label:     h.Node.Label,
				ContentMD: h.Node.ContentMD,
				Score:     h.Score,
			})
		case ctxmem.NodeKindConstraint:
			if len(out.RelatedConstraints) >= limit {
				continue
			}
			out.RelatedConstraints = append(out.RelatedConstraints, ctxmem.NodeSummary{
				NodeID:    h.Node.ID,
				Kind:      h.Node.Kind,
				Label:     h.Node.Label,
				ContentMD: h.Node.ContentMD,
				Score:     h.Score,
			})
		}
	}
	return out, nil
}
