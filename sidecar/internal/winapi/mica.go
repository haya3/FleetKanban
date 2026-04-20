//go:build windows

package winapi

import (
	"fmt"
	"unsafe"

	"golang.org/x/sys/windows"
)

// BackdropType selects the Windows 11 system backdrop passed to
// DwmSetWindowAttribute with DWMWA_SYSTEMBACKDROP_TYPE.
// Values mirror the DWMSBT_* enumeration in dwmapi.h.
type BackdropType int

const (
	BackdropAuto    BackdropType = iota // DWMSBT_AUTO = 0
	BackdropNone                        // DWMSBT_NONE = 1
	BackdropMica                        // DWMSBT_MAINWINDOW = 2
	BackdropAcrylic                     // DWMSBT_TRANSIENTWINDOW = 3
	BackdropMicaAlt                     // DWMSBT_TABBEDWINDOW = 4
)

// DWM attribute identifiers used by this package.
const (
	dwmwaUseImmersiveDarkMode = 20
	dwmwaSystemBackdropType   = 38
)

// ApplyBackdrop sets DWMWA_SYSTEMBACKDROP_TYPE on hwnd.
// Requires Windows 11 (build 22000+). On older OS the call returns a wrapped error.
func ApplyBackdrop(hwnd windows.HWND, t BackdropType) error {
	val := int32(t)
	r1, _, callErr := procDwmSetWindowAttribute.Call(
		uintptr(hwnd),
		uintptr(dwmwaSystemBackdropType),
		uintptr(unsafe.Pointer(&val)),
		unsafe.Sizeof(val),
	)
	if r1 != 0 {
		return fmt.Errorf("winapi: DwmSetWindowAttribute(DWMWA_SYSTEMBACKDROP_TYPE): HRESULT 0x%08X: %w", uint32(r1), callErr)
	}
	return nil
}

// SetImmersiveDarkMode enables Windows 11 dark title bars via
// DWMWA_USE_IMMERSIVE_DARK_MODE (attribute 20).
func SetImmersiveDarkMode(hwnd windows.HWND, enable bool) error {
	var val int32
	if enable {
		val = 1
	}
	r1, _, callErr := procDwmSetWindowAttribute.Call(
		uintptr(hwnd),
		uintptr(dwmwaUseImmersiveDarkMode),
		uintptr(unsafe.Pointer(&val)),
		unsafe.Sizeof(val),
	)
	if r1 != 0 {
		return fmt.Errorf("winapi: DwmSetWindowAttribute(DWMWA_USE_IMMERSIVE_DARK_MODE): HRESULT 0x%08X: %w", uint32(r1), callErr)
	}
	return nil
}

// --- Win32 bindings ---------------------------------------------------------

var (
	moddwmapi = windows.NewLazySystemDLL("dwmapi.dll")

	procDwmSetWindowAttribute = moddwmapi.NewProc("DwmSetWindowAttribute")
)
