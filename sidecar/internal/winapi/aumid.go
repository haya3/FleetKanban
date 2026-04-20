//go:build windows

package winapi

import (
	"fmt"
	"unsafe"

	"golang.org/x/sys/windows"
)

// SetAppUserModelID sets the process-wide AppUserModelID. Must be called
// before any UI / Toast / Jump List work for the app to appear correctly
// in Windows shell features (Start Menu pin, Toast grouping, Taskbar).
//
// Phase 1 uses "com.fleetkanban.desktop" (docs/phase1-spec.md §9.5).
func SetAppUserModelID(aumid string) error {
	if aumid == "" {
		return fmt.Errorf("winapi: SetAppUserModelID: aumid must not be empty")
	}
	ptr, err := windows.UTF16PtrFromString(aumid)
	if err != nil {
		return fmt.Errorf("winapi: SetAppUserModelID encode: %w", err)
	}
	r1, _, callErr := procSetCurrentProcessExplicitAppUserModelID.Call(
		uintptr(unsafe.Pointer(ptr)),
	)
	// HRESULT S_OK == 0
	if r1 != 0 {
		return fmt.Errorf("winapi: SetCurrentProcessExplicitAppUserModelID: HRESULT 0x%08X: %w", uint32(r1), callErr)
	}
	return nil
}

// --- Win32 bindings ---------------------------------------------------------

var (
	modshell32 = windows.NewLazySystemDLL("shell32.dll")

	procSetCurrentProcessExplicitAppUserModelID = modshell32.NewProc("SetCurrentProcessExplicitAppUserModelID")
)
