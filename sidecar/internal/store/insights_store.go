package store

import (
	"context"
	"database/sql"
	"fmt"
	"sort"
	"time"

	"github.com/FleetKanban/fleetkanban/internal/task"
)

// InsightsStore aggregates tasks-table statistics for the Insights pane.
//
// Every method is read-only and streams through the pooled read handle. The
// queries are designed to be index-friendly on updated_at / finished_at and
// to fit within a single round-trip per metric; GetSummary assembles the
// full dashboard snapshot in one call site so the UI does not have to chain
// four separate RPCs.
type InsightsStore struct{ db *DB }

// NewInsightsStore wraps a DB for Insights-specific aggregate queries.
func NewInsightsStore(db *DB) *InsightsStore { return &InsightsStore{db: db} }

// InsightsSummary is the domain-level payload for the Insights RPC. The
// ipc package converts it to protobuf in one step; nothing here depends on
// gRPC types so tests can assert against the plain struct.
type InsightsSummary struct {
	TotalTasks     int
	ActiveTasks    int // planning / queued / in_progress / *_review
	DoneTasks      int
	CancelledTasks int
	AbortedTasks   int
	FailedTasks    int

	CompletedSamples      int
	AvgDurationSeconds    float64
	MedianDurationSeconds float64
	P90DurationSeconds    float64

	ReworkBuckets   []ReworkBucket
	FailureBuckets  []FailureBucket
	Repositories    []RepositoryInsight
	DailyThroughput []DailyThroughput

	CompletionRate float64
}

type ReworkBucket struct {
	ReworkCount int
	TaskCount   int
}

type FailureBucket struct {
	ErrorCode string
	Count     int
}

type RepositoryInsight struct {
	RepositoryID       string
	DisplayName        string
	Total              int
	Done               int
	Failed             int
	Aborted            int
	Cancelled          int
	CompletionRate     float64
	AvgDurationSeconds float64
}

type DailyThroughput struct {
	Date      string // YYYY-MM-DD (UTC)
	Completed int
	Failed    int
}

// GetSummary computes the full dashboard snapshot. When repoID is empty the
// aggregation spans every registered repository and the Repositories slice
// is populated; otherwise the scope is the single repo and Repositories is
// left empty (the UI falls back to the top-level totals).
func (s *InsightsStore) GetSummary(ctx context.Context, repoID string) (*InsightsSummary, error) {
	out := &InsightsSummary{}

	// --- Status counts ----------------------------------------------------
	statusCounts, err := s.countByStatus(ctx, repoID)
	if err != nil {
		return nil, err
	}
	for st, n := range statusCounts {
		out.TotalTasks += n
		switch task.Status(st) {
		case task.StatusPlanning, task.StatusQueued, task.StatusInProgress,
			task.StatusAIReview, task.StatusHumanReview:
			out.ActiveTasks += n
		case task.StatusDone:
			out.DoneTasks += n
		case task.StatusCancelled:
			out.CancelledTasks += n
		case task.StatusAborted:
			out.AbortedTasks += n
		case task.StatusFailed:
			out.FailedTasks += n
		}
	}
	terminal := out.DoneTasks + out.FailedTasks + out.AbortedTasks + out.CancelledTasks
	if terminal > 0 {
		out.CompletionRate = float64(out.DoneTasks) / float64(terminal)
	}

	// --- Duration metrics -------------------------------------------------
	durations, err := s.durations(ctx, repoID)
	if err != nil {
		return nil, err
	}
	out.CompletedSamples = len(durations)
	if len(durations) > 0 {
		sort.Float64s(durations)
		var sum float64
		for _, d := range durations {
			sum += d
		}
		out.AvgDurationSeconds = sum / float64(len(durations))
		out.MedianDurationSeconds = percentile(durations, 50)
		out.P90DurationSeconds = percentile(durations, 90)
	}

	// --- Rework histogram -------------------------------------------------
	out.ReworkBuckets, err = s.reworkBuckets(ctx, repoID)
	if err != nil {
		return nil, err
	}

	// --- Failure breakdown ------------------------------------------------
	out.FailureBuckets, err = s.failureBuckets(ctx, repoID)
	if err != nil {
		return nil, err
	}

	// --- Per-repository rows (only when not scoped to one repo) -----------
	if repoID == "" {
		out.Repositories, err = s.repositoryBreakdown(ctx)
		if err != nil {
			return nil, err
		}
	}

	// --- 30-day throughput ------------------------------------------------
	out.DailyThroughput, err = s.dailyThroughput(ctx, repoID, 30)
	if err != nil {
		return nil, err
	}
	return out, nil
}

