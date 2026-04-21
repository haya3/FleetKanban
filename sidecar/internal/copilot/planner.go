//go:build windows

package copilot

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log/slog"
	"regexp"
	"sort"
	"strings"
	"time"

	copilot "github.com/github/copilot-sdk/go"
	"github.com/oklog/ulid/v2"

	"github.com/haya3/FleetKanban/internal/task"
)

// plannerTimeout is the wall-clock cap on a single planning session. Kept
// below the parent orchestrator's planning timeout so the session finishes
// cleanly rather than being cancelled mid-response.
const plannerTimeout = 3 * time.Minute

// plannerJSONTag is the sentinel the planner prompt asks the agent to
// wrap its DAG output in. Parsing scans for this tag first so surrounding
// prose does not confuse the JSON extractor.
const plannerJSONTag = "PLAN_JSON"

// plannerSummaryTag wraps the human-readable plan summary the planner
// emits before the DAG. Stored on `plan.summary` events so the UI can
// surface what the planner investigated and why it chose this approach,
// instead of leaving the user staring at opaque subtask titles.
const plannerSummaryTag = "PLAN_SUMMARY"

// MaxPlannerSubtasks caps the DAG size. The planner prompt asks for a
// small DAG; a runaway output is always a misbehaving model and should
// be rejected rather than flooding the store.
const MaxPlannerSubtasks = 40

// Planner is a Copilot-backed orchestrator.Planner. Each Plan call opens a
// short-lived session in the task's worktree, asks the agent to decompose
// the goal into a subtask DAG, and parses the resulting JSON.
//
// The session runs read-only — planning must not mutate code. Writes by a
// misbehaving planner model would be silent scope creep.
type Planner struct {
	client       *copilot.Client
	model        string
	timeout      time.Duration
	settings     SettingsLookup
	stagePrompts StagePromptLookup
}

// NewPlanner constructs a Planner bound to rt's SDK client. When model is
// empty the runtime's ListModels is consulted and the first model is used.
func (r *Runtime) NewPlanner(ctx context.Context, model string) (*Planner, error) {
	client := r.Client()
	if client == nil {
		return nil, errors.New("copilot: runtime client not started")
	}
	if model == "" {
		resolved, err := resolveModel(ctx, client)
		if err != nil {
			return nil, err
		}
		model = resolved
	}
	r.mu.RLock()
	settings := r.cfg.Settings
	stagePrompts := r.cfg.StagePrompts
	r.mu.RUnlock()
	return &Planner{
		client:       client,
		model:        model,
		timeout:      plannerTimeout,
		settings:     settings,
		stagePrompts: stagePrompts,
	}, nil
}

// plannerRawSubtask is the shape the model is asked to emit for each node.
// Parsed from the JSON block in the assistant's final message.
type plannerRawSubtask struct {
	ID        string   `json:"id"`
	Title     string   `json:"title"`
	AgentRole string   `json:"agent_role"`
	DependsOn []string `json:"depends_on"`
	// Prompt is the concrete instruction the executor feeds into the
	// Coder's Copilot session when running this subtask. The planner
	// writes what files to touch, what to implement, what to verify —
	// without it the Coder has to guess intent from the Title alone
	// and ends up re-planning on the fly.
	Prompt string `json:"prompt"`
}

// plannerRawPlan wraps the subtask array so the prompt can use a named key
// rather than a bare top-level array, which is more forgiving to parse
// when the model ad-libs a containing envelope.
type plannerRawPlan struct {
	Subtasks []plannerRawSubtask `json:"subtasks"`
}

