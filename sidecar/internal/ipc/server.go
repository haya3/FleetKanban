// Package ipc exposes the FleetKanban backend as a gRPC server consumed by
// the Flutter UI sidecar. Handlers wrap internal/app.Service 1:1; conversion
// between domain types and protobuf wire types is in convert.go.
package ipc

import (
	"context"
	"errors"
	"fmt"
	"runtime"
	"runtime/debug"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/types/known/emptypb"

	"github.com/FleetKanban/fleetkanban/internal/app"
	"github.com/FleetKanban/fleetkanban/internal/branding"
	"github.com/FleetKanban/fleetkanban/internal/copilot"
	"github.com/FleetKanban/fleetkanban/internal/orchestrator"
	"github.com/FleetKanban/fleetkanban/internal/setup"
	"github.com/FleetKanban/fleetkanban/internal/store"
	"github.com/FleetKanban/fleetkanban/internal/task"

	pb "github.com/FleetKanban/fleetkanban/internal/ipc/gen/fleetkanban/v1"
)

// Server bundles the gRPC service implementations. It owns no state of
// its own; all lookups route through app.Service. The event broker is a
// separate concern (see broker.go) but is kept here so WatchEvents can call
// into it without the handler needing a second struct reference.
type Server struct {
	pb.UnimplementedTaskServiceServer
	pb.UnimplementedSubtaskServiceServer
	pb.UnimplementedRepositoryServiceServer
	pb.UnimplementedAuthServiceServer
	pb.UnimplementedSystemServiceServer
	pb.UnimplementedWorktreeServiceServer
	pb.UnimplementedModelServiceServer
	pb.UnimplementedHousekeepingServiceServer
	pb.UnimplementedInsightsServiceServer

	app          *app.Service
	broker       *EventBroker
	shutdownHook func(context.Context) error
	housekeeping *HousekeepingDeps // nil when the reaper failed to init
}

// ServerConfig bundles dependencies.
type ServerConfig struct {
	App          *app.Service
	Broker       *EventBroker
	ShutdownHook func(context.Context) error // invoked by SystemService.Shutdown
	// Housekeeping is optional. When nil, HousekeepingService RPCs return
	// Unavailable (typically because the reaper failed to initialise).
	Housekeeping *HousekeepingDeps
}

// NewServer constructs a gRPC Server bound to the given Service.
func NewServer(cfg ServerConfig) (*Server, error) {
	if cfg.App == nil {
		return nil, errors.New("ipc: App is required")
	}
	if cfg.Broker == nil {
		return nil, errors.New("ipc: Broker is required")
	}
	return &Server{
		app:          cfg.App,
		broker:       cfg.Broker,
		shutdownHook: cfg.ShutdownHook,
		housekeeping: cfg.Housekeeping,
	}, nil
}

// --- TaskService -----------------------------------------------------------

func (s *Server) CreateTask(ctx context.Context, req *pb.CreateTaskRequest) (*pb.Task, error) {
	t, err := s.app.CreateTask(ctx, app.CreateTaskInput{
		RepositoryID: req.GetRepositoryId(),
		Goal:         req.GetGoal(),
		BaseBranch:   req.GetBaseBranch(),
		Model:        req.GetModel(),
		PlanModel:    req.GetPlanModel(),
		ReviewModel:  req.GetReviewModel(),
	})
	if err != nil {
		return nil, mapAppError(err)
	}
	return taskToPB(t), nil
}

func (s *Server) ListTasks(ctx context.Context, req *pb.ListTasksRequest) (*pb.ListTasksResponse, error) {
	tasks, err := s.app.ListTasks(ctx, listFilterFromPB(req))
	if err != nil {
		return nil, mapAppError(err)
	}
	return &pb.ListTasksResponse{Tasks: tasksToPB(tasks)}, nil
}

func (s *Server) GetTask(ctx context.Context, req *pb.IdRequest) (*pb.Task, error) {
	t, err := s.app.GetTask(ctx, req.GetId())
	if err != nil {
		return nil, mapAppError(err)
	}
	return taskToPB(t), nil
}

