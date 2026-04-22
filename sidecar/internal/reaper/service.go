//go:build windows

// Package reaper cleans up orphaned git worktrees and marks missing branches
// at startup. It is intended to run once after crash recovery and is
// non-fatal: errors are logged as warnings and the process continues.
//
// See docs/phase1-spec.md §3.1 and docs/architecture.md §4.1.
package reaper

import (
	"compress/gzip"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log/slog"
	"os"
	"path/filepath"
	"time"

	"github.com/oklog/ulid/v2"

	"github.com/haya3/FleetKanban/internal/store"
	"github.com/haya3/FleetKanban/internal/task"
	"github.com/haya3/FleetKanban/internal/worktree"
)

// ArchiveDefaultAge is the default cutoff for ArchiveOldEvents (phase1-spec
// §3.4): events belonging to terminal tasks older than this are gzipped and
// purged.
const ArchiveDefaultAge = 30 * 24 * time.Hour

// SettingAutoSweepMergedDays is the settings-store key for the Merged-sweep
// opt-in threshold (phase1-spec §3.1). The stored value is a positive
// integer representing days; 0 or unset disables the sweep.
const SettingAutoSweepMergedDays = "worktree.auto_sweep_merged_days"

// ReapStats summarises the outcome of a single ReapOnce / UpdateBranchExistence
// pass.
type ReapStats struct {
	Repositories          int
	WorktreesRemoved      int
	BranchesMarkedMissing int
}

// SweepStats summarises one SweepMergedBranches pass.
type SweepStats struct {
	Considered      int // tasks matched filter before merged-check
	BranchesDeleted int // -d succeeded
	BranchesSkipped int // -d refused (not merged to HEAD / locked / etc.)
}

// Config holds the dependencies for Service.
type Config struct {
	Repositories *store.RepositoryStore
	Tasks        *store.TaskStore
	Events       *store.EventStore
	Worktrees    *worktree.Manager
	// ArchiveDir is where ArchiveOldEvents writes gzipped JSON-lines files.
	// Typically %APPDATA%\FleetKanban\archive. Created on first write. If
	// empty, ArchiveOldEvents returns an error when called.
	ArchiveDir string
	// Publish is invoked after every housekeeping.branch_gc event the reaper
	// persists, so WatchEvents subscribers see branch-state changes live
	// instead of only via the next poll. Optional — when nil the event
	// still lands in the DB and TaskEvents() backfill works as usual, but
	// the Kanban UI will only refresh on the next mutation or reconnect.
	Publish func(*task.AgentEvent)
	Logger  *slog.Logger
}

// Service inspects registered repositories and removes orphaned worktrees or
// updates stale branch-existence flags.
type Service struct {
	repos      *store.RepositoryStore
	tasks      *store.TaskStore
	events     *store.EventStore
	wt         *worktree.Manager
	archiveDir string
	publish    func(*task.AgentEvent)
	logger     *slog.Logger
}

// New constructs a Service from cfg. Returns an error if a required dependency
// is nil.
func New(cfg Config) (*Service, error) {
	if cfg.Repositories == nil {
		return nil, errors.New("reaper: Repositories is required")
	}
	if cfg.Tasks == nil {
		return nil, errors.New("reaper: Tasks is required")
	}
	if cfg.Worktrees == nil {
		return nil, errors.New("reaper: Worktrees is required")
	}
	log := cfg.Logger
	if log == nil {
		log = slog.Default()
	}
	return &Service{
		repos:      cfg.Repositories,
		tasks:      cfg.Tasks,
		events:     cfg.Events,
		wt:         cfg.Worktrees,
		archiveDir: cfg.ArchiveDir,
		publish:    cfg.Publish,
		logger:     log,
	}, nil
}

// ReapOnce scans all registered repositories for fleetkanban/ worktrees that
// have no matching task in the DB and removes them. It returns accumulated
// stats and the first error encountered (subsequent repositories are still
// processed).
func (s *Service) ReapOnce(ctx context.Context) (ReapStats, error) {
	repos, err := s.repos.List(ctx)
	if err != nil {
		return ReapStats{}, fmt.Errorf("reaper: list repositories: %w", err)
	}

	var stats ReapStats
	var firstErr error

	for _, repo := range repos {
		stats.Repositories++
		if err := s.reapRepo(ctx, repo.Path, &stats); err != nil {
			s.logger.Warn("reaper: error processing repository",
				"repo", repo.Path, "err", err)
			if firstErr == nil {
				firstErr = err
			}
		}
	}
	return stats, firstErr
}

