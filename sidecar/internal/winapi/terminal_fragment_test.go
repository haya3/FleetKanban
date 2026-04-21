//go:build windows

package winapi

import (
	"encoding/json"
	"os"
	"path/filepath"
	"testing"
)

func TestEnsureTerminalFragment_WritesExpectedFile(t *testing.T) {
	// Override LOCALAPPDATA to an isolated temp directory so the test does
	// not touch the real Windows Terminal Fragments directory.
	t.Setenv("LOCALAPPDATA", t.TempDir())

	harnessRoot := t.TempDir()
	if err := EnsureTerminalFragment(harnessRoot); err != nil {
		t.Fatalf("EnsureTerminalFragment: %v", err)
	}

	fragPath, err := resolveFragmentPath()
	if err != nil {
		t.Fatalf("resolveFragmentPath: %v", err)
	}
	if _, err := os.Stat(fragPath); err != nil {
		t.Fatalf("fragment file not found at %s: %v", fragPath, err)
	}

	data, err := os.ReadFile(fragPath)
	if err != nil {
		t.Fatalf("read fragment: %v", err)
	}

	var doc fragmentDocument
	if err := json.Unmarshal(data, &doc); err != nil {
		t.Fatalf("unmarshal fragment JSON: %v", err)
	}

	if len(doc.Profiles) != 1 {
		t.Fatalf("expected 1 profile, got %d", len(doc.Profiles))
	}
	p := doc.Profiles[0]
	if p.GUID != terminalFragmentGUID {
		t.Errorf("GUID: got %q, want %q", p.GUID, terminalFragmentGUID)
	}
	if p.Name != "FleetKanban Harness Shell" {
		t.Errorf("Name: got %q", p.Name)
	}
	if p.TabTitle != "FleetKanban" {
		t.Errorf("TabTitle: got %q", p.TabTitle)
	}
	if !p.UseAcrylic {
		t.Error("UseAcrylic: expected true")
	}
}

func TestEnsureTerminalFragment_Idempotent(t *testing.T) {
	t.Setenv("LOCALAPPDATA", t.TempDir())
	harnessRoot := t.TempDir()

	// Two successive calls must both succeed and produce a valid file.
	if err := EnsureTerminalFragment(harnessRoot); err != nil {
		t.Fatalf("first call: %v", err)
	}
	if err := EnsureTerminalFragment(harnessRoot); err != nil {
		t.Fatalf("second call: %v", err)
	}

	fragPath, _ := resolveFragmentPath()
	data, err := os.ReadFile(fragPath)
	if err != nil {
		t.Fatalf("read after second call: %v", err)
	}
	var doc fragmentDocument
	if err := json.Unmarshal(data, &doc); err != nil {
		t.Fatalf("unmarshal: %v", err)
	}
	if len(doc.Profiles) != 1 {
		t.Errorf("expected 1 profile, got %d", len(doc.Profiles))
	}
}

func TestEnsureTerminalFragment_ParentDirsCreated(t *testing.T) {
	base := t.TempDir()
	t.Setenv("LOCALAPPDATA", base)

	// The Fragments sub-tree should not exist yet.
	fragDir := filepath.Join(base, terminalFragmentDir)
	if _, err := os.Stat(fragDir); !os.IsNotExist(err) {
		t.Skip("directory already exists; skipping creation check")
	}

	if err := EnsureTerminalFragment(t.TempDir()); err != nil {
		t.Fatalf("EnsureTerminalFragment: %v", err)
	}
	if _, err := os.Stat(fragDir); err != nil {
		t.Fatalf("directory not created: %v", err)
	}
}

func TestRemoveTerminalFragment_RemovesFile(t *testing.T) {
	t.Setenv("LOCALAPPDATA", t.TempDir())
	harnessRoot := t.TempDir()

	if err := EnsureTerminalFragment(harnessRoot); err != nil {
		t.Fatalf("EnsureTerminalFragment: %v", err)
	}
	fragPath, _ := resolveFragmentPath()
	if _, err := os.Stat(fragPath); err != nil {
		t.Fatalf("file should exist before remove: %v", err)
	}

	if err := RemoveTerminalFragment(); err != nil {
		t.Fatalf("RemoveTerminalFragment: %v", err)
	}
	if _, err := os.Stat(fragPath); !os.IsNotExist(err) {
		t.Error("file should not exist after remove")
	}
}

func TestRemoveTerminalFragment_Idempotent(t *testing.T) {
	t.Setenv("LOCALAPPDATA", t.TempDir())
	// Remove without prior EnsureTerminalFragment should not error.
	if err := RemoveTerminalFragment(); err != nil {
		t.Fatalf("remove on absent file: %v", err)
	}
}

func TestResolveFragmentPath_EmptyLOCALAPPDATA(t *testing.T) {
	t.Setenv("LOCALAPPDATA", "")
	if _, err := resolveFragmentPath(); err == nil {
		t.Fatal("expected error when LOCALAPPDATA is empty, got nil")
	}
}