func (s *Server) GetTaskDiff(ctx context.Context, req *pb.IdRequest) (*pb.DiffResponse, error) {
	diff, err := s.app.GetTaskDiff(ctx, req.GetId())
	if err != nil {
		return nil, mapAppError(err)
	}
	return &pb.DiffResponse{UnifiedDiff: diff}, nil
}

func (s *Server) RunTask(ctx context.Context, req *pb.IdRequest) (*emptypb.Empty, error) {
	if err := s.app.RunTask(ctx, req.GetId()); err != nil {
		return nil, mapAppError(err)
	}
	return &emptypb.Empty{}, nil
}

func (s *Server) CancelTask(ctx context.Context, req *pb.IdRequest) (*emptypb.Empty, error) {
	if err := s.app.CancelTask(ctx, req.GetId()); err != nil {
		return nil, mapAppError(err)
	}
	return &emptypb.Empty{}, nil
}

func (s *Server) FinalizeTask(ctx context.Context, req *pb.FinalizeTaskRequest) (*emptypb.Empty, error) {
	var finalization orchestrator.Finalization
	switch req.GetAction() {
	case pb.FinalizeAction_FINALIZE_ACTION_KEEP:
		finalization = orchestrator.FinalizeKeep
	case pb.FinalizeAction_FINALIZE_ACTION_MERGE:
		finalization = orchestrator.FinalizeMerge
	case pb.FinalizeAction_FINALIZE_ACTION_DISCARD:
		finalization = orchestrator.FinalizeDiscard
	default:
		return nil, status.Error(codes.InvalidArgument,
			"FinalizeTask: action is required (KEEP / MERGE / DISCARD)")
	}
	if err := s.app.FinalizeTask(ctx, req.GetId(), finalization); err != nil {
		return nil, mapAppError(err)
	}
	return &emptypb.Empty{}, nil
}

func (s *Server) DeleteTask(ctx context.Context, req *pb.DeleteTaskRequest) (*emptypb.Empty, error) {
	if err := s.app.DeleteTask(ctx, req.GetId(), req.GetDeleteBranch()); err != nil {
		return nil, mapAppError(err)
	}
	return &emptypb.Empty{}, nil
}

func (s *Server) DeleteTaskBranch(ctx context.Context, req *pb.IdRequest) (*emptypb.Empty, error) {
	if err := s.app.DeleteTaskBranch(ctx, req.GetId()); err != nil {
		return nil, mapAppError(err)
	}
	return &emptypb.Empty{}, nil
}

func (s *Server) SubmitReview(ctx context.Context, req *pb.SubmitReviewRequest) (*emptypb.Empty, error) {
	var action app.ReviewAction
	switch req.GetAction() {
	case pb.ReviewAction_REVIEW_ACTION_APPROVE:
		action = app.ReviewApprove
	case pb.ReviewAction_REVIEW_ACTION_REWORK:
		action = app.ReviewRework
	case pb.ReviewAction_REVIEW_ACTION_REJECT:
		action = app.ReviewReject
	default:
		return nil, status.Error(codes.InvalidArgument, "SubmitReview: action is required")
	}
	if err := s.app.SubmitReview(ctx, req.GetId(), action, req.GetFeedback()); err != nil {
		return nil, mapAppError(err)
	}
	return &emptypb.Empty{}, nil
}

// --- SubtaskService -------------------------------------------------------

func (s *Server) ListSubtasks(ctx context.Context, req *pb.ListSubtasksRequest) (*pb.ListSubtasksResponse, error) {
	subs, err := s.app.ListSubtasks(ctx, req.GetTaskId())
	if err != nil {
		return nil, mapAppError(err)
	}
	return &pb.ListSubtasksResponse{Subtasks: subtasksToPB(subs)}, nil
}