// Plan runs a planning session for t and returns the resulting subtask
// graph plus a human-readable summary explaining the planner's
// investigation findings and why it chose this decomposition. IDs on
// the returned subtasks are ULIDs assigned by the planner (replacing
// the model's free-form IDs so downstream code can trust them);
// DependsOn is rewritten to reference those ULIDs. OrderIdx is assigned
// from the topological order so the UI has a stable display sequence
// without having to re-sort.
//
// The summary is empty when the planner forgot the PLAN_SUMMARY block —
// callers should treat that as a soft warning, not a hard failure, since
// the DAG itself is still usable.
func (p *Planner) Plan(ctx context.Context, t *task.Task, out chan<- *task.AgentEvent) ([]*task.Subtask, string, string, task.SessionUsage, error) {
	defer close(out)
	if t.WorktreePath == "" {
		return nil, "", "", task.SessionUsage{}, errors.New("copilot: planner: task has no worktree")
	}

	ctx, cancel := context.WithTimeout(ctx, p.timeout)
	defer cancel()

	// Per-task override: when the user selected a specific Plan-stage
	// model in Settings the task carries it through t.PlanModel; honour
	// that verbatim. Otherwise fall back to the Planner's constructor-
	// time default (which itself was resolved via ListModels when the
	// Runtime came up).
	model := t.PlanModel
	if model == "" {
		model = p.model
	}

	guard, err := NewPermissionHandler(t.WorktreePath)
	if err != nil {
		return nil, "", "", task.SessionUsage{}, fmt.Errorf("copilot: planner permission: %w", err)
	}
	denyWrites := func(req copilot.PermissionRequest, inv copilot.PermissionInvocation) (copilot.PermissionRequestResult, error) {
		if req.Kind == copilot.PermissionRequestKindWrite {
			return copilot.PermissionRequestResult{
				Kind: copilot.PermissionRequestResultKindDeniedByRules,
			}, nil
		}
		return guard(req, inv)
	}

	settings := agentSettingsOrEmpty(ctx, p.settings)
	systemContent := ResolveStagePrompt(p.stagePrompts, "plan", DefaultPlanPrompt) + languageAddendum(settings.OutputLanguage)
	session, err := p.client.CreateSession(ctx, &copilot.SessionConfig{
		Model:            model,
		Streaming:        true,
		WorkingDirectory: t.WorktreePath,
		SystemMessage: &copilot.SystemMessageConfig{
			Mode:    "replace",
			Content: systemContent,
		},
		OnPermissionRequest: denyWrites,
	})
	if err != nil {
		return nil, "", "", task.SessionUsage{}, fmt.Errorf("copilot: planner session: %w", err)
	}
	defer func() { _ = session.Disconnect() }()

	idleCh := make(chan struct{})
	idleOnce := make(chan struct{}, 1)
	var transcript strings.Builder
	usage := &usageAccumulator{}
	mapper := NewSessionMapper()

	// Debug log: every SDK SessionEvent the planner session receives,
	// with timestamp + event kind + payload hint. Writes to slog at
	// INFO so supervisor ring buffer captures it without flipping the
	// whole sidecar to debug. Enough to answer "what is Plan doing?"
	// when the phase takes a long time.
	sessionStart := time.Now()
	slog.Info("planner: session start",
		"task_id", t.ID,
		"model", model,
		"worktree", t.WorktreePath)

	forward := func(events []*task.AgentEvent) {
		for _, ae := range events {
			select {
			case out <- ae:
			case <-ctx.Done():
				return
			}
		}
	}

	unsubscribe := session.On(func(e copilot.SessionEvent) {
		elapsed := time.Since(sessionStart)
		switch d := e.Data.(type) {
		case *copilot.AssistantUsageData:
			usage.add(d)
			// One-line summary of each LLM call the planner makes so
			// we can see how many turns it took + what it cost.
			in := int64(0)
			if d.InputTokens != nil {
				in = int64(*d.InputTokens)
			}
			outTok := int64(0)
			if d.OutputTokens != nil {
				outTok = int64(*d.OutputTokens)
			}
			cost := 0.0
			if d.Cost != nil {
				cost = *d.Cost
			}
			slog.Info("planner: llm call",
				"task_id", t.ID,
				"elapsed_ms", elapsed.Milliseconds(),
				"in_tokens", in,
				"out_tokens", outTok,
				"premium", cost,
				"calls_so_far", usage.u.Calls+1)
			return
		case *copilot.SessionIdleData:
			slog.Info("planner: idle",
				"task_id", t.ID,
				"elapsed_ms", elapsed.Milliseconds(),
				"total_calls", usage.u.Calls,
				"total_premium", usage.u.PremiumRequests)
			forward(mapper.Flush())
			select {
			case idleOnce <- struct{}{}:
				close(idleCh)
			default:
			}
			return
		case *copilot.ToolExecutionStartData:
			slog.Info("planner: tool start",
				"task_id", t.ID,
				"elapsed_ms", elapsed.Milliseconds(),
				"tool", d.ToolName,
				"call_id", d.ToolCallID,
				"args", compactArgs(d.Arguments))
		case *copilot.ToolExecutionCompleteData:
			errStr, resStr, telStr := toolEndSummary(d, 400)
			attrs := []any{
				"task_id", t.ID,
				"elapsed_ms", elapsed.Milliseconds(),
				"call_id", d.ToolCallID,
				"ok", d.Success,
			}
			if errStr != "" {
				attrs = append(attrs, "err", errStr)
			}
			if resStr != "" {
				attrs = append(attrs, "result", resStr)
			}
			if telStr != "" {
				attrs = append(attrs, "telemetry", telStr)
			}
			slog.Info("planner: tool end", attrs...)
		case *copilot.AssistantIntentData:
			slog.Info("planner: intent",
				"task_id", t.ID,
				"elapsed_ms", elapsed.Milliseconds(),
				"intent", d.Intent)
		}

		// Keep the raw transcript for PLAN_SUMMARY / PLAN_JSON parsing;
		// the mapper produces line-buffered events for live display.
		if raw := MapSessionEvent(e); raw != nil && raw.Kind == task.EventAssistantDelta {
			transcript.WriteString(raw.Payload)
		}
		forward(mapper.Map(e))
	})
	defer unsubscribe()

	if _, err := session.Send(ctx, copilot.MessageOptions{
		Prompt: buildPlannerPrompt(t),
	}); err != nil {
		return nil, "", "", usage.snapshot(), fmt.Errorf("copilot: planner send: %w", err)
	}

	select {
	case <-idleCh:
	case <-ctx.Done():
		_ = session.Disconnect()
		return nil, "", "", usage.snapshot(), ctx.Err()
	}

	transcriptStr := transcript.String()
	summary := extractPlanSummary(transcriptStr)
	if summary == "" {
		slog.Warn("copilot: planner: PLAN_SUMMARY block missing",
			"task_id", t.ID)
	}

	raw, usedFallback, err := extractPlanJSON(transcriptStr)
	if err != nil {
		return nil, "", summary, usage.snapshot(), err
	}
	if usedFallback {
		slog.Warn("copilot: planner: PLAN_JSON tags missing, fell back to brace scan",
			"task_id", t.ID)
	}

	var plan plannerRawPlan
	if err := json.Unmarshal([]byte(raw), &plan); err != nil {
		return nil, "", summary, usage.snapshot(), fmt.Errorf("copilot: planner: decode JSON: %w", err)
	}

	subs, err := normalisePlan(t.ID, plan.Subtasks)
	if err != nil {
		return nil, "", summary, usage.snapshot(), err
	}
	return subs, model, summary, usage.snapshot(), nil
}

