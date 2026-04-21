// Package svc is the ctxmem facade used by internal/ipc and
// internal/copilot. It aggregates stores, retrieval, injection,
// promotion, analyzer and exposes a narrow method surface so no
// caller needs to reach into a ctxmem subpackage directly.
//
// The facade lives in its own subpackage to avoid an import cycle:
// retrieval / inject / embed / graph / promotion all depend on the
// top-level ctxmem package for domain types, so the Service cannot
// sit next to those types without Go's cycle checker complaining.
package svc

import (
	"context"
	"fmt"
	"log/slog"
	"time"

	"github.com/oklog/ulid/v2"

	"github.com/FleetKanban/fleetkanban/internal/ctxmem"
	"github.com/FleetKanban/fleetkanban/internal/ctxmem/analyzer"
	"github.com/FleetKanban/fleetkanban/internal/ctxmem/codegraph"
	"github.com/FleetKanban/fleetkanban/internal/ctxmem/embed"
	"github.com/FleetKanban/fleetkanban/internal/ctxmem/graph"
	"github.com/FleetKanban/fleetkanban/internal/ctxmem/inject"
	"github.com/FleetKanban/fleetkanban/internal/ctxmem/promotion"
	"github.com/FleetKanban/fleetkanban/internal/ctxmem/retrieval"
	"github.com/FleetKanban/fleetkanban/internal/ctxmem/store"
)

// RepoPathLookup resolves a repo ID to its absolute filesystem path.
// Declared as an interface so the svc package does not import store
// (which would need avoidance of cycles through app).
type RepoPathLookup interface {
	Path(ctx context.Context, repoID string) (string, error)
}

// Service is the ctxmem facade used by internal/ipc and internal/copilot.
type Service struct {
	Stores    *store.Stores
	Graph     *graph.Graph
	Search    *retrieval.Searcher
	Inject    *inject.Builder
	Gate      *promotion.Gate
	Registry  *embed.Registry
	Changes   *ctxmem.ChangeBroker
	Ollama    *embed.OllamaAdmin
	Analyzer  *analyzer.Analyzer
	CodeIndex *codegraph.Indexer
	Repos     RepoPathLookup

	log *slog.Logger
}

// Config carries constructor dependencies.
type Config struct {
	Stores    *store.Stores
	Graph     *graph.Graph
	Search    *retrieval.Searcher
	Inject    *inject.Builder
	Gate      *promotion.Gate
	Registry  *embed.Registry
	Changes   *ctxmem.ChangeBroker
	Ollama    *embed.OllamaAdmin
	Analyzer  *analyzer.Analyzer
	CodeIndex *codegraph.Indexer
	Repos     RepoPathLookup
	Logger    *slog.Logger
}

// New constructs a Service from the provided pieces.
func New(cfg Config) *Service {
	log := cfg.Logger
	if log == nil {
		log = slog.Default()
	}
	return &Service{
		Stores:    cfg.Stores,
		Graph:     cfg.Graph,
		Search:    cfg.Search,
		Inject:    cfg.Inject,
		Gate:      cfg.Gate,
		Registry:  cfg.Registry,
		Changes:   cfg.Changes,
		Ollama:    cfg.Ollama,
		Analyzer:  cfg.Analyzer,
		CodeIndex: cfg.CodeIndex,
		Repos:     cfg.Repos,
		log:       log,
	}
}

// RebuildCodeGraph scans the repository filesystem and upserts File
// nodes + imports edges. Cheap compared to an Analyzer run (no LLM
// calls); the UI typically triggers this after the user enables
// Memory or adds a new source file. Returns (nodesCreated,
// nodesUpdated, edgesCreated) for the UI toast.
func (s *Service) RebuildCodeGraph(ctx context.Context, repoID string) (codegraph.IndexResult, error) {
	if repoID == "" {
		return codegraph.IndexResult{}, fmt.Errorf("%w: repo_id required", ctxmem.ErrInvalidArg)
	}
	if s.CodeIndex == nil || s.Repos == nil {
		return codegraph.IndexResult{}, fmt.Errorf("ctxmem/svc: code index is not configured")
	}
	path, err := s.Repos.Path(ctx, repoID)
	if err != nil {
		return codegraph.IndexResult{}, fmt.Errorf("ctxmem/svc: lookup repo path: %w", err)
	}
	res, err := s.CodeIndex.Rebuild(ctx, repoID, path)
	if err != nil {
		return res, err
	}
	// Closure depends on edges, so rebuild after the index pass.
	if err := s.Graph.Rebuild(ctx, repoID, graph.DefaultMaxDepth); err != nil {
		s.log.Warn("ctxmem: rebuild closure after code index", "err", err)
	}
	s.Changes.Publish(&ctxmem.ChangeEvent{
		Kind:    "codegraph",
		Op:      "complete",
		RepoID:  repoID,
		Message: fmt.Sprintf("files=%d nodes=+%d updated=%d edges=+%d", res.FilesScanned, res.NodesCreated, res.NodesUpdated, res.EdgesCreated),
	})
	return res, nil
}

