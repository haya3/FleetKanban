package store

import (
	"context"
	"database/sql"
	"fmt"

	"github.com/haya3/FleetKanban/internal/ctxmem"
)

// FactStore persists ctxmem.Fact rows.
type FactStore struct{ db DB }

// Create inserts a new fact.
func (s *FactStore) Create(ctx context.Context, f ctxmem.Fact) error {
	if f.ID == "" || f.RepoID == "" || f.SubjectNodeID == "" || f.Predicate == "" {
		return fmt.Errorf("%w: fact requires id, repo_id, subject_node_id, predicate", ctxmem.ErrInvalidArg)
	}
	validFrom := formatTime(f.ValidFrom)
	if validFrom == "" {
		validFrom = nowUTC()
	}
	created := formatTime(f.CreatedAt)
	if created == "" {
		created = nowUTC()
	}
	_, err := s.db.Write().ExecContext(ctx, `
INSERT INTO ctx_fact(
    id, repo_id, subject_node_id, predicate, object_text,
    valid_from, valid_to, supersedes, created_at
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
		f.ID, f.RepoID, f.SubjectNodeID, f.Predicate, f.ObjectText,
		validFrom, formatTimeNullable(f.ValidTo), nullableString(f.Supersedes), created,
	)
	if err != nil {
		return fmt.Errorf("ctxmem/store: insert fact: %w", err)
	}
	return nil
}

// Expire sets valid_to on a fact, terminating its active interval.
// When supersededBy is non-empty, also inserts that value as
// ctx_fact.supersedes so the Timeline can link successors.
func (s *FactStore) Expire(ctx context.Context, factID string, validTo string) error {
	_, err := s.db.Write().ExecContext(ctx,
		`UPDATE ctx_fact SET valid_to = ? WHERE id = ?`, validTo, factID)
	return err
}

// FactFilter narrows ListFacts.
type FactFilter struct {
	RepoID         string
	SubjectNodeID  string
	IncludeExpired bool
	Limit          int
	Offset         int
}

// List returns facts matching the filter.
func (s *FactStore) List(ctx context.Context, f FactFilter) ([]ctxmem.Fact, int, error) {
	where := []string{"repo_id = ?"}
	args := []any{f.RepoID}
	if f.SubjectNodeID != "" {
		where = append(where, "subject_node_id = ?")
		args = append(args, f.SubjectNodeID)
	}
	if !f.IncludeExpired {
		where = append(where, "(valid_to IS NULL OR valid_to > ?)")
		args = append(args, nowUTC())
	}
	whereSQL := joinWhere(where)
	var total int
	if err := s.db.Read().QueryRowContext(ctx,
		`SELECT COUNT(*) FROM ctx_fact WHERE `+whereSQL, args...).Scan(&total); err != nil {
		return nil, 0, fmt.Errorf("ctxmem/store: count facts: %w", err)
	}
	limit := f.Limit
	if limit <= 0 {
		limit = 200
	}
	rows, err := s.db.Read().QueryContext(ctx, `
SELECT id, repo_id, subject_node_id, predicate, object_text,
       valid_from, valid_to, supersedes, created_at
  FROM ctx_fact WHERE `+whereSQL+`
 ORDER BY valid_from DESC
 LIMIT ? OFFSET ?`, append(args, limit, f.Offset)...)
	if err != nil {
		return nil, 0, fmt.Errorf("ctxmem/store: list facts: %w", err)
	}
	defer rows.Close()
	var out []ctxmem.Fact
	for rows.Next() {
		fact, err := scanFact(rows)
		if err != nil {
			return nil, 0, err
		}
		out = append(out, fact)
	}
	return out, total, rows.Err()
}

// CountActive returns the count of facts whose valid_to is either NULL
// or in the future. Used by Overview. COALESCE guards against SUM()
// returning NULL when the repo has no fact rows (e.g. fresh install).
func (s *FactStore) CountActive(ctx context.Context, repoID string) (active, expired int32, err error) {
	if err := s.db.Read().QueryRowContext(ctx, `
SELECT COALESCE(SUM(CASE WHEN valid_to IS NULL OR valid_to > ? THEN 1 ELSE 0 END), 0),
       COALESCE(SUM(CASE WHEN valid_to IS NOT NULL AND valid_to <= ? THEN 1 ELSE 0 END), 0)
  FROM ctx_fact WHERE repo_id = ?`, nowUTC(), nowUTC(), repoID).Scan(&active, &expired); err != nil {
		return 0, 0, fmt.Errorf("ctxmem/store: count active facts: %w", err)
	}
	return active, expired, nil
}

func scanFact(rows *sql.Rows) (ctxmem.Fact, error) {
	var (
		f          ctxmem.Fact
		validFrom  string
		validTo    sql.NullString
		supersedes sql.NullString
		createdAt  string
	)
	if err := rows.Scan(
		&f.ID, &f.RepoID, &f.SubjectNodeID, &f.Predicate, &f.ObjectText,
		&validFrom, &validTo, &supersedes, &createdAt,
	); err != nil {
		return ctxmem.Fact{}, err
	}
	f.ValidFrom = parseTime(validFrom)
	f.ValidTo = parseTimeNullable(validTo)
	if supersedes.Valid {
		f.Supersedes = supersedes.String
	}
	f.CreatedAt = parseTime(createdAt)
	return f, nil
}

func joinWhere(clauses []string) string {
	if len(clauses) == 0 {
		return "1=1"
	}
	s := clauses[0]
	for _, c := range clauses[1:] {
		s += " AND " + c
	}
	return s
}

func nullableString(s string) sql.NullString {
	if s == "" {
		return sql.NullString{}
	}
	return sql.NullString{Valid: true, String: s}
}
