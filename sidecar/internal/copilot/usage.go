//go:build windows

package copilot

import (
	copilot "github.com/github/copilot-sdk/go"

	"github.com/haya3/FleetKanban/internal/task"
)

// usageAccumulator folds AssistantUsageData events from one Copilot
// session into a running task.SessionUsage total. Designed to be
// driven from session.On — not safe for concurrent calls (the SDK
// already serializes On invocations, so the accumulator inherits
// that guarantee).
//
// Built around AssistantUsageData rather than SessionShutdownData
// because shutdown's timing is fragile (it fires from inside
// Disconnect, which deferred cleanup paths run after we've already
// returned from the runner). assistant.usage events arrive
// in-stream during the agent loop, so accumulation is robust to
// abort / cancel / shutdown ordering quirks.
type usageAccumulator struct {
	u task.SessionUsage
}

// add folds one assistant.usage event into the running total.
func (a *usageAccumulator) add(d *copilot.AssistantUsageData) {
	if d == nil {
		return
	}
	if d.Model != "" {
		a.u.Model = d.Model
	}
	if d.Cost != nil {
		a.u.PremiumRequests += *d.Cost
	}
	if d.InputTokens != nil {
		a.u.InputTokens += int64(*d.InputTokens)
	}
	if d.OutputTokens != nil {
		a.u.OutputTokens += int64(*d.OutputTokens)
	}
	if d.CacheReadTokens != nil {
		a.u.CacheReadTokens += int64(*d.CacheReadTokens)
	}
	if d.Duration != nil {
		a.u.DurationMs += int64(*d.Duration)
	}
	a.u.Calls++
}

// snapshot returns a copy of the current usage total. Safe to call
// at any time after the session reaches idle.
func (a *usageAccumulator) snapshot() task.SessionUsage {
	return a.u
}
