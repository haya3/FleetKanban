// Package observer taps the orchestrator EventBroker and converts
// session behavior signals into ScratchpadEntry rows. The Phase 1
// implementation emits a single signal kind — co-accessed files —
// when a session has touched a meaningful number of distinct paths.
// Richer signals (dead-end detection, revert-edit, retry patterns)
// can layer on top of the same dispatcher without changing the
// ipc / ui surface.
package observer

import (
	"context"
	"encoding/json"
	"fmt"
	"log/slog"
	"sort"
	"strings"
	"sync"
	"time"

	"github.com/oklog/ulid/v2"

	"github.com/haya3/FleetKanban/internal/ctxmem"
	"github.com/haya3/FleetKanban/internal/ctxmem/store"
	"github.com/haya3/FleetKanban/internal/task"
)

// nodeLookup is the subset of store.NodeStore used for dedup checks.
// Declared as an interface so tests can swap in a fake.
type nodeLookup interface {
	FindByLabel(ctx context.Context, repoID, kind, label string) (ctxmem.Node, error)
}

// coAccessThreshold is the minimum number of distinct files a session
// must touch before the observer even considers it worth feeding to
// the decision summarizer. Trivial two-file tasks rarely produce
// interesting architectural decisions.
const coAccessThreshold = 3

// coAccessMaxFiles caps the file list forwarded to the summarizer —
// beyond this the session was probably a sweeping refactor and the
// LLM does better from the raw diff than a 50-file inventory.
const coAccessMaxFiles = 12

// EventStream is the subset of orchestrator / ipc broker that the
// observer needs. Declared here so the package does not import
// orchestrator (which would create a cycle through app).
type EventStream interface {
	Subscribe() (uint64, <-chan *task.AgentEvent)
	Unsubscribe(uint64)
}

// TaskLookup resolves a task id to its repository id so the observer
// can target the right scratchpad. Defined as an interface to avoid a
// hard store dependency in the observer package.
type TaskLookup interface {
	RepoIDForTask(ctx context.Context, taskID string) (string, error)
	TaskInfo(ctx context.Context, taskID string) (TaskInfo, error)
}

// TaskInfo is the subset of task.Task the summarizer needs.
type TaskInfo struct {
	RepoID       string
	Goal         string
	WorktreePath string
}

// TaskSummarizer condenses what a completed Copilot session actually
// accomplished into a 1-2 sentence Decision candidate. Runs in a
// goroutine after flushSession so it doesn't hold up the observer's
// event loop. Returning "" or "none" suppresses the scratchpad entry.
type TaskSummarizer interface {
	Summarize(ctx context.Context, repoID, worktreePath, goal string, files []string) (string, error)
}

// Observer consumes agent events and writes candidate scratchpad
// entries. It maintains per-task state so signals accumulated across
// events within one session land together at session.idle.
type Observer struct {
	scratchpad *store.ScratchpadStore
	settings   *store.SettingsStore
	stream     EventStream
	tasks      TaskLookup
	summarizer TaskSummarizer // nil = decision-summary disabled
	broker     *ctxmem.ChangeBroker
	nodes      nodeLookup // optional dedup check before writing scratchpad
	log        *slog.Logger

	mu       sync.Mutex
	sessions map[string]*sessionState // task_id → running state
	done     chan struct{}
}

// sessionState accumulates per-task data between session.start and
// session.idle. Reset when session.start re-opens a task.
type sessionState struct {
	filesAccessed map[string]struct{}
	toolCount     int
	errorCount    int
	reasoning     []string
}