func (s *Server) CreateSubtask(ctx context.Context, req *pb.CreateSubtaskRequest) (*pb.Subtask, error) {
	sub, err := s.app.CreateSubtask(ctx, app.CreateSubtaskInput{
		TaskID:    req.GetTaskId(),
		Title:     req.GetTitle(),
		AgentRole: req.GetAgentRole(),
		DependsOn: req.GetDependsOn(),
		Status:    task.SubtaskStatus(req.GetStatus()),
		OrderIdx:  int(req.GetOrderIdx()),
	})
	if err != nil {
		return nil, mapAppError(err)
	}
	return subtaskToPB(sub), nil
}

func (s *Server) UpdateSubtask(ctx context.Context, req *pb.UpdateSubtaskRequest) (*pb.Subtask, error) {
	sub, err := s.app.UpdateSubtask(ctx, app.UpdateSubtaskInput{
		ID:     req.GetId(),
		Title:  req.GetTitle(),
		Status: task.SubtaskStatus(req.GetStatus()),
	})
	if err != nil {
		return nil, mapAppError(err)
	}
	return subtaskToPB(sub), nil
}

func (s *Server) DeleteSubtask(ctx context.Context, req *pb.IdRequest) (*emptypb.Empty, error) {
	if err := s.app.DeleteSubtask(ctx, req.GetId()); err != nil {
		return nil, mapAppError(err)
	}
	return &emptypb.Empty{}, nil
}

func (s *Server) ReorderSubtasks(ctx context.Context, req *pb.ReorderSubtasksRequest) (*emptypb.Empty, error) {
	if err := s.app.ReorderSubtasks(ctx, req.GetTaskId(), req.GetIds()); err != nil {
		return nil, mapAppError(err)
	}
	return &emptypb.Empty{}, nil
}

func (s *Server) TaskEvents(ctx context.Context, req *pb.TaskEventsRequest) (*pb.TaskEventsResponse, error) {
	events, err := s.app.TaskEvents(ctx, req.GetTaskId(), req.GetSinceSeq(), int(req.GetLimit()))
	if err != nil {
		return nil, mapAppError(err)
	}
	return &pb.TaskEventsResponse{Events: eventsToPB(events)}, nil
}

// --- RepositoryService -----------------------------------------------------

func (s *Server) RegisterRepository(ctx context.Context, req *pb.RegisterRepositoryRequest) (*pb.Repository, error) {
	r, err := s.app.RegisterRepository(ctx, app.RegisterRepositoryInput{
		Path:              req.GetPath(),
		DisplayName:       req.GetDisplayName(),
		InitializeIfEmpty: req.GetInitializeIfEmpty(),
	})
	if err != nil {
		return nil, mapAppError(err)
	}
	return repositoryToPB(r), nil
}

func (s *Server) ListRepositories(ctx context.Context, _ *emptypb.Empty) (*pb.ListRepositoriesResponse, error) {
	rs, err := s.app.ListRepositories(ctx)
	if err != nil {
		return nil, mapAppError(err)
	}
	return &pb.ListRepositoriesResponse{Repositories: repositoriesToPB(rs)}, nil
}

func (s *Server) CheckGitConfig(ctx context.Context, _ *emptypb.Empty) (*pb.GitConfigStatus, error) {
	st, err := s.app.CheckGitConfig(ctx)
	if err != nil {
		return nil, mapAppError(err)
	}
	return gitConfigToPB(st), nil
}

func (s *Server) UpdateDefaultBaseBranch(ctx context.Context, req *pb.UpdateDefaultBaseBranchRequest) (*pb.Repository, error) {
	r, err := s.app.UpdateDefaultBaseBranch(ctx, req.GetRepositoryId(), req.GetDefaultBaseBranch())
	if err != nil {
		return nil, mapAppError(err)
	}
	return repositoryToPB(r), nil
}