// reapRepo removes orphaned fleetkanban/ worktrees for a single repository.
func (s *Service) reapRepo(ctx context.Context, repoPath string, stats *ReapStats) error {
	infos, err := s.wt.List(ctx, repoPath)
	if err != nil {
		return fmt.Errorf("list worktrees for %q: %w", repoPath, err)
	}

	var firstErr error
	for _, info := range infos {
		if !info.IsTaskBranch() {
			continue
		}
		taskID := info.TaskID()
		_, err := s.tasks.Get(ctx, taskID)
		if err == nil {
			// Task exists in DB — leave the worktree intact.
			continue
		}
		if !errors.Is(err, store.ErrNotFound) {
			// Unexpected DB error; skip this worktree and keep going.
			s.logger.Warn("reaper: task DB lookup failed",
				"taskID", taskID, "err", err)
			if firstErr == nil {
				firstErr = err
			}
			continue
		}
		// Task is not in the DB → orphan; delete worktree and branch.
		s.logger.Info("reaper: removing orphan worktree",
			"taskID", taskID, "path", info.Path)
		if rmErr := s.wt.Remove(ctx, repoPath, info.Path, taskID, worktree.DeleteBranch); rmErr != nil {
			s.logger.Warn("reaper: failed to remove orphan worktree",
				"taskID", taskID, "err", rmErr)
			if firstErr == nil {
				firstErr = rmErr
			}
			continue
		}
		stats.WorktreesRemoved++
	}
	return firstErr
}

// ArchiveStats summarises one ArchiveOldEvents run.
type ArchiveStats struct {
	TasksArchived int
	EventsPurged  int64
}

// ArchiveOldEvents scans tasks in terminal states (done / cancelled /
// failed / aborted) whose FinishedAt is older than olderThan, writes their
// events to a gzipped JSON-lines file under ArchiveDir, and purges the rows
// from SQLite. Finally runs PRAGMA incremental_vacuum to reclaim pages.
//
// Partial failures are logged but do not abort the pass: the archiver
// continues to the next task so a single disk error does not starve the
// whole cleanup. Returns stats and the first error seen.
//
// Passing olderThan == 0 uses ArchiveDefaultAge.
func (s *Service) ArchiveOldEvents(ctx context.Context, olderThan time.Duration) (ArchiveStats, error) {
	if olderThan <= 0 {
		olderThan = ArchiveDefaultAge
	}
	if s.events == nil {
		return ArchiveStats{}, errors.New("reaper: EventStore not configured")
	}
	if s.archiveDir == "" {
		return ArchiveStats{}, errors.New("reaper: ArchiveDir not configured")
	}
	if err := os.MkdirAll(s.archiveDir, 0o755); err != nil {
		return ArchiveStats{}, fmt.Errorf("reaper: mkdir archive dir: %w", err)
	}

	terminal := []task.Status{
		task.StatusDone, task.StatusCancelled,
		task.StatusFailed, task.StatusAborted,
	}
	tasks, err := s.tasks.List(ctx, store.ListFilter{Statuses: terminal})
	if err != nil {
		return ArchiveStats{}, fmt.Errorf("reaper: list terminal tasks: %w", err)
	}

	cutoff := time.Now().UTC().Add(-olderThan)
	var (
		stats    ArchiveStats
		firstErr error
	)
	for _, t := range tasks {
		if t.FinishedAt == nil || t.FinishedAt.After(cutoff) {
			continue
		}
		n, err := s.archiveOneTask(ctx, t.ID)
		if err != nil {
			s.logger.Warn("reaper: archive task", "taskID", t.ID, "err", err)
			if firstErr == nil {
				firstErr = err
			}
			continue
		}
		stats.TasksArchived++
		stats.EventsPurged += n
	}

	if stats.EventsPurged > 0 {
		if err := s.events.IncrementalVacuum(ctx); err != nil {
			s.logger.Warn("reaper: incremental_vacuum", "err", err)
			if firstErr == nil {
				firstErr = err
			}
		}
	}
	return stats, firstErr
}