// New wires an observer. broker is used to publish ctxmem
// ChangeEvents when scratchpad entries are written, so the Context UI
// refreshes without polling. summarizer is optional; pass nil to
// disable the LLM-backed Decision-candidate pass.
func New(
	scratchpad *store.ScratchpadStore,
	settings *store.SettingsStore,
	stream EventStream,
	tasks TaskLookup,
	broker *ctxmem.ChangeBroker,
	summarizer TaskSummarizer,
	nodes nodeLookup,
	log *slog.Logger,
) *Observer {
	if log == nil {
		log = slog.Default()
	}
	return &Observer{
		scratchpad: scratchpad,
		settings:   settings,
		stream:     stream,
		tasks:      tasks,
		summarizer: summarizer,
		broker:     broker,
		nodes:      nodes,
		log:        log,
		sessions:   map[string]*sessionState{},
		done:       make(chan struct{}),
	}
}

// Start launches the observer loop. Returns when ctx is cancelled or
// Close is called. Call in a goroutine.
func (o *Observer) Start(ctx context.Context) {
	if o.stream == nil {
		return
	}
	id, ch := o.stream.Subscribe()
	defer o.stream.Unsubscribe(id)
	for {
		select {
		case <-ctx.Done():
			return
		case <-o.done:
			return
		case ev, ok := <-ch:
			if !ok {
				return
			}
			o.handle(ctx, ev)
		}
	}
}

// Close releases the subscription; safe to call concurrently with Start.
func (o *Observer) Close() {
	select {
	case <-o.done:
	default:
		close(o.done)
	}
}

// handle is the per-event dispatcher. Keeping the switch thin makes
// it easy to add new signal extractors.
func (o *Observer) handle(ctx context.Context, ev *task.AgentEvent) {
	if ev == nil || ev.TaskID == "" {
		return
	}
	switch ev.Kind {
	case task.EventSessionStart:
		o.resetSession(ev.TaskID)
	case task.EventToolStart:
		o.recordToolStart(ev)
	case task.EventError, task.EventSecurityPathEscape:
		o.recordError(ev.TaskID)
	case task.EventAssistantReasoningDelta:
		o.recordReasoning(ev)
	case task.EventSessionIdle:
		o.flushSession(ctx, ev.TaskID)
	}
}

func (o *Observer) resetSession(taskID string) {
	o.mu.Lock()
	defer o.mu.Unlock()
	o.sessions[taskID] = &sessionState{
		filesAccessed: map[string]struct{}{},
	}
}

// recordToolStart scans the tool.start payload for a "path" argument
// and adds it to the session's file set. Compatible with the
// Copilot SDK's view / edit / powershell tools as they happen to
// emit an `args` object with a path key (the observer is tolerant —
// tools without a path simply contribute toolCount).
func (o *Observer) recordToolStart(ev *task.AgentEvent) {
	o.mu.Lock()
	defer o.mu.Unlock()
	st := o.stateFor(ev.TaskID)
	st.toolCount++

	var outer struct {
		Name string `json:"name"`
		Args string `json:"args"`
	}
	if err := json.Unmarshal([]byte(ev.Payload), &outer); err != nil {
		return
	}
	if outer.Args == "" {
		return
	}
	// args is a compacted JSON object encoded as a string. Parse it
	// into a loose map so we can pluck "path" without a per-tool
	// schema.
	var args map[string]any
	if err := json.Unmarshal([]byte(outer.Args), &args); err != nil {
		return
	}
	if raw, ok := args["path"]; ok {
		if p, ok := raw.(string); ok && p != "" {
			st.filesAccessed[p] = struct{}{}
		}
	}
	if raw, ok := args["paths"]; ok {
		if list, ok := raw.([]any); ok {
			for _, item := range list {
				if p, ok := item.(string); ok && p != "" {
					st.filesAccessed[p] = struct{}{}
				}
			}
		}
	}
}

func (o *Observer) recordError(taskID string) {
	o.mu.Lock()
	defer o.mu.Unlock()
	o.stateFor(taskID).errorCount++
}

