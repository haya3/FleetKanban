//go:build windows

// HarnessServer implements HarnessService gRPC (Phase B).
//
// # storage model (v16)
//
// Versions are stored in the harness_skill_version table via HarnessSkillStore.
// The previous Phase B model wrote artifact rows (stage='harness') and satisfied
// the artifact.task_id FK by injecting "__harness__" sentinel rows into the
// tasks and repositories tables. That sentinel approach was fragile: future
// migrations adding NOT NULL columns would break the INSERT OR IGNORE logic,
// and sentinel rows could leak into UI task-list queries.
//
// The new model stores content directly as TEXT in harness_skill_version with
// no FK dependency on tasks or repositories. The sentinel injection code
// (ensureHarnessPseudoTask, HarnessPseudoTaskID, pseudoOnce) has been removed.
package ipc

import (
	"context"
	"crypto/sha256"
	"errors"
	"fmt"
	"log/slog"
	"os"
	"path/filepath"
	"strings"
	"sync"

	"github.com/oklog/ulid/v2"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/types/known/emptypb"
	"google.golang.org/protobuf/types/known/timestamppb"

	"github.com/FleetKanban/fleetkanban/internal/ihr"
	pb "github.com/FleetKanban/fleetkanban/internal/ipc/gen/fleetkanban/v1"
	"github.com/FleetKanban/fleetkanban/internal/store"
)

// HarnessServer implements pb.HarnessServiceServer.
type HarnessServer struct {
	pb.UnimplementedHarnessServiceServer

	versions  *store.HarnessSkillStore
	skillRoot string // directory containing SKILL.md, e.g. <DataDir>/harness-skill/
	log       *slog.Logger

	// writeMu serialises every mutator path (UpdateSkill, RollbackSkill,
	// ApplyEvolverPatch). ApplyEvolverPatch reads SKILL.md from disk,
	// applies a patch, then calls updateSkill to persist the result —
	// a sequence with three FS/DB round-trips. Without the mutex a
	// concurrent UpdateSkill landing between those steps would either
	// see a stale base content (wrong patch target) or overwrite the
	// evolver's commit on the next write. Read paths (GetActiveSkill /
	// ListSkillVersions) do NOT acquire the mutex — they pull directly
	// from the DB/FS and are naturally consistent for a single query.
	writeMu sync.Mutex

	// onCharterUpdate is called after a successful UpdateSkill / RollbackSkill
	// with the re-parsed charter so live subscribers (orchestrator) can swap
	// their cached copy without a restart. nil is valid — in that case edits
	// land on disk but the running orchestrator keeps using the pre-edit
	// charter until the next sidecar start (pre-hot-reload behaviour).
	onCharterUpdate func(*ihr.Charter)
}

// NewHarnessServer constructs a HarnessServer backed by the dedicated
// harness_skill_version store. skillRoot is the directory holding SKILL.md.
// onCharterUpdate, when non-nil, is invoked after every successful
// UpdateSkill / RollbackSkill with the freshly parsed charter so the
// orchestrator can hot-reload runtime policy without a restart.
func NewHarnessServer(
	versions *store.HarnessSkillStore,
	skillRoot string,
	log *slog.Logger,
	onCharterUpdate func(*ihr.Charter),
) *HarnessServer {
	return &HarnessServer{
		versions:        versions,
		skillRoot:       skillRoot,
		log:             log,
		onCharterUpdate: onCharterUpdate,
	}
}

// ── GetActiveSkill ───────────────────────────────────────────────────────────

// GetActiveSkill returns the latest persisted version, or a synthetic
// HarnessSkill with artifact_id="" when no version has been saved yet
// (fallback: reads SKILL.md directly from disk).
func (s *HarnessServer) GetActiveSkill(ctx context.Context, _ *emptypb.Empty) (*pb.HarnessSkill, error) {
	latest, err := s.versions.Latest(ctx)
	if err == store.ErrNoSkillVersion {
		// No persisted version: read the live file and return without an artifact_id.
		content, hash, ferr := s.readSkillFile()
		if ferr != nil {
			return nil, status.Errorf(codes.Internal, "read SKILL.md: %v", ferr)
		}
		return &pb.HarnessSkill{
			ArtifactId:  "",
			Version:     0,
			ContentMd:   content,
			ContentHash: hash,
			CreatedAt:   timestamppb.Now(),
		}, nil
	}
	if err != nil {
		return nil, status.Errorf(codes.Internal, "latest skill version: %v", err)
	}

	ver, err := s.countVersions(ctx)
	if err != nil {
		ver = 1
	}

	return skillVersionToProto(latest, int32(ver)), nil
}