// archiveOneTask writes the task's events to a gzipped JSON-lines file and
// deletes them from SQLite. The delete is attempted only if the write
// succeeds; otherwise the events are left in place so the next pass can
// retry without losing data.
func (s *Service) archiveOneTask(ctx context.Context, taskID string) (int64, error) {
	events, err := s.events.ListByTask(ctx, taskID, 0, 0)
	if err != nil {
		return 0, fmt.Errorf("list events: %w", err)
	}
	if len(events) == 0 {
		return 0, nil
	}

	name := fmt.Sprintf("events_%s_%s.jsonl.gz", taskID, time.Now().UTC().Format("20060102T150405Z"))
	path := filepath.Join(s.archiveDir, name)
	tmpPath := path + ".tmp"

	f, err := os.Create(tmpPath)
	if err != nil {
		return 0, fmt.Errorf("create archive: %w", err)
	}
	gz := gzip.NewWriter(f)
	enc := json.NewEncoder(gz)
	for _, e := range events {
		if err := enc.Encode(e); err != nil {
			_ = gz.Close()
			_ = f.Close()
			_ = os.Remove(tmpPath)
			return 0, fmt.Errorf("encode event: %w", err)
		}
	}
	if err := gz.Close(); err != nil {
		_ = f.Close()
		_ = os.Remove(tmpPath)
		return 0, fmt.Errorf("close gzip: %w", err)
	}
	if err := f.Close(); err != nil {
		_ = os.Remove(tmpPath)
		return 0, fmt.Errorf("close file: %w", err)
	}
	if err := os.Rename(tmpPath, path); err != nil {
		_ = os.Remove(tmpPath)
		return 0, fmt.Errorf("rename archive: %w", err)
	}

	n, err := s.events.DeleteByTask(ctx, taskID)
	if err != nil {
		return 0, fmt.Errorf("delete after archive: %w", err)
	}
	s.logger.Info("reaper: archived events", "taskID", taskID, "count", n, "path", path)
	return n, nil
}

// sweepCandidateStatuses are the terminal-ish task states eligible for
// Merged-sweep. Aborted is included because the user may have walked away
// after external `git merge`; the branch still lingers in fleetkanban/*.
// Statuses where the branch was already removed by the app (Cancelled,
// Done-with-Merged) are excluded — branch_exists would be false anyway, but
// listing them explicitly documents intent.
var sweepCandidateStatuses = []task.Status{
	task.StatusDone,
	task.StatusAborted,
}

