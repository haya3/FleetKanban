//go:build windows

// HarnessAttemptServer implements HarnessAttemptService gRPC (Phase C).
//
// This server provides structured recording of REWORK occurrences from
// the orchestrator, and exposes approve/reject decision endpoints for the UI.
//
// Phase C scope: record + decide only. LLM-driven patch generation and
// SKILL.md application are intentionally absent here and deferred to the
// Phase C LLM integration step.

package ipc

import (
	"context"
	"errors"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/types/known/emptypb"
	"google.golang.org/protobuf/types/known/timestamppb"

	pb "github.com/FleetKanban/fleetkanban/internal/ipc/gen/fleetkanban/v1"
	"github.com/FleetKanban/fleetkanban/internal/store"
)

// SkillPatchApplier is the subset of HarnessServer the Approve path uses
// to promote an evolver-generated patch into a new SKILL.md version.
// Declared as an interface so the harness_attempt_server tests can stub it
// without pulling the full HarnessServer + filesystem wiring.
type SkillPatchApplier interface {
	ApplyEvolverPatch(ctx context.Context, attemptID, patch string) (*pb.HarnessSkill, error)
}

// HarnessAttemptServer implements pb.HarnessAttemptServiceServer.
type HarnessAttemptServer struct {
	pb.UnimplementedHarnessAttemptServiceServer

	store   *store.HarnessAttemptStore
	applier SkillPatchApplier // nil is valid — Approve then records decision only
}

// NewHarnessAttemptServer constructs a HarnessAttemptServer backed by s.
// applier, when non-nil, is invoked during Approve to apply the
// proposed_patch against SKILL.md before the decision flip. When nil
// (Phase C pre-LLM) Approve only records the user's accept marker and
// the user is expected to edit SKILL.md manually through HarnessService.
func NewHarnessAttemptServer(s *store.HarnessAttemptStore, applier SkillPatchApplier) *HarnessAttemptServer {
	return &HarnessAttemptServer{store: s, applier: applier}
}

// ListPending returns all harness attempts with decision='pending', newest first.
// Returns up to 100 rows (sufficient for the current Phase C UI surface).
func (srv *HarnessAttemptServer) ListPending(ctx context.Context, _ *emptypb.Empty) (*pb.ListHarnessAttemptsResponse, error) {
	rows, err := srv.store.ListPending(ctx, 100)
	if err != nil {
		return nil, status.Errorf(codes.Internal, "list pending harness attempts: %v", err)
	}
	return &pb.ListHarnessAttemptsResponse{Attempts: attemptsToProto(rows)}, nil
}

// ListForTask returns all harness attempts for a task, newest first.
// Returns up to 100 rows.
func (srv *HarnessAttemptServer) ListForTask(ctx context.Context, req *pb.ListHarnessAttemptsForTaskRequest) (*pb.ListHarnessAttemptsResponse, error) {
	if req == nil || req.TaskId == "" {
		return nil, status.Error(codes.InvalidArgument, "task_id is required")
	}
	rows, err := srv.store.ListForTask(ctx, req.TaskId, 100)
	if err != nil {
		return nil, status.Errorf(codes.Internal, "list harness attempts for task: %v", err)
	}
	return &pb.ListHarnessAttemptsResponse{Attempts: attemptsToProto(rows)}, nil
}

// Approve records an 'approved' decision for a pending harness attempt.
// When the attempt carries a non-empty proposed_patch AND the server was
// constructed with a SkillPatchApplier, the patch is applied against the
// current SKILL.md (producing a new harness_skill_version row with
// provenance "evolver:<attemptID>") BEFORE the decision flip. This
// ordering ensures a rejected patch (stale context, validation failure)
// leaves the attempt as pending so the user can edit manually and retry
// instead of being stranded in an approved-but-not-applied state.
//
// Patch application failures surface as FailedPrecondition so the UI
// can show a readable error and let the user either fix the patch
// manually (via HarnessService.UpdateSkill) or Reject the attempt.
func (srv *HarnessAttemptServer) Approve(ctx context.Context, req *pb.ApproveHarnessAttemptRequest) (*pb.HarnessAttempt, error) {
	if req == nil || req.Id == "" {
		return nil, status.Error(codes.InvalidArgument, "id is required")
	}

	// Peek at the attempt to decide whether patch application is needed.
	// We do not short-circuit to UpdateDecision early because a patch-apply
	// failure must leave the attempt pending.
	attempt, err := srv.store.Get(ctx, req.Id)
	if err != nil {
		return nil, mapAttemptError(err, req.Id)
	}
	if attempt.Decision != "pending" {
		return nil, status.Errorf(codes.FailedPrecondition,
			"harness attempt %s is already decided (%s)", req.Id, attempt.Decision)
	}

	if srv.applier != nil && attempt.ProposedPatch != "" {
		if _, aerr := srv.applier.ApplyEvolverPatch(ctx, attempt.ID, attempt.ProposedPatch); aerr != nil {
			// Bubble the applier's gRPC status through unchanged so the UI
			// keeps the failure category. The attempt stays pending.
			return nil, aerr
		}
	}

	updated, err := srv.store.UpdateDecision(ctx, req.Id, "approved", req.DecidedBy)
	if err != nil {
		return nil, mapAttemptError(err, req.Id)
	}
	return attemptToProto(updated), nil
}

// Reject records a 'rejected' decision for a pending harness attempt.
func (srv *HarnessAttemptServer) Reject(ctx context.Context, req *pb.RejectHarnessAttemptRequest) (*pb.HarnessAttempt, error) {
	if req == nil || req.Id == "" {
		return nil, status.Error(codes.InvalidArgument, "id is required")
	}
	updated, err := srv.store.UpdateDecision(ctx, req.Id, "rejected", req.DecidedBy)
	if err != nil {
		return nil, mapAttemptError(err, req.Id)
	}
	return attemptToProto(updated), nil
}

// ── helpers ──────────────────────────────────────────────────────────────────

func mapAttemptError(err error, id string) error {
	if errors.Is(err, store.ErrHarnessAttemptNotFound) {
		return status.Errorf(codes.NotFound, "harness attempt %s not found", id)
	}
	if errors.Is(err, store.ErrAlreadyDecided) {
		return status.Errorf(codes.FailedPrecondition, "harness attempt %s is already decided", id)
	}
	return status.Errorf(codes.Internal, "update decision: %v", err)
}

func attemptsToProto(rows []store.HarnessAttempt) []*pb.HarnessAttempt {
	out := make([]*pb.HarnessAttempt, 0, len(rows))
	for _, r := range rows {
		out = append(out, attemptToProto(r))
	}
	return out
}

func attemptToProto(a store.HarnessAttempt) *pb.HarnessAttempt {
	p := &pb.HarnessAttempt{
		Id:            a.ID,
		TaskId:        a.TaskID,
		ReworkRound:   a.ReworkRound,
		FailureClass:  a.FailureClass,
		ObservationMd: a.ObservationMD,
		ProposedPatch: a.ProposedPatch,
		ProposedHash:  a.ProposedHash,
		Decision:      a.Decision,
		DecidedBy:     a.DecidedBy,
		CreatedAt:     timestamppb.New(a.CreatedAt),
	}
	if a.DecidedAt != nil {
		p.DecidedAt = timestamppb.New(*a.DecidedAt)
	}
	return p
}
