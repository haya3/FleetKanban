//go:build windows

package ipc

import (
	"context"
	"log/slog"
	"os"
	"path/filepath"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"google.golang.org/protobuf/types/known/emptypb"

	pb "github.com/haya3/fleetkanban/internal/ipc/gen/fleetkanban/v1"
	"github.com/haya3/fleetkanban/internal/store"
)

// openTestHarnessDB opens a fresh file-backed SQLite DB for harness tests.
func openTestHarnessDB(t *testing.T) *store.DB {
	t.Helper()
	path := filepath.Join(t.TempDir(), "harness_test.db")
	db, err := store.Open(t.Context(), store.Options{Path: path})
	require.NoError(t, err)
	t.Cleanup(func() { _ = db.Close() })
	return db
}

// newTestHarnessServer creates a HarnessServer backed by a temp DB and a temp
// skillRoot directory, seeded with a minimal valid SKILL.md.
func newTestHarnessServer(t *testing.T) (*HarnessServer, string) {
	t.Helper()
	db := openTestHarnessDB(t)
	skillRoot := t.TempDir()

	// Seed a minimal valid SKILL.md in the temp root.
	seed := validSkillMD()
	require.NoError(t, os.WriteFile(filepath.Join(skillRoot, "SKILL.md"), []byte(seed), 0o644))

	vs := store.NewHarnessSkillStore(db)
	srv := NewHarnessServer(vs, skillRoot, slog.Default(), nil)
	return srv, skillRoot
}

// validSkillMD returns a minimal SKILL.md that passes ValidateSkill.
func validSkillMD() string {
	return `---
harness_version: 1
stages: [plan, code, review]
max_rework_count: 2
transitions:
  - from: plan
    to: code
    when: "true"
  - from: code
    to: review
    when: "true"
  - from: review
    to: human_review
    when: "true"
---

# Test Harness
`
}

// ── TestValidateSkill_Missing_stages ────────────────────────────────────────

func TestValidateSkill_Missing_stages(t *testing.T) {
	srv, _ := newTestHarnessServer(t)
	ctx := context.Background()

	// Frontmatter that omits the required 'code' and 'review' stages.
	bad := `---
harness_version: 1
stages: [plan]
max_rework_count: 2
transitions: []
---
body
`
	resp, err := srv.ValidateSkill(ctx, &pb.ValidateSkillRequest{ContentMd: bad})
	require.NoError(t, err)
	assert.False(t, resp.Ok, "must not be OK when stages are missing")
	assert.NotEmpty(t, resp.Errors, "must return error messages")

	// Verify the errors mention the missing stage names.
	combined := ""
	for _, e := range resp.Errors {
		combined += e
	}
	assert.Contains(t, combined, "code")
	assert.Contains(t, combined, "review")
}

func TestValidateSkill_No_frontmatter(t *testing.T) {
	srv, _ := newTestHarnessServer(t)
	resp, err := srv.ValidateSkill(context.Background(), &pb.ValidateSkillRequest{
		ContentMd: "# No frontmatter at all\n",
	})
	require.NoError(t, err)
	assert.False(t, resp.Ok)
	assert.NotEmpty(t, resp.Errors)
}

func TestValidateSkill_Valid(t *testing.T) {
	srv, _ := newTestHarnessServer(t)
	resp, err := srv.ValidateSkill(context.Background(), &pb.ValidateSkillRequest{
		ContentMd: validSkillMD(),
	})
	require.NoError(t, err)
	assert.True(t, resp.Ok, "valid charter must pass")
	assert.Empty(t, resp.Errors)
}

// ── TestUpdateSkill_Roundtrip ────────────────────────────────────────────────

