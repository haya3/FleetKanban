package task

import (
	"fmt"
	"time"
)

// EventKind classifies the origin and semantics of an AgentEvent.
//
// Keep these string values stable — they are persisted in the events table
// and consumed by the frontend.
type EventKind string

const (
	// Session lifecycle (emitted by orchestrator / copilot runner)
	EventSessionStart EventKind = "session.start"
	EventSessionIdle  EventKind = "session.idle"
	EventStatus       EventKind = "status" // arbitrary status snapshot

	// Streamed agent output (emitted by stream parser)
	EventAssistantDelta          EventKind = "assistant.delta"
	EventAssistantReasoningDelta EventKind = "assistant.reasoning.delta"
	EventToolStart               EventKind = "tool.start"
	EventToolEnd                 EventKind = "tool.end"
	EventPermissionRequest       EventKind = "permission.request"

	// Subtask lifecycle. Payload is JSON: start carries
	// {subtask_id, title, agent_role}; end carries {subtask_id, ok, err}.
	// Emitted by the orchestrator's subtask loop so the UI can group
	// downstream delta / tool events under the correct subtask.
	EventSubtaskStart EventKind = "subtask.start"
	EventSubtaskEnd   EventKind = "subtask.end"

	// Errors / security violations
	EventError              EventKind = "error"
	EventSecurityPathEscape EventKind = "security.path_escape"

	// Reviewer decisions. Payload is a JSON-encoded object with the action
	// (approve|rework|reject) and the free-form feedback string. Produced by
	// the IPC handler for SubmitReview so the review history survives across
	// rework iterations even though Task.ReviewFeedback only holds the latest.
	EventReviewSubmitted EventKind = "review.submitted"

	// Housekeeping (emitted by the reaper's background passes). Payload is
	// a JSON-encoded object describing what was acted on and why — see
	// phase1-spec §3.1 "ブランチ保持ポリシー / GC". Used by the Settings >
	// Housekeeping UI to show an audit trail of sweep activity.
	EventHousekeepingBranchGC EventKind = "housekeeping.branch_gc"
)

// Valid reports whether kind is a known EventKind.
func (k EventKind) Valid() bool {
	switch k {
	case EventSessionStart, EventSessionIdle, EventStatus,
		EventAssistantDelta, EventAssistantReasoningDelta,
		EventToolStart, EventToolEnd, EventPermissionRequest,
		EventSubtaskStart, EventSubtaskEnd,
		EventError, EventSecurityPathEscape,
		EventReviewSubmitted,
		EventHousekeepingBranchGC:
		return true
	}
	return false
}

// AgentEvent is one line of agent output or one lifecycle signal belonging to
// a specific Task. Events are append-only and ordered by Seq within a task.
//
// Payload is free-form: for EventAssistantDelta it is the raw text chunk; for
// EventToolStart / EventToolEnd it is a JSON-encoded object; for security
// events it is a JSON-encoded violation record. The schema per kind is owned
// by the producer and the frontend.
type AgentEvent struct {
	ID         string // ULID
	TaskID     string // FK tasks.id
	Seq        int64  // monotonic per TaskID, assigned at insert
	Kind       EventKind
	Payload    string
	OccurredAt time.Time
}

// Validate checks invariants required by the store layer.
func (e *AgentEvent) Validate() error {
	if e.ID == "" {
		return fmt.Errorf("event: ID is required")
	}
	if e.TaskID == "" {
		return fmt.Errorf("event %s: TaskID is required", e.ID)
	}
	if !e.Kind.Valid() {
		return fmt.Errorf("event %s: invalid kind %q", e.ID, e.Kind)
	}
	return nil
}