// RebuildEmbeddings recomputes ctx_node_vec for every enabled node in
// the repo using the current embedding provider. Called by the UI
// after the user enables Memory or switches provider so existing
// scratchpad / nodes become searchable without a re-analyze. Returns
// (rebuilt, skipped, error) — skipped counts include nodes with empty
// label + content and nodes that failed embedding individually.
func (s *Service) RebuildEmbeddings(ctx context.Context, repoID string) (rebuilt, skipped int, err error) {
	if repoID == "" {
		return 0, 0, fmt.Errorf("%w: repo_id required", ctxmem.ErrInvalidArg)
	}
	provider, err := s.Registry.Get(repoID)
	if err != nil {
		return 0, 0, err
	}
	// Pull all enabled nodes in reasonable pages. The brute-force loop
	// is fine for Phase 1 scale — typical repo has < 5K nodes.
	const pageSize = 500
	offset := 0
	for {
		nodes, _, err := s.Stores.Nodes.List(ctx, store.ListFilter{
			RepoID:      repoID,
			EnabledOnly: true,
			Limit:       pageSize,
			Offset:      offset,
		})
		if err != nil {
			return rebuilt, skipped, err
		}
		if len(nodes) == 0 {
			return rebuilt, skipped, nil
		}
		texts := make([]string, len(nodes))
		for i, n := range nodes {
			texts[i] = embedText(n)
		}
		vectors, err := provider.Embed(ctx, texts)
		if err != nil {
			return rebuilt, skipped + len(nodes), err
		}
		for i, vec := range vectors {
			if len(vec) == 0 {
				skipped++
				continue
			}
			if err := s.Stores.Vectors.Upsert(ctx, ctxmem.Vector{
				NodeID: nodes[i].ID,
				Model:  provider.Name(),
				Dim:    len(vec),
				Vector: vec,
			}); err != nil {
				s.log.Warn("ctxmem: upsert vector", "err", err, "node", nodes[i].ID)
				skipped++
				continue
			}
			rebuilt++
		}
		if len(nodes) < pageSize {
			return rebuilt, skipped, nil
		}
		offset += pageSize
	}
}

// embedText composes the text a node contributes to its embedding.
// Label + content concatenated so the vector captures both the quick
// summary and the expanded detail.
func embedText(n ctxmem.Node) string {
	if n.ContentMD == "" {
		return n.Label
	}
	return n.Label + "\n\n" + n.ContentMD
}

// RebuildClosureNow recomputes the closure table for the repo. Called
// from the UI's Rebuild Closure admin button. Cheaper to expose than
// forcing the user to delete+recreate an edge to trigger it.
func (s *Service) RebuildClosureNow(ctx context.Context, repoID string) error {
	if repoID == "" {
		return fmt.Errorf("%w: repo_id required", ctxmem.ErrInvalidArg)
	}
	return s.Graph.Rebuild(ctx, repoID, 0)
}

