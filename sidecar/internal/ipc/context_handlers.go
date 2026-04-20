package ipc

import (
	"context"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/types/known/emptypb"
	"google.golang.org/protobuf/types/known/timestamppb"

	"github.com/FleetKanban/fleetkanban/internal/ctxmem"
	"github.com/FleetKanban/fleetkanban/internal/ctxmem/embed"
	"github.com/FleetKanban/fleetkanban/internal/ctxmem/retrieval"
	"github.com/FleetKanban/fleetkanban/internal/ctxmem/store"

	pb "github.com/FleetKanban/fleetkanban/internal/ipc/gen/fleetkanban/v1"
)

// --- ContextService RPC handlers --------------------------------------------

func (s *Server) GetOverview(ctx context.Context, req *pb.RepoIdRequest) (*pb.ContextOverview, error) {
	if err := s.requireCtxmem(); err != nil {
		return nil, err
	}
	o, err := s.ctxmem.GetOverview(ctx, req.GetRepoId())
	if err != nil {
		return nil, mapCtxmemError(err)
	}
	return overviewToPB(o), nil
}

func (s *Server) SearchContext(ctx context.Context, req *pb.SearchContextRequest) (*pb.SearchContextResponse, error) {
	if err := s.requireCtxmem(); err != nil {
		return nil, err
	}
	set, err := s.ctxmem.GetSettings(ctx, req.GetRepoId())
	if err != nil {
		return nil, mapCtxmemError(err)
	}
	res, err := s.ctxmem.SearchContext(ctx, retrieval.Query{
		RepoID:        req.GetRepoId(),
		Text:          req.GetQuery(),
		Kinds:         req.GetKinds(),
		OnlyEnabled:   req.GetOnlyEnabled(),
		Limit:         int(req.GetLimit()),
		TopKNeighbors: set.TopKNeighbors,
	})
	if err != nil {
		return nil, mapCtxmemError(err)
	}
	return searchResultToPB(res), nil
}

func (s *Server) ListNodes(ctx context.Context, req *pb.ListNodesRequest) (*pb.ListNodesResponse, error) {
	if err := s.requireCtxmem(); err != nil {
		return nil, err
	}
	filter := store.ListFilter{
		RepoID:        req.GetRepoId(),
		Kinds:         req.GetKinds(),
		SourceKinds:   req.GetSourceKinds(),
		LabelContains: req.GetLabelContains(),
		PinnedOnly:    req.GetPinnedFilter() == 1,
		EnabledOnly:   req.GetEnabledFilter() == 1,
		Limit:         int(req.GetLimit()),
		Offset:        int(req.GetOffset()),
		SortBy:        req.GetSort(),
	}
	nodes, total, err := s.ctxmem.ListNodes(ctx, filter)
	if err != nil {
		return nil, mapCtxmemError(err)
	}
	return &pb.ListNodesResponse{
		Nodes: nodesToPB(nodes),
		Total: int32(total),
	}, nil
}

func (s *Server) GetNode(ctx context.Context, req *pb.NodeIdRequest) (*pb.ContextNodeDetail, error) {
	if err := s.requireCtxmem(); err != nil {
		return nil, err
	}
	detail, err := s.ctxmem.GetNodeDetail(ctx, req.GetNodeId())
	if err != nil {
		return nil, mapCtxmemError(err)
	}
	return nodeDetailToPB(detail), nil
}

func (s *Server) CreateNode(ctx context.Context, req *pb.CreateNodeRequest) (*pb.ContextNode, error) {
	if err := s.requireCtxmem(); err != nil {
		return nil, err
	}
	n := ctxmem.Node{
		RepoID:     req.GetRepoId(),
		Kind:       req.GetKind(),
		Label:      req.GetLabel(),
		ContentMD:  req.GetContentMd(),
		Attrs:      req.GetAttrs(),
		SourceKind: req.GetSourceKind(),
		Confidence: req.GetConfidence(),
	}
	out, err := s.ctxmem.CreateNode(ctx, n)
	if err != nil {
		return nil, mapCtxmemError(err)
	}
	return nodeToPB(out), nil
}

