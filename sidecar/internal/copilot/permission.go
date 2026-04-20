//go:build windows

package copilot

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	copilot "github.com/github/copilot-sdk/go"
	"golang.org/x/sys/windows"
)

// NewPermissionHandler builds a copilot.PermissionHandlerFunc that enforces
// the worktree-containment invariant for Write permission requests using the
// Guard. All other permission kinds (Shell, Read, MCP, URL, Memory, Hook,
// CustomTool) are approved without further inspection — the worktree boundary
// is the only hard security requirement for phase 1.
//
// The returned handler is safe for concurrent use.
func NewPermissionHandler(worktreeRoot string) (copilot.PermissionHandlerFunc, error) {
	guard, err := NewGuard(worktreeRoot)
	if err != nil {
		return nil, fmt.Errorf("copilot: permission handler: guard init: %w", err)
	}

	return func(req copilot.PermissionRequest, _ copilot.PermissionInvocation) (copilot.PermissionRequestResult, error) {
		if req.Kind == copilot.PermissionRequestKindWrite && req.FileName != nil {
			_, ok, guardErr := guard.Allow(*req.FileName)
			if guardErr != nil {
				// Resolution failure: deny with rules to avoid silently approving
				// a path we could not validate.
				return copilot.PermissionRequestResult{
					Kind: copilot.PermissionRequestResultKindDeniedByRules,
				}, nil
			}
			if !ok {
				return copilot.PermissionRequestResult{
					Kind: copilot.PermissionRequestResultKindDeniedByRules,
				}, nil
			}
		}
		return copilot.PermissionRequestResult{
			Kind: copilot.PermissionRequestResultKindApproved,
		}, nil
	}, nil
}

// ResolvePath resolves p to its canonical NTFS absolute form, following
// symbolic links, junctions, and other reparse points. When p does not yet
// exist (the common case for "Wrote file:" lines the Copilot CLI emits
// before sys flush), the closest existing ancestor is resolved and the
// remaining path components are appended verbatim.
//
// The returned path is normalized to drive-letter form (C:\foo) or UNC
// form (\\server\share\foo) — win32-namespaced prefixes (\\?\, \\.\) are
// stripped.
//
// Errors indicate structural problems (e.g. an unreadable ancestor); non-
// existent paths themselves are not an error.
func ResolvePath(p string) (string, error) {
	abs, err := filepath.Abs(p)
	if err != nil {
		return "", fmt.Errorf("copilot: abs %q: %w", p, err)
	}

	// Peel off path components until one exists. "" and "." terminate.
	cur := abs
	var tail []string
	for {
		if fi, err := os.Stat(cur); err == nil {
			_ = fi
			break
		}
		parent := filepath.Dir(cur)
		if parent == cur {
			// Reached the root without finding anything that exists. Fall
			// through with the literal input cleaned.
			return normalizeWin32(filepath.Clean(abs)), nil
		}
		tail = append([]string{filepath.Base(cur)}, tail...)
		cur = parent
	}

	resolved, err := finalPath(cur)
	if err != nil {
		return "", fmt.Errorf("copilot: resolve ancestor %q: %w", cur, err)
	}
	if len(tail) > 0 {
		resolved = filepath.Join(append([]string{resolved}, tail...)...)
	}
	return normalizeWin32(filepath.Clean(resolved)), nil
}

// finalPath wraps Win32 GetFinalPathNameByHandleW for existing paths. Using
// FILE_FLAG_BACKUP_SEMANTICS lets us open directories the same way as files.
func finalPath(existing string) (string, error) {
	path16, err := windows.UTF16PtrFromString(existing)
	if err != nil {
		return "", err
	}
	h, err := windows.CreateFile(
		path16,
		0, // no access — we only want the canonical name
		windows.FILE_SHARE_READ|windows.FILE_SHARE_WRITE|windows.FILE_SHARE_DELETE,
		nil,
		windows.OPEN_EXISTING,
		windows.FILE_FLAG_BACKUP_SEMANTICS,
		0,
	)
	if err != nil {
		return "", fmt.Errorf("CreateFile: %w", err)
	}
	defer windows.CloseHandle(h)

	const volumeNameDos = 0x0
	buf := make([]uint16, windows.MAX_PATH)
	n, err := windows.GetFinalPathNameByHandle(h, &buf[0], uint32(len(buf)), volumeNameDos)
	if err != nil {
		return "", fmt.Errorf("GetFinalPathNameByHandle: %w", err)
	}
	if int(n) > len(buf) {
		buf = make([]uint16, n)
		n, err = windows.GetFinalPathNameByHandle(h, &buf[0], uint32(len(buf)), volumeNameDos)
		if err != nil {
			return "", fmt.Errorf("GetFinalPathNameByHandle retry: %w", err)
		}
	}
	return windows.UTF16ToString(buf[:n]), nil
}

// normalizeWin32 trims win32-namespace prefixes from a resolved path so the
// result is comparable to a user-supplied drive-letter path.
//
//	\\?\C:\foo\bar          → C:\foo\bar
//	\\?\UNC\server\share\x  → \\server\share\x
//	\\.\C:\foo              → C:\foo
func normalizeWin32(p string) string {
	switch {
	case strings.HasPrefix(p, `\\?\UNC\`):
		return `\\` + p[len(`\\?\UNC\`):]
	case strings.HasPrefix(p, `\\?\`):
		return p[len(`\\?\`):]
	case strings.HasPrefix(p, `\\.\`):
		return p[len(`\\.\`):]
	}
	return p
}

// Guard enforces the worktree-containment invariant: every write the
// Copilot CLI performs must land under RealRoot.
//
// RealRoot must already be the canonical NTFS form of the worktree
// directory. NewGuard resolves it at construction time so the comparison is
// a simple prefix test at steady state.
type Guard struct {
	realRoot string // resolved, normalized, lowercase
	rawRoot  string // original input (for diagnostics)
}

// NewGuard resolves root once and caches the canonical form for use by
// Allow. An error is returned if root itself cannot be resolved (e.g. the
// worktree does not exist yet — callers should create it first).
func NewGuard(root string) (*Guard, error) {
	resolved, err := ResolvePath(root)
	if err != nil {
		return nil, err
	}
	return &Guard{
		realRoot: strings.ToLower(filepath.Clean(resolved)),
		rawRoot:  root,
	}, nil
}

// Allow reports whether p is inside the worktree. Returns the resolved
// target path in both allow and reject cases (so the caller can log it).
func (g *Guard) Allow(p string) (resolved string, ok bool, err error) {
	// Reject alternate-data-stream notation outright (phase1-spec §9.1). We
	// allow a single-letter drive colon but forbid any subsequent ':'.
	if hasADS(p) {
		return p, false, nil
	}

	resolved, err = ResolvePath(p)
	if err != nil {
		return "", false, err
	}
	lower := strings.ToLower(filepath.Clean(resolved))
	root := g.realRoot
	if lower == root {
		return resolved, true, nil
	}
	// Prefix match must terminate on a path separator to prevent a path
	// like C:\worktree-evil\ from matching C:\worktree.
	return resolved, strings.HasPrefix(lower, root+string(os.PathSeparator)), nil
}

// hasADS reports whether p contains an NTFS alternate-data-stream separator
// (":") anywhere after the drive letter.
func hasADS(p string) bool {
	if len(p) >= 2 && p[1] == ':' && isDriveLetter(p[0]) {
		return strings.Contains(p[2:], ":")
	}
	return strings.Contains(p, ":")
}

func isDriveLetter(b byte) bool {
	return (b >= 'A' && b <= 'Z') || (b >= 'a' && b <= 'z')
}
