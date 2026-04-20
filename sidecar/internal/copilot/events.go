//go:build windows

package copilot

import (
	"encoding/json"
	"fmt"
	"strings"

	"github.com/FleetKanban/fleetkanban/internal/task"
	copilot "github.com/github/copilot-sdk/go"
)

// MapSessionEvent converts a SDK SessionEvent to a task.AgentEvent, returning
// nil when the SDK event carries no information useful to the orchestrator
// (e.g. ephemeral telemetry events).
//
// This is a pure function: no I/O, no side effects — easy to unit-test.
func MapSessionEvent(e copilot.SessionEvent) *task.AgentEvent {
	switch d := e.Data.(type) {

	case *copilot.AssistantMessageDeltaData:
		return &task.AgentEvent{
			Kind:    task.EventAssistantDelta,
			Payload: d.DeltaContent,
		}

	case *copilot.AssistantReasoningDeltaData:
		return &task.AgentEvent{
			Kind:    task.EventAssistantReasoningDelta,
			Payload: d.DeltaContent,
		}

	case *copilot.ToolExecutionStartData:
		return &task.AgentEvent{
			Kind:    task.EventToolStart,
			Payload: mustJSON(map[string]any{"name": d.ToolName, "id": d.ToolCallID}),
		}

	case *copilot.ToolExecutionCompleteData:
		return &task.AgentEvent{
			Kind:    task.EventToolEnd,
			Payload: mustJSON(map[string]any{"name": toolName(d), "id": d.ToolCallID, "ok": d.Success}),
		}

	case *copilot.AssistantMessageData:
		// Final complete message — emit as a delta so the UI can display it
		// when streaming is not available or when a final snapshot is needed.
		if d.Content == "" {
			return nil
		}
		return &task.AgentEvent{
			Kind:    task.EventAssistantDelta,
			Payload: d.Content,
		}

	case *copilot.SessionIdleData:
		// SessionIdle signals the agentic loop is done. Aborted sessions are
		// handled by the runner's error path; the event itself is not emitted
		// here — the runner emits EventSessionIdle after Send returns.
		return nil

	case *copilot.SessionErrorData:
		return &task.AgentEvent{
			Kind:    task.EventError,
			Payload: fmt.Sprintf("session error: %s", sessionErrMsg(d)),
		}

	default:
		return nil
	}
}

// toolName extracts the tool name from a ToolExecutionCompleteData. The SDK
// does not echo the tool name in the complete event, so we use ToolCallID as
// fallback when a name is not available.
func toolName(d *copilot.ToolExecutionCompleteData) string {
	// ToolExecutionCompleteData carries ToolCallID but not ToolName; the runner
	// maintains a map from call-ID to name. For now emit the call ID — the
	// frontend can correlate with the matching tool.start event.
	return d.ToolCallID
}

// sessionErrMsg extracts a human-readable message from a SessionErrorData.
func sessionErrMsg(d *copilot.SessionErrorData) string {
	if d.Message != "" {
		return d.Message
	}
	b, _ := json.Marshal(d)
	return string(b)
}

// mustJSON encodes v or panics — only used with primitive map literals.
func mustJSON(v any) string {
	b, err := json.Marshal(v)
	if err != nil {
		panic("copilot: JSON encode: " + err.Error())
	}
	return string(b)
}

// SessionMapper wraps MapSessionEvent with per-session line-buffering state
// for streamed delta events. The underlying SDK fires Assistant*Delta events
// at token granularity (often a handful of characters), which — piped through
// the UI as one event = one line — produces a shredded log. The mapper
// accumulates delta content per MessageID / ReasoningID and emits one
// AgentEvent per LF-terminated line, so the UI renders real lines.
//
// Not safe for concurrent use. The Copilot SDK invokes the On handler
// serially, which is the only intended caller.
type SessionMapper struct {
	msgBufs       map[string]*strings.Builder
	reasoningBufs map[string]*strings.Builder
}

// NewSessionMapper returns a mapper with empty buffers.
func NewSessionMapper() *SessionMapper {
	return &SessionMapper{
		msgBufs:       map[string]*strings.Builder{},
		reasoningBufs: map[string]*strings.Builder{},
	}
}

// Map returns zero or more AgentEvents for e. Delta events are buffered and
// yield one event per completed line; non-delta events pass through. A
// SessionError first drains any residual partial lines so trailing output
// appears before the error.
func (m *SessionMapper) Map(e copilot.SessionEvent) []*task.AgentEvent {
	switch d := e.Data.(type) {
	case *copilot.AssistantMessageDeltaData:
		return m.pumpLines(m.msgBufs, d.MessageID, d.DeltaContent, task.EventAssistantDelta)

	case *copilot.AssistantReasoningDeltaData:
		return m.pumpLines(m.reasoningBufs, d.ReasoningID, d.DeltaContent, task.EventAssistantReasoningDelta)

	case *copilot.AssistantMessageData:
		// Final snapshot supersedes any residual buffered delta for this
		// MessageID — dropping it avoids emitting a prefix of Content twice.
		delete(m.msgBufs, d.MessageID)
		if ae := MapSessionEvent(e); ae != nil {
			return []*task.AgentEvent{ae}
		}
		return nil

	case *copilot.SessionErrorData:
		out := m.Flush()
		if ae := MapSessionEvent(e); ae != nil {
			out = append(out, ae)
		}
		return out

	default:
		if ae := MapSessionEvent(e); ae != nil {
			return []*task.AgentEvent{ae}
		}
		return nil
	}
}

// Flush emits any residual partial lines as final delta events and clears
// all buffers. Callers must invoke Flush at session end (idle / cancel) so
// trailing output that never received an LF still reaches the UI.
func (m *SessionMapper) Flush() []*task.AgentEvent {
	var out []*task.AgentEvent
	out = drainBufs(out, m.msgBufs, task.EventAssistantDelta)
	out = drainBufs(out, m.reasoningBufs, task.EventAssistantReasoningDelta)
	return out
}

func (m *SessionMapper) pumpLines(bufs map[string]*strings.Builder, id, content string, kind task.EventKind) []*task.AgentEvent {
	if content == "" {
		return nil
	}
	b, ok := bufs[id]
	if !ok {
		b = &strings.Builder{}
		bufs[id] = b
	}
	b.WriteString(content)
	s := b.String()
	idx := strings.LastIndexByte(s, '\n')
	if idx < 0 {
		return nil
	}
	complete := s[:idx]
	tail := s[idx+1:]
	b.Reset()
	b.WriteString(tail)

	lines := strings.Split(complete, "\n")
	out := make([]*task.AgentEvent, 0, len(lines))
	for _, line := range lines {
		out = append(out, &task.AgentEvent{
			Kind:    kind,
			Payload: strings.TrimRight(line, "\r"),
		})
	}
	return out
}

func drainBufs(out []*task.AgentEvent, bufs map[string]*strings.Builder, kind task.EventKind) []*task.AgentEvent {
	for id, b := range bufs {
		if b.Len() > 0 {
			out = append(out, &task.AgentEvent{
				Kind:    kind,
				Payload: strings.TrimRight(b.String(), "\r"),
			})
		}
		delete(bufs, id)
	}
	return out
}