// AnalyzeRepository invokes the analyzer to produce scratchpad entries.
// Runs synchronously; callers that want background execution should
// wrap in a goroutine. Each call publishes an "analyzer" ChangeEvent at
// start + end so the Context UI can show progress.
func (s *Service) AnalyzeRepository(ctx context.Context, repoID, model string) error {
	if repoID == "" {
		return fmt.Errorf("%w: repo_id required", ctxmem.ErrInvalidArg)
	}
	if s.Analyzer == nil {
		return fmt.Errorf("ctxmem/svc: analyzer is not configured")
	}
	s.Changes.Publish(&ctxmem.ChangeEvent{
		Kind:   "analyzer",
		Op:     "start",
		RepoID: repoID,
	})
	progress := func(msg string) {
		s.Changes.Publish(&ctxmem.ChangeEvent{
			Kind:    "analyzer",
			Op:      "progress",
			RepoID:  repoID,
			Message: msg,
		})
	}
	err := s.Analyzer.Analyze(ctx, repoID, model, progress)
	op := "complete"
	msg := ""
	if err != nil {
		op = "error"
		msg = err.Error()
		s.log.Warn("ctxmem: analyzer failed", "err", err, "repo", repoID)
	} else {
		s.log.Info("ctxmem: analyzer finished", "repo", repoID)
		// Chain a code-graph rebuild so File nodes + imports edges
		// land alongside the LLM-produced Concept / Decision
		// candidates. Cheap (no LLM calls) and keeps the user from
		// having to press two buttons in sequence. Errors are
		// logged but not propagated — the analyzer result is the
		// headline outcome.
		if res, cgErr := s.RebuildCodeGraph(ctx, repoID); cgErr != nil {
			s.log.Warn("ctxmem: auto-rebuild code graph after analyzer",
				"err", cgErr, "repo", repoID)
		} else {
			s.log.Info("ctxmem: auto-rebuild code graph after analyzer",
				"repo", repoID,
				"files", res.FilesScanned, "nodes_new", res.NodesCreated,
				"edges", res.EdgesCreated)
		}
	}
	s.Changes.Publish(&ctxmem.ChangeEvent{
		Kind:    "analyzer",
		Op:      op,
		RepoID:  repoID,
		Message: msg,
	})
	return err
}

// ---- Overview / settings ---------------------------------------------------

// GetOverview aggregates Memory statistics for one repo.
func (s *Service) GetOverview(ctx context.Context, repoID string) (ctxmem.Overview, error) {
	if repoID == "" {
		return ctxmem.Overview{}, fmt.Errorf("%w: repo_id required", ctxmem.ErrInvalidArg)
	}
	o := ctxmem.Overview{RepoID: repoID}
	nodes, err := s.Stores.Nodes.CountByKind(ctx, repoID)
	if err != nil {
		return o, err
	}
	o.NodeCountsByKind = nodes
	edges, err := s.Stores.Edges.CountByRel(ctx, repoID)
	if err != nil {
		return o, err
	}
	o.EdgeCountsByRel = edges
	active, expired, err := s.Stores.Facts.CountActive(ctx, repoID)
	if err != nil {
		return o, err
	}
	o.ActiveFactCount = active
	o.ExpiredFactCount = expired
	scratch, err := s.Stores.Scratchpad.CountByStatus(ctx, repoID)
	if err != nil {
		return o, err
	}
	o.PendingScratchpadCount = scratch[ctxmem.ScratchpadPending]
	o.PromotedScratchpadCount = scratch[ctxmem.ScratchpadPromoted]
	o.RejectedScratchpadCount = scratch[ctxmem.ScratchpadRejected]
	vCount, dim, bytes, err := s.Stores.Vectors.CountAndDim(ctx, repoID)
	if err != nil {
		return o, err
	}
	o.VectorCount = vCount
	o.VectorDim = dim
	o.VectorBytes = bytes
	set, err := s.Stores.Settings.Get(ctx, repoID)
	if err != nil {
		return o, err
	}
	o.Enabled = set.Enabled
	return o, nil
}

// GetSettings returns the per-repo settings, creating defaults if missing.
func (s *Service) GetSettings(ctx context.Context, repoID string) (ctxmem.Settings, error) {
	return s.Stores.Settings.Get(ctx, repoID)
}

