//go:build windows

// Package setup owns runtime-dependency preconditions that FleetKanban
// requires before agents can run. Today that is PowerShell 7+ — the
// embedded Copilot CLI shells out to `pwsh.exe` when the agent needs a
// shell, and Windows 11 ships only Windows PowerShell 5.1 (`powershell.exe`)
// by default, so sessions fail with "pwsh not found" until PowerShell 7
// is installed.
//
// The package detects whether pwsh is reachable and, on demand, drives
// a silent per-user winget install so the UI can recover from the
// "missing dependency" state without forcing the user to drop to a
// terminal.
package setup

import (
	"context"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"syscall"
)

// PwshCheckResult captures the outcome of a detection pass. Path is the
// absolute location of the pwsh binary when found; empty when not found.
type PwshCheckResult struct {
	Installed bool
	Path      string
	// Detail is a short human-readable description of how the binary was
	// (or wasn't) located. Surfaced to the UI's precondition banner so
	// users can understand "found on PATH" vs "found at well-known path"
	// without opening logs.
	Detail string
}

// SkipEnvVar is the opt-out hatch for CI / headless / corp-locked
// environments where the dependency machinery must not trigger. When
// set to any non-empty value, CheckPwsh reports Installed=true with a
// detail noting the override.
const SkipEnvVar = "FLEETKANBAN_SKIP_PWSH_CHECK"

// wellKnownPwshPaths are the install locations PowerShell 7's MSI and
// winget per-user installer drop the binary in. Checked after PATH
// because a PATH entry means the shell can launch pwsh without us
// needing to know the exact path.
func wellKnownPwshPaths() []string {
	paths := []string{
		`C:\Program Files\PowerShell\7\pwsh.exe`,
		`C:\Program Files (x86)\PowerShell\7\pwsh.exe`,
	}
	if local := os.Getenv("LOCALAPPDATA"); local != "" {
		// winget --scope user installs under %LOCALAPPDATA%\Microsoft\WinGet\Packages
		// but symlinks / shims the binary into %LOCALAPPDATA%\Microsoft\PowerShell\7\.
		paths = append(paths, filepath.Join(local, "Microsoft", "PowerShell", "7", "pwsh.exe"))
	}
	return paths
}

// CheckPwsh reports whether a PowerShell 7+ binary is reachable. It
// checks PATH first (most common post-install state), then the set of
// well-known install paths (covers the case where the MSI didn't refresh
// the caller's PATH, e.g. this sidecar was launched before the install
// finished). Honours SkipEnvVar so CI / locked-down environments can
// bypass the machinery entirely.
func CheckPwsh() PwshCheckResult {
	if v := os.Getenv(SkipEnvVar); v != "" {
		return PwshCheckResult{
			Installed: true,
			Detail:    fmt.Sprintf("check bypassed via %s", SkipEnvVar),
		}
	}
	if p, err := exec.LookPath("pwsh"); err == nil && p != "" {
		return PwshCheckResult{Installed: true, Path: p, Detail: "found on PATH"}
	}
	for _, p := range wellKnownPwshPaths() {
		if _, err := os.Stat(p); err == nil {
			return PwshCheckResult{Installed: true, Path: p, Detail: "found at " + p}
		}
	}
	return PwshCheckResult{Installed: false, Detail: "pwsh.exe not found on PATH or in known install locations"}
}

// WingetCommand is the winget invocation used to install PowerShell 7
// per-user. Exposed for tests and the UI's "copy manual command"
// fallback. The scope is user to avoid the UAC prompt; silent + the
// accept flags remove every interactive gate.
var WingetCommand = []string{
	"winget", "install",
	"--id", "Microsoft.PowerShell",
	"--scope", "user",
	"--silent",
	"--accept-source-agreements",
	"--accept-package-agreements",
	"--disable-interactivity",
}

// InstallError wraps a winget install failure with the captured output
// so the UI can display the real cause. Kept as a dedicated type so
// callers can match on it with errors.As.
type InstallError struct {
	ExitCode int
	Output   string
	Err      error
}

func (e *InstallError) Error() string {
	if e.Err != nil {
		return fmt.Sprintf("winget install failed (exit %d): %v", e.ExitCode, e.Err)
	}
	return fmt.Sprintf("winget install failed (exit %d)", e.ExitCode)
}

// InstallPwsh runs the winget command that installs PowerShell 7 at
// user scope, capturing stdout+stderr for diagnostics. Blocks until the
// installer finishes — typically 1–3 minutes — so the UI can show a
// simple spinner while awaiting the RPC.
//
// On success the binary lands at one of the wellKnownPwshPaths; callers
// should re-run CheckPwsh afterwards to confirm.
//
// Returns ErrWingetMissing if winget itself is not on PATH (rare but
// possible on trimmed Windows Server images that lack App Installer).
func InstallPwsh(ctx context.Context) (PwshCheckResult, error) {
	if _, err := exec.LookPath("winget"); err != nil {
		return PwshCheckResult{}, ErrWingetMissing
	}

	// Use CommandContext so cancellation (e.g. user closes the dialog)
	// kills the installer. winget respects SIGTERM; on Windows that is
	// delivered via TerminateProcess which is not graceful but is
	// acceptable for an aborted install.
	cmd := exec.CommandContext(ctx, WingetCommand[0], WingetCommand[1:]...)
	// Hide the winget console window. Without CREATE_NO_WINDOW a
	// detached console briefly flashes for every RPC — annoying and
	// looks like malware to jumpy users.
	cmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}

	out, err := cmd.CombinedOutput()
	exit := 0
	if cmd.ProcessState != nil {
		exit = cmd.ProcessState.ExitCode()
	}

	// Always re-check after the install attempt. winget can return
	// non-zero for benign reasons (package already installed, upgrade
	// not applicable) — the authoritative signal is "is pwsh now
	// reachable".
	result := CheckPwsh()

	if err != nil || exit != 0 {
		if result.Installed {
			// winget grumbled but the binary is in place — treat as
			// success and discard the process error.
			return result, nil
		}
		return result, &InstallError{
			ExitCode: exit,
			Output:   strings.TrimSpace(string(out)),
			Err:      err,
		}
	}
	return result, nil
}

// ErrWingetMissing is returned when winget itself cannot be found,
// meaning auto-install is not possible on this machine. The UI
// surfaces this distinctly so users can be told to install App
// Installer (or PowerShell 7 manually) rather than guessing.
var ErrWingetMissing = errors.New("setup: winget not found on PATH; cannot auto-install PowerShell 7")

// ManualInstallCommand is the command string to show the user when
// auto-install fails or winget is missing. Copy-paste friendly; using
// the raw strings.Join keeps the single-source-of-truth next to
// WingetCommand so the two can't drift apart.
func ManualInstallCommand() string {
	return strings.Join(WingetCommand, " ")
}
