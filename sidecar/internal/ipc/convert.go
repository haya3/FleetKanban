package ipc

import (
	"time"

	"google.golang.org/protobuf/types/known/timestamppb"

	"github.com/FleetKanban/fleetkanban/internal/app"
	"github.com/FleetKanban/fleetkanban/internal/copilot"
	"github.com/FleetKanban/fleetkanban/internal/store"
	"github.com/FleetKanban/fleetkanban/internal/task"
	"github.com/FleetKanban/fleetkanban/internal/worktree"

	pb "github.com/FleetKanban/fleetkanban/internal/ipc/gen/fleetkanban/v1"
)

// ts wraps a time.Time as *timestamppb.Timestamp. Zero time maps to nil so the
// client can treat "unset" (e.g. StartedAt before running) distinctly from
// "epoch".
func ts(t time.Time) *timestamppb.Timestamp {
	if t.IsZero() {
		return nil
	}
	return timestamppb.New(t)
}

// tsp is the same as ts for a nullable *time.Time.
func tsp(t *time.Time) *timestamppb.Timestamp {
	if t == nil {
		return nil
	}
	return ts(*t)
}

// taskToPB converts a persisted task.Task to its wire representation.
func taskToPB(t *task.Task) *pb.Task {
	if t == nil {
		return nil
	}
	return &pb.Task{
		Id:             t.ID,
		RepositoryId:   t.RepoID,
		Goal:           t.Goal,
		BaseBranch:     t.BaseBranch,
		Branch:         t.Branch,
		WorktreePath:   t.WorktreePath,
		Model:          t.Model,
		PlanModel:      t.PlanModel,
		ReviewModel:    t.ReviewModel,
		Status:         string(t.Status),
		ErrorCode:      string(t.ErrorCode),
		ErrorMessage:   t.ErrorMessage,
		SessionId:      t.SessionID,
		BranchExists:   t.BranchExists,
		ReviewFeedback: t.ReviewFeedback,
		ReworkCount:    int32(t.ReworkCount),
		CreatedAt:      ts(t.CreatedAt),
		UpdatedAt:      ts(t.UpdatedAt),
		StartedAt:      tsp(t.StartedAt),
		FinishedAt:     tsp(t.FinishedAt),
	}
}

func subtaskToPB(s *task.Subtask) *pb.Subtask {
	if s == nil {
		return nil
	}
	return &pb.Subtask{
		Id:        s.ID,
		TaskId:    s.TaskID,
		Title:     s.Title,
		Status:    string(s.Status),
		OrderIdx:  int32(s.OrderIdx),
		CreatedAt: ts(s.CreatedAt),
		UpdatedAt: ts(s.UpdatedAt),
		AgentRole: s.AgentRole,
		DependsOn: s.DependsOn,
		CodeModel: s.CodeModel,
		Round:     int32(s.Round),
		Prompt:    s.Prompt,
	}
}

func subtasksToPB(subs []*task.Subtask) []*pb.Subtask {
	out := make([]*pb.Subtask, 0, len(subs))
	for _, s := range subs {
		out = append(out, subtaskToPB(s))
	}
	return out
}

func tasksToPB(ts []*task.Task) []*pb.Task {
	out := make([]*pb.Task, 0, len(ts))
	for _, t := range ts {
		out = append(out, taskToPB(t))
	}
	return out
}

func repositoryToPB(r *store.Repository) *pb.Repository {
	if r == nil {
		return nil
	}
	return &pb.Repository{
		Id:                r.ID,
		Path:              r.Path,
		DisplayName:       r.DisplayName,
		DefaultBaseBranch: r.DefaultBaseBranch,
		CreatedAt:         ts(r.CreatedAt),
		LastUsedAt:        tsp(r.LastUsedAt),
	}
}

func repositoriesToPB(rs []*store.Repository) []*pb.Repository {
	out := make([]*pb.Repository, 0, len(rs))
	for _, r := range rs {
		out = append(out, repositoryToPB(r))
	}
	return out
}

func eventToPB(e *task.AgentEvent) *pb.AgentEvent {
	if e == nil {
		return nil
	}
	return &pb.AgentEvent{
		Id:         e.ID,
		TaskId:     e.TaskID,
		Seq:        e.Seq,
		Kind:       string(e.Kind),
		Payload:    e.Payload,
		OccurredAt: ts(e.OccurredAt),
	}
}