func (s *Server) UpdateNode(ctx context.Context, req *pb.UpdateNodeRequest) (*pb.ContextNode, error) {
	if err := s.requireCtxmem(); err != nil {
		return nil, err
	}
	patch := ctxmem.Node{
		ID:         req.GetNodeId(),
		Label:      req.GetLabel(),
		ContentMD:  req.GetContentMd(),
		Attrs:      req.GetAttrs(),
		Confidence: req.GetConfidence(),
	}
	out, err := s.ctxmem.UpdateNode(ctx, patch, req.GetEnabledOp(), req.GetPinnedOp())
	if err != nil {
		return nil, mapCtxmemError(err)
	}
	return nodeToPB(out), nil
}

func (s *Server) DeleteNode(ctx context.Context, req *pb.NodeIdRequest) (*emptypb.Empty, error) {
	if err := s.requireCtxmem(); err != nil {
		return nil, err
	}
	if err := s.ctxmem.DeleteNode(ctx, req.GetNodeId()); err != nil {
		return nil, mapCtxmemError(err)
	}
	return &emptypb.Empty{}, nil
}

func (s *Server) PinNode(ctx context.Context, req *pb.PinNodeRequest) (*emptypb.Empty, error) {
	if err := s.requireCtxmem(); err != nil {
		return nil, err
	}
	if err := s.ctxmem.PinNode(ctx, req.GetNodeId(), req.GetPinned()); err != nil {
		return nil, mapCtxmemError(err)
	}
	return &emptypb.Empty{}, nil
}

func (s *Server) ListEdges(ctx context.Context, req *pb.ListEdgesRequest) (*pb.ListEdgesResponse, error) {
	if err := s.requireCtxmem(); err != nil {
		return nil, err
	}
	edges, total, err := s.ctxmem.ListEdges(ctx, store.EdgeFilter{
		RepoID: req.GetRepoId(),
		NodeID: req.GetNodeId(),
		Rels:   req.GetRels(),
		Limit:  int(req.GetLimit()),
		Offset: int(req.GetOffset()),
	})
	if err != nil {
		return nil, mapCtxmemError(err)
	}
	return &pb.ListEdgesResponse{Edges: edgesToPB(edges), Total: int32(total)}, nil
}

func (s *Server) CreateEdge(ctx context.Context, req *pb.CreateEdgeRequest) (*pb.ContextEdge, error) {
	if err := s.requireCtxmem(); err != nil {
		return nil, err
	}
	e := ctxmem.Edge{
		RepoID:    req.GetRepoId(),
		SrcNodeID: req.GetSrcNodeId(),
		DstNodeID: req.GetDstNodeId(),
		Rel:       req.GetRel(),
		Attrs:     req.GetAttrs(),
	}
	out, err := s.ctxmem.CreateEdge(ctx, e)
	if err != nil {
		return nil, mapCtxmemError(err)
	}
	return edgeToPB(out), nil
}

func (s *Server) DeleteEdge(ctx context.Context, req *pb.EdgeIdRequest) (*emptypb.Empty, error) {
	if err := s.requireCtxmem(); err != nil {
		return nil, err
	}
	if err := s.ctxmem.DeleteEdge(ctx, req.GetEdgeId()); err != nil {
		return nil, mapCtxmemError(err)
	}
	return &emptypb.Empty{}, nil
}

func (s *Server) ListFacts(ctx context.Context, req *pb.ListFactsRequest) (*pb.ListFactsResponse, error) {
	if err := s.requireCtxmem(); err != nil {
		return nil, err
	}
	facts, total, err := s.ctxmem.ListFacts(ctx, store.FactFilter{
		RepoID:         req.GetRepoId(),
		SubjectNodeID:  req.GetSubjectNodeId(),
		IncludeExpired: req.GetIncludeExpired(),
		Limit:          int(req.GetLimit()),
		Offset:         int(req.GetOffset()),
	})
	if err != nil {
		return nil, mapCtxmemError(err)
	}
	return &pb.ListFactsResponse{Facts: factsToPB(facts), Total: int32(total)}, nil
}

func (s *Server) PreviewInjection(ctx context.Context, req *pb.PreviewInjectionRequest) (*pb.InjectionPreview, error) {
	if err := s.requireCtxmem(); err != nil {
		return nil, err
	}
	prompt := req.GetRawPrompt()
	preview, err := s.ctxmem.PreviewPassive(ctx, req.GetRepoId(), prompt, req.GetTaskId())
	if err != nil {
		return nil, mapCtxmemError(err)
	}
	return injectionPreviewToPB(preview), nil
}

