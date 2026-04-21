package store

import (
	"context"
	"database/sql"
	"fmt"

	"github.com/haya3/FleetKanban/internal/ctxmem"
)

// SettingsStore persists per-repo ctxmem.Settings.
type SettingsStore struct{ db DB }

// Get returns the settings for a repo, creating a default row on the
// fly if none exists. Default is Enabled=false so Memory contributes
// nothing until the user opts in.
func (s *SettingsStore) Get(ctx context.Context, repoID string) (ctxmem.Settings, error) {
	set, err := s.fetch(ctx, repoID)
	if err == ctxmem.ErrNotFound {
		defaults := ctxmem.DefaultSettings(repoID)
		if err := s.Save(ctx, defaults); err != nil {
			return ctxmem.Settings{}, err
		}
		return s.fetch(ctx, repoID)
	}
	return set, err
}

// Save writes (insert or replace) the settings. Callers are expected
// to load → mutate → save; individual field patches go through the
// same path for simplicity.
func (s *SettingsStore) Save(ctx context.Context, set ctxmem.Settings) error {
	if set.RepoID == "" {
		return fmt.Errorf("%w: settings require repo_id", ctxmem.ErrInvalidArg)
	}
	if set.EmbeddingProvider == "" {
		set.EmbeddingProvider = "ollama"
	}
	if set.EmbeddingModel == "" {
		set.EmbeddingModel = "nomic-embed-text"
	}
	if set.EmbeddingDim <= 0 {
		set.EmbeddingDim = 768
	}
	if set.LLMProvider == "" {
		set.LLMProvider = "openai"
	}
	if set.LLMModel == "" {
		set.LLMModel = "gpt-4o-mini"
	}
	if set.PassiveTokenBudget <= 0 {
		set.PassiveTokenBudget = 3000
	}
	if set.TopKNeighbors <= 0 {
		set.TopKNeighbors = 8
	}
	if set.AutoPromoteThreshold <= 0 {
		set.AutoPromoteThreshold = 0.9
	}
	_, err := s.db.Write().ExecContext(ctx, `
INSERT INTO ctx_memory_settings(
    repo_id, enabled, embedding_provider, embedding_model, embedding_dim,
    llm_provider, llm_model, passive_token_budget, top_k_neighbors,
    auto_promote_high_confidence, auto_promote_threshold, updated_at
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
ON CONFLICT(repo_id) DO UPDATE SET
    enabled                      = excluded.enabled,
    embedding_provider           = excluded.embedding_provider,
    embedding_model              = excluded.embedding_model,
    embedding_dim                = excluded.embedding_dim,
    llm_provider                 = excluded.llm_provider,
    llm_model                    = excluded.llm_model,
    passive_token_budget         = excluded.passive_token_budget,
    top_k_neighbors              = excluded.top_k_neighbors,
    auto_promote_high_confidence = excluded.auto_promote_high_confidence,
    auto_promote_threshold       = excluded.auto_promote_threshold,
    updated_at                   = excluded.updated_at`,
		set.RepoID, boolToInt(set.Enabled), set.EmbeddingProvider, set.EmbeddingModel, set.EmbeddingDim,
		set.LLMProvider, set.LLMModel, set.PassiveTokenBudget, set.TopKNeighbors,
		boolToInt(set.AutoPromoteHighConfidence), set.AutoPromoteThreshold, nowUTC(),
	)
	if err != nil {
		return fmt.Errorf("ctxmem/store: save settings: %w", err)
	}
	return nil
}

func (s *SettingsStore) fetch(ctx context.Context, repoID string) (ctxmem.Settings, error) {
	var (
		set       ctxmem.Settings
		enabled   int
		autoPromo int
		threshold float64
		updatedAt string
	)
	row := s.db.Read().QueryRowContext(ctx, `
SELECT repo_id, enabled, embedding_provider, embedding_model, embedding_dim,
       llm_provider, llm_model, passive_token_budget, top_k_neighbors,
       auto_promote_high_confidence, auto_promote_threshold, updated_at
  FROM ctx_memory_settings WHERE repo_id = ?`, repoID)
	if err := row.Scan(
		&set.RepoID, &enabled, &set.EmbeddingProvider, &set.EmbeddingModel, &set.EmbeddingDim,
		&set.LLMProvider, &set.LLMModel, &set.PassiveTokenBudget, &set.TopKNeighbors,
		&autoPromo, &threshold, &updatedAt,
	); err != nil {
		if err == sql.ErrNoRows {
			return ctxmem.Settings{}, ctxmem.ErrNotFound
		}
		return ctxmem.Settings{}, fmt.Errorf("ctxmem/store: fetch settings: %w", err)
	}
	set.Enabled = enabled == 1
	set.AutoPromoteHighConfidence = autoPromo == 1
	set.AutoPromoteThreshold = float32(threshold)
	set.UpdatedAt = parseTime(updatedAt)
	return set, nil
}