// TestUpdateSkill_Roundtrip calls UpdateSkill then GetActiveSkill and verifies
// the returned content matches the written content.
func TestUpdateSkill_Roundtrip(t *testing.T) {
	srv, skillRoot := newTestHarnessServer(t)
	ctx := context.Background()

	content := validSkillMD() + "\n## Extra section\nAdded.\n"

	skill, err := srv.UpdateSkill(ctx, &pb.UpdateSkillRequest{ContentMd: content})
	require.NoError(t, err)
	assert.NotEmpty(t, skill.ArtifactId)
	assert.Equal(t, int32(1), skill.Version)
	assert.Equal(t, content, skill.ContentMd)
	assert.NotEmpty(t, skill.ContentHash)

	// GetActiveSkill must return the same artifact.
	active, err := srv.GetActiveSkill(ctx, &emptypb.Empty{})
	require.NoError(t, err)
	assert.Equal(t, skill.ArtifactId, active.ArtifactId)
	assert.Equal(t, content, active.ContentMd)

	// SKILL.md must have been overwritten.
	raw, err := os.ReadFile(filepath.Join(skillRoot, "SKILL.md"))
	require.NoError(t, err)
	assert.Equal(t, content, string(raw))
}

// ── TestRollbackSkill ────────────────────────────────────────────────────────

// TestRollbackSkill writes two versions then rolls back to the first, verifying
// that GetActiveSkill returns the original content as the new (version 3) artifact.
func TestRollbackSkill(t *testing.T) {
	srv, _ := newTestHarnessServer(t)
	ctx := context.Background()

	v1Content := validSkillMD() + "\n## V1\n"
	v2Content := validSkillMD() + "\n## V2\n"

	first, err := srv.UpdateSkill(ctx, &pb.UpdateSkillRequest{ContentMd: v1Content})
	require.NoError(t, err)
	assert.Equal(t, int32(1), first.Version)

	second, err := srv.UpdateSkill(ctx, &pb.UpdateSkillRequest{ContentMd: v2Content})
	require.NoError(t, err)
	assert.Equal(t, int32(2), second.Version)

	// Rollback to v1.
	rolled, err := srv.RollbackSkill(ctx, &pb.RollbackSkillRequest{ArtifactId: first.ArtifactId})
	require.NoError(t, err)
	// A new version row must be created (version 3).
	assert.Equal(t, int32(3), rolled.Version)
	assert.NotEqual(t, first.ArtifactId, rolled.ArtifactId, "rollback must mint a new artifact_id")

	// GetActiveSkill must return the rolled-back content.
	active, err := srv.GetActiveSkill(ctx, &emptypb.Empty{})
	require.NoError(t, err)
	assert.Equal(t, v1Content, active.ContentMd, "active content must match the rolled-back version")

	// ListSkillVersions must return 3 entries.
	list, err := srv.ListSkillVersions(ctx, &emptypb.Empty{})
	require.NoError(t, err)
	assert.Len(t, list.Versions, 3)
	// Content should be empty in list responses.
	for _, v := range list.Versions {
		assert.Empty(t, v.ContentMd, "list response must not include content_md")
	}
}

// ── TestGetActiveSkill_NoVersions ────────────────────────────────────────────

// TestGetActiveSkill_NoVersions verifies that GetActiveSkill returns a synthetic
// response (artifact_id="") when no versions have been written yet.
func TestGetActiveSkill_NoVersions(t *testing.T) {
	srv, _ := newTestHarnessServer(t)
	active, err := srv.GetActiveSkill(context.Background(), &emptypb.Empty{})
	require.NoError(t, err)
	assert.Equal(t, "", active.ArtifactId, "no versions → artifact_id must be empty")
	assert.NotEmpty(t, active.ContentMd, "must return file content from SKILL.md")
}

// ── TestRollbackSkill_NotFound ───────────────────────────────────────────────

func TestRollbackSkill_NotFound(t *testing.T) {
	srv, _ := newTestHarnessServer(t)
	_, err := srv.RollbackSkill(context.Background(), &pb.RollbackSkillRequest{
		ArtifactId: "01NONEXISTENT0000000000000",
	})
	require.Error(t, err)
	assert.Contains(t, err.Error(), "not found")
}
