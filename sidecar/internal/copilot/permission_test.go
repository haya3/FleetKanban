//go:build windows

package copilot

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestResolvePath_ExistingFile(t *testing.T) {
	dir := t.TempDir()
	f := filepath.Join(dir, "hello.txt")
	require.NoError(t, os.WriteFile(f, []byte("x"), 0o644))

	resolved, err := ResolvePath(f)
	require.NoError(t, err)

	// The resolved form should be absolute and comparable to the temp dir
	// after case-folding. TempDir returns an already-canonical path.
	assert.True(t, filepath.IsAbs(resolved))
	assert.Equal(t,
		strings.ToLower(filepath.Clean(f)),
		strings.ToLower(filepath.Clean(resolved)))
}

func TestResolvePath_NonExisting_UsesAncestor(t *testing.T) {
	dir := t.TempDir()
	// Deep path where only the root exists.
	target := filepath.Join(dir, "a", "b", "c.txt")

	resolved, err := ResolvePath(target)
	require.NoError(t, err)
	assert.True(t, strings.HasSuffix(strings.ToLower(resolved),
		strings.ToLower(filepath.Join("a", "b", "c.txt"))))
}

func TestNormalizeWin32(t *testing.T) {
	cases := map[string]string{
		`\\?\C:\foo\bar`:            `C:\foo\bar`,
		`\\?\UNC\server\share\file`: `\\server\share\file`,
		`\\.\C:\foo`:                `C:\foo`,
		`C:\already\normal`:         `C:\already\normal`,
	}
	for in, want := range cases {
		assert.Equal(t, want, normalizeWin32(in), "input=%s", in)
	}
}

func TestGuard_Allow_Inside(t *testing.T) {
	root := t.TempDir()
	g, err := NewGuard(root)
	require.NoError(t, err)

	inside := filepath.Join(root, "src", "main.go")
	resolved, ok, err := g.Allow(inside)
	require.NoError(t, err)
	assert.True(t, ok, "file inside worktree must be allowed; got %s", resolved)
}

func TestGuard_Allow_RootItself(t *testing.T) {
	root := t.TempDir()
	g, err := NewGuard(root)
	require.NoError(t, err)

	_, ok, err := g.Allow(root)
	require.NoError(t, err)
	assert.True(t, ok, "the root directory itself is considered allowed")
}

func TestGuard_Allow_Outside(t *testing.T) {
	root := t.TempDir()
	g, err := NewGuard(root)
	require.NoError(t, err)

	// Sibling-of-temp-dir.
	outside := filepath.Join(filepath.Dir(root), "other", "escape.txt")
	_, ok, err := g.Allow(outside)
	require.NoError(t, err)
	assert.False(t, ok)
}

func TestGuard_Allow_PrefixConfusion(t *testing.T) {
	// If root is C:\work\a, then C:\work\alpha must NOT be considered inside.
	baseDir := t.TempDir()
	root := filepath.Join(baseDir, "a")
	require.NoError(t, os.Mkdir(root, 0o755))

	g, err := NewGuard(root)
	require.NoError(t, err)

	sibling := filepath.Join(baseDir, "alpha", "file.txt")
	_, ok, err := g.Allow(sibling)
	require.NoError(t, err)
	assert.False(t, ok, "prefix match must terminate on path separator")
}

func TestGuard_Allow_CaseInsensitive(t *testing.T) {
	root := t.TempDir()
	g, err := NewGuard(root)
	require.NoError(t, err)

	upper := strings.ToUpper(filepath.Join(root, "SRC", "Main.Go"))
	_, ok, err := g.Allow(upper)
	require.NoError(t, err)
	assert.True(t, ok, "NTFS is case-insensitive; upper-cased path must be allowed")
}

func TestGuard_Allow_RejectsADS(t *testing.T) {
	root := t.TempDir()
	g, err := NewGuard(root)
	require.NoError(t, err)

	ads := filepath.Join(root, "file.txt") + ":hidden"
	_, ok, err := g.Allow(ads)
	require.NoError(t, err)
	assert.False(t, ok, "alternate-data-stream paths must be rejected")
}

func TestHasADS(t *testing.T) {
	assert.False(t, hasADS(`C:\no\stream`))
	assert.False(t, hasADS(`C:\foo.txt`))
	assert.True(t, hasADS(`C:\foo.txt:hidden`))
	assert.True(t, hasADS(`no-drive:stream`))
}
