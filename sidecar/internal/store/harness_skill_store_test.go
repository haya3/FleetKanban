//go:build windows

package store

import (
	"context"
	"errors"
	"path/filepath"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func openTestSkillDB(t *testing.T) *DB {
	t.Helper()
	path := filepath.Join(t.TempDir(), "skill_test.db")
	db, err := Open(t.Context(), Options{Path: path})
	require.NoError(t, err)
	t.Cleanup(func() { _ = db.Close() })
	return db
}

// TestInsert_Roundtrip inserts two distinct versions and verifies that List
// returns them newest-first, and that Get retrieves each by ID.
func TestInsert_Roundtrip(t *testing.T) {
	ctx := context.Background()
	st := NewHarnessSkillStore(openTestSkillDB(t))

	v1 := HarnessSkillVersion{
		ContentMD:   "# v1\n",
		ContentHash: "hash-aaa",
		CreatedBy:   "user",
	}
	id1, inserted1, err := st.Insert(ctx, v1)
	require.NoError(t, err)
	assert.True(t, inserted1, "first insert should return inserted=true")
	assert.NotEmpty(t, id1)

	v2 := HarnessSkillVersion{
		ContentMD:   "# v2\n",
		ContentHash: "hash-bbb",
		CreatedBy:   "user",
	}
	id2, inserted2, err := st.Insert(ctx, v2)
	require.NoError(t, err)
	assert.True(t, inserted2)
	assert.NotEmpty(t, id2)
	assert.NotEqual(t, id1, id2)

	// List should return both, newest first.
	// Both were inserted within the same second so we rely on the DESC id
	// tiebreak — id2 was minted after id1 so it sorts higher.
	list, err := st.List(ctx, 0)
	require.NoError(t, err)
	require.Len(t, list, 2)
	assert.Equal(t, id2, list[0].ID, "newest ID should be first")
	assert.Equal(t, id1, list[1].ID)

	// Get should return each row with full content.
	got1, err := st.Get(ctx, id1)
	require.NoError(t, err)
	assert.Equal(t, v1.ContentMD, got1.ContentMD)
	assert.Equal(t, v1.ContentHash, got1.ContentHash)

	got2, err := st.Get(ctx, id2)
	require.NoError(t, err)
	assert.Equal(t, v2.ContentMD, got2.ContentMD)
}

// TestInsert_Duplicate_NoOp verifies that re-inserting the same content_hash
// is a no-op: inserted=false and the returned ID matches the existing row.
func TestInsert_Duplicate_NoOp(t *testing.T) {
	ctx := context.Background()
	st := NewHarnessSkillStore(openTestSkillDB(t))

	v := HarnessSkillVersion{
		ContentMD:   "# same\n",
		ContentHash: "hash-dup",
		CreatedBy:   "user",
	}

	id1, ins1, err := st.Insert(ctx, v)
	require.NoError(t, err)
	assert.True(t, ins1)

	// Second insert — same hash, different content_md to confirm hash wins.
	v2 := v
	v2.ContentMD = "# different text, same hash\n"
	id2, ins2, err := st.Insert(ctx, v2)
	require.NoError(t, err)
	assert.False(t, ins2, "duplicate hash must return inserted=false")
	assert.Equal(t, id1, id2, "must return existing row ID on duplicate")

	// Only one row should exist.
	list, err := st.List(ctx, 0)
	require.NoError(t, err)
	assert.Len(t, list, 1)
}

// TestLatest_Empty verifies that Latest returns ErrNoSkillVersion on an empty table.
func TestLatest_Empty(t *testing.T) {
	ctx := context.Background()
	st := NewHarnessSkillStore(openTestSkillDB(t))

	_, err := st.Latest(ctx)
	require.Error(t, err)
	assert.True(t, errors.Is(err, ErrNoSkillVersion), "expected ErrNoSkillVersion, got %v", err)
}

// TestGet_NotFound verifies that Get returns ErrNoSkillVersion for a missing ID.
func TestGet_NotFound(t *testing.T) {
	ctx := context.Background()
	st := NewHarnessSkillStore(openTestSkillDB(t))

	_, err := st.Get(ctx, "01NONEXISTENT0000000000000")
	assert.True(t, errors.Is(err, ErrNoSkillVersion))
}