// ── ListSkillVersions ────────────────────────────────────────────────────────

// ListSkillVersions returns all stored versions newest-first (up to 100).
// content_md is intentionally omitted (empty string) — callers use
// GetActiveSkill or a future GetSkillVersion RPC for full content.
func (s *HarnessServer) ListSkillVersions(ctx context.Context, _ *emptypb.Empty) (*pb.ListSkillVersionsResponse, error) {
	rows, err := s.versions.List(ctx, 100)
	if err != nil {
		return nil, status.Errorf(codes.Internal, "list skill versions: %v", err)
	}
	total := len(rows)
	skills := make([]*pb.HarnessSkill, 0, total)
	for i, v := range rows {
		// Version numbers: newest = total, oldest = 1.
		ver := int32(total - i)
		// content_md omitted for list responses to reduce traffic.
		stripped := v
		stripped.ContentMD = ""
		skills = append(skills, skillVersionToProto(stripped, ver))
	}
	return &pb.ListSkillVersionsResponse{Versions: skills}, nil
}

// ── ValidateSkill ────────────────────────────────────────────────────────────

// ValidateSkill performs a lightweight structural lint of the proposed content.
// It extracts the YAML frontmatter and checks:
//   - stages contains plan, code, and review
//   - max_rework_count > 0
//   - each transition from/to is in stages ∪ {human_review, failed}
func (s *HarnessServer) ValidateSkill(_ context.Context, req *pb.ValidateSkillRequest) (*pb.ValidateSkillResponse, error) {
	if req == nil {
		return nil, status.Error(codes.InvalidArgument, "request required")
	}
	errs, warns := validateCharter(req.ContentMd)
	return &pb.ValidateSkillResponse{
		Ok:       len(errs) == 0,
		Errors:   errs,
		Warnings: warns,
	}, nil
}

// validateCharter is the pure validation logic, separated for testability.
// It delegates to ihr.ParseCharter so that this function and the runtime
// parser can never diverge: if ValidateSkill / UpdateSkill accept content
// here, ihr.ParseCharter on the same bytes during hot-reload will also
// succeed. A prior hand-rolled frontmatter parser lived here and had
// drifted (different BOM / required-field coverage), which let
// ValidateSkill pass a charter that the runtime then rejected silently
// inside updateSkill's hot-reload block.
func validateCharter(contentMd string) (errs []string, warns []string) {
	c, err := ihr.ParseCharter([]byte(contentMd))
	if err != nil {
		// ParseCharter returns its semantic errors wrapped in ValidationError;
		// unwrap so the UI sees one bullet per item rather than one combined string.
		var ve *ihr.ValidationError
		if errors.As(err, &ve) {
			return append([]string(nil), ve.Errors...), append([]string(nil), ve.Warnings...)
		}
		return []string{err.Error()}, nil
	}

	// Parsed successfully — surface any warnings the parser collected
	// (e.g. missing prompts, missing failure_taxonomy entries for a class
	// the orchestrator emits).
	if ve := c.Validate(); ve != nil {
		warns = append(warns, ve.Warnings...)
	}

	if len(c.Transitions) == 0 {
		warns = append(warns, "no transitions defined")
	}

	return errs, warns
}

// ── UpdateSkill ──────────────────────────────────────────────────────────────

// UpdateSkill validates, persists, and activates a new harness charter.
// Steps:
//  1. Validate content; return FailedPrecondition on errors.
//  2. Compute SHA-256 hash.
//  3. Insert into harness_skill_version (no-op if duplicate hash).
//  4. Overwrite skillRoot/SKILL.md atomically so IHR picks up the new version.
//  5. Hot-reload: notify onCharterUpdate subscriber (orchestrator).
func (s *HarnessServer) UpdateSkill(ctx context.Context, req *pb.UpdateSkillRequest) (*pb.HarnessSkill, error) {
	s.writeMu.Lock()
	defer s.writeMu.Unlock()
	return s.updateSkill(ctx, req.ContentMd, "user", "")
}

