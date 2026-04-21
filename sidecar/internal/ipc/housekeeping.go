package ipc

import (
	"context"
	"time"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/types/known/emptypb"
	"google.golang.org/protobuf/types/known/timestamppb"

	"github.com/haya3/FleetKanban/internal/reaper"
	"github.com/haya3/FleetKanban/internal/store"
	"github.com/haya3/FleetKanban/internal/task"
	"github.com/haya3/FleetKanban/internal/worktree"

	pb "github.com/haya3/FleetKanban/internal/ipc/gen/fleetkanban/v1"
)

// HousekeepingDeps bundles the dependencies HousekeepingService handlers
// need. All four pointers are required; if any is nil the handlers return
// Unavailable so the UI can degrade gracefully.
type HousekeepingDeps struct {
	Settings  *store.SettingsStore
	Reaper    *reaper.Service
	Tasks     *store.TaskStore
	Repos     *store.RepositoryStore
	Worktrees *worktree.Manager
}

const (
	// autoSweepMaxDays is the upper bound for the stored sweep threshold.
	// A year is plenty — anyone who wants "never" sets 0 (disabled) instead.
	autoSweepMaxDays = 365

	// defaultStaleOlderThanDays is the cutoff applied when ListStaleBranches
	// is called with older_than_days == 0. Matches the spec's 30-day target.
	defaultStaleOlderThanDays = 30
)

func (s *Server) housekeepingReady() error {
	if s.housekeeping == nil ||
		s.housekeeping.Settings == nil ||
		s.housekeeping.Reaper == nil ||
		s.housekeeping.Tasks == nil ||
		s.housekeeping.Repos == nil ||
		s.housekeeping.Worktrees == nil {
		return status.Error(codes.Unavailable, "housekeeping not configured")
	}
	return nil
}

// GetAutoSweepDays reads the opt-in Merged-sweep threshold. Unset reports
// (0, present=false) so the UI can distinguish "never configured" from
// "explicitly set to 0" — useful for default value hints.
func (s *Server) GetAutoSweepDays(ctx context.Context, _ *emptypb.Empty) (*pb.GetAutoSweepDaysResponse, error) {
	if err := s.housekeepingReady(); err != nil {
		return nil, err
	}
	days, present, err := s.housekeeping.Settings.GetInt(ctx, reaper.SettingAutoSweepMergedDays, 0)
	if err != nil {
		return nil, status.Errorf(codes.Internal, "get setting: %v", err)
	}
	return &pb.GetAutoSweepDaysResponse{
		Days:    int32(days),
		Present: present,
	}, nil
}

// SetAutoSweepDays clamps the requested value to [0, autoSweepMaxDays] and
// upserts it. Negative values become 0 (disabled) rather than an error
// because the UI slider may legitimately send 0 to turn the feature off.
func (s *Server) SetAutoSweepDays(ctx context.Context, req *pb.SetAutoSweepDaysRequest) (*pb.SetAutoSweepDaysResponse, error) {
	if err := s.housekeepingReady(); err != nil {
		return nil, err
	}
	d := int(req.GetDays())
	switch {
	case d < 0:
		d = 0
	case d > autoSweepMaxDays:
		d = autoSweepMaxDays
	}
	if err := s.housekeeping.Settings.SetInt(ctx, reaper.SettingAutoSweepMergedDays, d); err != nil {
		return nil, status.Errorf(codes.Internal, "set setting: %v", err)
	}
	return &pb.SetAutoSweepDaysResponse{EffectiveDays: int32(d)}, nil
}

// ListStaleBranches returns Done/Aborted tasks whose branch is still in the
// repository and whose FinishedAt is older than the configured threshold.
// The merged flag is computed per row so the UI can highlight branches
// that a one-click sweep would actually delete.
func (s *Server) ListStaleBranches(ctx context.Context, req *pb.ListStaleBranchesRequest) (*pb.ListStaleBranchesResponse, error) {
	if err := s.housekeepingReady(); err != nil {
		return nil, err
	}
	days := int(req.GetOlderThanDays())
	if days <= 0 {
		days = defaultStaleOlderThanDays
	}

	tasks, err := s.housekeeping.Tasks.List(ctx, store.ListFilter{
		Statuses: []task.Status{task.StatusDone, task.StatusAborted},
	})
	if err != nil {
		return nil, status.Errorf(codes.Internal, "list tasks: %v", err)
	}

	cutoff := time.Now().UTC().Add(-time.Duration(days) * 24 * time.Hour)
	repoCache := make(map[string]string) // repoID → path

	var branches []*pb.StaleBranch
	for _, t := range tasks {
		if t.Branch == "" || !t.BranchExists {
			continue
		}
		if t.FinishedAt == nil || t.FinishedAt.After(cutoff) {
			continue
		}

		repoPath, ok := repoCache[t.RepoID]
		if !ok {
			r, rerr := s.housekeeping.Repos.Get(ctx, t.RepoID)
			if rerr != nil {
				// Missing repo: the task points at a registration that was
				// removed. Surface the row without a path so the UI can
				// still offer manual cleanup.
				repoCache[t.RepoID] = ""
			} else {
				repoCache[t.RepoID] = r.Path
				repoPath = r.Path
			}
		}

		merged := false
		if t.BaseBranch != "" && repoPath != "" {
			if ok, _ := s.housekeeping.Worktrees.IsBranchMerged(
				ctx, repoPath, t.Branch, t.BaseBranch); ok {
				merged = true
			}
		}

		ageDays := int32(time.Since(*t.FinishedAt) / (24 * time.Hour))
		branches = append(branches, &pb.StaleBranch{
			TaskId:     t.ID,
			RepoId:     t.RepoID,
			RepoPath:   repoPath,
			Branch:     t.Branch,
			BaseBranch: t.BaseBranch,
			Goal:       t.Goal,
			Status:     string(t.Status),
			FinishedAt: timestamppb.New(*t.FinishedAt),
			AgeDays:    ageDays,
			Merged:     merged,
		})
	}
	return &pb.ListStaleBranchesResponse{Branches: branches}, nil
}

// RunSweepNow executes a single Merged-sweep pass. When the request's days
// is zero the configured setting is used; if that is also zero the feature
// is disabled and the call is rejected so users see a clear error rather
// than a silent no-op.
func (s *Server) RunSweepNow(ctx context.Context, req *pb.RunSweepNowRequest) (*pb.RunSweepNowResponse, error) {
	if err := s.housekeepingReady(); err != nil {
		return nil, err
	}
	days := int(req.GetDays())
	if days <= 0 {
		configured, _, err := s.housekeeping.Settings.GetInt(
			ctx, reaper.SettingAutoSweepMergedDays, 0)
		if err != nil {
			return nil, status.Errorf(codes.Internal, "read sweep setting: %v", err)
		}
		if configured <= 0 {
			return nil, status.Error(codes.FailedPrecondition,
				"auto_sweep_merged_days is disabled; set a value or pass days explicitly")
		}
		days = configured
	}
	stats, err := s.housekeeping.Reaper.SweepMergedBranches(
		ctx, time.Duration(days)*24*time.Hour)
	resp := &pb.RunSweepNowResponse{
		Considered: int32(stats.Considered),
		Deleted:    int32(stats.BranchesDeleted),
		Skipped:    int32(stats.BranchesSkipped),
	}
	if err != nil {
		return resp, status.Errorf(codes.Internal, "sweep: %v", err)
	}
	return resp, nil
}