// planSummaryRE matches the PLAN_SUMMARY block. Captures the body
// between the markers, tolerant of trailing whitespace and optional
// code-fence decoration the model sometimes adds.
var planSummaryRE = regexp.MustCompile(
	`(?s)` + plannerSummaryTag + `\s*` + "`" + `*\s*(.*?)\s*` + "`" + `*\s*` + plannerSummaryTag,
)

// extractPlanSummary returns the text inside the PLAN_SUMMARY block,
// trimmed of surrounding whitespace. Empty when the markers are
// missing or contain only whitespace — callers treat that as a soft
// failure (the plan itself can still be useful).
func extractPlanSummary(transcript string) string {
	m := planSummaryRE.FindStringSubmatch(transcript)
	if len(m) != 2 {
		return ""
	}
	return strings.TrimSpace(m[1])
}

// buildPlannerPrompt composes the task description for the planner. The
// Goal occupies a single-line slot inside the prompt so it goes through
// SanitizeSingleLine — a newline in the user's goal cannot terminate the
// "Goal:" block and inject new instructions. The worktree path is
// interpolated verbatim (trusted input) so tools can use absolute
// paths without the planner having to call `pwd` / `Get-Location`
// just to discover cwd — a surprisingly common token-wasting pattern
// when the prompt omits the path.
func buildPlannerPrompt(t *task.Task) string {
	goal := SanitizeSingleLine(t.Goal)
	return fmt.Sprintf(`Plan how to accomplish the following task. Investigate the worktree first, then decompose.

Working directory (cwd) — all file paths should be relative to this, or use it as the absolute root:
%s

Goal:
%s

Investigation — just enough to produce a concrete plan:
  - Batch parallel view / grep / rg calls in ONE turn to locate the files the goal actually touches.
  - Note naming conventions and any hard constraints you'll reference in the per-subtask prompts.
  - Stop as soon as you have enough to write the plan — do not make extra exploratory turns.
  - No report_intent / thinking-out-loud tool calls; they are pure waste.

Plan summary requirements:
  - Wrap a Markdown summary in %s markers BEFORE the JSON — the UI renders it as Markdown, so use real line breaks, headings, and bullet points. A run-on paragraph is unacceptable.
  - Shape (use these exact headings):
      ## Investigation
      - what you looked at
      - what you found that matters
      ## Decomposition rationale
      - why this shape (parallelism, ordering, risk isolation, etc.)
  - Do NOT restate the goal verbatim — focus on what investigation revealed.

DAG constraints:
  - Produce between 1 and %d subtasks.
  - Each subtask must be implementable in a single, independent, short Copilot session.
  - Subtasks execute serially on the same worktree; parallelism in the DAG is representational only.
  - agent_role may be any descriptive name (e.g. coder, tester, researcher, verifier).
  - **Using "reviewer" or "ai_reviewer" as an agent_role is forbidden**: review is performed by the dedicated AI Review phase in a separate session after execution, so do not duplicate it inside the plan. If a read-only verification subtask is needed, use a role such as "verifier".
  - depends_on must reference subtask ids within the same plan (no cycles).
  - id must be a short alphanumeric string unique within the plan (e.g. "s1", "s2").

Per-subtask prompt requirements (CRITICAL — without these each subtask's Coder has to guess and ends up replanning):
  - Every subtask MUST include a "prompt" field written as Markdown. The UI renders this, and humans read it — run-on paragraphs are unacceptable.
  - Required Markdown shape (use real line breaks between sections; use \n inside the JSON string):
      **Goal:** one imperative sentence describing what this subtask accomplishes.
      **Files to touch:**
      - path/one.ext — what to change
      - path/two.ext — what to change
      **Behaviour:** 1-3 bullets or sentences on the change itself (wording, algorithm, API shape, etc.).
      **Verify:** the exact command to run (build, test, or check) — or "(no verify — final subtask covers it)" if the instruction legitimately has no per-subtask verification.
  - File paths must be the actual paths you discovered during investigation (not "the relevant files").
  - Do NOT restate generic planner-level context — focus on what makes THIS subtask different from its siblings.

Output format (in this exact order, no extra prose outside these blocks):
%s
<1-5 sentences of investigation findings + decomposition rationale>
%s

%s
{
  "subtasks": [
    {"id": "s1", "title": "short label", "agent_role": "...", "depends_on": [], "prompt": "Concrete, multi-sentence instruction: which files, what behaviour, how to verify."},
    {"id": "s2", "title": "...", "agent_role": "...", "depends_on": ["s1"], "prompt": "..."}
  ]
}
%s`,
		t.WorktreePath,
		goal,
		plannerSummaryTag,
		MaxPlannerSubtasks,
		plannerSummaryTag, plannerSummaryTag,
		plannerJSONTag, plannerJSONTag)
}