func (s *Server) ListBranches(ctx context.Context, req *pb.ListBranchesRequest) (*pb.ListBranchesResponse, error) {
	bl, err := s.app.ListBranches(ctx, req.GetRepositoryId())
	if err != nil {
		return nil, mapAppError(err)
	}
	return &pb.ListBranchesResponse{
		Branches:      bl.Branches,
		DefaultBranch: bl.DefaultBranch,
		HasCommits:    bl.HasCommits,
	}, nil
}

func (s *Server) CreateInitialCommit(ctx context.Context, req *pb.IdRequest) (*pb.Repository, error) {
	r, err := s.app.CreateInitialCommit(ctx, req.GetId())
	if err != nil {
		return nil, mapAppError(err)
	}
	return repositoryToPB(r), nil
}

func (s *Server) ScanGitRepositories(ctx context.Context, req *pb.ScanGitRepositoriesRequest) (*pb.ScanGitRepositoriesResponse, error) {
	found, rootIsRepo, err := s.app.ScanGitRepositories(ctx, req.GetPath(), int(req.GetMaxDepth()))
	if err != nil {
		return nil, mapAppError(err)
	}
	out := &pb.ScanGitRepositoriesResponse{
		RootIsRepo:   rootIsRepo,
		Repositories: make([]*pb.FoundRepository, 0, len(found)),
	}
	for _, f := range found {
		out.Repositories = append(out.Repositories, &pb.FoundRepository{
			Path:              f.Path,
			DefaultBranch:     f.DefaultBranch,
			AlreadyRegistered: f.AlreadyRegistered,
		})
	}
	return out, nil
}

// --- AuthService -----------------------------------------------------------

func (s *Server) CheckCopilotAuth(ctx context.Context, _ *emptypb.Empty) (*pb.AuthStatus, error) {
	a, err := s.app.CheckCopilotAuth(ctx)
	if err != nil {
		return nil, mapAppError(err)
	}
	return authStatusToPB(a), nil
}

func (s *Server) BeginCopilotLogin(ctx context.Context, _ *emptypb.Empty) (*pb.CopilotLoginChallenge, error) {
	ch, err := s.app.BeginCopilotLogin(ctx)
	if err != nil {
		return nil, mapAppError(err)
	}
	return &pb.CopilotLoginChallenge{
		UserCode:         ch.UserCode,
		VerificationUri:  ch.VerificationURI,
		ExpiresInSeconds: int32(ch.ExpiresIn.Seconds()),
	}, nil
}

func (s *Server) CancelCopilotLogin(ctx context.Context, _ *emptypb.Empty) (*emptypb.Empty, error) {
	if err := s.app.CancelCopilotLogin(ctx); err != nil {
		return nil, mapAppError(err)
	}
	return &emptypb.Empty{}, nil
}

func (s *Server) GetCopilotLoginSession(ctx context.Context, _ *emptypb.Empty) (*pb.CopilotLoginSessionInfo, error) {
	snap := s.app.GetCopilotLoginSession(ctx)
	return &pb.CopilotLoginSessionInfo{
		State:        loginSessionStateToPB(snap.State),
		ErrorMessage: snap.ErrorMessage,
	}, nil
}

func loginSessionStateToPB(s copilot.LoginSessionState) pb.CopilotLoginSessionState {
	switch s {
	case copilot.LoginSessionIdle:
		return pb.CopilotLoginSessionState_COPILOT_LOGIN_SESSION_STATE_IDLE
	case copilot.LoginSessionRunning:
		return pb.CopilotLoginSessionState_COPILOT_LOGIN_SESSION_STATE_RUNNING
	case copilot.LoginSessionSucceeded:
		return pb.CopilotLoginSessionState_COPILOT_LOGIN_SESSION_STATE_SUCCEEDED
	case copilot.LoginSessionFailed:
		return pb.CopilotLoginSessionState_COPILOT_LOGIN_SESSION_STATE_FAILED
	default:
		return pb.CopilotLoginSessionState_COPILOT_LOGIN_SESSION_STATE_UNSPECIFIED
	}
}

