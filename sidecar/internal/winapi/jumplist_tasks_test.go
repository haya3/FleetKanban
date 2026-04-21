//go:build windows

package winapi

import (
	"os"
	"testing"
)

// TestRegisterJumpList_CompileCheck verifies the function signatures exist and
// the package compiles. The actual COM initialisation requires a real Windows
// shell host; in headless CI environments CoCreateInstance for shell objects
// may fail with CO_E_SERVER_EXEC_FAILURE. We therefore skip the live test
// when COM cannot be initialised or when the process is not interactive.
func TestRegisterJumpList_CompileCheck(t *testing.T) {
	// Ensure both functions are callable (compile-time check).
	var _ func(string) error = RegisterJumpList
	var _ func() error = ClearJumpList
}

func TestRegisterJumpList_Live(t *testing.T) {
	if os.Getenv("FLEETKANBAN_JUMPLIST_LIVE_TEST") == "" {
		t.Skip("set FLEETKANBAN_JUMPLIST_LIVE_TEST=1 to run COM jump list integration test")
	}
	// Use a dummy exe path — the jump list entries point to explorer.exe
	// so the exePath argument is only reserved for future deep-link work.
	exe, err := os.Executable()
	if err != nil {
		t.Fatalf("os.Executable: %v", err)
	}
	if err := RegisterJumpList(exe); err != nil {
		t.Fatalf("RegisterJumpList: %v", err)
	}
	t.Log("RegisterJumpList succeeded")
}

func TestClearJumpList_Live(t *testing.T) {
	if os.Getenv("FLEETKANBAN_JUMPLIST_LIVE_TEST") == "" {
		t.Skip("set FLEETKANBAN_JUMPLIST_LIVE_TEST=1 to run COM jump list integration test")
	}
	if err := ClearJumpList(); err != nil {
		t.Fatalf("ClearJumpList: %v", err)
	}
	t.Log("ClearJumpList succeeded")
}

// TestCoInitialize_MultipleCalls verifies that calling coInitialize twice
// in the same goroutine is safe (the second call returns S_FALSE and also
// provides a valid uninit callback without double-freeing).
func TestCoInitialize_MultipleCalls(t *testing.T) {
	uninit1, err := coInitialize()
	if err != nil {
		t.Fatalf("coInitialize (1): %v", err)
	}
	defer uninit1()

	// Second call on same thread: COM returns S_FALSE (already initialised).
	uninit2, err := coInitialize()
	if err != nil {
		t.Fatalf("coInitialize (2): %v", err)
	}
	defer uninit2()
}
