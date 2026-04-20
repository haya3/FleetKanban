//go:build windows

package winapi

import (
	"fmt"
	"unsafe"

	"golang.org/x/sys/windows"
)

// dataBlob mirrors the Win32 DATA_BLOB structure used by the DPAPI entry
// points. `pbData` is a pointer to a heap-allocated buffer; when the OS
// allocates it on our behalf (as with CryptProtectData / CryptUnprotectData
// output buffers) we must release it via LocalFree.
type dataBlob struct {
	cbData uint32
	pbData *byte
}

func newBlob(data []byte) dataBlob {
	if len(data) == 0 {
		return dataBlob{}
	}
	return dataBlob{
		cbData: uint32(len(data)),
		pbData: &data[0],
	}
}

// toBytes copies out an OS-allocated blob into a Go-owned []byte. The caller
// still owns the original blob and is responsible for LocalFree'ing it.
func (b dataBlob) toBytes() []byte {
	if b.cbData == 0 || b.pbData == nil {
		return nil
	}
	src := unsafe.Slice(b.pbData, b.cbData)
	out := make([]byte, b.cbData)
	copy(out, src)
	return out
}

var (
	modCrypt32           = windows.NewLazySystemDLL("crypt32.dll")
	procCryptProtectData = modCrypt32.NewProc("CryptProtectData")
	procCryptUnprotect   = modCrypt32.NewProc("CryptUnprotectData")
	modKernel32          = windows.NewLazySystemDLL("kernel32.dll")
	procLocalFree        = modKernel32.NewProc("LocalFree")
)

// CryptProtectLocalMachine, if true, encrypts data so that any user on the
// current machine can decrypt it. When false, only the current user account
// can decrypt. FleetKanban uses user-scope exclusively for per-user secrets.
const cryptProtectLocalMachine uint32 = 0x4

// ProtectBytes encrypts data with DPAPI scoped to the current user. The
// returned ciphertext is opaque — treat it as bytes to store and later pass
// back to UnprotectBytes. Empty input returns an empty output.
func ProtectBytes(data []byte) ([]byte, error) {
	if len(data) == 0 {
		return nil, nil
	}
	in := newBlob(data)
	var out dataBlob
	ret, _, err := procCryptProtectData.Call(
		uintptr(unsafe.Pointer(&in)),
		0, // description (optional)
		0, // optional entropy
		0, // reserved
		0, // prompt struct
		0, // flags (user-scope)
		uintptr(unsafe.Pointer(&out)),
	)
	if ret == 0 {
		return nil, fmt.Errorf("winapi: CryptProtectData: %w", err)
	}
	defer procLocalFree.Call(uintptr(unsafe.Pointer(out.pbData)))
	return out.toBytes(), nil
}

// UnprotectBytes decrypts data previously produced by ProtectBytes on the
// same machine and user account. Empty input returns an empty output.
func UnprotectBytes(data []byte) ([]byte, error) {
	if len(data) == 0 {
		return nil, nil
	}
	in := newBlob(data)
	var out dataBlob
	ret, _, err := procCryptUnprotect.Call(
		uintptr(unsafe.Pointer(&in)),
		0, 0, 0, 0, 0,
		uintptr(unsafe.Pointer(&out)),
	)
	if ret == 0 {
		return nil, fmt.Errorf("winapi: CryptUnprotectData: %w", err)
	}
	defer procLocalFree.Call(uintptr(unsafe.Pointer(out.pbData)))
	return out.toBytes(), nil
}

// silence "unused constant" if build tags prune callers.
var _ = cryptProtectLocalMachine