// updateSkill is the shared implementation used by UpdateSkill and RollbackSkill.
// createdBy is the provenance string; parentID is the source version for rollbacks.
func (s *HarnessServer) updateSkill(ctx context.Context, contentMD, createdBy, parentID string) (*pb.HarnessSkill, error) {
	if contentMD == "" {
		return nil, status.Error(codes.InvalidArgument, "content_md required")
	}

	// 1. Parse + validate in one step. Authoritative parse: if this
	//    succeeds, hot-reload cannot fail on the same bytes later. This
	//    removes the earlier validate→write→re-parse window where a
	//    hand-rolled validator would pass content that ihr.ParseCharter
	//    would then silently reject — leaving DB / disk updated but the
	//    orchestrator still on the old charter.
	charter, perr := ihr.ParseCharter([]byte(contentMD))
	if perr != nil {
		var ve *ihr.ValidationError
		if errors.As(perr, &ve) && len(ve.Errors) > 0 {
			return nil, status.Errorf(codes.FailedPrecondition, "skill validation failed: %s", strings.Join(ve.Errors, "; "))
		}
		return nil, status.Errorf(codes.FailedPrecondition, "skill parse failed: %v", perr)
	}

	// 2. Compute hash and mint ID.
	hash := contentHash(contentMD)
	id := ulid.Make().String()

	// 3. Insert into store (no-op if identical hash already exists).
	resolvedID, inserted, err := s.versions.Insert(ctx, store.HarnessSkillVersion{
		ID:          id,
		ContentMD:   contentMD,
		ContentHash: hash,
		CreatedBy:   createdBy,
		ParentID:    parentID,
	})
	if err != nil {
		return nil, status.Errorf(codes.Internal, "insert skill version: %v", err)
	}
	if !inserted {
		// Content was already stored; use the existing row's ID.
		id = resolvedID
	}

	// 4. Overwrite SKILL.md atomically.
	skillMd := filepath.Join(s.skillRoot, "SKILL.md")
	if err := atomicWrite(skillMd, []byte(contentMD)); err != nil {
		s.log.Warn("harness: wrote version but failed to update SKILL.md", "err", err)
		// Non-fatal: the versioned row is persisted; SKILL.md is best-effort.
	}

	// 5. Hot-reload: publish the already-parsed charter to subscribers.
	//    No re-parse here: the charter from step 1 is the same bytes as
	//    the content we just stored and wrote, so publishing it directly
	//    cannot diverge from what the DB / disk now hold.
	if s.onCharterUpdate != nil {
		s.onCharterUpdate(charter)
	}

	ver, err := s.countVersions(ctx)
	if err != nil {
		ver = 1
	}

	v, err := s.versions.Get(ctx, id)
	if err != nil {
		// Fallback: construct from what we know.
		return &pb.HarnessSkill{
			ArtifactId:  id,
			Version:     int32(ver),
			ContentMd:   contentMD,
			ContentHash: hash,
			CreatedAt:   timestamppb.Now(),
		}, nil
	}
	return skillVersionToProto(v, int32(ver)), nil
}

// ApplyEvolverPatch reads the current SKILL.md, applies the given unified
// diff via ihr.ApplyPatch (50-line cap, strict context matching), validates
// the post-patch content against the charter schema, and commits it as a
// new version with provenance "evolver:<attempt_id>". Intended for the
// HarnessAttemptService.Approve path: wraps patch application and version
// publication in one transaction-shaped call so the attempt server does not
// need to know about the charter store internals.
//
// Errors:
//   - InvalidArgument: attemptID or patch empty
//   - FailedPrecondition: patch fails to apply (stale context, touches >50
//     lines, malformed header) or produces content that fails validation
//   - Internal: filesystem / store errors
func (s *HarnessServer) ApplyEvolverPatch(ctx context.Context, attemptID, patch string) (*pb.HarnessSkill, error) {
	if attemptID == "" || patch == "" {
		return nil, status.Error(codes.InvalidArgument, "attemptID and patch required")
	}

	// writeMu covers the read-apply-updateSkill sequence so a concurrent
	// UpdateSkill cannot slip in between readSkillFile and updateSkill
	// and cause the patch to land on a stale base (or clobber a fresh
	// user edit on the updateSkill write).
	s.writeMu.Lock()
	defer s.writeMu.Unlock()

	current, _, err := s.readSkillFile()
	if err != nil {
		return nil, status.Errorf(codes.Internal, "read SKILL.md: %v", err)
	}

	next, err := ihr.ApplyPatch([]byte(current), patch)
	if err != nil {
		return nil, status.Errorf(codes.FailedPrecondition, "apply patch: %v", err)
	}

	createdBy := fmt.Sprintf("evolver:%s", attemptID)
	return s.updateSkill(ctx, string(next), createdBy, "")
}

