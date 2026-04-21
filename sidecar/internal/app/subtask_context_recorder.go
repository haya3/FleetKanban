//go:build windows

package app

import (
	"context"
	"errors"
	"log/slog"

	"github.com/haya3/FleetKanban/internal/copilot"
	"github.com/haya3/FleetKanban/internal/store"
)

// subtaskContextRecorder implements copilot.SubtaskContextRecorder by
// persisting each snapshot into subtask_context and stamping the row
// with the active harness_skill_version at the time of the run.
//
// Declared in the app package (rather than copilot or store) because it
// needs both: copilot for the interface shape, store for the backing
// tables. The copilot package deliberately stays store-free to keep
// unit tests hermetic.
type subtaskContextRecorder struct {
	ctxStore     *store.SubtaskContextStore
	harnessStore *store.HarnessSkillStore
	log          *slog.Logger
}

// NewSubtaskContextRecorder wraps the two stores into a
// copilot.SubtaskContextRecorder. Pass the result to
// copilot.RuntimeConfig.ContextRecorder. Logger may be nil.
func NewSubtaskContextRecorder(
	ctxStore *store.SubtaskContextStore,
	harnessStore *store.HarnessSkillStore,
	logger *slog.Logger,
) copilot.SubtaskContextRecorder {
	if logger == nil {
		logger = slog.Default()
	}
	return &subtaskContextRecorder{
		ctxStore:     ctxStore,
		harnessStore: harnessStore,
		log:          logger,
	}
}

// RecordSubtaskContext resolves the active harness version (best-effort,
// empty on miss) and upserts a subtask_context row. Errors are logged
// but never returned — recording is observability, not a prerequisite
// for running the subtask, so a DB hiccup here must not kill the task.
func (r *subtaskContextRecorder) RecordSubtaskContext(ctx context.Context, snap copilot.SubtaskContextSnapshot) {
	var harnessID string
	if r.harnessStore != nil {
		latest, err := r.harnessStore.Latest(ctx)
		switch {
		case err == nil:
			harnessID = latest.ID
		case errors.Is(err, store.ErrNoSkillVersion):
			// No harness row yet — the runner is using the fallback
			// embedded prompt. Leave ID empty; the UI shows "embedded
			// default" for rows without a version link.
		default:
			r.log.Warn("subtask_context: fetch harness version",
				"subtask_id", snap.SubtaskID, "err", err)
		}
	}
	err := r.ctxStore.Upsert(ctx, store.SubtaskContext{
		SubtaskID:             snap.SubtaskID,
		Round:                 snap.Round,
		HarnessSkillVersionID: harnessID,
		SystemPrompt:          snap.SystemPrompt,
		UserPrompt:            snap.UserPrompt,
		StagePromptTemplate:   snap.StagePromptTemplate,
		PlanSummary:           snap.PlanSummary,
		PriorSummaries:        snap.PriorSummaries,
		MemoryBlock:           snap.MemoryBlock,
		OutputLanguage:        snap.OutputLanguage,
	})
	if err != nil {
		r.log.Warn("subtask_context: upsert",
			"subtask_id", snap.SubtaskID, "round", snap.Round, "err", err)
	}
}
