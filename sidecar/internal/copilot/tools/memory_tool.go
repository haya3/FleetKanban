//go:build windows

// Package tools contains the Copilot SDK tools FleetKanban registers on
// runner and reviewer sessions. Each tool is a thin adapter wrapping a
// sidecar service — memory_tool.go routes search_memory calls into the
// ctxmem layer — so agents can request information not already pushed
// into their prompt via Passive injection.
package tools

import (
	"context"

	copilot "github.com/github/copilot-sdk/go"
)

// SearchMemoryParams is the typed schema DefineTool auto-generates from
// the struct tags. Kept minimal: query text is the only required field.
// Limit is optional; the handler clamps it to a safe range so a
// hallucinated 500 cannot DoS the sidecar.
type SearchMemoryParams struct {
	Query string `json:"query" jsonschema:"Natural-language description of the context you need — a question, a file path, a topic."`
	Limit int    `json:"limit,omitempty" jsonschema:"Maximum items to return (default 6, max 12)."`
}

// MemorySearcher is the narrow interface the tool needs. Exactly one
// method, matching the copilot.MemoryInjector signature so a single
// Service can satisfy every hook in the copilot package.
type MemorySearcher interface {
	BuildReactiveForRunner(ctx context.Context, repoID, query string) string
}

// NewSearchMemoryTool builds the search_memory tool the agent can call
// mid-session to pull additional context from Graph Memory. repoID is
// captured at session-creation time so the agent cannot search another
// repository's memory — the tool is per-session.
func NewSearchMemoryTool(memory MemorySearcher, repoID string) copilot.Tool {
	return copilot.DefineTool[SearchMemoryParams, string](
		"search_memory",
		"Search the repository's Graph Memory for Decisions, Constraints, and related Concepts. Use when you need specific prior context the Passive block may have missed, such as an architectural decision, a binding constraint, or a historical choice that should shape the next edit.",
		func(p SearchMemoryParams, inv copilot.ToolInvocation) (string, error) {
			if memory == nil {
				return "(memory is not configured)", nil
			}
			if p.Limit <= 0 || p.Limit > 12 {
				p.Limit = 6
			}
			ctx := inv.TraceContext
			if ctx == nil {
				ctx = context.Background()
			}
			result := memory.BuildReactiveForRunner(ctx, repoID, p.Query)
			if result == "" {
				return "(no matching memory entries)", nil
			}
			return result, nil
		},
	)
}
