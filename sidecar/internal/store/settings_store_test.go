package store

import (
	"path/filepath"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func openSettingsDB(t *testing.T) *DB {
	t.Helper()
	path := filepath.Join(t.TempDir(), "settings.db")
	db, err := Open(t.Context(), Options{Path: path})
	require.NoError(t, err)
	t.Cleanup(func() { _ = db.Close() })
	return db
}

func TestSettingsStore_GetIntMissingReturnsDefault(t *testing.T) {
	ctx := t.Context()
	s := NewSettingsStore(openSettingsDB(t))

	v, present, err := s.GetInt(ctx, "worktree.auto_sweep_merged_days", 42)
	require.NoError(t, err)
	assert.False(t, present)
	assert.Equal(t, 42, v)
}

func TestSettingsStore_SetGetIntRoundtrip(t *testing.T) {
	ctx := t.Context()
	s := NewSettingsStore(openSettingsDB(t))

	require.NoError(t, s.SetInt(ctx, "k", 30))
	v, present, err := s.GetInt(ctx, "k", 0)
	require.NoError(t, err)
	assert.True(t, present)
	assert.Equal(t, 30, v)
}

func TestSettingsStore_SetOverwrites(t *testing.T) {
	ctx := t.Context()
	s := NewSettingsStore(openSettingsDB(t))

	require.NoError(t, s.SetInt(ctx, "k", 1))
	require.NoError(t, s.SetInt(ctx, "k", 2))
	v, _, err := s.GetInt(ctx, "k", 0)
	require.NoError(t, err)
	assert.Equal(t, 2, v)
}

func TestSettingsStore_Delete(t *testing.T) {
	ctx := t.Context()
	s := NewSettingsStore(openSettingsDB(t))

	require.NoError(t, s.SetInt(ctx, "k", 7))
	require.NoError(t, s.Delete(ctx, "k"))
	_, present, err := s.GetInt(ctx, "k", 0)
	require.NoError(t, err)
	assert.False(t, present)

	// Deleting an absent key is a no-op.
	require.NoError(t, s.Delete(ctx, "never-set"))
}

func TestSettingsStore_GetJSONDecodesStruct(t *testing.T) {
	ctx := t.Context()
	s := NewSettingsStore(openSettingsDB(t))

	type prefs struct {
		Concurrency int    `json:"concurrency"`
		Locale      string `json:"locale"`
	}
	require.NoError(t, s.SetJSON(ctx, "ui.prefs", prefs{Concurrency: 4, Locale: "ja"}))

	var got prefs
	present, err := s.GetJSON(ctx, "ui.prefs", &got)
	require.NoError(t, err)
	assert.True(t, present)
	assert.Equal(t, prefs{Concurrency: 4, Locale: "ja"}, got)
}
