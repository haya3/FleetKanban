package task

import (
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func newValidTask() *Task {
	return &Task{
		ID:           "01J000000000000000000000",
		RepoID:       "01J000000000000000000001",
		Goal:         "Add Hello World to README",
		BaseBranch:   "main",
		Branch:       "fleetkanban/01J000000000000000000000",
		WorktreePath: `C:\Users\x\AppData\Roaming\FleetKanban\worktrees\01J000000000000000000000`,
		Model:        "gpt-4.1",
		Status:       StatusQueued,
		CreatedAt:    time.Now(),
	}
}

func TestTaskValidate_OK(t *testing.T) {
	tk := newValidTask()
	require.NoError(t, tk.Validate())
}

func TestTaskValidate_MissingFields(t *testing.T) {
	cases := []struct {
		name   string
		mutate func(*Task)
	}{
		{"no ID", func(tk *Task) { tk.ID = "" }},
		{"no RepoID", func(tk *Task) { tk.RepoID = "" }},
		{"no Goal", func(tk *Task) { tk.Goal = "" }},
		{"invalid status", func(tk *Task) { tk.Status = "bogus" }},
		{"invalid finalization", func(tk *Task) { tk.Finalization = "bogus" }},
	}
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			tk := newValidTask()
			c.mutate(tk)
			assert.Error(t, tk.Validate())
		})
	}
}

func TestTaskValidate_FailedRequiresErrorCode(t *testing.T) {
	tk := newValidTask()
	tk.Status = StatusFailed
	assert.Error(t, tk.Validate(), "failed without ErrorCode should be rejected")

	tk.ErrorCode = ErrCodeRuntime
	assert.NoError(t, tk.Validate())
}

func TestTaskValidate_NonFailedForbidsErrorCode(t *testing.T) {
	tk := newValidTask()
	tk.Status = StatusInProgress
	tk.ErrorCode = ErrCodeRuntime
	assert.Error(t, tk.Validate(), "non-failed with ErrorCode should be rejected")
}

func TestTaskValidate_DoneRequiresFinalization(t *testing.T) {
	tk := newValidTask()
	tk.Status = StatusDone
	assert.Error(t, tk.Validate(), "done without Finalization should be rejected")

	tk.Finalization = FinalizationKeep
	assert.NoError(t, tk.Validate())
}

func TestTaskValidate_NonDoneForbidsFinalization(t *testing.T) {
	tk := newValidTask()
	tk.Status = StatusHumanReview
	tk.Finalization = FinalizationKeep
	assert.Error(t, tk.Validate(), "non-done with Finalization should be rejected")
}

func TestStatus_Valid(t *testing.T) {
	valid := []Status{
		StatusPlanning, StatusQueued, StatusInProgress,
		StatusAIReview, StatusHumanReview, StatusDone,
		StatusCancelled, StatusAborted, StatusFailed,
	}
	for _, s := range valid {
		assert.True(t, s.Valid(), "%s should be valid", s)
	}
	assert.False(t, Status("unknown").Valid())
	assert.False(t, Status("").Valid())
}

func TestStatus_IsTerminal(t *testing.T) {
	terminal := []Status{StatusDone, StatusCancelled, StatusFailed}
	nonTerminal := []Status{
		StatusPlanning, StatusQueued, StatusInProgress,
		StatusAIReview, StatusHumanReview, StatusAborted,
	}

	for _, s := range terminal {
		assert.True(t, s.IsTerminal(), "%s should be terminal", s)
	}
	for _, s := range nonTerminal {
		assert.False(t, s.IsTerminal(), "%s should not be terminal", s)
	}
}

func TestFinalization_Valid(t *testing.T) {
	valid := []FinalizationKind{FinalizationNone, FinalizationKeep, FinalizationMerged}
	for _, f := range valid {
		assert.True(t, f.Valid(), "%s should be valid", f)
	}
	assert.False(t, FinalizationKind("bogus").Valid())
}

func TestCanTransition_LegalEdges(t *testing.T) {
	legal := [][2]Status{
		{StatusQueued, StatusPlanning},
		{StatusQueued, StatusInProgress}, // rework bypass
		{StatusQueued, StatusCancelled},
		{StatusPlanning, StatusInProgress},
		{StatusPlanning, StatusFailed},
		{StatusPlanning, StatusAborted},
		{StatusInProgress, StatusAIReview},
		{StatusInProgress, StatusFailed},
		{StatusInProgress, StatusAborted},
		{StatusAIReview, StatusHumanReview},
		{StatusAIReview, StatusFailed},
		{StatusAIReview, StatusQueued},
		{StatusAIReview, StatusAborted},
		{StatusHumanReview, StatusDone},
		{StatusHumanReview, StatusCancelled},
		{StatusHumanReview, StatusQueued},
		{StatusAborted, StatusDone},
		{StatusAborted, StatusCancelled},
		{StatusAborted, StatusQueued},
		{StatusFailed, StatusQueued},
	}
	for _, e := range legal {
		assert.True(t, CanTransition(e[0], e[1]), "%s -> %s should be legal", e[0], e[1])
	}
}