// UpdateSettings writes a full Settings row and refreshes the embedding
// registry so subsequent retrieval uses the new provider immediately.
// When Memory transitions from disabled to enabled, a code-graph
// rebuild is chained so the Browse tab has File nodes to show on
// first visit — the user should not have to press two buttons.
func (s *Service) UpdateSettings(ctx context.Context, set ctxmem.Settings, opts embed.BuildOptions) (ctxmem.Settings, error) {
	prev, _ := s.Stores.Settings.Get(ctx, set.RepoID)
	if err := s.Stores.Settings.Save(ctx, set); err != nil {
		return ctxmem.Settings{}, err
	}
	if set.Enabled {
		provider, err := embed.Build(set, opts)
		if err != nil {
			s.log.Warn("ctxmem: embedding provider build failed", "err", err, "repo", set.RepoID)
			// Surface the failure on WatchContextChanges so the
			// Settings panel can render an inline warning instead of
			// having the user discover it only when retrieval returns
			// empty. Log-only was insufficient — the prior silent-fail
			// path left users thinking Memory was working.
			s.Changes.Publish(&ctxmem.ChangeEvent{
				Kind:    "memory-settings",
				Op:      "provider-error",
				RepoID:  set.RepoID,
				Message: err.Error(),
			})
		} else {
			s.Registry.Set(set.RepoID, provider)
			s.Changes.Publish(&ctxmem.ChangeEvent{
				Kind:   "memory-settings",
				Op:     "provider-ready",
				RepoID: set.RepoID,
			})
		}
	} else {
		s.Registry.Set(set.RepoID, nil)
	}
	// Seed code graph + embeddings on the disabled → enabled transition.
	// Skipped when it was already enabled (avoid redundant rebuilds on
	// every provider tweak). Embeddings run after the code graph so the
	// freshly-upserted File nodes are captured in the same pass, which
	// is what lets the first Passive injection surface something useful
	// instead of an empty block.
	if set.Enabled && !prev.Enabled && s.CodeIndex != nil && s.Repos != nil {
		go func() {
			bg := context.Background()
			if _, err := s.RebuildCodeGraph(bg, set.RepoID); err != nil {
				s.log.Warn("ctxmem: seed code graph on enable", "err", err, "repo", set.RepoID)
			}
			if rebuilt, skipped, err := s.RebuildEmbeddings(bg, set.RepoID); err != nil {
				s.log.Warn("ctxmem: seed embeddings on enable", "err", err, "repo", set.RepoID)
				s.Changes.Publish(&ctxmem.ChangeEvent{
					Kind:    "embeddings",
					Op:      "error",
					RepoID:  set.RepoID,
					Message: err.Error(),
				})
			} else {
				s.log.Info("ctxmem: seed embeddings on enable",
					"repo", set.RepoID, "rebuilt", rebuilt, "skipped", skipped)
				s.Changes.Publish(&ctxmem.ChangeEvent{
					Kind:    "embeddings",
					Op:      "complete",
					RepoID:  set.RepoID,
					Message: fmt.Sprintf("rebuilt=%d skipped=%d", rebuilt, skipped),
				})
			}
		}()
	}
	return s.Stores.Settings.Get(ctx, set.RepoID)
}

// GetMemoryHealth returns the runtime state of Memory for a repo so the
// Settings panel and Kanban badge can show "is it actually working".
// Separated from Overview because Overview is heavy (counts by kind,
// scratchpad buckets, etc.) and we poll Health every few seconds.
func (s *Service) GetMemoryHealth(ctx context.Context, repoID string) (ctxmem.MemoryHealth, error) {
	if repoID == "" {
		return ctxmem.MemoryHealth{}, fmt.Errorf("%w: repo_id required", ctxmem.ErrInvalidArg)
	}
	set, err := s.Stores.Settings.Get(ctx, repoID)
	if err != nil {
		return ctxmem.MemoryHealth{}, err
	}
	out := ctxmem.MemoryHealth{
		Enabled:       set.Enabled,
		LastRebuildAt: set.UpdatedAt,
	}
	vCount, _, _, err := s.Stores.Vectors.CountAndDim(ctx, repoID)
	if err == nil {
		out.VectorCount = vCount
	}
	// Cheap reachability probe. Ollama has a dedicated admin client;
	// every other provider is assumed reachable once the registry
	// accepted its configuration (API key present, URL valid).
	if set.Enabled {
		switch set.EmbeddingProvider {
		case "ollama":
			if s.Ollama != nil {
				st := s.Ollama.GetStatus(ctx)
				out.ProviderReachable = st.Running
				if !st.Running {
					out.LastError = st.Message
				}
			}
		default:
			if _, regErr := s.Registry.Get(repoID); regErr != nil {
				out.ProviderReachable = false
				out.LastError = regErr.Error()
			} else {
				out.ProviderReachable = true
			}
		}
	}
	return out, nil
}

