//go:build windows

package harnessembed

import (
	"io/fs"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"testing"
)

// TestSeedMatchesSource guarantees the embedded seed/ tree is a byte-for-byte
// copy of the sidecar/harness-skill/ source tree. Drift happens whenever
// someone edits harness-skill/*.md without mirroring into seed/*.md (or the
// other way round — though seed/ is meant to be downstream). Without this
// test, the bundled binary can ship an outdated default that first-boot
// users get seeded with, while developers see the newer content locally.
//
// The test walks both trees and fails with a precise diff line per
// mismatched / missing / extra file. It uses runtime.Caller to locate the
// source tree relative to this test file, which keeps it stable across
// `go test` invocation directories.
func TestSeedMatchesSource(t *testing.T) {
	// Locate sidecar/harness-skill/ relative to this test file.
	_, thisFile, _, ok := runtime.Caller(0)
	if !ok {
		t.Fatal("runtime.Caller failed")
	}
	// thisFile = …/internal/harnessembed/embed_test.go → up 2 → …/internal → up 1 → …/sidecar
	sidecarRoot := filepath.Dir(filepath.Dir(filepath.Dir(thisFile)))
	sourceRoot := filepath.Join(sidecarRoot, "harness-skill")

	// Walk the source tree and cross-check every entry against the
	// embedded FS. Record missing / mismatched files instead of
	// failing at the first one — a single edit that touches three
	// files should produce three diff lines, not force three
	// round-trips to green.
	var diffs []string

	err := filepath.WalkDir(sourceRoot, func(path string, d fs.DirEntry, walkErr error) error {
		if walkErr != nil {
			return walkErr
		}
		if d.IsDir() {
			return nil
		}
		rel, err := filepath.Rel(sourceRoot, path)
		if err != nil {
			return err
		}
		relSlash := filepath.ToSlash(rel)
		embedPath := "seed/" + relSlash

		srcBytes, err := os.ReadFile(path)
		if err != nil {
			return err
		}
		embBytes, err := fs.ReadFile(FS, embedPath)
		if err != nil {
			diffs = append(diffs, "missing in embed: "+embedPath+" (source: "+rel+")")
			return nil
		}
		if string(srcBytes) != string(embBytes) {
			diffs = append(diffs, "content mismatch: "+embedPath+" differs from harness-skill/"+rel)
		}
		return nil
	})
	if err != nil {
		t.Fatalf("walk source: %v", err)
	}

	// Walk the embed FS too and flag files that exist there but not in
	// source — otherwise a deletion from harness-skill/ that wasn't
	// mirrored into seed/ would ship stale content silently.
	err = fs.WalkDir(FS, "seed", func(path string, d fs.DirEntry, walkErr error) error {
		if walkErr != nil {
			return walkErr
		}
		if d.IsDir() {
			return nil
		}
		rel := strings.TrimPrefix(path, "seed/")
		srcPath := filepath.Join(sourceRoot, filepath.FromSlash(rel))
		if _, err := os.Stat(srcPath); os.IsNotExist(err) {
			diffs = append(diffs, "extra in embed: "+path+" has no counterpart in harness-skill/"+rel)
		} else if err != nil {
			return err
		}
		return nil
	})
	if err != nil {
		t.Fatalf("walk embed: %v", err)
	}

	if len(diffs) > 0 {
		t.Fatalf("embed seed is out of sync with harness-skill/ — run the sync (cp) or go generate, then re-run:\n  %s",
			strings.Join(diffs, "\n  "))
	}
}
