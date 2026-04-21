//go:build windows

// ArtifactServer exposes the NLAH file-backed state module (Phase A) over
// gRPC. List / Get read from the artifact SQL table via store.ArtifactStore;
// GetContent streams the on-disk file pointed to by the artifact row in
// fixed-size chunks so the UI never has to buffer large plans or diffs.

package ipc

import (
	"context"
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/types/known/timestamppb"

	pb "github.com/FleetKanban/fleetkanban/internal/ipc/gen/fleetkanban/v1"
	"github.com/FleetKanban/fleetkanban/internal/store"
)

// artifactContentChunkSize is the payload size for GetContent streaming.
// 64 KiB keeps each message well under the default gRPC message cap (4
// MiB) while still reaching ~1 GiB/s throughput on loopback.
const artifactContentChunkSize = 64 * 1024

// artifactListDefaultLimit caps unbounded List calls at a value the UI
// can paginate comfortably. Clients pass an explicit `limit` to get
// smaller result sets; 0 falls back to this cap.
const artifactListDefaultLimit = 500

// ArtifactServer implements pb.ArtifactServiceServer.
type ArtifactServer struct {
	pb.UnimplementedArtifactServiceServer

	store *store.ArtifactStore
}

// NewArtifactServer wraps an ArtifactStore into a gRPC server. The store
// is required; pass a non-nil value from main.go.
func NewArtifactServer(s *store.ArtifactStore) *ArtifactServer {
	return &ArtifactServer{store: s}
}

// List returns artifacts for a task, newest first. An empty stage filter
// returns every stage; a non-empty stage restricts to that stage only.
//
// Pagination: page_size caps each response at up to artifactListDefaultLimit;
// page_token is an opaque cursor returned by the server (currently a
// decimal offset, but clients must treat it as opaque). The legacy `limit`
// field is honoured for pre-pagination clients but only on the first page;
// when page_token is non-empty, limit is ignored in favour of page_size.
func (s *ArtifactServer) List(ctx context.Context, req *pb.ListArtifactsRequest) (*pb.ListArtifactsResponse, error) {
	if req == nil || req.TaskId == "" {
		return nil, status.Error(codes.InvalidArgument, "task_id required")
	}
	pageSize := int(req.PageSize)
	if pageSize <= 0 {
		// Legacy fallback: respect the old `limit` field when page_size is unset.
		pageSize = int(req.Limit)
	}
	if pageSize <= 0 || pageSize > artifactListDefaultLimit {
		pageSize = artifactListDefaultLimit
	}

	offset := 0
	if req.PageToken != "" {
		parsed, err := parseArtifactCursor(req.PageToken)
		if err != nil {
			return nil, status.Errorf(codes.InvalidArgument, "invalid page_token: %v", err)
		}
		offset = parsed
	}

	rows, nextOffset, err := s.store.ListPage(ctx, req.TaskId, req.Stage, offset, pageSize)
	if err != nil {
		return nil, status.Errorf(codes.Internal, "list artifacts: %v", err)
	}
	resp := &pb.ListArtifactsResponse{Artifacts: make([]*pb.Artifact, 0, len(rows))}
	for _, a := range rows {
		resp.Artifacts = append(resp.Artifacts, artifactToProto(a))
	}
	if nextOffset >= 0 {
		resp.NextPageToken = encodeArtifactCursor(nextOffset)
	}
	return resp, nil
}

// parseArtifactCursor decodes a page_token into an offset. The format is a
// simple decimal string wrapped in nothing — kept deliberately opaque to
// callers (docs say they must not interpret it) so we can migrate to a
// keyset cursor later without a proto bump.
func parseArtifactCursor(token string) (int, error) {
	var n int
	if _, err := fmt.Sscanf(token, "%d", &n); err != nil {
		return 0, err
	}
	if n < 0 {
		return 0, fmt.Errorf("negative offset")
	}
	return n, nil
}

func encodeArtifactCursor(offset int) string {
	return fmt.Sprintf("%d", offset)
}