func (s *Server) RebuildEmbeddings(ctx context.Context, req *pb.RepoIdRequest) (*pb.RebuildEmbeddingsResponse, error) {
	if err := s.requireCtxmem(); err != nil {
		return nil, err
	}
	rebuilt, skipped, err := s.ctxmem.RebuildEmbeddings(ctx, req.GetRepoId())
	if err != nil {
		return nil, mapCtxmemError(err)
	}
	return &pb.RebuildEmbeddingsResponse{
		Rebuilt: int32(rebuilt),
		Skipped: int32(skipped),
	}, nil
}

func (s *Server) RebuildClosure(ctx context.Context, req *pb.RepoIdRequest) (*emptypb.Empty, error) {
	if err := s.requireCtxmem(); err != nil {
		return nil, err
	}
	if err := s.ctxmem.RebuildClosureNow(ctx, req.GetRepoId()); err != nil {
		return nil, mapCtxmemError(err)
	}
	return &emptypb.Empty{}, nil
}

func (s *Server) RebuildCodeGraph(ctx context.Context, req *pb.RepoIdRequest) (*pb.RebuildCodeGraphResponse, error) {
	if err := s.requireCtxmem(); err != nil {
		return nil, err
	}
	res, err := s.ctxmem.RebuildCodeGraph(ctx, req.GetRepoId())
	if err != nil {
		return nil, mapCtxmemError(err)
	}
	return &pb.RebuildCodeGraphResponse{
		FilesScanned: int32(res.FilesScanned),
		NodesCreated: int32(res.NodesCreated),
		NodesUpdated: int32(res.NodesUpdated),
		EdgesCreated: int32(res.EdgesCreated),
	}, nil
}

func (s *Server) AnalyzeRepository(ctx context.Context, req *pb.AnalyzeRepoRequest) (*emptypb.Empty, error) {
	if err := s.requireCtxmem(); err != nil {
		return nil, err
	}
	// Run synchronously in a detached goroutine so the RPC returns
	// immediately — analyzer sessions can take minutes. The UI
	// subscribes to WatchContextChanges to observe start / complete /
	// error events published by svc.AnalyzeRepository; svc also logs
	// via slog so sidecar.log has a durable record even after the
	// UI's in-memory banner fades.
	go func() {
		bg := context.Background()
		_ = s.ctxmem.AnalyzeRepository(bg, req.GetRepoId(), req.GetModel())
	}()
	return &emptypb.Empty{}, nil
}

func (s *Server) GetMemorySettings(ctx context.Context, req *pb.RepoIdRequest) (*pb.MemorySettings, error) {
	if err := s.requireCtxmem(); err != nil {
		return nil, err
	}
	set, err := s.ctxmem.GetSettings(ctx, req.GetRepoId())
	if err != nil {
		return nil, mapCtxmemError(err)
	}
	return memorySettingsToPB(set), nil
}

func (s *Server) UpdateMemorySettings(ctx context.Context, req *pb.UpdateMemorySettingsRequest) (*pb.MemorySettings, error) {
	if err := s.requireCtxmem(); err != nil {
		return nil, err
	}
	set := memorySettingsFromPB(req.GetSettings())
	out, err := s.ctxmem.UpdateSettings(ctx, set, embed.BuildOptions{
		OllamaBaseURL: s.embedOpts.OllamaBaseURL,
		OpenAIAPIKey:  s.embedOpts.OpenAIAPIKey,
	})
	if err != nil {
		return nil, mapCtxmemError(err)
	}
	return memorySettingsToPB(out), nil
}

