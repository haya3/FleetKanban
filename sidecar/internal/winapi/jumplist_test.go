//go:build windows

package winapi

import (
	"os"
	"path/filepath"
	"testing"
)

// SHAddToRecentDocs is a best-effort Shell API that never reports failure
// through a surfaceable HRESULT — we rely on path-encoding sanity rather
// than behaviour verification. The tests here cover the thin pre-conditions
// in our wrapper and that RefreshJumpList walks its input correctly.

func TestAddRecentDocument_EmptyPathRejected(t *testing.T) {
	if err := AddRecentDocument(""); err == nil {
		t.Fatal("expected error for empty path, got nil")
	}
}

func TestAddRecentDocument_RelativePathResolved(t *testing.T) {
	// Use a temp file so the path is guaranteed valid on this host.
	f, err := os.CreateTemp(t.TempDir(), "fleetkanban-jumplist-*.tmp")
	if err != nil {
		t.Fatalf("tempfile: %v", err)
	}
	_ = f.Close()

	cwd, err := os.Getwd()
	if err != nil {
		t.Fatalf("getwd: %v", err)
	}
	rel, err := filepath.Rel(cwd, f.Name())
	if err != nil {
		// Cross-drive fallback — feed the absolute path; the test's intent
		// is that non-abs input does not crash, not that a specific form
		// survives the round-trip.
		rel = f.Name()
	}
	if err := AddRecentDocument(rel); err != nil {
		t.Fatalf("AddRecentDocument: %v", err)
	}
}

func TestRefreshJumpList_ClearsAndReadds(t *testing.T) {
	// Fabricate a handful of paths under tempdir so each AddRecentDocument
	// has a real target to resolve — SHAddToRecentDocs silently drops
	// non-existent paths on some Windows builds.
	dir := t.TempDir()
	paths := []string{
		filepath.Join(dir, "a"),
		filepath.Join(dir, "b"),
		filepath.Join(dir, "c"),
	}
	for _, p := range paths {
		if err := os.MkdirAll(p, 0o755); err != nil {
			t.Fatalf("mkdir %s: %v", p, err)
		}
	}
	if err := RefreshJumpList(paths); err != nil {
		t.Fatalf("RefreshJumpList: %v", err)
	}
}

func TestClearRecentDocuments_DoesNotPanic(t *testing.T) {
	// No observable side-effect we can assert against without reading the
	// current user's AutomaticDestinations file, which is out of scope for
	// a unit test. Just ensure the syscall path runs cleanly.
	ClearRecentDocuments()
}
