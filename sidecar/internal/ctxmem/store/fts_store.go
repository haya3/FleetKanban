package store

import (
	"context"
	"fmt"
)

// FTSStore wraps queries against the ctx_node_fts FTS5 virtual table.
// Writes to ctx_node are mirrored automatically by the migration's
// AFTER INSERT / UPDATE / DELETE triggers, so this store is read-only.
type FTSStore struct{ db DB }

// FTSHit is one BM25-ranked result. Score is the negated BM25 value
// (SQLite's bm25() returns a penalty; we flip it so higher = better).
type FTSHit struct {
	NodeID string
	Score  float32
}

// Search runs an FTS5 MATCH query against label + content_md, filtered
// by repo_id via the UNINDEXED column. Returns hits ordered by BM25
// descending (best-first).
func (s *FTSStore) Search(ctx context.Context, repoID, query string, limit int) ([]FTSHit, error) {
	if query == "" {
		return nil, nil
	}
	if limit <= 0 {
		limit = 50
	}
	sanitized := sanitizeFTSQuery(query)
	if sanitized == "" {
		return nil, nil
	}
	rows, err := s.db.Read().QueryContext(ctx, `
SELECT n.id, bm25(ctx_node_fts) AS score
  FROM ctx_node_fts f
  JOIN ctx_node    n ON n.rowid = f.rowid
 WHERE f.ctx_node_fts MATCH ?
   AND f.repo_id = ?
   AND n.enabled = 1
 ORDER BY score ASC
 LIMIT ?`, sanitized, repoID, limit)
	if err != nil {
		return nil, fmt.Errorf("ctxmem/store: fts search: %w", err)
	}
	defer rows.Close()
	var out []FTSHit
	for rows.Next() {
		var (
			id    string
			score float64
		)
		if err := rows.Scan(&id, &score); err != nil {
			return nil, err
		}
		// BM25 is a penalty (lower is better) — invert so higher score = better.
		out = append(out, FTSHit{NodeID: id, Score: -float32(score)})
	}
	return out, rows.Err()
}

// sanitizeFTSQuery escapes FTS5 operator characters that would
// otherwise blow up queries typed by users in the Search tab. We quote
// each whitespace-separated term; FTS5 treats quoted terms as literal
// phrases, which is the most predictable behavior for Browse-style
// lookup. This intentionally does not expose advanced FTS5 operators
// to the UI.
func sanitizeFTSQuery(q string) string {
	var out []byte
	inTerm := false
	term := make([]byte, 0, 32)
	flush := func() {
		if len(term) == 0 {
			return
		}
		if len(out) > 0 {
			out = append(out, ' ')
		}
		out = append(out, '"')
		out = append(out, term...)
		out = append(out, '"')
		term = term[:0]
	}
	for i := 0; i < len(q); i++ {
		c := q[i]
		if c == ' ' || c == '\t' || c == '\n' || c == '\r' {
			if inTerm {
				flush()
				inTerm = false
			}
			continue
		}
		// Drop FTS5 syntactic characters entirely.
		if c == '"' || c == '(' || c == ')' || c == ':' || c == '*' {
			continue
		}
		term = append(term, c)
		inTerm = true
	}
	if inTerm {
		flush()
	}
	return string(out)
}