// WatchContextChanges streams ctxmem ChangeEvents until the client
// disconnects. since_seq_by_kind suppresses events whose (kind, seq)
// is already seen on reconnect, matching the WatchEvents pattern.
func (s *Server) WatchContextChanges(req *pb.WatchContextRequest, stream grpc.ServerStreamingServer[pb.ContextChangeEvent]) error {
	if err := s.requireCtxmem(); err != nil {
		return err
	}
	id, ch := s.ctxmem.SubscribeChanges()
	defer s.ctxmem.UnsubscribeChanges(id)

	since := req.GetSinceSeqByKind()
	repoFilter := req.GetRepoId()
	ctx := stream.Context()
	for {
		select {
		case <-ctx.Done():
			return ctx.Err()
		case evt, ok := <-ch:
			if !ok {
				return nil
			}
			if repoFilter != "" && evt.RepoID != repoFilter {
				continue
			}
			if since != nil {
				if cutoff, present := since[evt.Kind]; present && evt.Seq <= cutoff {
					continue
				}
			}
			if err := stream.Send(changeEventToPB(evt)); err != nil {
				return err
			}
		}
	}
}

// --- ScratchpadService RPC handlers -----------------------------------------

func (s *Server) ListPending(ctx context.Context, req *pb.ListPendingRequest) (*pb.ListPendingResponse, error) {
	if err := s.requireCtxmem(); err != nil {
		return nil, err
	}
	entries, total, err := s.ctxmem.ListPending(ctx, store.ScratchpadFilter{
		RepoID:   req.GetRepoId(),
		Statuses: req.GetStatuses(),
		Limit:    int(req.GetLimit()),
		Offset:   int(req.GetOffset()),
	})
	if err != nil {
		return nil, mapCtxmemError(err)
	}
	return &pb.ListPendingResponse{
		Entries: scratchpadEntriesToPB(entries),
		Total:   int32(total),
	}, nil
}

func (s *Server) GetEntry(ctx context.Context, req *pb.EntryIdRequest) (*pb.ScratchpadEntry, error) {
	if err := s.requireCtxmem(); err != nil {
		return nil, err
	}
	entry, err := s.ctxmem.GetScratchpadEntry(ctx, req.GetEntryId())
	if err != nil {
		return nil, mapCtxmemError(err)
	}
	return scratchpadEntryToPB(entry), nil
}

func (s *Server) PromoteEntry(ctx context.Context, req *pb.EntryIdRequest) (*pb.ContextNode, error) {
	if err := s.requireCtxmem(); err != nil {
		return nil, err
	}
	n, err := s.ctxmem.PromoteEntry(ctx, req.GetEntryId())
	if err != nil {
		return nil, mapCtxmemError(err)
	}
	return nodeToPB(n), nil
}

func (s *Server) RejectEntry(ctx context.Context, req *pb.RejectEntryRequest) (*emptypb.Empty, error) {
	if err := s.requireCtxmem(); err != nil {
		return nil, err
	}
	if err := s.ctxmem.RejectEntry(ctx, req.GetEntryId(), req.GetReason()); err != nil {
		return nil, mapCtxmemError(err)
	}
	return &emptypb.Empty{}, nil
}

func (s *Server) EditAndPromote(ctx context.Context, req *pb.EditAndPromoteRequest) (*pb.ContextNode, error) {
	if err := s.requireCtxmem(); err != nil {
		return nil, err
	}
	n, err := s.ctxmem.EditAndPromote(ctx, req.GetEntryId(),
		req.GetEditedKind(), req.GetEditedLabel(), req.GetEditedContentMd(), req.GetEditedAttrs())
	if err != nil {
		return nil, mapCtxmemError(err)
	}
	return nodeToPB(n), nil
}

func (s *Server) SnoozeEntry(ctx context.Context, req *pb.SnoozeRequest) (*emptypb.Empty, error) {
	if err := s.requireCtxmem(); err != nil {
		return nil, err
	}
	if err := s.ctxmem.Snooze(ctx, req.GetEntryId(), int(req.GetDays())); err != nil {
		return nil, mapCtxmemError(err)
	}
	return &emptypb.Empty{}, nil
}

