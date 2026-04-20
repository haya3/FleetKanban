package task

// SessionUsage aggregates per-call usage metrics from one Copilot
// session into the totals the UI surfaces under each task / subtask /
// stage. Built up by the copilot runner from `assistant.usage` events
// (one per LLM call) and surfaced via the EventSessionUsage event so
// the UI can render premium-request consumption without re-querying
// the SDK.
//
// PremiumRequests is the sum of per-call Cost (the model's billing
// multiplier × 1 per call). For free models (multiplier = 0) this
// stays 0; for paid models it accumulates as the agent takes turns.
type SessionUsage struct {
	// Model identifier the session ran against. When the SDK reports
	// different models across calls (rare; usually only when the user
	// switches mid-session) the last seen value wins.
	Model string
	// Total premium request count for this session (sum of per-call Cost).
	// Float because the SDK reports fractional multipliers for some plans.
	PremiumRequests float64
	// Token totals across every LLM call in the session.
	InputTokens     int64
	OutputTokens    int64
	CacheReadTokens int64
	// Wall-clock time spent inside LLM API calls (sum of per-call
	// Duration). Excludes local tool execution / file I/O time, so
	// this is the user-attributable "model time" not the full
	// session wall-clock.
	DurationMs int64
	// Number of LLM calls (= agent turns) the session made.
	Calls int
}

// IsZero reports whether no usage was recorded — typically because the
// session was aborted before any LLM call landed, or the SDK
// suppressed usage events for a free-tier model. UI uses this to skip
// rendering a usage section that would only show zeros.
func (u SessionUsage) IsZero() bool {
	return u.PremiumRequests == 0 &&
		u.InputTokens == 0 && u.OutputTokens == 0 &&
		u.CacheReadTokens == 0 && u.DurationMs == 0 && u.Calls == 0
}