func (s *InsightsStore) countByStatus(ctx context.Context, repoID string) (map[string]int, error) {
	q := `SELECT status, COUNT(*) FROM tasks`
	var args []any
	if repoID != "" {
		q += ` WHERE repository_id = ?`
		args = append(args, repoID)
	}
	q += ` GROUP BY status`
	rows, err := s.db.read.QueryContext(ctx, q, args...)
	if err != nil {
		return nil, fmt.Errorf("insights: count by status: %w", err)
	}
	defer rows.Close()
	out := map[string]int{}
	for rows.Next() {
		var st string
		var n int
		if err := rows.Scan(&st, &n); err != nil {
			return nil, err
		}
		out[st] = n
	}
	return out, rows.Err()
}

// durations returns finished_at - started_at (seconds) for every task that
// actually ran to a terminal state with both timestamps set. Tasks without
// started_at (cancelled from queued) or without finished_at are skipped.
func (s *InsightsStore) durations(ctx context.Context, repoID string) ([]float64, error) {
	q := `
SELECT started_at, finished_at
  FROM tasks
 WHERE started_at IS NOT NULL
   AND finished_at IS NOT NULL`
	var args []any
	if repoID != "" {
		q += ` AND repository_id = ?`
		args = append(args, repoID)
	}
	rows, err := s.db.read.QueryContext(ctx, q, args...)
	if err != nil {
		return nil, fmt.Errorf("insights: durations: %w", err)
	}
	defer rows.Close()

	var out []float64
	for rows.Next() {
		var startedStr, finishedStr sql.NullString
		if err := rows.Scan(&startedStr, &finishedStr); err != nil {
			return nil, err
		}
		if !startedStr.Valid || !finishedStr.Valid {
			continue
		}
		started, err := parseTime(startedStr.String)
		if err != nil || started.IsZero() {
			continue
		}
		finished, err := parseTime(finishedStr.String)
		if err != nil || finished.IsZero() {
			continue
		}
		d := finished.Sub(started).Seconds()
		if d < 0 {
			// Clock skew or mutation race — ignore rather than skewing avg.
			continue
		}
		out = append(out, d)
	}
	return out, rows.Err()
}

func (s *InsightsStore) reworkBuckets(ctx context.Context, repoID string) ([]ReworkBucket, error) {
	q := `SELECT rework_count, COUNT(*) FROM tasks`
	var args []any
	if repoID != "" {
		q += ` WHERE repository_id = ?`
		args = append(args, repoID)
	}
	q += ` GROUP BY rework_count ORDER BY rework_count ASC`
	rows, err := s.db.read.QueryContext(ctx, q, args...)
	if err != nil {
		return nil, fmt.Errorf("insights: rework buckets: %w", err)
	}
	defer rows.Close()
	var out []ReworkBucket
	for rows.Next() {
		var rc, n int
		if err := rows.Scan(&rc, &n); err != nil {
			return nil, err
		}
		out = append(out, ReworkBucket{ReworkCount: rc, TaskCount: n})
	}
	return out, rows.Err()
}

func (s *InsightsStore) failureBuckets(ctx context.Context, repoID string) ([]FailureBucket, error) {
	q := `
SELECT error_code, COUNT(*)
  FROM tasks
 WHERE status = ? AND error_code <> ''`
	args := []any{string(task.StatusFailed)}
	if repoID != "" {
		q += ` AND repository_id = ?`
		args = append(args, repoID)
	}
	q += ` GROUP BY error_code ORDER BY COUNT(*) DESC`
	rows, err := s.db.read.QueryContext(ctx, q, args...)
	if err != nil {
		return nil, fmt.Errorf("insights: failure buckets: %w", err)
	}
	defer rows.Close()
	var out []FailureBucket
	for rows.Next() {
		var code string
		var n int
		if err := rows.Scan(&code, &n); err != nil {
			return nil, err
		}
		out = append(out, FailureBucket{ErrorCode: code, Count: n})
	}
	return out, rows.Err()
}