func (o *Observer) recordReasoning(ev *task.AgentEvent) {
	o.mu.Lock()
	defer o.mu.Unlock()
	st := o.stateFor(ev.TaskID)
	// Keep only a short rolling buffer — the reasoning buffer is
	// here to anchor the scratchpad entry, not to archive it.
	if len(st.reasoning) > 20 {
		st.reasoning = st.reasoning[len(st.reasoning)-20:]
	}
	st.reasoning = append(st.reasoning, ev.Payload)
}

func (o *Observer) stateFor(taskID string) *sessionState {
	if st, ok := o.sessions[taskID]; ok {
		return st
	}
	st := &sessionState{filesAccessed: map[string]struct{}{}}
	o.sessions[taskID] = st
	return st
}

// flushSession runs at session.idle. If the accumulated state meets
// the co-access threshold and the repo has Memory enabled, write a
// scratchpad entry describing the files that were read together.
func (o *Observer) flushSession(ctx context.Context, taskID string) {
	o.mu.Lock()
	st, ok := o.sessions[taskID]
	delete(o.sessions, taskID)
	o.mu.Unlock()
	if !ok || st == nil {
		return
	}
	if len(st.filesAccessed) < coAccessThreshold {
		return
	}
	if o.tasks == nil {
		return
	}
	repoID, err := o.tasks.RepoIDForTask(ctx, taskID)
	if err != nil || repoID == "" {
		return
	}
	set, err := o.settings.Get(ctx, repoID)
	if err != nil || !set.Enabled {
		// Memory disabled — don't write anything. The observer is
		// silent until the user opts in.
		return
	}

	files := make([]string, 0, len(st.filesAccessed))
	for f := range st.filesAccessed {
		files = append(files, f)
	}
	sort.Strings(files)
	if len(files) > coAccessMaxFiles {
		files = files[:coAccessMaxFiles]
	}
	o.log.Info("observer: session co-access captured",
		"task", taskID, "repo", repoID, "files", len(files))

	// Co-access data is NOT written as a scratchpad entry — raw file
	// lists aren't actionable knowledge and just create noise. The
	// graph-neighborhood boost will consume co-access as
	// coAccessedWith edges in a future pass; for now the signal is
	// logged only so we can verify the pipeline is alive.
	//
	// Decision-summary pass (via LLM) is what actually produces
	// meaningful scratchpad candidates.
	if o.summarizer != nil {
		go o.runSummarizer(taskID, repoID, files)
	}
}

// summaryVerdict is the JSON shape the summarizer prompt instructs
// the LLM to return. Fields are tolerant — the LLM occasionally
// shortens the key names or omits `reasoning`, so parsing uses
// json.Decoder and accepts whatever we can read.
type summaryVerdict struct {
	WorthRemembering bool    `json:"worth_remembering"`
	Confidence       float32 `json:"confidence"`
	Label            string  `json:"label"`
	Summary          string  `json:"summary"`
	Reasoning        string  `json:"reasoning"`
}

// summaryMinConfidence gates entries below the LLM's own self-rated
// 0.7. Intentionally strict — we want Scratchpad to contain only
// decisions the model is meaningfully confident about. Users who
// disagree with the bar can still promote manually from the
// Scratchpad later (if we surface snoozed entries); tighter defaults
// are easier to loosen than loosen-then-tighten.
const summaryMinConfidence = 0.7