// WatchPending reuses the ChangeBroker filtered to scratchpad events.
func (s *Server) WatchPending(req *pb.RepoIdRequest, stream grpc.ServerStreamingServer[pb.ScratchpadChangeEvent]) error {
	if err := s.requireCtxmem(); err != nil {
		return err
	}
	id, ch := s.ctxmem.SubscribeChanges()
	defer s.ctxmem.UnsubscribeChanges(id)

	repoFilter := req.GetRepoId()
	ctx := stream.Context()
	for {
		select {
		case <-ctx.Done():
			return ctx.Err()
		case evt, ok := <-ch:
			if !ok {
				return nil
			}
			if evt.Kind != "scratchpad" {
				continue
			}
			if repoFilter != "" && evt.RepoID != repoFilter {
				continue
			}
			if err := stream.Send(&pb.ScratchpadChangeEvent{
				Seq:        evt.Seq,
				Op:         evt.Op,
				EntryId:    evt.ID,
				RepoId:     evt.RepoID,
				OccurredAt: toProtoTime(evt.OccurredAt),
			}); err != nil {
				return err
			}
		}
	}
}

// --- OllamaService RPC handlers ---------------------------------------------

func (s *Server) GetOllamaStatus(ctx context.Context, _ *emptypb.Empty) (*pb.OllamaStatus, error) {
	if err := s.requireCtxmem(); err != nil {
		return nil, err
	}
	st := s.ctxmem.Ollama.GetStatus(ctx)
	return &pb.OllamaStatus{
		Installed:      st.Installed,
		Running:        st.Running,
		BaseUrl:        st.BaseURL,
		Version:        st.Version,
		Message:        st.Message,
		InstallCommand: st.InstallCommand,
	}, nil
}

func (s *Server) ListInstalledModels(ctx context.Context, _ *emptypb.Empty) (*pb.OllamaListModelsResponse, error) {
	if err := s.requireCtxmem(); err != nil {
		return nil, err
	}
	models, err := s.ctxmem.Ollama.ListModels(ctx)
	if err != nil {
		return nil, status.Error(codes.Unavailable, err.Error())
	}
	out := &pb.OllamaListModelsResponse{}
	for _, m := range models {
		out.Models = append(out.Models, &pb.OllamaModel{
			Name:         m.Name,
			SizeBytes:    m.SizeBytes,
			SizeGb:       m.SizeGB,
			ModifiedAt:   m.ModifiedAt,
			IsEmbedding:  m.IsEmbedding,
			EmbeddingDim: m.EmbeddingDim,
			Description:  m.Description,
		})
	}
	return out, nil
}

func (s *Server) GetRecommendedModels(ctx context.Context, _ *emptypb.Empty) (*pb.OllamaListRecommendedResponse, error) {
	if err := s.requireCtxmem(); err != nil {
		return nil, err
	}
	models, err := s.ctxmem.Ollama.GetRecommendedModels(ctx)
	if err != nil {
		return nil, status.Error(codes.Unavailable, err.Error())
	}
	out := &pb.OllamaListRecommendedResponse{}
	for _, m := range models {
		out.Models = append(out.Models, &pb.OllamaRecommendedModel{
			Name:         m.Name,
			Description:  m.Description,
			SizeEstimate: m.SizeEstimate,
			EmbeddingDim: m.EmbeddingDim,
			Installed:    m.Installed,
			Role:         m.Role,
		})
	}
	return out, nil
}

func (s *Server) PullOllamaModel(req *pb.PullModelRequest, stream grpc.ServerStreamingServer[pb.OllamaPullProgressEvent]) error {
	if err := s.requireCtxmem(); err != nil {
		return err
	}
	ctx := stream.Context()
	err := s.ctxmem.Ollama.PullModel(ctx, req.GetName(), func(p embed.PullProgress) {
		_ = stream.Send(&pb.OllamaPullProgressEvent{
			Status:     p.Status,
			Downloaded: p.Downloaded,
			Total:      p.Total,
			Digest:     p.Digest,
			Error:      p.Error,
			Done:       p.Done,
		})
	})
	if err != nil {
		// Convert to a final error event and an RPC error so clients
		// observe both (the event stream is how the UI surfaces the
		// message; the error closes the stream cleanly).
		_ = stream.Send(&pb.OllamaPullProgressEvent{Error: err.Error()})
		return status.Error(codes.Internal, err.Error())
	}
	return nil
}

// --- PB conversion helpers --------------------------------------------------

