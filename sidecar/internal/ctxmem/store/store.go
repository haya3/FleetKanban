// Package store persists ctxmem domain objects to SQLite. It uses the
// same split read/write *sql.DB pair as the top-level store package
// (writes serialized through a single connection; reads pooled against
// WAL snapshots) so concurrent Context queries do not contend with
// Task / Subtask updates.
//
// The package intentionally exposes per-type stores (NodeStore,
// EdgeStore, ...) rather than one monolith so tests can instantiate
// only what they need. A Stores aggregate is provided for callers who
// need the whole set.
package store

import (
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/haya3/FleetKanban/internal/ctxmem"
)

// DB is the subset of *store.DB that ctxmem needs. Declared here so the
// package does not import the parent store package (which would be a
// sibling-package import).
type DB interface {
	Write() *sql.DB
	Read() *sql.DB
}

// Stores aggregates every per-type store against a single DB. Used by
// the ctxmem Service facade and by integration tests.
type Stores struct {
	Nodes      *NodeStore
	Edges      *EdgeStore
	Closure    *ClosureStore
	Facts      *FactStore
	Scratchpad *ScratchpadStore
	Vectors    *VectorStore
	FTS        *FTSStore
	Settings   *SettingsStore
}

// New returns a Stores aggregate wrapping db.
func New(db DB) *Stores {
	return &Stores{
		Nodes:      &NodeStore{db: db},
		Edges:      &EdgeStore{db: db},
		Closure:    &ClosureStore{db: db},
		Facts:      &FactStore{db: db},
		Scratchpad: &ScratchpadStore{db: db},
		Vectors:    &VectorStore{db: db},
		FTS:        &FTSStore{db: db},
		Settings:   &SettingsStore{db: db},
	}
}

// rfc3339Nano is the time format used for TEXT columns. Chosen so
// lexicographic order matches chronological order and sub-second
// precision survives the round-trip.
const rfc3339Nano = time.RFC3339Nano

func nowUTC() string { return time.Now().UTC().Format(rfc3339Nano) }

func formatTime(t time.Time) string {
	if t.IsZero() {
		return ""
	}
	return t.UTC().Format(rfc3339Nano)
}

func formatTimeNullable(t time.Time) sql.NullString {
	if t.IsZero() {
		return sql.NullString{}
	}
	return sql.NullString{Valid: true, String: t.UTC().Format(rfc3339Nano)}
}

func parseTime(s string) time.Time {
	if s == "" {
		return time.Time{}
	}
	t, err := time.Parse(rfc3339Nano, s)
	if err != nil {
		// Fall back to the non-nano format for legacy rows.
		t2, err2 := time.Parse(time.RFC3339, s)
		if err2 != nil {
			return time.Time{}
		}
		return t2
	}
	return t
}

func parseTimeNullable(s sql.NullString) time.Time {
	if !s.Valid {
		return time.Time{}
	}
	return parseTime(s.String)
}

func encodeAttrs(attrs map[string]string) (string, error) {
	if len(attrs) == 0 {
		return "{}", nil
	}
	b, err := json.Marshal(attrs)
	if err != nil {
		return "", fmt.Errorf("ctxmem/store: encode attrs: %w", err)
	}
	return string(b), nil
}

func decodeAttrs(raw string) (map[string]string, error) {
	if raw == "" || raw == "{}" {
		return map[string]string{}, nil
	}
	var out map[string]string
	if err := json.Unmarshal([]byte(raw), &out); err != nil {
		return nil, fmt.Errorf("ctxmem/store: decode attrs: %w", err)
	}
	if out == nil {
		out = map[string]string{}
	}
	return out, nil
}

func encodeStringSlice(values []string) (string, error) {
	if len(values) == 0 {
		return "[]", nil
	}
	b, err := json.Marshal(values)
	if err != nil {
		return "", fmt.Errorf("ctxmem/store: encode slice: %w", err)
	}
	return string(b), nil
}

func decodeStringSlice(raw string) ([]string, error) {
	if raw == "" || raw == "[]" {
		return nil, nil
	}
	var out []string
	if err := json.Unmarshal([]byte(raw), &out); err != nil {
		return nil, fmt.Errorf("ctxmem/store: decode slice: %w", err)
	}
	return out, nil
}

func boolToInt(b bool) int {
	if b {
		return 1
	}
	return 0
}

// buildPlaceholders returns "?,?,?" for n items, handy for IN clauses.
func buildPlaceholders(n int) string {
	if n <= 0 {
		return ""
	}
	return strings.TrimRight(strings.Repeat("?,", n), ",")
}

// translateError converts sql.ErrNoRows to ctxmem.ErrNotFound so the
// ipc layer can map it to NotFound without leaking database/sql details.
func translateError(err error) error {
	if errors.Is(err, sql.ErrNoRows) {
		return ctxmem.ErrNotFound
	}
	return err
}
