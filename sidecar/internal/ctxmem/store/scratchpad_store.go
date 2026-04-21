package store

import (
	"context"
	"database/sql"
	"fmt"
	"time"

	"github.com/haya3/fleetkanban/internal/ctxmem"
)

// ScratchpadStore persists ctxmem.ScratchpadEntry rows.
type ScratchpadStore struct{ db DB }

// Create inserts a new pending entry.
func (s *ScratchpadStore) Create(ctx context.Context, e ctxmem.ScratchpadEntry) error {
	if e.ID == "" || e.RepoID == "" || e.ProposedKind == "" || e.ProposedLabel == "" || e.SourceKind == "" {
		return fmt.Errorf("%w: scratchpad requires id/repo/kind/label/source_kind", ctxmem.ErrInvalidArg)
	}
	attrs, err := encodeAttrs(e.ProposedAttrs)
	if err != nil {
		return err
	}
	signals, err := encodeStringSlice(e.Signals)
	if err != nil {
		return err
	}
	now := nowUTC()
	status := e.Status
	if status == "" {
		status = ctxmem.ScratchpadPending
	}
	confidence := e.Confidence
	if confidence <= 0 {
		confidence = 0.5
	}
	_, err = s.db.Write().ExecContext(ctx, `
INSERT INTO ctx_scratchpad(
    id, repo_id, proposed_kind, proposed_label, proposed_content_md,
    proposed_attrs_json, source_kind, source_ref, signals_json,
    confidence, status, reject_reason, snoozed_until,
    promoted_node_id, created_at, updated_at
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
		e.ID, e.RepoID, e.ProposedKind, e.ProposedLabel, e.ProposedContentMD,
		attrs, e.SourceKind, e.SourceRef, signals,
		confidence, status, e.RejectReason, formatTimeNullable(e.SnoozedUntil),
		nullableString(e.PromotedNodeID), now, now,
	)
	if err != nil {
		return fmt.Errorf("ctxmem/store: insert scratchpad: %w", err)
	}
	return nil
}

// Get fetches an entry by ID.
func (s *ScratchpadStore) Get(ctx context.Context, id string) (ctxmem.ScratchpadEntry, error) {
	row := s.db.Read().QueryRowContext(ctx, `
SELECT id, repo_id, proposed_kind, proposed_label, proposed_content_md,
       proposed_attrs_json, source_kind, source_ref, signals_json,
       confidence, status, reject_reason, snoozed_until,
       promoted_node_id, created_at, updated_at
  FROM ctx_scratchpad WHERE id = ?`, id)
	e, err := scanScratchpad(row)
	return e, translateError(err)
}

// ListFilter narrows ListPending.
type ScratchpadFilter struct {
	RepoID   string
	Statuses []string // empty → ["pending"]
	Limit    int
	Offset   int
}

// List returns pending entries for a repo.
func (s *ScratchpadStore) List(ctx context.Context, f ScratchpadFilter) ([]ctxmem.ScratchpadEntry, int, error) {
	statuses := f.Statuses
	if len(statuses) == 0 {
		statuses = []string{ctxmem.ScratchpadPending}
	}
	args := []any{f.RepoID}
	placeholders := buildPlaceholders(len(statuses))
	for _, st := range statuses {
		args = append(args, st)
	}
	whereSQL := "repo_id = ? AND status IN (" + placeholders + ")"

	var total int
	if err := s.db.Read().QueryRowContext(ctx,
		`SELECT COUNT(*) FROM ctx_scratchpad WHERE `+whereSQL, args...).Scan(&total); err != nil {
		return nil, 0, fmt.Errorf("ctxmem/store: count scratchpad: %w", err)
	}

	limit := f.Limit
	if limit <= 0 {
		limit = 200
	}
	rows, err := s.db.Read().QueryContext(ctx, `
SELECT id, repo_id, proposed_kind, proposed_label, proposed_content_md,
       proposed_attrs_json, source_kind, source_ref, signals_json,
       confidence, status, reject_reason, snoozed_until,
       promoted_node_id, created_at, updated_at
  FROM ctx_scratchpad WHERE `+whereSQL+`
 ORDER BY confidence DESC, updated_at DESC
 LIMIT ? OFFSET ?`, append(args, limit, f.Offset)...)
	if err != nil {
		return nil, 0, fmt.Errorf("ctxmem/store: list scratchpad: %w", err)
	}
	defer rows.Close()
	var out []ctxmem.ScratchpadEntry
	for rows.Next() {
		e, err := scanScratchpad(rows)
		if err != nil {
			return nil, 0, err
		}
		out = append(out, e)
	}
	return out, total, rows.Err()
}

// RecentlyRejectedLabels returns the set of labels the user has
// rejected in the last `window` for the given repo. Used by the
// observer to auto-snooze candidates whose label the user already
// declared uninteresting — avoids recreating the same pending card
// after every similar session.
func (s *ScratchpadStore) RecentlyRejectedLabels(ctx context.Context, repoID string, window time.Duration) (map[string]struct{}, error) {
	if repoID == "" {
		return nil, fmt.Errorf("%w: repo_id required", ctxmem.ErrInvalidArg)
	}
	cutoff := time.Now().UTC().Add(-window).Format(rfc3339Nano)
	rows, err := s.db.Read().QueryContext(ctx, `
SELECT DISTINCT proposed_label
  FROM ctx_scratchpad
 WHERE repo_id = ?
   AND status  = ?
   AND updated_at >= ?`, repoID, ctxmem.ScratchpadRejected, cutoff)
	if err != nil {
		return nil, fmt.Errorf("ctxmem/store: recently rejected labels: %w", err)
	}
	defer rows.Close()
	out := map[string]struct{}{}
	for rows.Next() {
		var label string
		if err := rows.Scan(&label); err != nil {
			return nil, err
		}
		out[label] = struct{}{}
	}
	return out, rows.Err()
}

// CountByStatus returns per-status counts used by Overview.
func (s *ScratchpadStore) CountByStatus(ctx context.Context, repoID string) (map[string]int32, error) {
	rows, err := s.db.Read().QueryContext(ctx, `
SELECT status, COUNT(*) FROM ctx_scratchpad
 WHERE repo_id = ? GROUP BY status`, repoID)
	if err != nil {
		return nil, fmt.Errorf("ctxmem/store: count scratchpad: %w", err)
	}
	defer rows.Close()
	out := map[string]int32{}
	for rows.Next() {
		var status string
		var n int32
		if err := rows.Scan(&status, &n); err != nil {
			return nil, err
		}
		out[status] = n
	}
	return out, rows.Err()
}

// MarkPromoted updates an entry's status to promoted and stores the
// resulting node id for audit trail.
func (s *ScratchpadStore) MarkPromoted(ctx context.Context, id, nodeID string) error {
	res, err := s.db.Write().ExecContext(ctx, `
UPDATE ctx_scratchpad
   SET status = ?, promoted_node_id = ?, updated_at = ?
 WHERE id = ? AND status IN (?, ?)`,
		ctxmem.ScratchpadPromoted, nodeID, nowUTC(),
		id, ctxmem.ScratchpadPending, ctxmem.ScratchpadSnoozed)
	if err != nil {
		return fmt.Errorf("ctxmem/store: mark promoted: %w", err)
	}
	rows, _ := res.RowsAffected()
	if rows == 0 {
		return ctxmem.ErrNotFound
	}
	return nil
}

// MarkRejected transitions an entry to rejected, recording the reason.
func (s *ScratchpadStore) MarkRejected(ctx context.Context, id, reason string) error {
	res, err := s.db.Write().ExecContext(ctx, `
UPDATE ctx_scratchpad
   SET status = ?, reject_reason = ?, updated_at = ?
 WHERE id = ?`,
		ctxmem.ScratchpadRejected, reason, nowUTC(), id)
	if err != nil {
		return fmt.Errorf("ctxmem/store: mark rejected: %w", err)
	}
	rows, _ := res.RowsAffected()
	if rows == 0 {
		return ctxmem.ErrNotFound
	}
	return nil
}

// Snooze sets the entry status to snoozed with snoozed_until.
func (s *ScratchpadStore) Snooze(ctx context.Context, id string, until string) error {
	res, err := s.db.Write().ExecContext(ctx, `
UPDATE ctx_scratchpad
   SET status = ?, snoozed_until = ?, updated_at = ?
 WHERE id = ?`,
		ctxmem.ScratchpadSnoozed, until, nowUTC(), id)
	if err != nil {
		return fmt.Errorf("ctxmem/store: snooze: %w", err)
	}
	rows, _ := res.RowsAffected()
	if rows == 0 {
		return ctxmem.ErrNotFound
	}
	return nil
}

// ApplyEdits updates the editable fields of a pending entry. Used by
// EditAndPromote before the promotion write.
func (s *ScratchpadStore) ApplyEdits(ctx context.Context, id, kind, label, content string, attrs map[string]string) error {
	attrsJSON, err := encodeAttrs(attrs)
	if err != nil {
		return err
	}
	_, err = s.db.Write().ExecContext(ctx, `
UPDATE ctx_scratchpad
   SET proposed_kind = COALESCE(NULLIF(?, ''), proposed_kind),
       proposed_label = COALESCE(NULLIF(?, ''), proposed_label),
       proposed_content_md = COALESCE(NULLIF(?, ''), proposed_content_md),
       proposed_attrs_json = ?,
       updated_at = ?
 WHERE id = ?`,
		kind, label, content, attrsJSON, nowUTC(), id)
	return err
}

type scratchpadScanner interface {
	Scan(dest ...any) error
}

func scanScratchpad(s scratchpadScanner) (ctxmem.ScratchpadEntry, error) {
	var (
		e            ctxmem.ScratchpadEntry
		attrsJSON    string
		signalsJSON  string
		snoozedUntil sql.NullString
		promotedID   sql.NullString
		confidence   float64
		createdAt    string
		updatedAt    string
	)
	if err := s.Scan(
		&e.ID, &e.RepoID, &e.ProposedKind, &e.ProposedLabel, &e.ProposedContentMD,
		&attrsJSON, &e.SourceKind, &e.SourceRef, &signalsJSON,
		&confidence, &e.Status, &e.RejectReason, &snoozedUntil,
		&promotedID, &createdAt, &updatedAt,
	); err != nil {
		return ctxmem.ScratchpadEntry{}, err
	}
	attrs, err := decodeAttrs(attrsJSON)
	if err != nil {
		return ctxmem.ScratchpadEntry{}, err
	}
	e.ProposedAttrs = attrs
	signals, err := decodeStringSlice(signalsJSON)
	if err != nil {
		return ctxmem.ScratchpadEntry{}, err
	}
	e.Signals = signals
	e.Confidence = float32(confidence)
	e.SnoozedUntil = parseTimeNullable(snoozedUntil)
	if promotedID.Valid {
		e.PromotedNodeID = promotedID.String
	}
	e.CreatedAt = parseTime(createdAt)
	e.UpdatedAt = parseTime(updatedAt)
	return e, nil
}
