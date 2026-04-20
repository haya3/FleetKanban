package store

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
)

// SettingsStore persists key/value application settings. The underlying
// column is `value_json` so any Go value the caller supplies is JSON-encoded
// on write and decoded on read. Keys are opaque; by convention FleetKanban
// uses dotted namespaces like `worktree.auto_sweep_merged_days`.
type SettingsStore struct{ db *DB }

// NewSettingsStore wraps a DB with settings-specific helpers.
func NewSettingsStore(db *DB) *SettingsStore { return &SettingsStore{db: db} }

// GetJSON reads the value stored under key and decodes it into dst (which
// must be a pointer). Returns (false, nil) when the key is absent so callers
// can fall back to a default without error handling.
func (s *SettingsStore) GetJSON(ctx context.Context, key string, dst any) (bool, error) {
	var raw string
	err := s.db.read.QueryRowContext(ctx,
		`SELECT value_json FROM settings WHERE key = ?`, key).Scan(&raw)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return false, nil
		}
		return false, fmt.Errorf("settings: get %q: %w", key, err)
	}
	if err := json.Unmarshal([]byte(raw), dst); err != nil {
		return false, fmt.Errorf("settings: decode %q: %w", key, err)
	}
	return true, nil
}

// SetJSON encodes value as JSON and upserts it under key. A nil value
// encodes as JSON null; to remove a key entirely, use Delete.
func (s *SettingsStore) SetJSON(ctx context.Context, key string, value any) error {
	raw, err := json.Marshal(value)
	if err != nil {
		return fmt.Errorf("settings: encode %q: %w", key, err)
	}
	if _, err := s.db.write.ExecContext(ctx, `
INSERT INTO settings(key, value_json) VALUES (?, ?)
ON CONFLICT(key) DO UPDATE SET value_json = excluded.value_json`,
		key, string(raw)); err != nil {
		return fmt.Errorf("settings: upsert %q: %w", key, err)
	}
	return nil
}

// Delete removes a setting. Absent keys are treated as success (no error).
func (s *SettingsStore) Delete(ctx context.Context, key string) error {
	if _, err := s.db.write.ExecContext(ctx,
		`DELETE FROM settings WHERE key = ?`, key); err != nil {
		return fmt.Errorf("settings: delete %q: %w", key, err)
	}
	return nil
}

// GetInt is a convenience for numeric keys. Returns (defaultValue, false, nil)
// when the key is absent; callers that care about "set to 0" vs "unset" should
// inspect the bool.
func (s *SettingsStore) GetInt(ctx context.Context, key string, defaultValue int) (int, bool, error) {
	var v int
	present, err := s.GetJSON(ctx, key, &v)
	if err != nil {
		return 0, false, err
	}
	if !present {
		return defaultValue, false, nil
	}
	return v, true, nil
}

// SetInt stores a numeric value.
func (s *SettingsStore) SetInt(ctx context.Context, key string, value int) error {
	return s.SetJSON(ctx, key, value)
}