func (s *Server) StartCopilotLogout(ctx context.Context, _ *emptypb.Empty) (*emptypb.Empty, error) {
	if err := s.app.StartCopilotLogout(ctx); err != nil {
		return nil, mapAppError(err)
	}
	return &emptypb.Empty{}, nil
}

func (s *Server) ReloadCopilotAuth(ctx context.Context, _ *emptypb.Empty) (*pb.AuthStatus, error) {
	a, err := s.app.ReloadCopilotAuth(ctx)
	if err != nil {
		return nil, mapAppError(err)
	}
	return authStatusToPB(a), nil
}

func (s *Server) HasGitHubToken(ctx context.Context, _ *emptypb.Empty) (*pb.BoolValue, error) {
	ok, err := s.app.HasGitHubToken(ctx)
	if err != nil {
		return nil, mapAppError(err)
	}
	return &pb.BoolValue{Value: ok}, nil
}

func (s *Server) SetGitHubToken(ctx context.Context, req *pb.SetGitHubTokenRequest) (*emptypb.Empty, error) {
	if err := s.app.SetGitHubToken(ctx, req.GetToken()); err != nil {
		return nil, mapAppError(err)
	}
	return &emptypb.Empty{}, nil
}

func (s *Server) ListGitHubTokens(ctx context.Context, _ *emptypb.Empty) (*pb.ListGitHubTokensResponse, error) {
	entries, active, err := s.app.ListGitHubTokens(ctx)
	if err != nil {
		return nil, mapAppError(err)
	}
	return tokenListToPB(entries, active), nil
}

func (s *Server) AddGitHubToken(ctx context.Context, req *pb.AddGitHubTokenRequest) (*emptypb.Empty, error) {
	if err := s.app.AddGitHubToken(ctx, req.GetLabel(), req.GetToken(), req.GetSetActive()); err != nil {
		return nil, mapAppError(err)
	}
	return &emptypb.Empty{}, nil
}

func (s *Server) RemoveGitHubToken(ctx context.Context, req *pb.GitHubTokenLabelRequest) (*emptypb.Empty, error) {
	if err := s.app.RemoveGitHubToken(ctx, req.GetLabel()); err != nil {
		return nil, mapAppError(err)
	}
	return &emptypb.Empty{}, nil
}

func (s *Server) SetActiveGitHubToken(ctx context.Context, req *pb.GitHubTokenLabelRequest) (*emptypb.Empty, error) {
	if err := s.app.SetActiveGitHubToken(ctx, req.GetLabel()); err != nil {
		return nil, mapAppError(err)
	}
	return &emptypb.Empty{}, nil
}

func (s *Server) GetGitHubAccountInfo(ctx context.Context, _ *emptypb.Empty) (*pb.GitHubAccountInfo, error) {
	info, err := s.app.GetGitHubAccountInfo(ctx)
	if err != nil {
		return nil, mapAppError(err)
	}
	return &pb.GitHubAccountInfo{
		Login:             info.Login,
		Name:              info.Name,
		AvatarUrl:         info.AvatarURL,
		PlanName:          info.PlanName,
		PlanPrivateRepos:  info.PlanRepos,
		PlanCollaborators: info.PlanSeats,
		PlanSpace:         info.PlanSpace,
		CopilotEnabled:    info.CopilotActive,
		RawMessage:        info.RawMessage,
	}, nil
}

// --- SystemService ---------------------------------------------------------

func (s *Server) GetConcurrency(ctx context.Context, _ *emptypb.Empty) (*pb.IntValue, error) {
	n, err := s.app.GetConcurrency(ctx)
	if err != nil {
		return nil, mapAppError(err)
	}
	return &pb.IntValue{Value: int32(n)}, nil
}

func (s *Server) SetConcurrency(ctx context.Context, req *pb.IntValue) (*pb.IntValue, error) {
	n, err := s.app.SetConcurrency(ctx, int(req.GetValue()))
	if err != nil {
		return nil, mapAppError(err)
	}
	return &pb.IntValue{Value: int32(n)}, nil
}

