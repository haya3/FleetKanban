//go:build windows

package winapi

import (
	"errors"
	"fmt"
	"path/filepath"
	"unsafe"

	"golang.org/x/sys/windows"
)

// Shell32 SHAddToRecentDocs uFlags values.
//
// We only need SHARD_PATHW (add a wide-char file path to the per-user
// Recent Documents MRU, which Windows renders as the "Recent" section of
// the app's Jump List when an AUMID is set). The richer SHARD_LINK and
// SHARD_APPIDINFO variants are useful for the full ICustomDestinationList
// dance with pinned "Tasks" categories; Phase 1 sticks to the automatic
// destinations list which already covers the "recent repositories"
// discoverability story described in docs/phase1-spec.md §9.4.
const shardPathW = 0x00000003

// AddRecentDocument pushes a local path into the Recent Documents list so
// Windows surfaces it in the Jump List for the current process's AUMID.
// Failures are logged by the caller — losing an MRU entry is never fatal.
func AddRecentDocument(path string) error {
	if path == "" {
		return errors.New("winapi: AddRecentDocument: path is required")
	}
	abs, err := filepath.Abs(path)
	if err != nil {
		return fmt.Errorf("winapi: AddRecentDocument abs: %w", err)
	}
	ptr, err := windows.UTF16PtrFromString(abs)
	if err != nil {
		return fmt.Errorf("winapi: AddRecentDocument encode: %w", err)
	}
	// SHAddToRecentDocs is HRESULT-less (void return) but we still call it
	// through the syscall machinery. Errors from the Call layer only
	// surface Windows errors in callErr; we ignore them because the API
	// cannot "fail" in a way the user needs to see — the worst case is a
	// missing MRU entry.
	_, _, _ = procSHAddToRecentDocs.Call(
		uintptr(shardPathW),
		uintptr(unsafe.Pointer(ptr)),
	)
	return nil
}

// ClearRecentDocuments empties the process's Recent Documents list. Called
// when the user asks us to "refresh" the Jump List so stale entries don't
// linger after repos are unregistered.
func ClearRecentDocuments() {
	_, _, _ = procSHAddToRecentDocs.Call(uintptr(shardPathW), 0)
}

// RefreshJumpList rebuilds the Recent Documents list from the provided
// paths in the order given (most recent first). The underlying API is
// append-only, so we clear first and re-add — cheap for handfuls of repos.
func RefreshJumpList(paths []string) error {
	ClearRecentDocuments()
	var firstErr error
	// Walk from last to first so the most recently-touched repo ends up at
	// the top of the Jump List (SHAddToRecentDocs prepends).
	for i := len(paths) - 1; i >= 0; i-- {
		if err := AddRecentDocument(paths[i]); err != nil && firstErr == nil {
			firstErr = err
		}
	}
	return firstErr
}

// --- Win32 bindings ---------------------------------------------------------

// modshell32 is declared in aumid.go; reuse it here.
var procSHAddToRecentDocs = modshell32.NewProc("SHAddToRecentDocs")