// ---- Node / edge / fact CRUD ----------------------------------------------

// CreateNode inserts a user-authored node and publishes a change event.
func (s *Service) CreateNode(ctx context.Context, n ctxmem.Node) (ctxmem.Node, error) {
	if n.ID == "" {
		n.ID = ulid.Make().String()
	}
	if n.SourceKind == "" {
		n.SourceKind = ctxmem.SourceManual
	}
	if n.Confidence == 0 {
		n.Confidence = 1.0
	}
	n.Enabled = true
	if err := s.Stores.Nodes.Create(ctx, n); err != nil {
		return ctxmem.Node{}, err
	}
	s.publish("node", "create", n.ID, n.RepoID)
	return n, nil
}

// UpdateNode applies a partial patch (tri-state enabled_op / pinned_op
// semantics match proto.UpdateNodeRequest).
func (s *Service) UpdateNode(ctx context.Context, patch ctxmem.Node, enabledOp, pinnedOp int32) (ctxmem.Node, error) {
	existing, err := s.Stores.Nodes.Get(ctx, patch.ID)
	if err != nil {
		return ctxmem.Node{}, err
	}
	if patch.Label != "" {
		existing.Label = patch.Label
	}
	if patch.ContentMD != "" {
		existing.ContentMD = patch.ContentMD
	}
	if patch.Attrs != nil {
		existing.Attrs = patch.Attrs
	}
	if patch.Confidence > 0 {
		existing.Confidence = patch.Confidence
	}
	switch enabledOp {
	case 1:
		existing.Enabled = true
	case 2:
		existing.Enabled = false
	}
	switch pinnedOp {
	case 1:
		existing.Pinned = true
	case 2:
		existing.Pinned = false
	}
	if err := s.Stores.Nodes.Update(ctx, existing); err != nil {
		return ctxmem.Node{}, err
	}
	s.publish("node", "update", existing.ID, existing.RepoID)
	return existing, nil
}

// DeleteNode removes a node; associated edges / vectors / facts cascade
// via the FK rules in the migration.
func (s *Service) DeleteNode(ctx context.Context, nodeID string) error {
	n, err := s.Stores.Nodes.Get(ctx, nodeID)
	if err != nil {
		return err
	}
	if err := s.Stores.Nodes.Delete(ctx, nodeID); err != nil {
		return err
	}
	s.publish("node", "delete", nodeID, n.RepoID)
	return nil
}

// PinNode toggles the pinned flag.
func (s *Service) PinNode(ctx context.Context, nodeID string, pinned bool) error {
	if err := s.Stores.Nodes.SetPinned(ctx, nodeID, pinned); err != nil {
		return err
	}
	n, err := s.Stores.Nodes.Get(ctx, nodeID)
	if err == nil {
		s.publish("node", "update", nodeID, n.RepoID)
	}
	return nil
}

// ListNodes exposes the Browse filter.
func (s *Service) ListNodes(ctx context.Context, f store.ListFilter) ([]ctxmem.Node, int, error) {
	return s.Stores.Nodes.List(ctx, f)
}

// GetNodeDetail returns a node with its neighbors and facts in one shot.
func (s *Service) GetNodeDetail(ctx context.Context, nodeID string) (ctxmem.NodeDetail, error) {
	n, err := s.Stores.Nodes.Get(ctx, nodeID)
	if err != nil {
		return ctxmem.NodeDetail{}, err
	}
	out := ctxmem.NodeDetail{
		Node:            n,
		SourceTaskID:    n.SourceTaskID,
		SourceSessionID: n.SourceSessionID,
	}
	out.OutEdges, _ = s.Stores.Edges.OutEdges(ctx, nodeID)
	out.InEdges, _ = s.Stores.Edges.InEdges(ctx, nodeID)
	neighborIDs := map[string]struct{}{}
	for _, e := range out.OutEdges {
		neighborIDs[e.DstNodeID] = struct{}{}
	}
	for _, e := range out.InEdges {
		neighborIDs[e.SrcNodeID] = struct{}{}
	}
	ids := make([]string, 0, len(neighborIDs))
	for id := range neighborIDs {
		ids = append(ids, id)
	}
	if len(ids) > 0 {
		out.Neighbors, _ = s.Stores.Nodes.GetMany(ctx, ids)
	}
	facts, _, _ := s.Stores.Facts.List(ctx, store.FactFilter{
		RepoID:        n.RepoID,
		SubjectNodeID: nodeID,
		Limit:         50,
	})
	out.Facts = facts
	return out, nil
}

