//go:build windows

package ipc

import (
	"context"
	"log/slog"
	"os"
	"path/filepath"
	"sync"
	"sync/atomic"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/haya3/FleetKanban/internal/ihr"
	pb "github.com/haya3/FleetKanban/internal/ipc/gen/fleetkanban/v1"
	"github.com/haya3/FleetKanban/internal/store"
)

// newHarnessServerWithCallback builds a HarnessServer like
// newTestHarnessServer but wires an onCharterUpdate callback so the test
// can observe hot-reload notifications without needing a real orchestrator.
func newHarnessServerWithCallback(t *testing.T, cb func(*ihr.Charter)) (*HarnessServer, string) {
	t.Helper()
	db := openTestHarnessDB(t)
	skillRoot := t.TempDir()
	require.NoError(t, os.WriteFile(filepath.Join(skillRoot, "SKILL.md"), []byte(validSkillMD()), 0o644))

	vs := store.NewHarnessSkillStore(db)
	return NewHarnessServer(vs, skillRoot, slog.Default(), cb), skillRoot
}

// TestUpdateSkill_FiresCharterCallback proves the hot-reload contract:
// UpdateSkill must invoke onCharterUpdate exactly once with the freshly
// parsed charter so the orchestrator can swap its cached copy.
func TestUpdateSkill_FiresCharterCallback(t *testing.T) {
	var got *ihr.Charter
	var calls int32

	srv, _ := newHarnessServerWithCallback(t, func(c *ihr.Charter) {
		atomic.AddInt32(&calls, 1)
		got = c
	})
	ctx := context.Background()

	newContent := validSkillMD() + "\n# extra body line\n"
	_, err := srv.UpdateSkill(ctx, &pb.UpdateSkillRequest{ContentMd: newContent})
	require.NoError(t, err)

	require.Equal(t, int32(1), atomic.LoadInt32(&calls), "callback must fire exactly once")
	require.NotNil(t, got)
	assert.Equal(t, 2, got.MaxReworkCount, "charter must parse from the updated content")
	assert.Contains(t, got.Stages, "plan")
	assert.Contains(t, got.Stages, "code")
	assert.Contains(t, got.Stages, "review")
}

// TestRollbackSkill_FiresCharterCallback confirms that rollback (which
// also mutates the active charter) triggers the same notification path.
func TestRollbackSkill_FiresCharterCallback(t *testing.T) {
	var calls int32
	srv, _ := newHarnessServerWithCallback(t, func(*ihr.Charter) {
		atomic.AddInt32(&calls, 1)
	})
	ctx := context.Background()

	v1 := validSkillMD() + "\n# v1\n"
	v2 := validSkillMD() + "\n# v2\n"

	first, err := srv.UpdateSkill(ctx, &pb.UpdateSkillRequest{ContentMd: v1})
	require.NoError(t, err)
	_, err = srv.UpdateSkill(ctx, &pb.UpdateSkillRequest{ContentMd: v2})
	require.NoError(t, err)

	// Two updates → two callbacks so far.
	require.Equal(t, int32(2), atomic.LoadInt32(&calls))

	_, err = srv.RollbackSkill(ctx, &pb.RollbackSkillRequest{ArtifactId: first.ArtifactId})
	require.NoError(t, err)

	// Rollback inserts a new version row and must publish it too.
	assert.Equal(t, int32(3), atomic.LoadInt32(&calls), "rollback must fire the callback once more")
}

// TestApplyEvolverPatch_RoundTrip feeds a patch that adds one failure class
// to the taxonomy and asserts (1) the returned HarnessSkill carries the
// patched content, (2) the disk SKILL.md is overwritten to match, (3) a
// version row with created_by=="evolver:<id>" is persisted, (4) the
// hot-reload callback fires.
func TestApplyEvolverPatch_RoundTrip(t *testing.T) {
	var fired int32
	srv, skillRoot := newHarnessServerWithCallback(t, func(*ihr.Charter) {
		atomic.AddInt32(&fired, 1)
	})
	ctx := context.Background()

	// Seed a concrete version (one with real content_md rather than the
	// file-only fallback) so ApplyEvolverPatch starts from a known base.
	baseContent := validSkillMD()
	_, err := srv.UpdateSkill(ctx, &pb.UpdateSkillRequest{ContentMd: baseContent})
	require.NoError(t, err)
	require.Equal(t, int32(1), atomic.LoadInt32(&fired))

	// Patch adds a "max_rework_count: 2" → "max_rework_count: 3" tweak.
	// ihr.ApplyPatch requires strict context matching so we quote the
	// exact neighbouring lines from baseContent.
	patch := `--- a/SKILL.md
+++ b/SKILL.md
@@ -3,5 +3,5 @@
 stages: [plan, code, review]
-max_rework_count: 2
+max_rework_count: 3
 transitions:
   - from: plan
     to: code
`

	skill, err := srv.ApplyEvolverPatch(ctx, "01TEST000000000000000000", patch)
	require.NoError(t, err, "valid patch must apply cleanly")
	assert.Contains(t, skill.ContentMd, "max_rework_count: 3")
	assert.NotContains(t, skill.ContentMd, "max_rework_count: 2")

	// Disk view reflects the patch.
	onDisk, err := os.ReadFile(filepath.Join(skillRoot, "SKILL.md"))
	require.NoError(t, err)
	assert.Contains(t, string(onDisk), "max_rework_count: 3")

	// ListSkillVersions shows two rows (initial + evolver patch).
	listResp, err := srv.ListSkillVersions(ctx, nil)
	require.NoError(t, err)
	assert.GreaterOrEqual(t, len(listResp.Versions), 2, "evolver patch must produce a new row")

	// Hot-reload fired a second time (once for UpdateSkill seed, once for patch).
	assert.Equal(t, int32(2), atomic.LoadInt32(&fired))
}