func TestCanTransition_IllegalEdges(t *testing.T) {
	illegal := [][2]Status{
		// Queued must pass through in_progress before review/done.
		{StatusQueued, StatusHumanReview},
		{StatusQueued, StatusAIReview},
		{StatusQueued, StatusDone},
		// InProgress must pass through ai_review before human_review/done.
		{StatusInProgress, StatusHumanReview},
		{StatusInProgress, StatusDone},
		{StatusInProgress, StatusCancelled},
		// Terminal states never move forward.
		{StatusDone, StatusInProgress},
		{StatusDone, StatusHumanReview},
		{StatusDone, StatusQueued},
		{StatusCancelled, StatusInProgress},
		{StatusFailed, StatusInProgress},
		{StatusFailed, StatusHumanReview},
		{StatusDone, StatusQueued},
		{StatusCancelled, StatusQueued},
		// Rework must flow via queued; direct resume is not supported.
		{StatusHumanReview, StatusInProgress},
		{StatusAborted, StatusInProgress},
		{StatusAIReview, StatusInProgress},
		// Planning is an intermediate gate only; it does not loop back to queued.
		{StatusPlanning, StatusQueued},
		{StatusPlanning, StatusAIReview},
		{StatusPlanning, StatusHumanReview},
		{StatusPlanning, StatusDone},
	}
	for _, e := range illegal {
		assert.False(t, CanTransition(e[0], e[1]), "%s -> %s should be illegal", e[0], e[1])
	}
}

func TestCanTransition_SameStateRejected(t *testing.T) {
	all := []Status{
		StatusPlanning, StatusQueued, StatusInProgress,
		StatusAIReview, StatusHumanReview, StatusDone,
		StatusCancelled, StatusAborted, StatusFailed,
	}
	for _, s := range all {
		assert.False(t, CanTransition(s, s), "%s -> %s should be rejected", s, s)
	}
}

func TestTransition_UpdatesStatusOnLegalEdge(t *testing.T) {
	tk := newValidTask()
	require.NoError(t, tk.Transition(StatusInProgress))
	assert.Equal(t, StatusInProgress, tk.Status)
	require.NoError(t, tk.Transition(StatusAIReview))
	require.NoError(t, tk.Transition(StatusHumanReview))
	require.NoError(t, tk.Transition(StatusDone))
	assert.Equal(t, StatusDone, tk.Status)
}

func TestTransition_ReworkLoop(t *testing.T) {
	// human_review → queued (rework) → in_progress → ai_review → human_review → done
	tk := newValidTask()
	tk.Status = StatusHumanReview
	require.NoError(t, tk.Transition(StatusQueued))
	require.NoError(t, tk.Transition(StatusInProgress))
	require.NoError(t, tk.Transition(StatusAIReview))
	require.NoError(t, tk.Transition(StatusHumanReview))
	assert.Equal(t, StatusHumanReview, tk.Status)
}

func TestTransition_LeavesStatusUnchangedOnIllegal(t *testing.T) {
	tk := newValidTask()
	err := tk.Transition(StatusDone)
	assert.Error(t, err)
	assert.Equal(t, StatusQueued, tk.Status, "illegal transition must not mutate status")
}

func TestTransition_RejectsInvalidTarget(t *testing.T) {
	tk := newValidTask()
	err := tk.Transition(Status("bogus"))
	assert.Error(t, err)
	assert.Equal(t, StatusQueued, tk.Status)
}

func TestEventKind_Valid(t *testing.T) {
	valid := []EventKind{
		EventSessionStart, EventSessionIdle, EventStatus,
		EventAssistantDelta, EventAssistantReasoningDelta,
		EventToolStart, EventToolEnd, EventPermissionRequest,
		EventError, EventSecurityPathEscape,
		EventPlanSummary, EventSessionUsage, EventFileChanged,
		EventAIReviewDecision,
	}
	for _, k := range valid {
		assert.True(t, k.Valid(), "%s should be valid", k)
	}
	assert.False(t, EventKind("").Valid())
	assert.False(t, EventKind("unknown.kind").Valid())
}

func TestEventValidate(t *testing.T) {
	ev := &AgentEvent{
		ID:         "01J00000000000000000000E",
		TaskID:     "01J00000000000000000000T",
		Seq:        1,
		Kind:       EventAssistantDelta,
		Payload:    "hello",
		OccurredAt: time.Now(),
	}
	require.NoError(t, ev.Validate())

	ev.Kind = "bad"
	assert.Error(t, ev.Validate())
}
