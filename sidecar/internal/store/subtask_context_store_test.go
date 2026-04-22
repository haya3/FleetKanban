//go:build windows

package store

import (
	"errors"
	"testing"
	"time"

	"github.com/oklog/ulid/v2"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/haya3/FleetKanban/internal/task"
)

// seedSubtaskForContext creates the minimal repo+task+subtask chain needed
// to satisfy subtask_context.subtask_id FK. Returns the subtask ID.
func seedSubtaskForContext(t *testing.T, db *DB, label string) string {
	t.Helper()
	rs := NewRepositoryStore(db)
	ts := NewTaskStore(db)
	ss := NewSubtaskStore(db)

	repoID := "repo-sc-" + label
	taskID := "task-sc-" + label
	subID := "sub-sc-" + label
	mustRepo(t, rs, repoID, "repo-"+label)
	mustTask(t, ts, taskID, repoID)

	require.NoError(t, ss.Create(t.Context(), &task.Subtask{
		ID:        subID,
		TaskID:    taskID,
		Title:     "ctx-" + label,
		AgentRole: "coder",
		Status:    task.SubtaskPending,
		OrderIdx:  1,
		Round:     1,
	}))
	return subID
}

func TestSubtaskContext_UpsertAndGetLatest(t *testing.T) {
	db := openTestDB(t)
	scs := NewSubtaskContextStore(db)
	hss := NewHarnessSkillStore(db)
	subID := seedSubtaskForContext(t, db, "a")

	harnessID := ulid.Make().String()
	_, _, err := hss.Insert(t.Context(), HarnessSkillVersion{
		ID:          harnessID,
		ContentMD:   "# test harness",
		ContentHash: "h1",
		CreatedAt:   time.Now().UTC(),
		CreatedBy:   "user",
	})
	require.NoError(t, err)

	want := SubtaskContext{
		SubtaskID:             subID,
		Round:                 1,
		HarnessSkillVersionID: harnessID,
		SystemPrompt:          "SYSTEM PROMPT BODY",
		StagePromptTemplate:   "Default code prompt",
		PlanSummary:           "do the thing",
		PriorSummaries:        []string{"step 1 done", "step 2 done"},
		MemoryBlock:           "### Memory\nsome context",
		OutputLanguage:        "Japanese",
	}
	require.NoError(t, scs.Upsert(t.Context(), want))

	got, err := scs.GetLatest(t.Context(), subID)
	require.NoError(t, err)
	assert.Equal(t, want.SubtaskID, got.SubtaskID)
	assert.Equal(t, want.Round, got.Round)
	assert.Equal(t, want.HarnessSkillVersionID, got.HarnessSkillVersionID)
	assert.Equal(t, want.SystemPrompt, got.SystemPrompt)
	assert.Equal(t, want.StagePromptTemplate, got.StagePromptTemplate)
	assert.Equal(t, want.PlanSummary, got.PlanSummary)
	assert.Equal(t, want.PriorSummaries, got.PriorSummaries)
	assert.Equal(t, want.MemoryBlock, got.MemoryBlock)
	assert.Equal(t, want.OutputLanguage, got.OutputLanguage)
	assert.False(t, got.CreatedAt.IsZero())
}

func TestSubtaskContext_UpsertOverwritesSameRound(t *testing.T) {
	db := openTestDB(t)
	scs := NewSubtaskContextStore(db)
	subID := seedSubtaskForContext(t, db, "b")

	first := SubtaskContext{
		SubtaskID:           subID,
		Round:               2,
		SystemPrompt:        "first",
		StagePromptTemplate: "tmpl",
	}
	require.NoError(t, scs.Upsert(t.Context(), first))

	second := first
	second.SystemPrompt = "overwritten"
	require.NoError(t, scs.Upsert(t.Context(), second))

	got, err := scs.Get(t.Context(), subID, 2)
	require.NoError(t, err)
	assert.Equal(t, "overwritten", got.SystemPrompt)
}

func TestSubtaskContext_PreservesRoundHistory(t *testing.T) {
	db := openTestDB(t)
	scs := NewSubtaskContextStore(db)
	subID := seedSubtaskForContext(t, db, "c")

	for i := 1; i <= 3; i++ {
		require.NoError(t, scs.Upsert(t.Context(), SubtaskContext{
			SubtaskID:           subID,
			Round:               i,
			SystemPrompt:        "round-" + string(rune('0'+i)),
			StagePromptTemplate: "tmpl",
		}))
	}

	latest, err := scs.GetLatest(t.Context(), subID)
	require.NoError(t, err)
	assert.Equal(t, 3, latest.Round)
	assert.Equal(t, "round-3", latest.SystemPrompt)

	round1, err := scs.Get(t.Context(), subID, 1)
	require.NoError(t, err)
	assert.Equal(t, "round-1", round1.SystemPrompt)
}

func TestSubtaskContext_MissingReturnsSentinel(t *testing.T) {
	db := openTestDB(t)
	scs := NewSubtaskContextStore(db)
	_, err := scs.GetLatest(t.Context(), "does-not-exist")
	assert.True(t, errors.Is(err, ErrNoSubtaskContext))
	_, err = scs.Get(t.Context(), "does-not-exist", 1)
	assert.True(t, errors.Is(err, ErrNoSubtaskContext))
}

func TestSubtaskContext_CascadeDeletesWithSubtask(t *testing.T) {
	db := openTestDB(t)
	scs := NewSubtaskContextStore(db)
	subID := seedSubtaskForContext(t, db, "d")

	require.NoError(t, scs.Upsert(t.Context(), SubtaskContext{
		SubtaskID:           subID,
		Round:               1,
		SystemPrompt:        "before-delete",
		StagePromptTemplate: "tmpl",
	}))

	_, err := db.write.ExecContext(t.Context(), `DELETE FROM subtasks WHERE id = ?`, subID)
	require.NoError(t, err)

	_, err = scs.GetLatest(t.Context(), subID)
	assert.True(t, errors.Is(err, ErrNoSubtaskContext))
}