// --- ModelService ----------------------------------------------------------

func (s *Server) ListModels(ctx context.Context, _ *emptypb.Empty) (*pb.ListModelsResponse, error) {
	models, err := s.app.ListCopilotModels(ctx)
	if err != nil {
		return nil, mapAppError(err)
	}
	out := make([]*pb.ModelInfo, 0, len(models))
	for _, m := range models {
		out = append(out, &pb.ModelInfo{
			Id:         m.ID,
			Name:       m.Name,
			Multiplier: m.Multiplier,
		})
	}
	return &pb.ListModelsResponse{Models: out}, nil
}

func (s *Server) GetVersion(_ context.Context, _ *emptypb.Empty) (*pb.VersionInfo, error) {
	return &pb.VersionInfo{
		ProtocolVersion:   int32(branding.ProtocolVersion),
		CopilotSdkVersion: copilotSDKVersion(),
		GoVersion:         runtime.Version(),
	}, nil
}

// copilotSDKVersion scans the linked build info for the Copilot SDK's
// semver, so the Status page can display it without a build-time
// codegen step. Returns "" if the sidecar was built without module
// info (test binaries, stripped releases).
func copilotSDKVersion() string {
	info, ok := debug.ReadBuildInfo()
	if !ok {
		return ""
	}
	const modulePath = "github.com/github/copilot-sdk/go"
	for _, dep := range info.Deps {
		if dep != nil && dep.Path == modulePath {
			return dep.Version
		}
	}
	return ""
}

func (s *Server) Shutdown(ctx context.Context, _ *emptypb.Empty) (*emptypb.Empty, error) {
	if s.shutdownHook == nil {
		return &emptypb.Empty{}, nil
	}
	if err := s.shutdownHook(ctx); err != nil {
		return nil, status.Errorf(codes.Internal, "shutdown: %v", err)
	}
	return &emptypb.Empty{}, nil
}

// preconditionKindPwsh is the sole supported precondition in Phase 1.
// The string is stable gRPC wire content, not a user-facing label —
// changing it would break UI clients compiled against the old value.
const preconditionKindPwsh = "pwsh"

func (s *Server) GetPreconditions(_ context.Context, _ *emptypb.Empty) (*pb.PreconditionsResponse, error) {
	return &pb.PreconditionsResponse{
		Preconditions: []*pb.Precondition{pwshPrecondition()},
	}, nil
}

func (s *Server) InstallPrecondition(ctx context.Context, req *pb.InstallPreconditionRequest) (*pb.InstallPreconditionResponse, error) {
	switch req.GetKind() {
	case preconditionKindPwsh:
		result, err := setup.InstallPwsh(ctx)
		resp := &pb.InstallPreconditionResponse{
			Precondition: pwshPreconditionFromCheck(result),
		}
		if err != nil {
			// ErrWingetMissing is the one error we want the UI to treat
			// distinctly (no auto-install possible). Everything else is a
			// transient installer failure; include the short form so the
			// user has something to paste into a support thread.
			if errors.Is(err, setup.ErrWingetMissing) {
				resp.Precondition.AutoInstallable = false
			}
			resp.Error = err.Error()
		}
		return resp, nil
	default:
		return nil, status.Errorf(codes.InvalidArgument, "unknown precondition kind %q", req.GetKind())
	}
}

// pwshPrecondition is the canonical Precondition payload for the
// pwsh dependency. Re-checks on every call so the UI always sees the
// authoritative state (the user may have installed pwsh manually
// between two UI-side polls).
func pwshPrecondition() *pb.Precondition {
	return pwshPreconditionFromCheck(setup.CheckPwsh())
}

func pwshPreconditionFromCheck(c setup.PwshCheckResult) *pb.Precondition {
	return &pb.Precondition{
		Kind:            preconditionKindPwsh,
		Satisfied:       c.Installed,
		Description:     "PowerShell 7 (pwsh) — used by Copilot agents for shell operations",
		AutoInstallable: true,
		Detail:          c.Detail,
		ManualCommand:   setup.ManualInstallCommand(),
	}
}

