//go:build windows

package setup

import (
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestCheckPwsh_SkipEnvVar(t *testing.T) {
	t.Setenv(SkipEnvVar, "1")
	got := CheckPwsh()
	assert.True(t, got.Installed, "env-var bypass must short-circuit to installed=true")
	assert.Contains(t, got.Detail, SkipEnvVar)
}

func TestCheckPwsh_NotInstalled(t *testing.T) {
	// Point PATH to a dir that cannot contain pwsh and blank out
	// LOCALAPPDATA / ProgramFiles-style hints by keeping the current
	// values — well-known paths resolve to files that don't exist on
	// a clean CI worker. This relies on the CI environment genuinely
	// not having pwsh; the assertion is best-effort.
	t.Setenv(SkipEnvVar, "") // explicit empty, do not bypass
	t.Setenv("PATH", t.TempDir())
	t.Setenv("LOCALAPPDATA", t.TempDir())

	got := CheckPwsh()
	if got.Installed {
		t.Skipf("pwsh was found via hardcoded Program Files path (%s); skipping", got.Path)
	}
	assert.False(t, got.Installed)
	assert.Empty(t, got.Path)
	assert.Contains(t, got.Detail, "not found")
}

func TestManualInstallCommand_MatchesWingetCommand(t *testing.T) {
	// Guard against drift: if WingetCommand changes, ManualInstallCommand
	// must reflect the same arguments so the UI's copy-paste instructions
	// stay accurate.
	got := ManualInstallCommand()
	for _, arg := range WingetCommand {
		assert.Contains(t, got, arg, "manual command missing %q", arg)
	}
	assert.True(t, strings.HasPrefix(got, "winget "), "command must be invokable as-is")
}

func TestInstallError_Format(t *testing.T) {
	e := &InstallError{ExitCode: 42, Output: "oops"}
	require.Error(t, e)
	assert.Contains(t, e.Error(), "42")
}
