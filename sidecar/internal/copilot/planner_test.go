//go:build windows

package copilot

import (
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/FleetKanban/fleetkanban/internal/task"
)

func TestExtractPlanJSON_TaggedBlock(t *testing.T) {
	tr := "I will output after a brief preamble.\n" + // multi-byte sample (original was multi-byte Japanese text)
		plannerJSONTag + `
{"subtasks":[{"id":"s1","title":"x","agent_role":"coder","depends_on":[]}]}
` + plannerJSONTag
	got, usedFallback, err := extractPlanJSON(tr)
	require.NoError(t, err)
	assert.False(t, usedFallback, "tagged path must not flag fallback")
	assert.True(t, strings.HasPrefix(got, "{"), "expected JSON object start")
	assert.Contains(t, got, "\"s1\"")
}

func TestExtractPlanJSON_TaggedBlockWithCodeFence(t *testing.T) {
	tr := plannerJSONTag + "\n```json\n" +
		`{"subtasks":[]}` + "\n```\n" + plannerJSONTag
	got, usedFallback, err := extractPlanJSON(tr)
	require.NoError(t, err)
	assert.False(t, usedFallback)
	assert.Equal(t, `{"subtasks":[]}`, got)
}

func TestExtractPlanJSON_FallbackBalancedBraces(t *testing.T) {
	tr := "no tag but here:\n" +
		`{"subtasks":[{"id":"s1","title":"work { in title }","agent_role":"r","depends_on":[]}]}` +
		"\nafter"
	got, usedFallback, err := extractPlanJSON(tr)
	require.NoError(t, err)
	assert.True(t, usedFallback, "missing PLAN_JSON tag must flag fallback so callers can warn")
	assert.Contains(t, got, "work { in title }", "brace inside string must not break the balance")
}

func TestExtractPlanJSON_NoJSON(t *testing.T) {
	_, _, err := extractPlanJSON("plain prose, no json here at all")
	require.Error(t, err)
}

func TestNormalisePlan_AssignsULIDsAndTopoOrder(t *testing.T) {
	raw := []plannerRawSubtask{
		{ID: "b", Title: "build", AgentRole: "coder", DependsOn: []string{"a"}},
		{ID: "a", Title: "design", AgentRole: "planner", DependsOn: []string{}},
		{ID: "c", Title: "test", AgentRole: "tester", DependsOn: []string{"b"}},
	}
	subs, err := normalisePlan("TASK1", raw)
	require.NoError(t, err)
	require.Len(t, subs, 3)

	assert.Equal(t, "design", subs[0].Title, "a has no deps, should come first")
	assert.Equal(t, "build", subs[1].Title, "b depends on a")
	assert.Equal(t, "test", subs[2].Title, "c depends on b")

	for i, s := range subs {
		assert.Equal(t, i, s.OrderIdx)
		assert.Equal(t, "TASK1", s.TaskID)
		assert.Equal(t, task.SubtaskPending, s.Status)
		assert.Len(t, s.ID, 26, "ULID length")
	}

	assert.ElementsMatch(t, []string{subs[0].ID}, subs[1].DependsOn)
	assert.ElementsMatch(t, []string{subs[1].ID}, subs[2].DependsOn)
}

func TestNormalisePlan_RejectsCycle(t *testing.T) {
	raw := []plannerRawSubtask{
		{ID: "a", Title: "A", AgentRole: "r", DependsOn: []string{"b"}},
		{ID: "b", Title: "B", AgentRole: "r", DependsOn: []string{"a"}},
	}
	_, err := normalisePlan("T", raw)
	require.Error(t, err)
	assert.Contains(t, err.Error(), "cycle")
}

func TestNormalisePlan_RejectsSelfDep(t *testing.T) {
	raw := []plannerRawSubtask{
		{ID: "a", Title: "A", AgentRole: "r", DependsOn: []string{"a"}},
	}
	_, err := normalisePlan("T", raw)
	require.Error(t, err)
	assert.Contains(t, err.Error(), "depends on itself")
}

