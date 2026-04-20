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

	"github.com/FleetKanban/fleetkanban/internal/task"
)

// plannerTimeout is the wall-clock cap on a single planning session. Kept
// below the parent orchestrator's planning timeout so the session finishes
// cleanly rather than being cancelled mid-response.
const plannerTimeout = 3 * time.Minute

// plannerJSONTag is the sentinel the planner prompt asks the agent to
// wrap its DAG output in. Parsing scans for this tag first so surrounding
// prose does not confuse the JSON extractor.
const plannerJSONTag = "PLAN_JSON"

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
	client  *copilot.Client
	model   string
	timeout time.Duration
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
	return &Planner{client: client, model: model, timeout: plannerTimeout}, nil
}

// plannerRawSubtask is the shape the model is asked to emit for each node.
// Parsed from the JSON block in the assistant's final message.
type plannerRawSubtask struct {
	ID        string   `json:"id"`
	Title     string   `json:"title"`
	AgentRole string   `json:"agent_role"`
	DependsOn []string `json:"depends_on"`
}

// plannerRawPlan wraps the subtask array so the prompt can use a named key
// rather than a bare top-level array, which is more forgiving to parse
// when the model ad-libs a containing envelope.
type plannerRawPlan struct {
	Subtasks []plannerRawSubtask `json:"subtasks"`
}

// Plan runs a planning session for t and returns the resulting subtask
// graph. IDs on the returned subtasks are ULIDs assigned by the planner
// (replacing the model's free-form IDs so downstream code can trust them);
// DependsOn is rewritten to reference those ULIDs. OrderIdx is assigned
// from the topological order so the UI has a stable display sequence
// without having to re-sort.
func (p *Planner) Plan(ctx context.Context, t *task.Task) ([]*task.Subtask, string, error) {
	if t.WorktreePath == "" {
		return nil, "", errors.New("copilot: planner: task has no worktree")
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
		return nil, "", fmt.Errorf("copilot: planner permission: %w", err)
	}
	denyWrites := func(req copilot.PermissionRequest, inv copilot.PermissionInvocation) (copilot.PermissionRequestResult, error) {
		if req.Kind == copilot.PermissionRequestKindWrite {
			return copilot.PermissionRequestResult{
				Kind: copilot.PermissionRequestResultKindDeniedByRules,
			}, nil
		}
		return guard(req, inv)
	}

	session, err := p.client.CreateSession(ctx, &copilot.SessionConfig{
		Model:            model,
		Streaming:        true,
		WorkingDirectory: t.WorktreePath,
		SystemMessage: &copilot.SystemMessageConfig{
			Mode: "replace",
			Content: "あなたはタスク分解プランナーです。目的を小さな実行可能 subtask の DAG に分解します。\n" +
				"ファイルを書き換えてはいけません（読み取りのみ）。\n" +
				"出力は必ず " + plannerJSONTag + " で挟んだ JSON ブロックのみで返してください。余分な解説は不要です。",
		},
		OnPermissionRequest: denyWrites,
	})
	if err != nil {
		return nil, "", fmt.Errorf("copilot: planner session: %w", err)
	}
	defer func() { _ = session.Disconnect() }()

	idleCh := make(chan struct{})
	idleOnce := make(chan struct{}, 1)
	var transcript strings.Builder

	unsubscribe := session.On(func(e copilot.SessionEvent) {
		if _, ok := e.Data.(*copilot.SessionIdleData); ok {
			select {
			case idleOnce <- struct{}{}:
				close(idleCh)
			default:
			}
			return
		}
		if ae := MapSessionEvent(e); ae != nil && ae.Kind == task.EventAssistantDelta {
			transcript.WriteString(ae.Payload)
		}
	})
	defer unsubscribe()

	if _, err := session.Send(ctx, copilot.MessageOptions{
		Prompt: buildPlannerPrompt(t),
	}); err != nil {
		return nil, "", fmt.Errorf("copilot: planner send: %w", err)
	}

	select {
	case <-idleCh:
	case <-ctx.Done():
		_ = session.Disconnect()
		return nil, "", ctx.Err()
	}

	raw, usedFallback, err := extractPlanJSON(transcript.String())
	if err != nil {
		return nil, "", err
	}
	if usedFallback {
		slog.Warn("copilot: planner: PLAN_JSON tags missing, fell back to brace scan",
			"task_id", t.ID)
	}

	var plan plannerRawPlan
	if err := json.Unmarshal([]byte(raw), &plan); err != nil {
		return nil, "", fmt.Errorf("copilot: planner: decode JSON: %w", err)
	}

	subs, err := normalisePlan(t.ID, plan.Subtasks)
	if err != nil {
		return nil, "", err
	}
	return subs, model, nil
}

// buildPlannerPrompt composes the task description for the planner. The
// Goal occupies a single-line slot inside the prompt so it goes through
// SanitizeSingleLine — a newline in the user's goal cannot terminate the
// "目的:" block and inject new instructions.
func buildPlannerPrompt(t *task.Task) string {
	goal := SanitizeSingleLine(t.Goal)
	return fmt.Sprintf(`以下のタスクを実行可能な subtask の DAG に分解してください。

目的:
%s

制約:
  - subtask は 1〜%d 個に収める
  - 各 subtask は独立した短い Copilot セッションで実装可能な粒度にする
  - 同一 worktree でシリアル実行されるため、並行性は DAG の表現上の概念であり実際の並列度ではない
  - agent_role は自由命名（planner / coder / tester / researcher / verifier など）
  - **ただし agent_role に "reviewer" / "ai_reviewer" を使用することは禁止**:
    レビューは専用の AI Review フェーズが実行後に別セッションで実施するため、
    プラン内で二重化しないこと。読み取り専用の検証 subtask が必要な場合は
    role を "verifier" などにし、変更を生成しない読み取りだけの作業にする。
  - depends_on は同じプラン内の subtask id を参照する（循環禁止）
  - id はプラン内で一意な短い英数字（例: "s1", "s2"）

出力フォーマット（これ以外は出力しない）:
%s
{
  "subtasks": [
    {"id": "s1", "title": "...", "agent_role": "...", "depends_on": []},
    {"id": "s2", "title": "...", "agent_role": "...", "depends_on": ["s1"]}
  ]
}
%s`, goal, MaxPlannerSubtasks, plannerJSONTag, plannerJSONTag)
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