// ── RollbackSkill ────────────────────────────────────────────────────────────

// RollbackSkill re-applies a prior version's content as a new version.
// The historical row is never mutated — a fresh row is inserted, preserving
// an immutable audit trail. created_by is set to "rollback:<source_id>" and
// parent_id points to the source row.
func (s *HarnessServer) RollbackSkill(ctx context.Context, req *pb.RollbackSkillRequest) (*pb.HarnessSkill, error) {
	if req == nil || req.ArtifactId == "" {
		return nil, status.Error(codes.InvalidArgument, "artifact_id required")
	}

	s.writeMu.Lock()
	defer s.writeMu.Unlock()

	// Look up the target version.
	target, err := s.versions.Get(ctx, req.ArtifactId)
	if err == store.ErrNoSkillVersion {
		return nil, status.Errorf(codes.NotFound, "skill version %s not found", req.ArtifactId)
	}
	if err != nil {
		return nil, status.Errorf(codes.Internal, "get skill version: %v", err)
	}

	// content_md may be empty for rows migrated from the old artifact model
	// (v16 migration sets content_md='' as a placeholder). In that case we
	// fall back to the live SKILL.md so the rollback still produces a valid row.
	content := target.ContentMD
	if content == "" {
		content, _, err = s.readSkillFile()
		if err != nil {
			return nil, status.Errorf(codes.Internal, "rollback: read fallback SKILL.md: %v", err)
		}
	}

	createdBy := fmt.Sprintf("rollback:%s", req.ArtifactId)
	return s.updateSkill(ctx, content, createdBy, req.ArtifactId)
}

// ── helpers ──────────────────────────────────────────────────────────────────

// countVersions returns the total number of stored versions.
func (s *HarnessServer) countVersions(ctx context.Context) (int, error) {
	rows, err := s.versions.List(ctx, 0)
	if err != nil {
		return 0, err
	}
	return len(rows), nil
}

// readSkillFile reads skillRoot/SKILL.md and returns (content, sha256hex, error).
func (s *HarnessServer) readSkillFile() (string, string, error) {
	p := filepath.Join(s.skillRoot, "SKILL.md")
	b, err := os.ReadFile(p)
	if err != nil {
		return "", "", err
	}
	content := string(b)
	return content, contentHash(content), nil
}

// skillVersionToProto converts a HarnessSkillVersion to *pb.HarnessSkill.
// ArtifactId is mapped from the version ID to keep the proto contract stable.
func skillVersionToProto(v store.HarnessSkillVersion, version int32) *pb.HarnessSkill {
	return &pb.HarnessSkill{
		ArtifactId:  v.ID,
		Version:     version,
		ContentMd:   v.ContentMD,
		ContentHash: v.ContentHash,
		CreatedAt:   timestamppb.New(v.CreatedAt),
	}
}

// contentHash returns the hex-encoded SHA-256 of s.
func contentHash(s string) string {
	sum := sha256.Sum256([]byte(s))
	return fmt.Sprintf("%x", sum)
}

// atomicWrite writes data to path using a temp file + rename for atomicity.
// Parent directories are created as needed.
func atomicWrite(path string, data []byte) error {
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return fmt.Errorf("mkdir: %w", err)
	}
	tmp := path + ".tmp"
	if err := os.WriteFile(tmp, data, 0o644); err != nil {
		return fmt.Errorf("write tmp: %w", err)
	}
	if err := os.Rename(tmp, path); err != nil {
		_ = os.Remove(tmp)
		return fmt.Errorf("rename: %w", err)
	}
	return nil
}