// repositoryBreakdown joins tasks onto repositories so rows include the
// display name even when a repo has zero tasks yet — those are filtered
// out here (total=0 rows add noise, not insight).
func (s *InsightsStore) repositoryBreakdown(ctx context.Context) ([]RepositoryInsight, error) {
	rows, err := s.db.read.QueryContext(ctx, `
SELECT r.id, r.display_name,
       COUNT(t.id)                                                  AS total,
       SUM(CASE WHEN t.status = 'done'      THEN 1 ELSE 0 END)      AS done,
       SUM(CASE WHEN t.status = 'failed'    THEN 1 ELSE 0 END)      AS failed,
       SUM(CASE WHEN t.status = 'aborted'   THEN 1 ELSE 0 END)      AS aborted,
       SUM(CASE WHEN t.status = 'cancelled' THEN 1 ELSE 0 END)      AS cancelled
  FROM repositories r
  LEFT JOIN tasks t ON t.repository_id = r.id
 GROUP BY r.id, r.display_name
 ORDER BY total DESC, r.display_name ASC`)
	if err != nil {
		return nil, fmt.Errorf("insights: repo breakdown: %w", err)
	}
	defer rows.Close()

	var out []RepositoryInsight
	for rows.Next() {
		var (
			id, name                       string
			total, done, failed, abt, canc sql.NullInt64
		)
		if err := rows.Scan(&id, &name, &total, &done, &failed, &abt, &canc); err != nil {
			return nil, err
		}
		if total.Int64 == 0 {
			continue
		}
		row := RepositoryInsight{
			RepositoryID: id,
			DisplayName:  name,
			Total:        int(total.Int64),
			Done:         int(done.Int64),
			Failed:       int(failed.Int64),
			Aborted:      int(abt.Int64),
			Cancelled:    int(canc.Int64),
		}
		terminal := row.Done + row.Failed + row.Aborted + row.Cancelled
		if terminal > 0 {
			row.CompletionRate = float64(row.Done) / float64(terminal)
		}
		out = append(out, row)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}

	// Average duration needs a second pass per repo. The N is small
	// (number of registered repos, typically < 20) so an in-memory join
	// is cheaper than an aggregate SQL query with julianday arithmetic —
	// and works the same way as the top-level duration computation.
	for i := range out {
		durs, derr := s.durations(ctx, out[i].RepositoryID)
		if derr != nil {
			return nil, derr
		}
		if len(durs) == 0 {
			continue
		}
		var sum float64
		for _, d := range durs {
			sum += d
		}
		out[i].AvgDurationSeconds = sum / float64(len(durs))
	}
	return out, nil
}

// dailyThroughput returns one DailyThroughput per day for the trailing
// `days` window (UTC), oldest first. Days with zero activity are included
// so the UI can draw a continuous series without gap handling.
func (s *InsightsStore) dailyThroughput(ctx context.Context, repoID string, days int) ([]DailyThroughput, error) {
	if days <= 0 {
		days = 30
	}
	// Compute the window boundary inline so we can filter both in SQL and
	// in the in-memory backfill below.
	now := time.Now().UTC()
	start := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, time.UTC).
		AddDate(0, 0, -(days - 1))

	q := `
SELECT substr(finished_at, 1, 10) AS day, status, COUNT(*)
  FROM tasks
 WHERE finished_at IS NOT NULL
   AND finished_at >= ?`
	args := []any{start.Format(timeFormat)}
	if repoID != "" {
		q += ` AND repository_id = ?`
		args = append(args, repoID)
	}
	q += ` GROUP BY day, status`
	rows, err := s.db.read.QueryContext(ctx, q, args...)
	if err != nil {
		return nil, fmt.Errorf("insights: daily throughput: %w", err)
	}
	defer rows.Close()

	type bucket struct{ completed, failed int }
	byDay := map[string]*bucket{}
	for rows.Next() {
		var day, status string
		var n int
		if err := rows.Scan(&day, &status, &n); err != nil {
			return nil, err
		}
		b := byDay[day]
		if b == nil {
			b = &bucket{}
			byDay[day] = b
		}
		switch task.Status(status) {
		case task.StatusDone:
			b.completed += n
		case task.StatusFailed, task.StatusAborted, task.StatusCancelled:
			b.failed += n
		}
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}

	out := make([]DailyThroughput, 0, days)
	for i := 0; i < days; i++ {
		day := start.AddDate(0, 0, i).Format("2006-01-02")
		d := DailyThroughput{Date: day}
		if b, ok := byDay[day]; ok {
			d.Completed = b.completed
			d.Failed = b.failed
		}
		out = append(out, d)
	}
	return out, nil
}

// percentile returns the p-th percentile (0..100) of a pre-sorted slice.
// Uses the nearest-rank method, which is enough for dashboard display and
// keeps the implementation obvious for reviewers.
func percentile(sorted []float64, p float64) float64 {
	if len(sorted) == 0 {
		return 0
	}
	if p <= 0 {
		return sorted[0]
	}
	if p >= 100 {
		return sorted[len(sorted)-1]
	}
	rank := int(p / 100 * float64(len(sorted)-1))
	return sorted[rank]
}