func eventsToPB(events []*task.AgentEvent) []*pb.AgentEvent {
	out := make([]*pb.AgentEvent, 0, len(events))
	for _, e := range events {
		out = append(out, eventToPB(e))
	}
	return out
}

func authStatusToPB(s copilot.AuthStatus) *pb.AuthStatus {
	return &pb.AuthStatus{
		Authenticated: s.Authenticated,
		User:          s.User,
		Message:       s.Message,
		CheckedAt:     ts(s.CheckedAt),
	}
}

func subtaskContextInfoToPB(info app.SubtaskContextInfo) *pb.CopilotSubtaskContext {
	priors := info.PriorSummaries
	if priors == nil {
		priors = []string{}
	}
	return &pb.CopilotSubtaskContext{
		SubtaskId:             info.SubtaskID,
		Round:                 int32(info.Round),
		SystemPrompt:          info.SystemPrompt,
		UserPrompt:            info.UserPrompt,
		StagePromptTemplate:   info.StagePromptTemplate,
		PlanSummary:           info.PlanSummary,
		PriorSummaries:        priors,
		MemoryBlock:           info.MemoryBlock,
		OutputLanguage:        info.OutputLanguage,
		HarnessSkillVersionId: info.HarnessSkillVersionID,
		HarnessSkillMd:        info.HarnessSkillMD,
		NotRecorded:           info.NotRecorded,
	}
}

func copilotQuotaToPB(snapshots map[string]copilot.QuotaSnapshot) *pb.CopilotQuotaInfo {
	out := &pb.CopilotQuotaInfo{
		Snapshots: make(map[string]*pb.CopilotQuotaSnapshot, len(snapshots)),
	}
	for k, v := range snapshots {
		out.Snapshots[k] = &pb.CopilotQuotaSnapshot{
			EntitlementRequests:              v.Entitlement,
			UsedRequests:                     v.Used,
			RemainingPercentage:              v.RemainingPercentage,
			Overage:                          v.Overage,
			OverageAllowedWithExhaustedQuota: v.OverageAllowed,
			ResetDate:                        v.ResetDate,
		}
	}
	return out
}

func tokenListToPB(entries []app.TokenEntry, active string) *pb.ListGitHubTokensResponse {
	out := &pb.ListGitHubTokensResponse{
		Tokens:      make([]*pb.GitHubTokenEntry, 0, len(entries)),
		ActiveLabel: active,
	}
	for _, e := range entries {
		out.Tokens = append(out.Tokens, &pb.GitHubTokenEntry{
			Label:  e.Label,
			Active: e.Active,
		})
	}
	return out
}

func worktreeInfosToPB(infos []app.WorktreeInfo) []*pb.WorktreeEntry {
	out := make([]*pb.WorktreeEntry, 0, len(infos))
	for _, w := range infos {
		out = append(out, &pb.WorktreeEntry{
			RepositoryId:   w.RepositoryID,
			RepositoryPath: w.RepositoryPath,
			Path:           w.Path,
			Branch:         w.Branch,
			PathExists:     w.PathExists,
			IsPrimary:      w.IsPrimary,
			TaskId:         w.TaskID,
			TaskStatus:     w.TaskStatus,
			Head:           w.HEAD,
		})
	}
	return out
}

func gitConfigToPB(s worktree.GlobalConfigStatus) *pb.GitConfigStatus {
	return &pb.GitConfigStatus{
		LongPathsOk:  s.LongPathsOK,
		LongPathsVal: s.LongPathsVal,
		AutocrlfOk:   s.AutoCRLFOK,
		AutocrlfVal:  s.AutoCRLFVal,
	}
}

// listFilterFromPB reconstructs a store.ListFilter from the wire request.
// Unknown status strings are passed through; the store layer validates them
// at query time.
func listFilterFromPB(req *pb.ListTasksRequest) store.ListFilter {
	f := store.ListFilter{
		RepoID:    req.GetRepoId(),
		Limit:     int(req.GetLimit()),
		Ascending: req.GetAscending(),
	}
	for _, s := range req.GetStatuses() {
		f.Statuses = append(f.Statuses, task.Status(s))
	}
	return f
}