// SweepMergedBranches deletes fleetkanban/<id> branches that the user has
// integrated into their base branch outside the app (CLI / IDE / PR merge).
// See phase1-spec.md §3.1 "Branch retention policy / GC".
//
// Inclusion criteria, all must hold:
//
//  1. task.Status in {Done, Aborted}
//  2. task.BranchExists == true (skip already-removed branches)
//  3. task.FinishedAt is older than olderThan
//  4. `git merge-base --is-ancestor fleetkanban/<id> <base>` exits 0
//
// Deletion is always via `git branch -d` (fast-forward required). Callers
// that want to disable the feature should skip calling this method rather
// than passing olderThan <= 0 — we treat a non-positive olderThan as an
// error to catch caller bugs early.
//
// Per deleted branch:
//   - the task row is updated via SetBranchExists(false)
//   - a `housekeeping.branch_gc` event is appended to the task's event log
//
// Per-task errors do not abort the pass; the method returns stats plus the
// first error encountered.
func (s *Service) SweepMergedBranches(ctx context.Context, olderThan time.Duration) (SweepStats, error) {
	if olderThan <= 0 {
		return SweepStats{}, errors.New("reaper: SweepMergedBranches requires olderThan > 0")
	}

	tasks, err := s.tasks.List(ctx, store.ListFilter{Statuses: sweepCandidateStatuses})
	if err != nil {
		return SweepStats{}, fmt.Errorf("reaper: list sweep candidates: %w", err)
	}

	cutoff := time.Now().UTC().Add(-olderThan)
	repoCache := make(map[string]string) // repoID → path

	var (
		stats    SweepStats
		firstErr error
	)
	for _, t := range tasks {
		if t.Branch == "" || !t.BranchExists {
			continue
		}
		if t.BaseBranch == "" {
			// Without a base branch we can't verify merged-ness. Skip.
			continue
		}
		if t.FinishedAt == nil || t.FinishedAt.After(cutoff) {
			continue
		}

		repoPath, ok := repoCache[t.RepoID]
		if !ok {
			repo, err := s.repos.Get(ctx, t.RepoID)
			if err != nil {
				s.logger.Warn("reaper: sweep: repo lookup failed",
					"taskID", t.ID, "repoID", t.RepoID, "err", err)
				if firstErr == nil {
					firstErr = err
				}
				continue
			}
			repoCache[t.RepoID] = repo.Path
			repoPath = repo.Path
		}

		stats.Considered++

		merged, err := s.wt.IsBranchMerged(ctx, repoPath, t.Branch, t.BaseBranch)
		if err != nil {
			s.logger.Warn("reaper: sweep: is-ancestor failed",
				"taskID", t.ID, "branch", t.Branch, "base", t.BaseBranch, "err", err)
			if firstErr == nil {
				firstErr = err
			}
			continue
		}
		if !merged {
			stats.BranchesSkipped++
			continue
		}

		deleted, err := s.wt.DeleteBranchIfMerged(ctx, repoPath, t.Branch)
		if err != nil {
			s.logger.Warn("reaper: sweep: branch -d failed",
				"taskID", t.ID, "branch", t.Branch, "err", err)
			if firstErr == nil {
				firstErr = err
			}
			continue
		}
		if !deleted {
			// Git refused (branch not merged to HEAD, or in-use). Leave it;
			// a future sweep will retry once HEAD is on the base branch.
			stats.BranchesSkipped++
			continue
		}

		stats.BranchesDeleted++
		s.logger.Info("reaper: swept merged branch",
			"taskID", t.ID, "branch", t.Branch, "base", t.BaseBranch)

		if setErr := s.tasks.SetBranchExists(ctx, t.ID, false); setErr != nil {
			s.logger.Warn("reaper: sweep: SetBranchExists failed",
				"taskID", t.ID, "err", setErr)
			if firstErr == nil {
				firstErr = setErr
			}
		}
		if ev := s.events; ev != nil {
			if appendErr := s.appendSweepEvent(ctx, t, olderThan); appendErr != nil {
				s.logger.Warn("reaper: sweep: append audit event failed",
					"taskID", t.ID, "err", appendErr)
				if firstErr == nil {
					firstErr = appendErr
				}
			}
		}
	}
	return stats, firstErr
}

// appendSweepEvent records one housekeeping.branch_gc audit row for a
// successfully-swept branch. The payload is a small JSON object so the
// Housekeeping UI can render a readable log line.
func (s *Service) appendSweepEvent(ctx context.Context, t *task.Task, olderThan time.Duration) error {
	payload := struct {
		Branch    string `json:"branch"`
		Base      string `json:"base"`
		Reason    string `json:"reason"`
		OlderThan string `json:"older_than"`
	}{
		Branch:    t.Branch,
		Base:      t.BaseBranch,
		Reason:    "merged-sweep",
		OlderThan: olderThan.String(),
	}
	body, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("marshal sweep event: %w", err)
	}
	return s.emitBranchGC(ctx, t.ID, body)
}

// appendBranchExistsChangeEvent records a housekeeping.branch_gc event
// when UpdateBranchExistence flips the branch_exists flag. Payload reason
// is "missing" when the branch disappeared externally and "restored" when
// the user recreated it by hand — both cases need a live stream event so
// the Kanban card's finalize pills (Merge / Delete branch / Keep) update
// without waiting for the next mutation or poll.
func (s *Service) appendBranchExistsChangeEvent(ctx context.Context, t *task.Task, nowExists bool) error {
	reason := "missing"
	if nowExists {
		reason = "restored"
	}
	payload := struct {
		Branch string `json:"branch"`
		Base   string `json:"base"`
		Reason string `json:"reason"`
		Exists bool   `json:"exists"`
	}{
		Branch: t.Branch,
		Base:   t.BaseBranch,
		Reason: reason,
		Exists: nowExists,
	}
	body, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("marshal branch-gc event: %w", err)
	}
	return s.emitBranchGC(ctx, t.ID, body)
}

