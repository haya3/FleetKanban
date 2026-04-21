package store

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"time"
)

// ErrNoSubtaskContext is returned by GetLatest when no row matches the
// requested subtask (either never executed under the v18 schema, or all
// rows have been cascade-deleted with the parent subtask). Distinct from
// sql.ErrNoRows so call sites can branch without leaking driver errors.
var ErrNoSubtaskContext = errors.New("store: subtask context not recorded")

// SubtaskContext captures the full prompt + injected context the Copilot
// runner saw for a single subtask execution. One row per (subtask_id,
// round) so rework iterations preserve their history: the UI Subtask
// Summary dialog joins on the subtask row and displays the latest round
// by default, with a round selector to step back through earlier runs.
//
// HarnessSkillVersionID may be empty when the active harness was the
// embedded fallback (no harness_skill_version row exists yet). The rest
// of the string fields are always populated: the store treats empty
// strings as valid content rather than nullable values, matching the
// column defaults.
type SubtaskContext struct {
	SubtaskID             string
	Round                 int
	HarnessSkillVersionID string
	// SystemPrompt is the exact content passed to the Copilot SDK's
	// SystemMessage (DefaultCodePrompt + output-language addendum).
	SystemPrompt string
	// UserPrompt is the first user-side MessageOptions.Prompt — memory
	// injection block + the rendered subtask prompt (plan summary, prior
	// summaries, role, title, planner-authored instruction).
	UserPrompt string
	// StagePromptTemplate is the raw template (DefaultCodePrompt) before
	// addenda are appended, so the UI can diff "what the user edited"
	// from "what we auto-appended".
	StagePromptTemplate string
	PlanSummary         string
	PriorSummaries      []string
	MemoryBlock         string
	OutputLanguage      string
	CreatedAt           time.Time
}

// SubtaskContextStore provides Upsert (runner write path) and GetLatest /
// Get (UI read path) over the subtask_context table.
type SubtaskContextStore struct{ db *DB }

// NewSubtaskContextStore wraps a DB with subtask-context helpers.
func NewSubtaskContextStore(db *DB) *SubtaskContextStore {
	return &SubtaskContextStore{db: db}
}

// Upsert persists the context snapshot for (subtask_id, round). Existing
// rows at the same primary key are overwritten — a given (subtask, round)
// pair only runs once per orchestrator pass, so any re-write indicates
// the runner retried the step and the newer prompt should replace the
// previous one.
//
// PriorSummaries is serialized as a JSON array so the column stays
// single-value and round-trippable; an empty slice serializes to "[]"
// rather than NULL to match the column's NOT NULL DEFAULT.
func (s *SubtaskContextStore) Upsert(ctx context.Context, c SubtaskContext) error {
	if c.SubtaskID == "" {
		return fmt.Errorf("subtask_context: subtask_id required")
	}
	if c.Round <= 0 {
		c.Round = 1
	}
	if c.CreatedAt.IsZero() {
		c.CreatedAt = time.Now().UTC()
	}
	priors := c.PriorSummaries
	if priors == nil {
		priors = []string{}
	}
	priorsJSON, err := json.Marshal(priors)
	if err != nil {
		return fmt.Errorf("subtask_context: encode prior summaries: %w", err)
	}
	var harnessID any
	if c.HarnessSkillVersionID != "" {
		harnessID = c.HarnessSkillVersionID
	}
	_, err = s.db.write.ExecContext(ctx, `
INSERT INTO subtask_context(
    subtask_id, round, harness_skill_version_id,
    system_prompt, user_prompt, stage_prompt_template,
    plan_summary, prior_summaries_json,
    memory_block, output_language, created_at
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
ON CONFLICT(subtask_id, round) DO UPDATE SET
    harness_skill_version_id = excluded.harness_skill_version_id,
    system_prompt            = excluded.system_prompt,
    user_prompt              = excluded.user_prompt,
    stage_prompt_template    = excluded.stage_prompt_template,
    plan_summary             = excluded.plan_summary,
    prior_summaries_json     = excluded.prior_summaries_json,
    memory_block             = excluded.memory_block,
    output_language          = excluded.output_language,
    created_at               = excluded.created_at`,
		c.SubtaskID, c.Round, harnessID,
		c.SystemPrompt, c.UserPrompt, c.StagePromptTemplate,
		c.PlanSummary, string(priorsJSON),
		c.MemoryBlock, c.OutputLanguage, formatTime(c.CreatedAt),
	)
	if err != nil {
		return fmt.Errorf("subtask_context: upsert: %w", err)
	}
	return nil
}

// GetLatest returns the most recent round for subtaskID, or
// ErrNoSubtaskContext when no row exists. The UI uses this as the
// default view; round-specific history goes through Get.
func (s *SubtaskContextStore) GetLatest(ctx context.Context, subtaskID string) (SubtaskContext, error) {
	row := s.db.read.QueryRowContext(ctx, `
SELECT subtask_id, round, COALESCE(harness_skill_version_id, ''),
       system_prompt, user_prompt, stage_prompt_template,
       plan_summary, prior_summaries_json,
       memory_block, output_language, created_at
  FROM subtask_context
 WHERE subtask_id = ?
 ORDER BY round DESC
 LIMIT 1`, subtaskID)
	return scanSubtaskContext(row)
}

// Get returns the row for (subtaskID, round) exactly. Returns
// ErrNoSubtaskContext when absent.
func (s *SubtaskContextStore) Get(ctx context.Context, subtaskID string, round int) (SubtaskContext, error) {
	row := s.db.read.QueryRowContext(ctx, `
SELECT subtask_id, round, COALESCE(harness_skill_version_id, ''),
       system_prompt, user_prompt, stage_prompt_template,
       plan_summary, prior_summaries_json,
       memory_block, output_language, created_at
  FROM subtask_context
 WHERE subtask_id = ? AND round = ?`, subtaskID, round)
	return scanSubtaskContext(row)
}

func scanSubtaskContext(row *sql.Row) (SubtaskContext, error) {
	var (
		c          SubtaskContext
		priorsJSON string
		createdAt  string
	)
	err := row.Scan(
		&c.SubtaskID, &c.Round, &c.HarnessSkillVersionID,
		&c.SystemPrompt, &c.UserPrompt, &c.StagePromptTemplate,
		&c.PlanSummary, &priorsJSON,
		&c.MemoryBlock, &c.OutputLanguage, &createdAt,
	)
	if errors.Is(err, sql.ErrNoRows) {
		return SubtaskContext{}, ErrNoSubtaskContext
	}
	if err != nil {
		return SubtaskContext{}, fmt.Errorf("subtask_context: scan: %w", err)
	}
	if priorsJSON != "" {
		if jerr := json.Unmarshal([]byte(priorsJSON), &c.PriorSummaries); jerr != nil {
			return SubtaskContext{}, fmt.Errorf("subtask_context: decode prior summaries: %w", jerr)
		}
	}
	t, terr := parseTime(createdAt)
	if terr != nil {
		return SubtaskContext{}, fmt.Errorf("subtask_context: parse created_at: %w", terr)
	}
	c.CreatedAt = t
	return c, nil
}
