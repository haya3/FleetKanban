//go:build windows

// Package runstate implements the NLAH-style file-backed durable state
// module for FleetKanban. Each task owns a directory tree under the
// Writer's baseDir, mirroring the layout in Appendix B of
// arXiv:2603.25723v1 ("Natural-Language Agent Harnesses"):
//
//	<baseDir>\<taskID>\
//	  TASK.md                          goal + contract + current stage
//	  state\task_history.jsonl         append-only event log (durable)
//	  children\<round>\<order>\        subtask workspace (PROMPT/OUTPUT/DIFF)
//	  artifacts\plan.json | review_<n>.md | attempt_<n>.md | harness.md
//
// Writes are recorded in the `artifact` SQL table through ArtifactStore
// so the UI can enumerate them without traversing the filesystem.
//
// Idempotency: (task_id, relPath, content_hash) is the natural key.
// WriteArtifact re-running with identical bytes is a full no-op; with
// different bytes it writes a new file alongside the old one (the
// relative path typically encodes a version suffix, e.g.
// `artifacts\review_02.md`), so history is preserved immutably.
package runstate

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"log/slog"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"

	"github.com/oklog/ulid/v2"

	"github.com/haya3/fleetkanban/internal/store"
)

// Writer owns the NLAH run directory for every active task. A single
// instance is shared across the sidecar process.
type Writer struct {
	artifacts *store.ArtifactStore
	baseDir   string
	log       *slog.Logger

	mu     sync.Mutex
	histFs map[string]*os.File // taskID → open state\task_history.jsonl handle
}

// NewWriter constructs a Writer. baseDir is the parent directory that
// will contain <taskID>/ subdirectories (typically
// filepath.Join(paths.DataDir, "runs")). The directory is created on
// demand by InitTaskDir; NewWriter itself does no filesystem work.
func NewWriter(artifacts *store.ArtifactStore, baseDir string, log *slog.Logger) *Writer {
	if log == nil {
		log = slog.Default()
	}
	return &Writer{
		artifacts: artifacts,
		baseDir:   baseDir,
		log:       log.With("component", "runstate"),
		histFs:    make(map[string]*os.File),
	}
}

// Close flushes and closes every open task_history.jsonl handle. Safe to
// call from shutdown paths; subsequent writes will re-open on demand.
func (w *Writer) Close() error {
	w.mu.Lock()
	defer w.mu.Unlock()
	var firstErr error
	for id, f := range w.histFs {
		if err := f.Close(); err != nil && firstErr == nil {
			firstErr = fmt.Errorf("runstate: close history for %s: %w", id, err)
		}
		delete(w.histFs, id)
	}
	return firstErr
}

// InitTaskDir creates the run directory tree for taskID and seeds
// TASK.md with the goal + base branch. Idempotent: if the directory
// already exists the contents are left alone and the recorded root_path
// is refreshed. Returns the absolute directory path.
func (w *Writer) InitTaskDir(ctx context.Context, taskID, goal, baseBranch string) (string, error) {
	if taskID == "" {
		return "", errors.New("runstate: InitTaskDir: taskID required")
	}
	root := filepath.Join(w.baseDir, taskID)

	dirs := []string{
		root,
		filepath.Join(root, "state"),
		filepath.Join(root, "artifacts"),
		filepath.Join(root, "children"),
	}
	for _, d := range dirs {
		if err := os.MkdirAll(d, 0o755); err != nil {
			return "", fmt.Errorf("runstate: mkdir %s: %w", d, err)
		}
	}

	if err := w.artifacts.UpsertTaskRunRoot(ctx, taskID, root); err != nil {
		return "", err
	}

	// TASK.md: only write when absent so a resume doesn't clobber
	// edits a user (or harness) made between sessions.
	taskMd := filepath.Join(root, "TASK.md")
	if _, err := os.Stat(taskMd); errors.Is(err, os.ErrNotExist) {
		body := renderTaskMd(taskID, goal, baseBranch)
		if _, _, werr := w.writeArtifactLocked(ctx, taskID, "", "plan",
			"task_md", "TASK.md", []byte(body), nil); werr != nil {
			return "", werr
		}
	} else if err != nil {
		return "", fmt.Errorf("runstate: stat TASK.md: %w", err)
	}

	return root, nil
}

// WriteArtifact writes content to relPath (relative to the task run root)
// and records an artifact row. relPath uses forward slashes; they are
// converted to OS separators for the filesystem write. Returns the
// artifact ID and the absolute path.
//
// When an artifact with identical (task_id, path, content_hash) already
// exists the filesystem write is skipped and the existing row's ID is
// returned — callers can detect a no-op by comparing the returned absPath
// against os.Stat (see task_history append logic for an example).
func (w *Writer) WriteArtifact(
	ctx context.Context,
	taskID, subtaskID, stage, kind, relPath string,
	content []byte,
	attrs map[string]any,
) (artifactID, absPath string, err error) {
	return w.writeArtifactLocked(ctx, taskID, subtaskID, stage, kind, relPath, content, attrs)
}

