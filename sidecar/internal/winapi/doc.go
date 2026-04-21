// Package winapi wraps the Win32 APIs that FleetKanban depends on but that
// the Go standard library (and golang.org/x/sys/windows) do not expose in
// a convenient form.
//
// The package is Windows-only. FleetKanban does not support any other OS
// and intentionally does not provide cross-platform stubs (see
// docs/phase1-spec.md §9 and docs/architecture.md §1).
//
// Current surface:
//   - AppUserModelID (aumid.go)
//   - Mica backdrop + immersive dark mode (mica.go)
//   - Toast notifications (toast.go)
//   - DPAPI protect/unprotect for secrets at rest (dpapi.go)
//   - Jump List Recent Documents (jumplist.go)
//   - Jump List Tasks category via ICustomDestinationList COM (jumplist_tasks.go)
//   - Windows Terminal Fragment profile registration (terminal_fragment.go)
package winapi