// CreateEdge inserts an edge and schedules a closure rebuild for the repo.
func (s *Service) CreateEdge(ctx context.Context, e ctxmem.Edge) (ctxmem.Edge, error) {
	if e.ID == "" {
		e.ID = ulid.Make().String()
	}
	if err := s.Stores.Edges.Create(ctx, e); err != nil {
		return ctxmem.Edge{}, err
	}
	if err := s.Graph.Rebuild(ctx, e.RepoID, graph.DefaultMaxDepth); err != nil {
		s.log.Warn("ctxmem: rebuild closure after edge create", "err", err)
	}
	s.publish("edge", "create", e.ID, e.RepoID)
	return e, nil
}

// DeleteEdge removes an edge and rebuilds the closure.
func (s *Service) DeleteEdge(ctx context.Context, edgeID string) error {
	e, err := s.Stores.Edges.GetByID(ctx, edgeID)
	if err != nil {
		return err
	}
	if err := s.Stores.Edges.Delete(ctx, edgeID); err != nil {
		return err
	}
	if err := s.Graph.Rebuild(ctx, e.RepoID, graph.DefaultMaxDepth); err != nil {
		s.log.Warn("ctxmem: rebuild closure after edge delete", "err", err)
	}
	s.publish("edge", "delete", edgeID, e.RepoID)
	return nil
}

// ListEdges exposes the edge filter.
func (s *Service) ListEdges(ctx context.Context, f store.EdgeFilter) ([]ctxmem.Edge, int, error) {
	return s.Stores.Edges.List(ctx, f)
}

// ListFacts exposes the fact filter.
func (s *Service) ListFacts(ctx context.Context, f store.FactFilter) ([]ctxmem.Fact, int, error) {
	return s.Stores.Facts.List(ctx, f)
}

// ---- Search / injection ---------------------------------------------------

// SearchContext runs hybrid retrieval.
func (s *Service) SearchContext(ctx context.Context, q retrieval.Query) (ctxmem.SearchResult, error) {
	return s.Search.Search(ctx, q)
}

// PreviewPassive returns the Passive injection block for a task prompt
// without side effects.
func (s *Service) PreviewPassive(ctx context.Context, repoID, prompt, taskID string) (ctxmem.InjectionPreview, error) {
	return s.Inject.BuildPassive(ctx, inject.PassiveRequest{
		RepoID:    repoID,
		RawPrompt: prompt,
		TaskID:    taskID,
	})
}

// BuildPassiveForRunner is the hook copilot.runner calls at session start.
func (s *Service) BuildPassiveForRunner(ctx context.Context, repoID, prompt, taskID string) string {
	preview, err := s.PreviewPassive(ctx, repoID, prompt, taskID)
	if err != nil {
		s.log.Warn("ctxmem: build passive", "err", err, "repo", repoID)
		return ""
	}
	return preview.SystemPrompt
}

// BuildReactiveForRunner is the hook the search_memory tool handler calls
// when an agent decides mid-session that it needs additional context.
// Returns the Markdown block the LLM consumes; empty string when Memory
// is disabled or the hybrid search produced no hits.
func (s *Service) BuildReactiveForRunner(ctx context.Context, repoID, query string) string {
	preview, err := s.Inject.BuildReactive(ctx, repoID, query)
	if err != nil {
		s.log.Warn("ctxmem: build reactive", "err", err, "repo", repoID)
		return ""
	}
	return preview.SystemPrompt
}

// BuildForReviewer is the hook copilot.Reviewer calls at session start
// to prepend a Decision / Constraint / Concept-weighted memory block.
// Returns empty string on any error or when Memory is disabled so the
// reviewer prompt stays unchanged from its pre-Memory baseline.
func (s *Service) BuildForReviewer(ctx context.Context, repoID, goal, diffSummary, taskID string) string {
	preview, err := s.Inject.BuildForReview(ctx, repoID, goal, diffSummary, taskID)
	if err != nil {
		s.log.Warn("ctxmem: build review", "err", err, "repo", repoID)
		return ""
	}
	return preview.SystemPrompt
}