// planJSONTagRE finds the JSON block wrapped in plannerJSONTag markers.
// Tolerant of surrounding whitespace, optional code fences (incl. a
// language hint like ```json), and either order of closing markers vs.
// JSON terminators.
var planJSONTagRE = regexp.MustCompile(
	`(?s)` + plannerJSONTag + `\s*` + "`" + `*\w*\s*(\{.*?\})\s*` + "`" + `*\s*` + plannerJSONTag,
)

// extractPlanJSON pulls the JSON body out of the transcript. It looks for
// the sentinel-wrapped block first; falls back to the first balanced {...}
// span when the model forgot the tags (sloppy but common). Anything that
// cannot be reduced to balanced braces is rejected.
//
// usedFallback reports whether the tagged path was taken (false) or the
// brace-scan fallback (true). Callers typically log a warning on the
// fallback path so prompt regressions are observable — the fallback can
// silently accept stray JSON-looking text from elsewhere in the
// transcript (see the prompt example leak risk in the Planner's doc
// comment).
func extractPlanJSON(transcript string) (raw string, usedFallback bool, err error) {
	if m := planJSONTagRE.FindStringSubmatch(transcript); len(m) == 2 {
		return m[1], false, nil
	}
	if b := firstBalancedJSON(transcript); b != "" {
		return b, true, nil
	}
	return "", false, errors.New("copilot: planner: no JSON block in response")
}