func (w *Writer) writeArtifactLocked(
	ctx context.Context,
	taskID, subtaskID, stage, kind, relPath string,
	content []byte,
	attrs map[string]any,
) (string, string, error) {
	if taskID == "" || stage == "" || kind == "" || relPath == "" {
		return "", "", errors.New("runstate: WriteArtifact: missing required field")
	}
	root, err := w.resolveRoot(ctx, taskID)
	if err != nil {
		return "", "", err
	}

	rel := filepath.FromSlash(relPath)
	abs := filepath.Join(root, rel)

	sum := sha256.Sum256(content)
	hash := hex.EncodeToString(sum[:])

	attrsJSON := "{}"
	if len(attrs) > 0 {
		b, err := json.Marshal(attrs)
		if err != nil {
			return "", "", fmt.Errorf("runstate: encode attrs: %w", err)
		}
		attrsJSON = string(b)
	}

	id, inserted, err := w.artifacts.InsertIfNew(ctx, store.Artifact{
		ID:          ulid.Make().String(),
		TaskID:      taskID,
		SubtaskID:   subtaskID,
		Stage:       stage,
		Path:        relPath,
		Kind:        kind,
		ContentHash: hash,
		SizeBytes:   int64(len(content)),
		AttrsJSON:   attrsJSON,
		CreatedAt:   time.Now().UTC(),
	})
	if err != nil {
		return "", "", err
	}
	if !inserted {
		// Identical content already on disk under this path — skip FS write.
		return id, abs, nil
	}

	if err := os.MkdirAll(filepath.Dir(abs), 0o755); err != nil {
		return "", "", fmt.Errorf("runstate: mkdir parent %s: %w", abs, err)
	}
	if err := writeFileAtomic(abs, content); err != nil {
		return "", "", err
	}
	return id, abs, nil
}

// AppendHistory appends a JSON-encoded entry (with trailing newline) to
// state/task_history.jsonl for taskID. The file is opened lazily on
// first write per task and kept open for the lifetime of the Writer;
// Close flushes every handle.
//
// No artifact row is emitted: the file is a rolling log, not a discrete
// versioned artifact. The events table remains the primary time-series
// sink; this function projects those rows onto a durable on-disk log
// LLMs can grep directly.
func (w *Writer) AppendHistory(ctx context.Context, taskID string, entry any) error {
	if taskID == "" {
		return errors.New("runstate: AppendHistory: taskID required")
	}
	buf, err := json.Marshal(entry)
	if err != nil {
		return fmt.Errorf("runstate: marshal history entry: %w", err)
	}

	w.mu.Lock()
	defer w.mu.Unlock()

	f, ok := w.histFs[taskID]
	if !ok {
		root, err := w.resolveRoot(ctx, taskID)
		if err != nil {
			return err
		}
		histPath := filepath.Join(root, "state", "task_history.jsonl")
		if err := os.MkdirAll(filepath.Dir(histPath), 0o755); err != nil {
			return fmt.Errorf("runstate: mkdir history parent: %w", err)
		}
		opened, err := os.OpenFile(histPath, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0o644)
		if err != nil {
			return fmt.Errorf("runstate: open history: %w", err)
		}
		w.histFs[taskID] = opened
		f = opened
	}
	buf = append(buf, '\n')
	if _, err := f.Write(buf); err != nil {
		return fmt.Errorf("runstate: append history: %w", err)
	}
	return nil
}

// TaskRoot returns the absolute run directory path for taskID. Returns
// an empty string with a nil error if InitTaskDir has not been called.
func (w *Writer) TaskRoot(ctx context.Context, taskID string) (string, error) {
	return w.artifacts.TaskRunRoot(ctx, taskID)
}

// resolveRoot returns the run directory path, preferring the DB record
// (so a Writer re-created after relocation still resolves correctly).
// Falls back to the canonical <baseDir>/<taskID> when no record exists,
// which happens for fresh tasks between InitTaskDir's mkdir and its
// UpsertTaskRunRoot call — a narrow window exercised only in tests.
func (w *Writer) resolveRoot(ctx context.Context, taskID string) (string, error) {
	root, err := w.artifacts.TaskRunRoot(ctx, taskID)
	if err != nil {
		return "", err
	}
	if root == "" {
		return filepath.Join(w.baseDir, taskID), nil
	}
	return root, nil
}

// writeFileAtomic writes content to path via a temp file + rename so
// partial writes on crash are not visible to readers. On Windows the
// rename succeeds only when the destination is closed; since callers
// never keep artifact files open this is safe in practice.
func writeFileAtomic(path string, content []byte) error {
	tmp := path + ".tmp"
	if err := os.WriteFile(tmp, content, 0o644); err != nil {
		return fmt.Errorf("runstate: write temp %s: %w", tmp, err)
	}
	if err := os.Rename(tmp, path); err != nil {
		_ = os.Remove(tmp)
		return fmt.Errorf("runstate: rename %s → %s: %w", tmp, path, err)
	}
	return nil
}

// renderTaskMd produces the initial TASK.md body for a new run directory.
// The format mirrors the NLAH paper's Appendix B sketch: goal statement,
// execution contract placeholder, current-stage block.
func renderTaskMd(taskID, goal, baseBranch string) string {
	var sb strings.Builder
	sb.WriteString("# Task ")
	sb.WriteString(taskID)
	sb.WriteString("\n\n")
	sb.WriteString("## Goal\n\n")
	sb.WriteString(goal)
	if !strings.HasSuffix(goal, "\n") {
		sb.WriteString("\n")
	}
	sb.WriteString("\n## Base branch\n\n")
	sb.WriteString(baseBranch)
	sb.WriteString("\n\n## Current stage\n\nplan\n\n")
	sb.WriteString("## Contract\n\n")
	sb.WriteString("Defined in harness-skill/SKILL.md (harness_version resolved at dispatch).\n")
	return sb.String()
}