// ---- Scratchpad / promotion -----------------------------------------------

// ListPending returns scratchpad entries for a repo.
func (s *Service) ListPending(ctx context.Context, f store.ScratchpadFilter) ([]ctxmem.ScratchpadEntry, int, error) {
	return s.Stores.Scratchpad.List(ctx, f)
}

// GetScratchpadEntry fetches one entry.
func (s *Service) GetScratchpadEntry(ctx context.Context, id string) (ctxmem.ScratchpadEntry, error) {
	return s.Stores.Scratchpad.Get(ctx, id)
}

// PromoteEntry is the manual trust-gate path.
func (s *Service) PromoteEntry(ctx context.Context, entryID string) (ctxmem.Node, error) {
	n, err := s.Gate.Promote(ctx, entryID)
	if err != nil {
		return ctxmem.Node{}, err
	}
	s.publish("scratchpad", "promote", entryID, n.RepoID)
	s.publish("node", "create", n.ID, n.RepoID)
	return n, nil
}

// RejectEntry rejects a scratchpad entry with an optional reason.
func (s *Service) RejectEntry(ctx context.Context, entryID, reason string) error {
	entry, err := s.Stores.Scratchpad.Get(ctx, entryID)
	if err != nil {
		return err
	}
	if err := s.Gate.Reject(ctx, entryID, reason); err != nil {
		return err
	}
	s.publish("scratchpad", "reject", entryID, entry.RepoID)
	return nil
}

// EditAndPromote applies edits then promotes.
func (s *Service) EditAndPromote(ctx context.Context, entryID, kind, label, content string, attrs map[string]string) (ctxmem.Node, error) {
	n, err := s.Gate.EditAndPromote(ctx, entryID, kind, label, content, attrs)
	if err != nil {
		return ctxmem.Node{}, err
	}
	s.publish("scratchpad", "promote", entryID, n.RepoID)
	s.publish("node", "create", n.ID, n.RepoID)
	return n, nil
}

// Snooze pushes an entry out by the given days.
func (s *Service) Snooze(ctx context.Context, entryID string, days int) error {
	if days <= 0 {
		days = 7
	}
	if days > 30 {
		days = 30
	}
	until := time.Now().UTC().Add(time.Duration(days) * 24 * time.Hour).Format(time.RFC3339Nano)
	entry, err := s.Stores.Scratchpad.Get(ctx, entryID)
	if err != nil {
		return err
	}
	if err := s.Stores.Scratchpad.Snooze(ctx, entryID, until); err != nil {
		return err
	}
	s.publish("scratchpad", "snooze", entryID, entry.RepoID)
	return nil
}

// CreateScratchpadEntry is used by the analyzer (and eventually observer)
// to write a pending candidate.
func (s *Service) CreateScratchpadEntry(ctx context.Context, e ctxmem.ScratchpadEntry) (ctxmem.ScratchpadEntry, error) {
	if e.ID == "" {
		e.ID = ulid.Make().String()
	}
	if err := s.Stores.Scratchpad.Create(ctx, e); err != nil {
		return ctxmem.ScratchpadEntry{}, err
	}
	s.publish("scratchpad", "create", e.ID, e.RepoID)
	if _, promoted, err := s.Gate.AutoPromoteIfEligible(ctx, e.ID); err == nil && promoted {
		s.publish("scratchpad", "promote", e.ID, e.RepoID)
	}
	return s.Stores.Scratchpad.Get(ctx, e.ID)
}

// ---- Change broker --------------------------------------------------------

// SubscribeChanges returns a (id, channel) pair for WatchContextChanges
// and WatchPending.
func (s *Service) SubscribeChanges() (uint64, <-chan *ctxmem.ChangeEvent) {
	return s.Changes.Subscribe()
}

// UnsubscribeChanges releases a subscription.
func (s *Service) UnsubscribeChanges(id uint64) {
	s.Changes.Unsubscribe(id)
}

func (s *Service) publish(kind, op, id, repoID string) {
	s.Changes.Publish(&ctxmem.ChangeEvent{
		Kind:   kind,
		Op:     op,
		ID:     id,
		RepoID: repoID,
	})
}