func nodeToPB(n ctxmem.Node) *pb.ContextNode {
	if n.Attrs == nil {
		n.Attrs = map[string]string{}
	}
	return &pb.ContextNode{
		Id:              n.ID,
		RepoId:          n.RepoID,
		Kind:            n.Kind,
		Label:           n.Label,
		ContentMd:       n.ContentMD,
		Attrs:           n.Attrs,
		SourceKind:      n.SourceKind,
		Confidence:      n.Confidence,
		Enabled:         n.Enabled,
		Pinned:          n.Pinned,
		CreatedAt:       toProtoTime(n.CreatedAt),
		UpdatedAt:       toProtoTime(n.UpdatedAt),
	}
}

func nodesToPB(nodes []ctxmem.Node) []*pb.ContextNode {
	out := make([]*pb.ContextNode, 0, len(nodes))
	for _, n := range nodes {
		out = append(out, nodeToPB(n))
	}
	return out
}

func edgeToPB(e ctxmem.Edge) *pb.ContextEdge {
	if e.Attrs == nil {
		e.Attrs = map[string]string{}
	}
	return &pb.ContextEdge{
		Id:        e.ID,
		RepoId:    e.RepoID,
		SrcNodeId: e.SrcNodeID,
		DstNodeId: e.DstNodeID,
		Rel:       e.Rel,
		Attrs:     e.Attrs,
		CreatedAt: toProtoTime(e.CreatedAt),
	}
}

func edgesToPB(edges []ctxmem.Edge) []*pb.ContextEdge {
	out := make([]*pb.ContextEdge, 0, len(edges))
	for _, e := range edges {
		out = append(out, edgeToPB(e))
	}
	return out
}

func factToPB(f ctxmem.Fact) *pb.ContextFact {
	return &pb.ContextFact{
		Id:            f.ID,
		RepoId:        f.RepoID,
		SubjectNodeId: f.SubjectNodeID,
		Predicate:     f.Predicate,
		ObjectText:    f.ObjectText,
		ValidFrom:     toProtoTime(f.ValidFrom),
		ValidTo:       toProtoTime(f.ValidTo),
		Supersedes:    f.Supersedes,
		CreatedAt:     toProtoTime(f.CreatedAt),
	}
}

func factsToPB(facts []ctxmem.Fact) []*pb.ContextFact {
	out := make([]*pb.ContextFact, 0, len(facts))
	for _, f := range facts {
		out = append(out, factToPB(f))
	}
	return out
}

func nodeDetailToPB(d ctxmem.NodeDetail) *pb.ContextNodeDetail {
	return &pb.ContextNodeDetail{
		Node:            nodeToPB(d.Node),
		OutEdges:        edgesToPB(d.OutEdges),
		InEdges:         edgesToPB(d.InEdges),
		Neighbors:       nodesToPB(d.Neighbors),
		Facts:           factsToPB(d.Facts),
		SourceTaskId:    d.SourceTaskID,
		SourceSessionId: d.SourceSessionID,
	}
}

func overviewToPB(o ctxmem.Overview) *pb.ContextOverview {
	return &pb.ContextOverview{
		RepoId:                  o.RepoID,
		NodeCountsByKind:        o.NodeCountsByKind,
		EdgeCountsByRel:         o.EdgeCountsByRel,
		ActiveFactCount:         o.ActiveFactCount,
		ExpiredFactCount:        o.ExpiredFactCount,
		PendingScratchpadCount:  o.PendingScratchpadCount,
		PromotedScratchpadCount: o.PromotedScratchpadCount,
		RejectedScratchpadCount: o.RejectedScratchpadCount,
		VectorCount:             o.VectorCount,
		VectorDim:               o.VectorDim,
		VectorBytes:             o.VectorBytes,
		ObservedSessionCount:    o.ObservedSessionCount,
		Enabled:                 o.Enabled,
	}
}

func searchResultToPB(r ctxmem.SearchResult) *pb.SearchContextResponse {
	channels := map[string]*pb.SearchHitList{}
	for name, hits := range r.Channels {
		list := &pb.SearchHitList{Hits: make([]*pb.SearchHit, 0, len(hits))}
		for _, h := range hits {
			list.Hits = append(list.Hits, &pb.SearchHit{
				Node:    nodeToPB(h.Node),
				Score:   h.Score,
				Rank:    int32(h.Rank),
				Channel: h.Channel,
				Reason:  h.Reason,
			})
		}
		channels[name] = list
	}
	return &pb.SearchContextResponse{
		Channels:    channels,
		TotalUnique: int32(r.TotalUnique),
	}
}

