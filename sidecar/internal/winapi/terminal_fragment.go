//go:build windows

package winapi

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
)

// fragmentProfile mirrors the Windows Terminal Fragment profile schema
// (Windows Terminal 1.15+). Only the fields FleetKanban populates are
// declared; the rest are left to Terminal defaults.
type fragmentProfile struct {
	GUID             string `json:"guid"`
	Name             string `json:"name"`
	Commandline      string `json:"commandline"`
	Icon             string `json:"icon"`
	StartingDir      string `json:"startingDirectory"`
	TabTitle         string `json:"tabTitle"`
	UseAcrylic       bool   `json:"useAcrylic"`
}

type fragmentDocument struct {
	Profiles []fragmentProfile `json:"profiles"`
}

const (
	// terminalFragmentGUID is fixed so Windows Terminal deduplicates across
	// restarts. Changing this GUID would create a duplicate profile entry.
	terminalFragmentGUID = "{a4e9dfed-48ce-4b2c-a4ec-fa6e0b1e2c2b}"

	terminalFragmentDir  = `Microsoft\Windows Terminal\Fragments\FleetKanban`
	terminalFragmentFile = "fleetkanban.json"
)

// resolveFragmentPath returns the canonical fragment path:
//
//	<LOCALAPPDATA>\Microsoft\Windows Terminal\Fragments\FleetKanban\fleetkanban.json
//
// Returns an error if LOCALAPPDATA is unset (e.g. a service account context
// where the user profile is not loaded).
func resolveFragmentPath() (string, error) {
	local := os.Getenv("LOCALAPPDATA")
	if local == "" {
		return "", fmt.Errorf("winapi: terminal fragment: LOCALAPPDATA is not set")
	}
	return filepath.Join(local, terminalFragmentDir, terminalFragmentFile), nil
}

// EnsureTerminalFragment writes the FleetKanban profile fragment to the
// Windows Terminal Fragments directory. Idempotent: overwrites on each call
// so edits to the embedded profile (e.g. commandline tweak) land on restart.
// A failure here is non-fatal — Terminal integration is a nice-to-have.
//
// harnessSkillRoot is the absolute path to the harness-skill directory
// (typically %APPDATA%\FleetKanban\harness-skill). It is embedded in the
// profile's commandline and startingDirectory fields.
func EnsureTerminalFragment(harnessSkillRoot string) error {
	fragPath, err := resolveFragmentPath()
	if err != nil {
		return err
	}

	// Commandline: pwsh opens at harnessSkillRoot and prints a banner.
	// Double-quoted because the path may contain spaces.
	cmdline := fmt.Sprintf(
		`pwsh -NoExit -Command "Set-Location '%s'; Write-Host 'FleetKanban harness-skill root — edit SKILL.md and save to UpdateSkill via UI.' -ForegroundColor Green"`,
		harnessSkillRoot,
	)

	doc := fragmentDocument{
		Profiles: []fragmentProfile{
			{
				GUID:        terminalFragmentGUID,
				Name:        "FleetKanban Harness Shell",
				Commandline: cmdline,
				Icon:        "⛵",
				StartingDir: harnessSkillRoot,
				TabTitle:    "FleetKanban",
				UseAcrylic:  true,
			},
		},
	}

	data, err := json.MarshalIndent(doc, "", "  ")
	if err != nil {
		return fmt.Errorf("winapi: terminal fragment: marshal: %w", err)
	}
	// Ensure UTF-8 with no BOM — json.Marshal already emits UTF-8 without BOM.

	// Idempotency: if the fragment file already contains byte-identical JSON
	// skip the write entirely. This preserves user edits (e.g. a tweaked
	// commandline or a swapped icon) across sidecar restarts — we only
	// overwrite when the canonical template actually changed between
	// builds. A manual hand-edit survives indefinitely unless the user
	// bumps the template in source and rebuilds.
	if existing, rerr := os.ReadFile(fragPath); rerr == nil {
		if bytesEqual(existing, data) {
			return nil
		}
	}

	if err := os.MkdirAll(filepath.Dir(fragPath), 0o755); err != nil {
		return fmt.Errorf("winapi: terminal fragment: mkdir: %w", err)
	}

	// Atomic write: write to a sibling temp file then rename so a concurrent
	// Terminal read never observes a partial JSON document.
	tmp := fragPath + ".tmp"
	if err := os.WriteFile(tmp, data, 0o644); err != nil {
		return fmt.Errorf("winapi: terminal fragment: write tmp: %w", err)
	}
	if err := os.Rename(tmp, fragPath); err != nil {
		// Clean up the temp file on rename failure; best-effort.
		_ = os.Remove(tmp)
		return fmt.Errorf("winapi: terminal fragment: rename: %w", err)
	}
	return nil
}

// bytesEqual is a local byte-slice equality helper to avoid pulling in
// bytes.Equal just for this one use.
func bytesEqual(a, b []byte) bool {
	if len(a) != len(b) {
		return false
	}
	for i := range a {
		if a[i] != b[i] {
			return false
		}
	}
	return true
}

// RemoveTerminalFragment deletes the fragment file and its parent directory
// (if the directory becomes empty after removal). Intended for uninstall
// workflows; not called during normal sidecar shutdown because the profile
// is re-registered on the next launch anyway.
func RemoveTerminalFragment() error {
	fragPath, err := resolveFragmentPath()
	if err != nil {
		return err
	}
	if err := os.Remove(fragPath); err != nil && !os.IsNotExist(err) {
		return fmt.Errorf("winapi: terminal fragment: remove: %w", err)
	}
	// Remove the FleetKanban sub-directory only if it is now empty so we do
	// not accidentally delete files created by other tools.
	_ = os.Remove(filepath.Dir(fragPath)) // ignores error when non-empty
	return nil
}