// --- WorktreeService -------------------------------------------------------

func (s *Server) ListWorktrees(ctx context.Context, _ *emptypb.Empty) (*pb.ListWorktreesResponse, error) {
	infos, err := s.app.ListWorktrees(ctx)
	if err != nil {
		return nil, mapAppError(err)
	}
	return &pb.ListWorktreesResponse{Worktrees: worktreeInfosToPB(infos)}, nil
}

func (s *Server) RemoveWorktree(ctx context.Context, req *pb.RemoveWorktreeRequest) (*emptypb.Empty, error) {
	err := s.app.RemoveWorktree(ctx, app.RemoveWorktreeInput{
		RepositoryID: req.GetRepositoryId(),
		WorktreePath: req.GetWorktreePath(),
		DeleteBranch: req.GetDeleteBranch(),
	})
	if err != nil {
		return nil, mapAppError(err)
	}
	return &emptypb.Empty{}, nil
}

// --- Error mapping ---------------------------------------------------------

// mapAppError converts well-known application errors to gRPC status codes.
// Anything it does not recognize becomes Unknown; the original message is
// preserved so the client can display it.
func mapAppError(err error) error {
	if err == nil {
		return nil
	}
	switch {
	case errors.Is(err, store.ErrNotFound):
		return status.Error(codes.NotFound, err.Error())
	case errors.Is(err, store.ErrDuplicatePath):
		return status.Error(codes.AlreadyExists, err.Error())
	case errors.Is(err, app.ErrWSLPathRejected):
		return status.Error(codes.InvalidArgument, err.Error())
	case errors.Is(err, app.ErrUnsupportedToken):
		return status.Error(codes.InvalidArgument, err.Error())
	case errors.Is(err, app.ErrSecretsUnavailable):
		return status.Error(codes.FailedPrecondition, err.Error())
	case errors.Is(err, app.ErrPrimaryWorktreeProtected):
		return status.Error(codes.FailedPrecondition, err.Error())
	case errors.Is(err, app.ErrNoPAT):
		return status.Error(codes.FailedPrecondition, err.Error())
	case errors.Is(err, app.ErrInvalidToken):
		// Unauthenticated so the UI surfaces "rotate your PAT" rather than
		// conflating with "scopes missing" (ErrInsufficientScopes below).
		return status.Error(codes.Unauthenticated, err.Error())
	case errors.Is(err, app.ErrInsufficientScopes):
		return status.Error(codes.PermissionDenied, err.Error())
	case errors.Is(err, app.ErrTaskStillRunning):
		return status.Error(codes.FailedPrecondition, err.Error())
	case errors.Is(err, app.ErrTaskBranchAlreadyRemoved):
		// Not really an error — branch is already gone. Use NotFound so the
		// UI can treat it as a no-op refresh rather than a scary failure.
		return status.Error(codes.NotFound, err.Error())
	case errors.Is(err, app.ErrNotAGitRepo):
		// FailedPrecondition so the UI can catch the exact condition and
		// prompt the user to `git init`; the string tag is checked
		// client-side to disambiguate from other FailedPrecondition errors.
		return status.Error(codes.FailedPrecondition, "not_a_git_repo: "+err.Error())
	case errors.Is(err, app.ErrRepositoryAlreadyHasCommits):
		// FailedPrecondition: caller's cached has_commits flag is stale.
		// String tag mirrors the not_a_git_repo prefix so clients can
		// disambiguate via prefix match rather than message parsing.
		return status.Error(codes.FailedPrecondition, "already_has_commits: "+err.Error())
	}
	// copilot.ErrNotAuthenticated and orchestrator errors use string values;
	// surface the message without relying on sentinel equality.
	return status.Error(codes.Unknown, fmt.Sprintf("%v", err))
}
