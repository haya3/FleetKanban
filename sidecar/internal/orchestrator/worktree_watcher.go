package orchestrator

import (
	"context"
	"encoding/json"
	"log/slog"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/fsnotify/fsnotify"

	"github.com/FleetKanban/fleetkanban/internal/task"
)

// fileChangeDebounce coalesces bursts of file events into a single
// EventFileChanged emit. Tuned to feel real-time without drowning the UI
// when an agent runs `npm install` or similar high-churn work.
const fileChangeDebounce = 250 * time.Millisecond

// fileChangeFlushFloor caps the per-emit batch size. A flood of events
// (e.g. a build artifact dump) gets chunked into multiple emits instead
// of one giant payload that the gRPC stream would have to allocate at
// once.
const fileChangeBatchMax = 200

// fileChangePayload is the JSON shape carried by an EventFileChanged
// event. Paths are worktree-relative POSIX strings so the UI can render
// them without re-stripping the worktree prefix.
type fileChangePayload struct {
	Paths []string `json:"paths"`
}

// worktreeWatcher observes a task's worktree directory tree and publishes
// debounced EventFileChanged events to an EventSink. The watcher is
// publish-only — events do NOT flow through the EventStore — because the
// volume during an active build would bloat SQLite without any backfill
// value (the diff itself is the source of truth; this is just a "the
// diff might have changed" signal).
type worktreeWatcher struct {
	taskID   string
	root     string
	sink     EventSink
	log      *slog.Logger
	eventIDs *ulidFactory

	cancel context.CancelFunc
	done   chan struct{}
}

// startWorktreeWatcher boots a watcher rooted at root and returns it. The
// caller MUST call Stop() to release the underlying ReadDirectoryChangesW
// handle. Returns nil + nil when sink is nil — no point watching if
// nothing will receive the events.
func startWorktreeWatcher(taskID, root string, sink EventSink, log *slog.Logger, ids *ulidFactory) (*worktreeWatcher, error) {
	if sink == nil {
		return nil, nil
	}
	fsw, err := fsnotify.NewWatcher()
	if err != nil {
		return nil, err
	}
	if err := addRecursive(fsw, root); err != nil {
		_ = fsw.Close()
		return nil, err
	}
	ctx, cancel := context.WithCancel(context.Background())
	w := &worktreeWatcher{
		taskID:   taskID,
		root:     root,
		sink:     sink,
		log:      log,
		eventIDs: ids,
		cancel:   cancel,
		done:     make(chan struct{}),
	}
	go w.run(ctx, fsw)
	return w, nil
}

// Stop signals the watcher goroutine to exit and waits for it to drain.
// Safe to call multiple times.
func (w *worktreeWatcher) Stop() {
	if w == nil {
		return
	}
	w.cancel()
	<-w.done
}

func (w *worktreeWatcher) run(ctx context.Context, fsw *fsnotify.Watcher) {
	defer close(w.done)
	defer fsw.Close()

	pending := make(map[string]struct{})
	var timer *time.Timer
	var timerC <-chan time.Time

	flush := func() {
		if len(pending) == 0 {
			return
		}
		paths := make([]string, 0, len(pending))
		for p := range pending {
			paths = append(paths, p)
			if len(paths) >= fileChangeBatchMax {
				break
			}
		}
		for _, p := range paths {
			delete(pending, p)
		}
		w.emit(paths)
	}

	for {
		select {
		case <-ctx.Done():
			flush()
			return
		case ev, ok := <-fsw.Events:
			if !ok {
				flush()
				return
			}
			if shouldIgnorePath(ev.Name, w.root) {
				continue
			}
			// Newly-created directories are not auto-watched on Windows;
			// add them so descendant changes are observed too. Best-effort
			// — failures here only narrow the watch scope.
			if ev.Op&fsnotify.Create == fsnotify.Create {
				if isDir(ev.Name) {
					_ = addRecursive(fsw, ev.Name)
				}
			}
			rel, rerr := filepath.Rel(w.root, ev.Name)
			if rerr != nil {
				rel = ev.Name
			}
			pending[filepath.ToSlash(rel)] = struct{}{}
			if timer == nil {
				timer = time.NewTimer(fileChangeDebounce)
				timerC = timer.C
			} else {
				if !timer.Stop() {
					select {
					case <-timer.C:
					default:
					}
				}
				timer.Reset(fileChangeDebounce)
			}
		case <-timerC:
			timer = nil
			timerC = nil
			flush()
		case err, ok := <-fsw.Errors:
			if !ok {
				flush()
				return
			}
			w.log.Warn("orchestrator: file watcher error", "task", w.taskID, "err", err)
		}
	}
}

func (w *worktreeWatcher) emit(paths []string) {
	payload, err := json.Marshal(fileChangePayload{Paths: paths})
	if err != nil {
		return
	}
	ev := &task.AgentEvent{
		ID:         w.eventIDs.next(),
		TaskID:     w.taskID,
		Kind:       task.EventFileChanged,
		Payload:    string(payload),
		OccurredAt: time.Now().UTC(),
	}
	w.sink(ev)
}

// addRecursive walks root and registers every non-ignored subdirectory
// with fsw. fsnotify on Windows uses ReadDirectoryChangesW which is
// per-directory, so the recursive add is mandatory.
func addRecursive(fsw *fsnotify.Watcher, root string) error {
	return filepath.WalkDir(root, func(path string, d os.DirEntry, walkErr error) error {
		if walkErr != nil {
			return nil
		}
		if !d.IsDir() {
			return nil
		}
		if path != root && shouldIgnoreDirName(d.Name()) {
			return filepath.SkipDir
		}
		_ = fsw.Add(path)
		return nil
	})
}

// shouldIgnoreDirName lists directories that produce high-volume,
// low-signal change traffic — git internals, dependency caches, build
// outputs. A `npm install` or `go build` inside the worktree must not
// drown the UI with thousands of irrelevant invalidations.
func shouldIgnoreDirName(name string) bool {
	switch name {
	case ".git", "node_modules", "vendor", "build", "dist", "out",
		"target", ".gradle", ".idea", ".vscode", ".venv", "venv",
		".next", ".nuxt", ".cache", "__pycache__", ".dart_tool",
		".pub-cache", ".terraform":
		return true
	}
	return false
}

// shouldIgnorePath checks whether any segment of p (relative to root)
// matches the ignored-directory list. Catches events in subtrees we
// could not pre-filter via SkipDir (e.g. a directory created mid-run).
func shouldIgnorePath(p, root string) bool {
	rel, err := filepath.Rel(root, p)
	if err != nil {
		return true
	}
	for part := range strings.SplitSeq(filepath.ToSlash(rel), "/") {
		if shouldIgnoreDirName(part) {
			return true
		}
	}
	return false
}

func isDir(p string) bool {
	fi, err := os.Stat(p)
	return err == nil && fi.IsDir()
}
