//go:build windows

package copilot

import (
	"testing"

	copilot "github.com/github/copilot-sdk/go"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/FleetKanban/fleetkanban/internal/task"
)

func TestMapSessionEvent_AssistantDelta(t *testing.T) {
	e := copilot.SessionEvent{
		Data: &copilot.AssistantMessageDeltaData{
			MessageID:    "m1",
			DeltaContent: "hello",
		},
	}
	got := MapSessionEvent(e)
	require.NotNil(t, got)
	assert.Equal(t, task.EventAssistantDelta, got.Kind)
	assert.Equal(t, "hello", got.Payload)
}

func TestMapSessionEvent_ReasoningDelta(t *testing.T) {
	e := copilot.SessionEvent{
		Data: &copilot.AssistantReasoningDeltaData{
			ReasoningID:  "r1",
			DeltaContent: "thinking...",
		},
	}
	got := MapSessionEvent(e)
	require.NotNil(t, got)
	assert.Equal(t, task.EventAssistantReasoningDelta, got.Kind)
	assert.Equal(t, "thinking...", got.Payload)
}

func TestMapSessionEvent_ToolStart(t *testing.T) {
	e := copilot.SessionEvent{
		Data: &copilot.ToolExecutionStartData{
			ToolCallID: "tc1",
			ToolName:   "write_file",
		},
	}
	got := MapSessionEvent(e)
	require.NotNil(t, got)
	assert.Equal(t, task.EventToolStart, got.Kind)
	assert.Contains(t, got.Payload, "write_file")
}

func TestMapSessionEvent_ToolEnd(t *testing.T) {
	e := copilot.SessionEvent{
		Data: &copilot.ToolExecutionCompleteData{
			ToolCallID: "tc1",
			Success:    true,
		},
	}
	got := MapSessionEvent(e)
	require.NotNil(t, got)
	assert.Equal(t, task.EventToolEnd, got.Kind)
	assert.Contains(t, got.Payload, `"ok":true`)
}

func TestMapSessionEvent_AssistantMessage_NonEmpty(t *testing.T) {
	e := copilot.SessionEvent{
		Data: &copilot.AssistantMessageData{
			MessageID: "m1",
			Content:   "final answer",
		},
	}
	got := MapSessionEvent(e)
	require.NotNil(t, got)
	assert.Equal(t, task.EventAssistantDelta, got.Kind)
	assert.Equal(t, "final answer", got.Payload)
}

func TestMapSessionEvent_AssistantMessage_Empty(t *testing.T) {
	e := copilot.SessionEvent{
		Data: &copilot.AssistantMessageData{MessageID: "m1", Content: ""},
	}
	got := MapSessionEvent(e)
	assert.Nil(t, got, "empty assistant message must be suppressed")
}

func TestMapSessionEvent_SessionIdle_ReturnsNil(t *testing.T) {
	e := copilot.SessionEvent{Data: &copilot.SessionIdleData{}}
	got := MapSessionEvent(e)
	assert.Nil(t, got, "SessionIdle is handled by the runner, not MapSessionEvent")
}

func TestMapSessionEvent_SessionError(t *testing.T) {
	e := copilot.SessionEvent{
		Data: &copilot.SessionErrorData{
			ErrorType: "authentication",
			Message:   "token expired",
		},
	}
	got := MapSessionEvent(e)
	require.NotNil(t, got)
	assert.Equal(t, task.EventError, got.Kind)
	assert.Contains(t, got.Payload, "token expired")
}

func TestMapSessionEvent_Unknown_ReturnsNil(t *testing.T) {
	e := copilot.SessionEvent{Data: &copilot.RawSessionEventData{}}
	got := MapSessionEvent(e)
	assert.Nil(t, got)
}

func delta(id, s string) copilot.SessionEvent {
	return copilot.SessionEvent{Data: &copilot.AssistantMessageDeltaData{
		MessageID: id, DeltaContent: s,
	}}
}

func TestSessionMapper_PartialLineNotEmitted(t *testing.T) {
	m := NewSessionMapper()
	got := m.Map(delta("m1", "hello"))
	assert.Empty(t, got, "a chunk without LF must not emit — it is buffered")
}

func TestSessionMapper_SingleLineAcrossChunks(t *testing.T) {
	m := NewSessionMapper()
	assert.Empty(t, m.Map(delta("m1", "hel")))
	assert.Empty(t, m.Map(delta("m1", "lo")))
	got := m.Map(delta("m1", " world\n"))
	require.Len(t, got, 1)
	assert.Equal(t, task.EventAssistantDelta, got[0].Kind)
	assert.Equal(t, "hello world", got[0].Payload, "LF terminator must be stripped")
}

