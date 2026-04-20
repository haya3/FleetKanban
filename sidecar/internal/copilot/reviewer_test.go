//go:build windows

package copilot

import (
	"testing"

	"github.com/stretchr/testify/assert"

	"github.com/FleetKanban/fleetkanban/internal/task"
)

func TestParseReviewDecision_Approve(t *testing.T) {
	got := parseReviewDecision("The changes look good.\nAPPROVE")
	assert.True(t, got.Approve)
	assert.Empty(t, got.Feedback)
}

func TestParseReviewDecision_ApproveWithTrailingWhitespace(t *testing.T) {
	got := parseReviewDecision("ok\nAPPROVE\n\n  \n")
	assert.True(t, got.Approve, "blank trailing lines should be ignored")
}

func TestParseReviewDecision_ReworkWithFeedback(t *testing.T) {
	got := parseReviewDecision("REWORK: Please add tests")
	assert.False(t, got.Approve)
	assert.Equal(t, "Please add tests", got.Feedback)
}

func TestParseReviewDecision_ReworkWithoutFeedback(t *testing.T) {
	got := parseReviewDecision("REWORK:")
	assert.False(t, got.Approve)
	assert.NotEmpty(t, got.Feedback, "empty rework body should fall back to a default")
}

func TestParseReviewDecision_UnstructuredFallsThroughAsApprove(t *testing.T) {
	// Post-cap refactor: ambiguous replies let the human reviewer decide
	// instead of triggering another auto-rework. The rework cap lives
	// upstream and picks up the escalation duty.
	body := "There are issues with these changes. Edge cases are missing."
	got := parseReviewDecision(body)
	assert.True(t, got.Approve,
		"unstructured response must fall through to APPROVE so the human picks up the decision")
	assert.Empty(t, got.Feedback)
}

func TestParseReviewDecision_EmptyTranscript(t *testing.T) {
	// Empty transcript: nothing to review; let the human decide.
	got := parseReviewDecision("")
	assert.True(t, got.Approve)
}

func TestParseReviewDecision_PrefixNotWholeLine(t *testing.T) {
	// APPROVE appearing in the middle of a line must not count as approval
	// — but under the new fall-through semantics an unstructured reply
	// still approves, just not on the "prefix" path.
	got := parseReviewDecision("I would not APPROVE this at all")
	assert.True(t, got.Approve,
		"unstructured reply approves via fall-through, not the APPROVE prefix match")
}

func TestBuildReviewPrompt_IncludesPrevFeedbackAndReworkCount(t *testing.T) {
	tk := &task.Task{
		ID:         "T1",
		Goal:       "write a README",
		BaseBranch: "main",
		Branch:     "fleetkanban/T1",
	}
	prompt := buildReviewPrompt(tk, "diff content here", "Last time I asked you to add a LICENSE", 2)

	assert.Contains(t, prompt, "write a README", "goal must appear")
	assert.Contains(t, prompt, "Last time I asked you to add a LICENSE",
		"prevFeedback must be surfaced to the reviewer so it can self-check")
	assert.Contains(t, prompt, "Rework iterations so far: 2",
		"reworkCount must be visible as context")
	assert.Contains(t, prompt, "APPROVE")
	assert.Contains(t, prompt, "REWORK:")
	assert.Contains(t, prompt, "When in doubt, choose APPROVE",
		"ambiguous-case guidance must be in the prompt")
}

func TestBuildReviewPrompt_InitialReviewFlagsNoPrevFeedback(t *testing.T) {
	tk := &task.Task{ID: "T1", Goal: "g", BaseBranch: "main", Branch: "b"}
	prompt := buildReviewPrompt(tk, "d", "", 0)
	assert.Contains(t, prompt, "(initial review)",
		"empty prevFeedback must render as (initial review) so the reviewer knows")
}

func TestBuildReviewPrompt_EmptyDiffIsLabelled(t *testing.T) {
	tk := &task.Task{ID: "T1", Goal: "g", BaseBranch: "main", Branch: "b"}
	prompt := buildReviewPrompt(tk, "", "", 0)
	assert.Contains(t, prompt, "(empty diff — no changes)")
}
