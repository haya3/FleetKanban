//go:build windows

package ihr

import (
	"context"
	"fmt"
	"log/slog"
)

// Runtime is injected into Orchestrator in the Phase B integration step.
// Drive returns the next stage for a task given the current state; the
// orchestrator performs the actual stage execution and calls back via
// StageCallbacks.
type Runtime struct {
	charter *Charter
	log     *slog.Logger
}

// NewRuntime constructs a Runtime from a pre-parsed Charter. log may be nil,
// in which case slog.Default() is used.
func NewRuntime(charter *Charter, log *slog.Logger) *Runtime {
	if log == nil {
		log = slog.Default()
	}
	return &Runtime{
		charter: charter,
		log:     log.With("component", "ihr"),
	}
}

// Charter exposes the parsed charter for callers that need contract or stage
// metadata (e.g. HarnessService.Validate reuses this).
func (r *Runtime) Charter() *Charter {
	return r.charter
}

// NextStage is a thin wrapper around Charter.NextStage that also logs the
// decision at debug level for post-mortem analysis.
func (r *Runtime) NextStage(ctx context.Context, s StageState) (string, bool, error) {
	next, terminal, err := r.charter.NextStage(s)
	if err != nil {
		r.log.DebugContext(ctx, "ihr: transition evaluation failed",
			"current_stage", s.CurrentStage,
			"rework_count", s.ReworkCount,
			"decision", s.Decision,
			"error", err,
		)
		return "", false, fmt.Errorf("ihr: Runtime.NextStage: %w", err)
	}
	r.log.DebugContext(ctx, "ihr: stage transition resolved",
		"from", s.CurrentStage,
		"to", next,
		"terminal", terminal,
		"rework_count", s.ReworkCount,
		"decision", s.Decision,
	)
	return next, terminal, nil
}