func TestSessionMapper_MultipleLinesInOneChunk(t *testing.T) {
	m := NewSessionMapper()
	got := m.Map(delta("m1", "line1\nline2\nline3\n"))
	require.Len(t, got, 3)
	assert.Equal(t, "line1", got[0].Payload)
	assert.Equal(t, "line2", got[1].Payload)
	assert.Equal(t, "line3", got[2].Payload)
}

func TestSessionMapper_PartialTailKeptForNextChunk(t *testing.T) {
	m := NewSessionMapper()
	got := m.Map(delta("m1", "line1\nlin"))
	require.Len(t, got, 1)
	assert.Equal(t, "line1", got[0].Payload)

	got = m.Map(delta("m1", "e2\n"))
	require.Len(t, got, 1)
	assert.Equal(t, "line2", got[0].Payload)
}

func TestSessionMapper_CRLFStripped(t *testing.T) {
	m := NewSessionMapper()
	got := m.Map(delta("m1", "windows line\r\nnext\r\n"))
	require.Len(t, got, 2)
	assert.Equal(t, "windows line", got[0].Payload)
	assert.Equal(t, "next", got[1].Payload)
}

func TestSessionMapper_BlankLinePreserved(t *testing.T) {
	m := NewSessionMapper()
	got := m.Map(delta("m1", "a\n\nb\n"))
	require.Len(t, got, 3)
	assert.Equal(t, "a", got[0].Payload)
	assert.Equal(t, "", got[1].Payload, "blank line must be preserved")
	assert.Equal(t, "b", got[2].Payload)
}

func TestSessionMapper_FlushEmitsResidual(t *testing.T) {
	m := NewSessionMapper()
	assert.Empty(t, m.Map(delta("m1", "partial tail no LF")))
	got := m.Flush()
	require.Len(t, got, 1)
	assert.Equal(t, task.EventAssistantDelta, got[0].Kind)
	assert.Equal(t, "partial tail no LF", got[0].Payload)

	assert.Empty(t, m.Flush(), "second flush is empty — buffer was cleared")
}

func TestSessionMapper_ReasoningBufferedSeparately(t *testing.T) {
	m := NewSessionMapper()
	reasoning := func(id, s string) copilot.SessionEvent {
		return copilot.SessionEvent{Data: &copilot.AssistantReasoningDeltaData{
			ReasoningID: id, DeltaContent: s,
		}}
	}
	assert.Empty(t, m.Map(delta("m1", "msg ")))
	assert.Empty(t, m.Map(reasoning("r1", "think ")))
	got := m.Map(delta("m1", "done\n"))
	require.Len(t, got, 1)
	assert.Equal(t, task.EventAssistantDelta, got[0].Kind)
	assert.Equal(t, "msg done", got[0].Payload)

	got = m.Map(reasoning("r1", "hard\n"))
	require.Len(t, got, 1)
	assert.Equal(t, task.EventAssistantReasoningDelta, got[0].Kind)
	assert.Equal(t, "think hard", got[0].Payload)
}

func TestSessionMapper_AssistantMessageDropsResidual(t *testing.T) {
	m := NewSessionMapper()
	assert.Empty(t, m.Map(delta("m1", "streamed prefix")))
	got := m.Map(copilot.SessionEvent{Data: &copilot.AssistantMessageData{
		MessageID: "m1",
		Content:   "streamed prefix and the rest",
	}})
	require.Len(t, got, 1)
	assert.Equal(t, "streamed prefix and the rest", got[0].Payload,
		"snapshot supersedes residual buffer — no prefix duplicate")

	assert.Empty(t, m.Flush(), "buffer for m1 was dropped by the snapshot")
}

func TestSessionMapper_SessionErrorFlushesFirst(t *testing.T) {
	m := NewSessionMapper()
	assert.Empty(t, m.Map(delta("m1", "tail no LF")))
	got := m.Map(copilot.SessionEvent{Data: &copilot.SessionErrorData{
		Message: "boom",
	}})
	require.Len(t, got, 2, "residual line must be emitted before the error")
	assert.Equal(t, task.EventAssistantDelta, got[0].Kind)
	assert.Equal(t, "tail no LF", got[0].Payload)
	assert.Equal(t, task.EventError, got[1].Kind)
	assert.Contains(t, got[1].Payload, "boom")
}

func TestSessionMapper_PassThroughNonDelta(t *testing.T) {
	m := NewSessionMapper()
	got := m.Map(copilot.SessionEvent{Data: &copilot.ToolExecutionStartData{
		ToolCallID: "tc1", ToolName: "write_file",
	}})
	require.Len(t, got, 1)
	assert.Equal(t, task.EventToolStart, got[0].Kind)

	got = m.Map(copilot.SessionEvent{Data: &copilot.SessionIdleData{}})
	assert.Empty(t, got, "SessionIdle passes through as nil — runner flushes explicitly")
}