// Get returns a single artifact row by ID.
func (s *ArtifactServer) Get(ctx context.Context, req *pb.GetArtifactRequest) (*pb.Artifact, error) {
	if req == nil || req.Id == "" {
		return nil, status.Error(codes.InvalidArgument, "id required")
	}
	a, err := s.store.Get(ctx, req.Id)
	if errors.Is(err, store.ErrArtifactNotFound) {
		return nil, status.Error(codes.NotFound, "artifact not found")
	}
	if err != nil {
		return nil, status.Errorf(codes.Internal, "get artifact: %v", err)
	}
	return artifactToProto(a), nil
}

// GetContent streams the on-disk file bytes for an artifact. The server
// resolves <task_run_root.root_path>/<artifact.path>, verifies the
// resolved path stays within root (defence in depth against stored
// relative paths that try to escape via ..), and streams the file in
// artifactContentChunkSize chunks. The final message has Eof=true and
// zero-length Data.
func (s *ArtifactServer) GetContent(req *pb.GetArtifactContentRequest, stream pb.ArtifactService_GetContentServer) error {
	if req == nil || req.Id == "" {
		return status.Error(codes.InvalidArgument, "id required")
	}
	ctx := stream.Context()

	a, err := s.store.Get(ctx, req.Id)
	if errors.Is(err, store.ErrArtifactNotFound) {
		return status.Error(codes.NotFound, "artifact not found")
	}
	if err != nil {
		return status.Errorf(codes.Internal, "get artifact: %v", err)
	}

	root, err := s.store.TaskRunRoot(ctx, a.TaskID)
	if err != nil {
		return status.Errorf(codes.Internal, "task_run_root: %v", err)
	}
	if root == "" {
		return status.Error(codes.FailedPrecondition, "task run directory not initialised")
	}

	abs, err := resolveArtifactPath(root, a.Path)
	if err != nil {
		return status.Errorf(codes.PermissionDenied, "artifact path: %v", err)
	}

	f, err := os.Open(abs)
	if errors.Is(err, os.ErrNotExist) {
		return status.Errorf(codes.NotFound, "artifact file missing: %s", a.Path)
	}
	if err != nil {
		return status.Errorf(codes.Internal, "open artifact: %v", err)
	}
	defer func() { _ = f.Close() }()

	buf := make([]byte, artifactContentChunkSize)
	for {
		if err := ctx.Err(); err != nil {
			return err
		}
		n, err := f.Read(buf)
		if n > 0 {
			if sendErr := stream.Send(&pb.ArtifactChunk{Data: buf[:n]}); sendErr != nil {
				return sendErr
			}
		}
		if errors.Is(err, io.EOF) {
			break
		}
		if err != nil {
			return status.Errorf(codes.Internal, "read artifact: %v", err)
		}
	}
	return stream.Send(&pb.ArtifactChunk{Eof: true})
}

// resolveArtifactPath joins root + rel and verifies the result stays
// within root. Relative paths use forward slashes on the wire; FromSlash
// normalises them to OS separators. Symlinks are not resolved — the
// sidecar has write-only control of the run tree.
func resolveArtifactPath(root, rel string) (string, error) {
	if strings.Contains(rel, "\x00") {
		return "", fmt.Errorf("null byte in path")
	}
	abs := filepath.Join(root, filepath.FromSlash(rel))
	absClean := filepath.Clean(abs)
	rootClean := filepath.Clean(root) + string(filepath.Separator)
	if !strings.HasPrefix(absClean+string(filepath.Separator), rootClean) && absClean+string(filepath.Separator) != rootClean {
		return "", fmt.Errorf("path escapes run root")
	}
	return absClean, nil
}

func artifactToProto(a store.Artifact) *pb.Artifact {
	return &pb.Artifact{
		Id:          a.ID,
		TaskId:      a.TaskID,
		SubtaskId:   a.SubtaskID,
		Stage:       a.Stage,
		Path:        a.Path,
		Kind:        a.Kind,
		ContentHash: a.ContentHash,
		SizeBytes:   a.SizeBytes,
		AttrsJson:   a.AttrsJSON,
		CreatedAt:   timestamppb.New(a.CreatedAt),
	}
}