// emitBranchGC persists one housekeeping.branch_gc event and fans it out
// to live WatchEvents subscribers via s.publish. The caller is responsible
// for constructing the payload JSON. When Config.Events is nil (tests that
// only exercise the branch-flip path), the event is silently dropped —
// the flag was still flipped in the DB and a subsequent WatchEvents
// reconnect or mutation will resync the UI.
func (s *Service) emitBranchGC(ctx context.Context, taskID string, body []byte) error {
	if s.events == nil {
		return nil
	}
	seq, err := s.events.NextSeq(ctx, taskID)
	if err != nil {
		return fmt.Errorf("next seq: %w", err)
	}
	ev := &task.AgentEvent{
		ID:         ulid.Make().String(),
		TaskID:     taskID,
		Seq:        seq,
		Kind:       task.EventHousekeepingBranchGC,
		Payload:    string(body),
		OccurredAt: time.Now().UTC(),
	}
	if err := s.events.Append(ctx, ev); err != nil {
		return err
	}
	if s.publish != nil {
		s.publish(ev)
	}
	return nil
}

// UpdateBranchExistence checks every task whose Branch field is non-empty and
// sets branch_exists=false in the DB when the branch is no longer present in
// the repository. See docs/phase1-spec.md §2-8.
func (s *Service) UpdateBranchExistence(ctx context.Context) error {
	tasks, err := s.tasks.List(ctx, store.ListFilter{})
	if err != nil {
		return fmt.Errorf("reaper: list tasks: %w", err)
	}

	// Collect the repo path for each unique RepoID in one pass. We use
	// RepositoryStore.Get which is a cheap PK lookup.
	repoCache := make(map[string]string) // repoID → path

	var firstErr error
	for _, t := range tasks {
		if t.Branch == "" {
			continue
		}

		repoPath, ok := repoCache[t.RepoID]
		if !ok {
			repo, err := s.repos.Get(ctx, t.RepoID)
			if err != nil {
				s.logger.Warn("reaper: cannot resolve repository for task",
					"taskID", t.ID, "repoID", t.RepoID, "err", err)
				if firstErr == nil {
					firstErr = err
				}
				continue
			}
			repoCache[t.RepoID] = repo.Path
			repoPath = repo.Path
		}

		exists, err := s.wt.BranchExists(ctx, repoPath, t.Branch)
		if err != nil {
			s.logger.Warn("reaper: branch existence check failed",
				"taskID", t.ID, "branch", t.Branch, "err", err)
			if firstErr == nil {
				firstErr = err
			}
			continue
		}

		// Only write when the flag actually changes, to avoid spurious DB
		// writes. Both directions are tracked: marking branches missing
		// (for the reaper's primary purpose) *and* restoring branches a
		// user revived externally with `git branch <name> <sha>` so the
		// Kanban stops showing them as "missing" after the resurrection.
		if exists == t.BranchExists {
			continue
		}
		if exists {
			s.logger.Info("reaper: branch restored, clearing missing flag",
				"taskID", t.ID, "branch", t.Branch)
		} else {
			s.logger.Info("reaper: marking branch missing",
				"taskID", t.ID, "branch", t.Branch)
		}
		if setErr := s.tasks.SetBranchExists(ctx, t.ID, exists); setErr != nil {
			s.logger.Warn("reaper: SetBranchExists failed",
				"taskID", t.ID, "err", setErr)
			if firstErr == nil {
				firstErr = setErr
			}
			continue
		}
		if emitErr := s.appendBranchExistsChangeEvent(ctx, t, exists); emitErr != nil {
			// Flag-flip already succeeded; log the audit failure but keep
			// going. The next invalidate on the UI (mutation, reconnect,
			// or next pass) will resync branchExists from the fresh list.
			s.logger.Warn("reaper: emit branch_gc event failed",
				"taskID", t.ID, "err", emitErr)
		}
	}
	return firstErr
}