// firstBalancedJSON returns the first substring spanning a balanced pair of
// { and } (tracking nesting and skipping quoted strings so a closing brace
// inside a string does not terminate early). Returns "" when none found.
func firstBalancedJSON(s string) string {
	start := strings.IndexByte(s, '{')
	if start < 0 {
		return ""
	}
	depth := 0
	inStr := false
	escape := false
	for i := start; i < len(s); i++ {
		c := s[i]
		if inStr {
			if escape {
				escape = false
				continue
			}
			if c == '\\' {
				escape = true
				continue
			}
			if c == '"' {
				inStr = false
			}
			continue
		}
		switch c {
		case '"':
			inStr = true
		case '{':
			depth++
		case '}':
			depth--
			if depth == 0 {
				return s[start : i+1]
			}
		}
	}
	return ""
}

// normalisePlan validates the parsed plan and rewrites it into the storage
// shape: each raw subtask gets a fresh ULID, DependsOn references are
// remapped to those ULIDs, and OrderIdx is assigned from topological
// order. Rejects empty plans, oversized plans, duplicate/unknown
// references, self-deps, and cycles.
func normalisePlan(parentTaskID string, raw []plannerRawSubtask) ([]*task.Subtask, error) {
	if len(raw) == 0 {
		return nil, errors.New("copilot: planner: empty plan")
	}
	if len(raw) > MaxPlannerSubtasks {
		return nil, fmt.Errorf("copilot: planner: plan exceeds cap (%d > %d)", len(raw), MaxPlannerSubtasks)
	}

	rawID := make(map[string]string, len(raw)) // raw id → ULID
	for _, r := range raw {
		id := strings.TrimSpace(r.ID)
		if id == "" {
			return nil, errors.New("copilot: planner: subtask missing id")
		}
		if _, dup := rawID[id]; dup {
			return nil, fmt.Errorf("copilot: planner: duplicate subtask id %q", id)
		}
		rawID[id] = ulid.Make().String()
	}

	// Build the working set with ULIDs so we can topologically sort on
	// real dependency pointers rather than the model's free-form IDs.
	nodes := make(map[string]*plannerNode, len(raw))
	for _, r := range raw {
		title := strings.TrimSpace(r.Title)
		if title == "" {
			return nil, fmt.Errorf("copilot: planner: subtask %q missing title", r.ID)
		}
		role := strings.TrimSpace(r.AgentRole)
		if role == "" {
			return nil, fmt.Errorf("copilot: planner: subtask %q missing agent_role", r.ID)
		}
		// Last-line defense: even with the prompt forbidding it, a
		// misbehaving model occasionally emits `reviewer` as a role.
		// Reject here so the dedicated AI Review phase isn't silently
		// duplicated inside the execution plan.
		switch strings.ToLower(role) {
		case "reviewer", "ai_reviewer", "ai-reviewer":
			return nil, fmt.Errorf("copilot: planner: subtask %q uses forbidden role %q (AI Review runs in a separate phase; use `verifier` for read-only checks)", r.ID, role)
		}

		deps := make([]string, 0, len(r.DependsOn))
		for _, dep := range r.DependsOn {
			dep = strings.TrimSpace(dep)
			if dep == "" {
				continue
			}
			if dep == r.ID {
				return nil, fmt.Errorf("copilot: planner: subtask %q depends on itself", r.ID)
			}
			mappedDep, ok := rawID[dep]
			if !ok {
				return nil, fmt.Errorf("copilot: planner: subtask %q depends on unknown %q", r.ID, dep)
			}
			deps = append(deps, mappedDep)
		}

		ulidID := rawID[r.ID]
		nodes[ulidID] = &plannerNode{
			sub: &task.Subtask{
				ID:        ulidID,
				TaskID:    parentTaskID,
				Title:     title,
				AgentRole: role,
				DependsOn: deps,
				Status:    task.SubtaskPending,
				Prompt:    strings.TrimSpace(r.Prompt),
			},
			rawDeps: deps,
		}
	}

	ordered, err := topoSort(nodes)
	if err != nil {
		return nil, err
	}
	for i, sub := range ordered {
		sub.OrderIdx = i
	}
	return ordered, nil
}