// runSummarizer calls the configured TaskSummarizer, parses the
// structured verdict, and writes a Decision scratchpad candidate only
// when the LLM itself declared the change worth remembering at
// sufficient confidence. Errors and rejections are both logged so
// the user can see why a task did/didn't produce a candidate without
// tailing the sidecar at DEBUG level.
func (o *Observer) runSummarizer(taskID, repoID string, files []string) {
	ctx := context.Background()
	info, err := o.tasks.TaskInfo(ctx, taskID)
	if err != nil {
		o.log.Warn("observer: summarizer: task lookup", "err", err, "task", taskID)
		return
	}
	if info.Goal == "" {
		return
	}
	raw, err := o.summarizer.Summarize(ctx, repoID, info.WorktreePath, info.Goal, files)
	if err != nil {
		o.log.Warn("observer: summarizer failed", "err", err, "task", taskID)
		return
	}
	verdict, parseErr := parseSummaryVerdict(raw)
	if parseErr != nil {
		o.log.Info("observer: summarizer: unparseable output dropped",
			"task", taskID, "err", parseErr,
			"raw_preview", firstN(raw, 160))
		return
	}
	if !verdict.WorthRemembering {
		o.log.Info("observer: summarizer: self-reported not worth remembering",
			"task", taskID, "reasoning", verdict.Reasoning)
		return
	}
	if verdict.Confidence < summaryMinConfidence {
		o.log.Info("observer: summarizer: confidence below threshold",
			"task", taskID, "confidence", verdict.Confidence,
			"threshold", summaryMinConfidence, "reasoning", verdict.Reasoning)
		return
	}
	summary := strings.TrimSpace(verdict.Summary)
	if summary == "" {
		o.log.Info("observer: summarizer: empty summary dropped",
			"task", taskID)
		return
	}
	label := strings.TrimSpace(verdict.Label)
	if label == "" {
		label = firstN(summary, 60)
	}
	// Final guard against duplicate Decisions: if an enabled node
	// with the same kind+label already exists, skip — promoting from
	// scratchpad would merge anyway but we save the user the review.
	if o.nodes != nil {
		if existing, err := o.nodes.FindByLabel(ctx, repoID, ctxmem.NodeKindDecision, label); err == nil {
			o.log.Info("observer: summarizer: label matches existing node, skipped",
				"task", taskID, "node", existing.ID, "label", label)
			return
		}
	}

	entry := ctxmem.ScratchpadEntry{
		ID:                ulid.Make().String(),
		RepoID:            repoID,
		ProposedKind:      ctxmem.NodeKindDecision,
		ProposedLabel:     label,
		ProposedContentMD: summary,
		SourceKind:        ctxmem.SourceSessionSummary,
		SourceRef:         taskID,
		Signals: []string{
			"llm-decision-summary",
			fmt.Sprintf("self-confidence: %.2f", verdict.Confidence),
			fmt.Sprintf("files: %d", len(files)),
		},
		Confidence: verdict.Confidence,
		Status:     ctxmem.ScratchpadPending,
	}
	if err := o.scratchpad.Create(ctx, entry); err != nil {
		o.log.Warn("observer: summarizer scratchpad create", "err", err)
		return
	}
	if o.broker != nil {
		o.broker.Publish(&ctxmem.ChangeEvent{
			Kind:       "scratchpad",
			Op:         "create",
			ID:         entry.ID,
			RepoID:     repoID,
			OccurredAt: time.Now().UTC(),
		})
	}
	o.log.Info("observer: decision summary scratched",
		"task", taskID, "repo", repoID, "label", label,
		"confidence", verdict.Confidence)
}

// parseSummaryVerdict extracts the summary JSON from the model's
// response. Tolerant of leading prose + ``` fences — json.Decoder
// reads exactly one top-level value from the first '{'.
func parseSummaryVerdict(raw string) (summaryVerdict, error) {
	raw = strings.TrimSpace(raw)
	if raw == "" {
		return summaryVerdict{}, fmt.Errorf("empty response")
	}
	first := strings.Index(raw, "{")
	if first < 0 {
		return summaryVerdict{}, fmt.Errorf("no JSON object found")
	}
	dec := json.NewDecoder(strings.NewReader(raw[first:]))
	var v summaryVerdict
	if err := dec.Decode(&v); err != nil {
		return summaryVerdict{}, err
	}
	if v.Confidence < 0 {
		v.Confidence = 0
	}
	if v.Confidence > 1 {
		v.Confidence = 1
	}
	return v, nil
}

func firstN(s string, n int) string {
	if len(s) <= n {
		return s
	}
	return s[:n]
}