func injectionPreviewToPB(p ctxmem.InjectionPreview) *pb.InjectionPreview {
	sources := make([]*pb.InjectionSource, 0, len(p.Sources))
	for _, src := range p.Sources {
		sources = append(sources, &pb.InjectionSource{
			SourceType: src.SourceType,
			SourceRef:  src.SourceRef,
			Label:      src.Label,
			Channel:    src.Channel,
			Tokens:     src.Tokens,
			Relevance:  src.Relevance,
		})
	}
	return &pb.InjectionPreview{
		SystemPrompt:    p.SystemPrompt,
		Sources:         sources,
		EstimatedTokens: p.EstimatedTokens,
		Tier:            p.Tier,
	}
}

func memorySettingsToPB(set ctxmem.Settings) *pb.MemorySettings {
	return &pb.MemorySettings{
		RepoId:                    set.RepoID,
		Enabled:                   set.Enabled,
		EmbeddingProvider:         set.EmbeddingProvider,
		EmbeddingModel:            set.EmbeddingModel,
		EmbeddingDim:              int32(set.EmbeddingDim),
		LlmProvider:               set.LLMProvider,
		LlmModel:                  set.LLMModel,
		PassiveTokenBudget:        int32(set.PassiveTokenBudget),
		TopKNeighbors:             int32(set.TopKNeighbors),
		AutoPromoteHighConfidence: set.AutoPromoteHighConfidence,
		AutoPromoteThreshold:      set.AutoPromoteThreshold,
		UpdatedAt:                 toProtoTime(set.UpdatedAt),
	}
}

func memorySettingsFromPB(p *pb.MemorySettings) ctxmem.Settings {
	if p == nil {
		return ctxmem.Settings{}
	}
	return ctxmem.Settings{
		RepoID:                    p.GetRepoId(),
		Enabled:                   p.GetEnabled(),
		EmbeddingProvider:         p.GetEmbeddingProvider(),
		EmbeddingModel:            p.GetEmbeddingModel(),
		EmbeddingDim:              int(p.GetEmbeddingDim()),
		LLMProvider:               p.GetLlmProvider(),
		LLMModel:                  p.GetLlmModel(),
		PassiveTokenBudget:        int(p.GetPassiveTokenBudget()),
		TopKNeighbors:             int(p.GetTopKNeighbors()),
		AutoPromoteHighConfidence: p.GetAutoPromoteHighConfidence(),
		AutoPromoteThreshold:      p.GetAutoPromoteThreshold(),
	}
}

func changeEventToPB(evt *ctxmem.ChangeEvent) *pb.ContextChangeEvent {
	return &pb.ContextChangeEvent{
		Seq:        evt.Seq,
		Kind:       evt.Kind,
		Op:         evt.Op,
		Id:         evt.ID,
		RepoId:     evt.RepoID,
		Message:    evt.Message,
		OccurredAt: toProtoTime(evt.OccurredAt),
	}
}

func scratchpadEntryToPB(e ctxmem.ScratchpadEntry) *pb.ScratchpadEntry {
	return &pb.ScratchpadEntry{
		Id:                e.ID,
		RepoId:            e.RepoID,
		ProposedKind:      e.ProposedKind,
		ProposedLabel:     e.ProposedLabel,
		ProposedContentMd: e.ProposedContentMD,
		SourceKind:        e.SourceKind,
		SourceRef:         e.SourceRef,
		Signals:           e.Signals,
		Confidence:        e.Confidence,
		Status:            e.Status,
		SnoozedUntil:      toProtoTime(e.SnoozedUntil),
		CreatedAt:         toProtoTime(e.CreatedAt),
	}
}

func scratchpadEntriesToPB(entries []ctxmem.ScratchpadEntry) []*pb.ScratchpadEntry {
	out := make([]*pb.ScratchpadEntry, 0, len(entries))
	for _, e := range entries {
		out = append(out, scratchpadEntryToPB(e))
	}
	return out
}

func toProtoTime(t time.Time) *timestamppb.Timestamp {
	if t.IsZero() {
		return nil
	}
	return timestamppb.New(t)
}