// plannerNode is the working-set entry used during DAG validation and
// topological sort — the final task.Subtask plus the dependency list
// remapped to ULIDs.
type plannerNode struct {
	sub     *task.Subtask
	rawDeps []string
}

// topoSort returns the subtasks in dependency order (Kahn's algorithm).
// Rejects cycles. Sibling order among ready nodes follows the ULID sort so
// output is deterministic across runs.
func topoSort(nodes map[string]*plannerNode) ([]*task.Subtask, error) {
	indeg := make(map[string]int, len(nodes))
	successors := make(map[string][]string, len(nodes))
	ids := make([]string, 0, len(nodes))
	for id, n := range nodes {
		indeg[id] = len(n.rawDeps)
		ids = append(ids, id)
		for _, dep := range n.rawDeps {
			successors[dep] = append(successors[dep], id)
		}
	}
	sort.Strings(ids)
	for _, succs := range successors {
		sort.Strings(succs)
	}

	ready := make([]string, 0)
	for _, id := range ids {
		if indeg[id] == 0 {
			ready = append(ready, id)
		}
	}

	out := make([]*task.Subtask, 0, len(nodes))
	for len(ready) > 0 {
		id := ready[0]
		ready = ready[1:]
		out = append(out, nodes[id].sub)
		for _, succ := range successors[id] {
			indeg[succ]--
			if indeg[succ] == 0 {
				ready = append(ready, succ)
			}
		}
	}

	if len(out) != len(nodes) {
		return nil, errors.New("copilot: planner: cycle in dependency graph")
	}
	return out, nil
}