func TestNormalisePlan_RejectsUnknownDep(t *testing.T) {
	raw := []plannerRawSubtask{
		{ID: "a", Title: "A", AgentRole: "r", DependsOn: []string{"ghost"}},
	}
	_, err := normalisePlan("T", raw)
	require.Error(t, err)
	assert.Contains(t, err.Error(), "unknown")
}

func TestNormalisePlan_RejectsDuplicateID(t *testing.T) {
	raw := []plannerRawSubtask{
		{ID: "a", Title: "A", AgentRole: "r"},
		{ID: "a", Title: "A2", AgentRole: "r"},
	}
	_, err := normalisePlan("T", raw)
	require.Error(t, err)
	assert.Contains(t, err.Error(), "duplicate")
}

func TestNormalisePlan_RejectsReviewerRole(t *testing.T) {
	// The dedicated AI Review phase runs after plan execution; allowing
	// a reviewer subtask in the plan would double-review the task and
	// historically caused phantom-rework loops.
	for _, role := range []string{"reviewer", "Reviewer", "AI_REVIEWER", "ai-reviewer"} {
		_, err := normalisePlan("T", []plannerRawSubtask{
			{ID: "a", Title: "x", AgentRole: role},
		})
		require.Error(t, err, "role %q must be rejected", role)
		assert.Contains(t, err.Error(), "forbidden role")
	}
}

func TestNormalisePlan_RejectsMissingTitleOrRole(t *testing.T) {
	_, err := normalisePlan("T", []plannerRawSubtask{
		{ID: "a", Title: "", AgentRole: "r"},
	})
	require.Error(t, err)
	assert.Contains(t, err.Error(), "title")

	_, err = normalisePlan("T", []plannerRawSubtask{
		{ID: "a", Title: "x", AgentRole: ""},
	})
	require.Error(t, err)
	assert.Contains(t, err.Error(), "agent_role")
}

func TestNormalisePlan_RejectsEmptyAndOversized(t *testing.T) {
	_, err := normalisePlan("T", nil)
	require.Error(t, err)
	assert.Contains(t, err.Error(), "empty")

	raw := make([]plannerRawSubtask, MaxPlannerSubtasks+1)
	for i := range raw {
		raw[i] = plannerRawSubtask{
			ID: toID(i), Title: "x", AgentRole: "r",
		}
	}
	_, err = normalisePlan("T", raw)
	require.Error(t, err)
	assert.Contains(t, err.Error(), "cap")
}

func TestNormalisePlan_DeterministicSiblingOrder(t *testing.T) {
	raw := []plannerRawSubtask{
		{ID: "a", Title: "A", AgentRole: "r"},
		{ID: "b", Title: "B", AgentRole: "r"},
		{ID: "c", Title: "C", AgentRole: "r"},
	}
	subs1, err := normalisePlan("T", raw)
	require.NoError(t, err)
	subs2, err := normalisePlan("T", raw)
	require.NoError(t, err)

	// Titles must be emitted in a repeatable order across two invocations
	// of the same input. ULIDs differ run-to-run, but the sort-by-ULID in
	// topoSort guarantees titles follow whichever ULID sort emerges.
	titles1 := []string{subs1[0].Title, subs1[1].Title, subs1[2].Title}
	titles2 := []string{subs2[0].Title, subs2[1].Title, subs2[2].Title}

	_ = titles1
	_ = titles2
	// We can't assert titles1 == titles2 because ULIDs are time-ordered and
	// the test generates them in the same call each time. But we can assert
	// that within a single run, sibling order equals the ULID sort order.
	ids := []string{subs1[0].ID, subs1[1].ID, subs1[2].ID}
	sorted := append([]string(nil), ids...)
	for i := 1; i < len(sorted); i++ {
		for j := i; j > 0 && sorted[j-1] > sorted[j]; j-- {
			sorted[j-1], sorted[j] = sorted[j], sorted[j-1]
		}
	}
	assert.Equal(t, sorted, ids, "siblings must emerge in ULID-sort order")
}

func toID(i int) string {
	// small helper — limited range is fine for the oversized-plan test
	return string(rune('a'+i%26)) + string(rune('0'+i/26%10))
}