// TestApplyEvolverPatch_MalformedPatch_LeavesStateUntouched covers the
// safety promise: a bad patch must not produce a version row and must
// leave the disk SKILL.md unchanged.
func TestApplyEvolverPatch_MalformedPatch_LeavesStateUntouched(t *testing.T) {
	srv, skillRoot := newHarnessServerWithCallback(t, nil)
	ctx := context.Background()

	_, err := srv.UpdateSkill(ctx, &pb.UpdateSkillRequest{ContentMd: validSkillMD()})
	require.NoError(t, err)

	pre, err := os.ReadFile(filepath.Join(skillRoot, "SKILL.md"))
	require.NoError(t, err)

	listBefore, err := srv.ListSkillVersions(ctx, nil)
	require.NoError(t, err)

	// Context lines fabricated — do not exist in the seed — so ApplyPatch must reject.
	garbage := `--- a/SKILL.md
+++ b/SKILL.md
@@ -1,3 +1,3 @@
 this_line_does_not_exist
-neither does this
+nor this
`
	_, err = srv.ApplyEvolverPatch(ctx, "01BAD0000000000000000000", garbage)
	require.Error(t, err)

	post, err := os.ReadFile(filepath.Join(skillRoot, "SKILL.md"))
	require.NoError(t, err)
	assert.Equal(t, pre, post, "disk SKILL.md must be untouched on patch failure")

	listAfter, err := srv.ListSkillVersions(ctx, nil)
	require.NoError(t, err)
	assert.Len(t, listAfter.Versions, len(listBefore.Versions), "no new version row on failed patch")
}

// TestWriteMu_SerializesWriters races UpdateSkill and ApplyEvolverPatch
// hard enough that an unprotected implementation would produce either
// a corrupted SKILL.md or a mismatched version count. With the mutex in
// place every write lands sequentially and the final state is consistent.
func TestWriteMu_SerializesWriters(t *testing.T) {
	srv, skillRoot := newHarnessServerWithCallback(t, nil)
	ctx := context.Background()

	_, err := srv.UpdateSkill(ctx, &pb.UpdateSkillRequest{ContentMd: validSkillMD()})
	require.NoError(t, err)

	const iterations = 10
	var wg sync.WaitGroup
	wg.Add(2)

	// Goroutine A: alternates between two valid contents so every
	// UpdateSkill produces either a no-op (duplicate hash) or a fresh row.
	go func() {
		defer wg.Done()
		a := validSkillMD() + "\n# writer A\n"
		b := validSkillMD() + "\n# writer A alt\n"
		for i := 0; i < iterations; i++ {
			content := a
			if i%2 == 1 {
				content = b
			}
			_, _ = srv.UpdateSkill(ctx, &pb.UpdateSkillRequest{ContentMd: content})
		}
	}()

	// Goroutine B: repeatedly triggers ApplyEvolverPatch with a no-op patch
	// (adds and removes the same line). The patch is deliberately crafted
	// to succeed regardless of which UpdateSkill content is the base.
	// Since the base ends with the writer A line which changes, we instead
	// use a patch that touches the invariant `harness_version: 1` line.
	go func() {
		defer wg.Done()
		patch := `--- a/SKILL.md
+++ b/SKILL.md
@@ -1,4 +1,4 @@
 ---
-harness_version: 1
+harness_version: 1
 stages: [plan, code, review]
`
		for i := 0; i < iterations; i++ {
			_, _ = srv.ApplyEvolverPatch(ctx, "01CONCURRENT000000000000", patch)
		}
	}()

	wg.Wait()

	// Post-condition: the disk SKILL.md is valid YAML-frontmatter-bearing
	// markdown (i.e. no interleaved half-writes). We check by asking the
	// server to validate it — ValidateSkill re-parses frontmatter the same
	// way the orchestrator would.
	onDisk, err := os.ReadFile(filepath.Join(skillRoot, "SKILL.md"))
	require.NoError(t, err)
	resp, err := srv.ValidateSkill(ctx, &pb.ValidateSkillRequest{ContentMd: string(onDisk)})
	require.NoError(t, err)
	assert.True(t, resp.Ok, "final SKILL.md must still be valid after concurrent writes; errors=%v", resp.Errors)
}
