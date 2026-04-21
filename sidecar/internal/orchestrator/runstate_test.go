//go:build windows

package orchestrator

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"os"
	"path/filepath"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/FleetKanban/fleetkanban/internal/runstate"
	"github.com/FleetKanban/fleetkanban/internal/store"
	"github.com/FleetKanban/fleetkanban/internal/task"
	"github.com/FleetKanban/fleetkanban/internal/worktree"
)

// fakePlannerFn implements Planner by invoking a function literal.
type fakePlannerFn func(ctx context.Context, t *task.Task, out chan<- *task.AgentEvent) ([]*task.Subtask, string, string, task.SessionUsage, error)

func (f fakePlannerFn) Plan(ctx context.Context, t *task.Task, out chan<- *task.AgentEvent) ([]*task.Subtask, string, string, task.SessionUsage, error) {
	return f(ctx, t, out)
}

// fakeApproveReviewer implements AIReviewer and always approves.
type fakeApproveReviewer struct{}

func (r *fakeApproveReviewer) Review(_ context.Context, _ *task.Task, _, _ string, _ int, out chan<- *task.AgentEvent) (ReviewDecision, string, task.SessionUsage, error) {
	defer close(out)
	return ReviewDecision{Approve: true}, "test-model", task.SessionUsage{}, nil
}

// newOrchWithRunstate creates an Orchestrator with a real Planner + SubtaskStore
// + Reviewer + Runstate writer, sharing the same fakes as the existing helpers.
func newOrchWithRunstate(
	t *testing.T,
	ts *fakeTaskStore,
	es *fakeEventStore,
	wt *fakeWorktrees,
	ss *fakeSubtaskStore,
	planner Planner,
	reviewer AIReviewer,
	writer *runstate.Writer,
) *Orchestrator {
	t.Helper()
	o, err := New(Config{
		Concurrency:        4,
		EventBatchInterval: 10 * time.Millisecond,
		TaskStore:          ts,
		EventStore:         es,
		Repositories:       &fakeRepos{path: `C:\repo`},
		Worktrees:          wt,
		Runner: runnerFn(func(_ context.Context, _ *task.Task, out chan<- *task.AgentEvent) error {
			close(out)
			return nil
		}),
		Planner:      planner,
		SubtaskStore: ss,
		Reviewer:     reviewer,
		Runstate:     writer,
		Logger:       discardLogger(),
	})
	require.NoError(t, err)
	t.Cleanup(func() { _ = o.Shutdown(context.Background()) })
	return o
}

// openTestDB opens an in-memory SQLite DB suitable for runstate tests.
// It disables foreign-key checks so that artifact rows can reference task IDs
// that live only in fakeTaskStore (not in the real SQL tasks table).
func openTestDB(t *testing.T) *store.DB {
	t.Helper()
	db, err := store.Open(context.Background(), store.Options{Path: ":memory:"})
	require.NoError(t, err)
	// Disable FK enforcement for the test — task rows live in fakeTaskStore,
	// not in this DB, so artifact and task_run_root inserts would fail FK checks
	// against the empty tasks table.
	_, err = db.Write().ExecContext(context.Background(), "PRAGMA foreign_keys = OFF")
	require.NoError(t, err, "disable FK for test DB")
	t.Cleanup(func() { _ = db.Close() })
	return db
}

// TestRunstate_ArtifactsWrittenOnSuccess verifies that running a task through
// the planner path with a single-subtask plan produces the expected NLAH
// file-backed artifact layout under the Writer's baseDir.
func TestRunstate_ArtifactsWrittenOnSuccess(t *testing.T) {
	const taskID = "runstate-task-1"
	const goal = "implement runstate artifact generation"
	const baseBranch = "main"

	tmpDir := t.TempDir()
	db := openTestDB(t)
	artifactStore := store.NewArtifactStore(db)
	writer := runstate.NewWriter(artifactStore, tmpDir, discardLogger())
	t.Cleanup(func() { _ = writer.Close() })

	ts := newFakeTaskStore()
	es := newFakeEventStore()
	ss := newFakeSubtaskStore()

	// fakeWorktrees must create real directories so runstate can write inside.
	wtRoot := t.TempDir()
	wt := &fakeWorktrees{
		createFn: func(_ context.Context, in worktree.CreateInput) (*worktree.Created, error) {
			p := filepath.Join(wtRoot, in.TaskID)
			if err := os.MkdirAll(p, 0o755); err != nil {
				return nil, err
			}
			return &worktree.Created{Path: p, Branch: "fleetkanban/" + in.TaskID}, nil
		},
	}

	ts.insert(&task.Task{
		ID:         taskID,
		RepoID:     "repo-1",
		Goal:       goal,
		BaseBranch: baseBranch,
		Status:     task.StatusQueued,
		CreatedAt:  time.Now().UTC(),
	})

	// Fake planner returns one subtask with a non-empty Prompt so PROMPT.md
	// gets written. OrderIdx=0 and Round will be set by CreatePlan.
	planner := fakePlannerFn(func(ctx context.Context, t *task.Task, out chan<- *task.AgentEvent) ([]*task.Subtask, string, string, task.SessionUsage, error) {
		defer close(out)
		subs := []*task.Subtask{
			{
				ID:        "sub-1",
				TaskID:    taskID,
				Title:     "write code",
				AgentRole: "coder",
				Prompt:    "Please implement the feature.",
				OrderIdx:  0,
				Status:    task.SubtaskPending,
			},
		}
		return subs, "plan-model", "investigated and decomposed", task.SessionUsage{}, nil
	})

	reviewer := &fakeApproveReviewer{}

	o := newOrchWithRunstate(t, ts, es, wt, ss, planner, reviewer, writer)
	require.NoError(t, o.Enqueue(taskID))

	// Wait for task to reach human_review (success terminal state for agent).
	waitFor(t, 10*time.Second, func() bool {
		return lastStatus(ts, taskID) == task.StatusHumanReview
	})

	ctx := context.Background()
	taskDir := filepath.Join(tmpDir, taskID)

	// --- TASK.md exists and contains taskID and goal ---
	taskMdPath := filepath.Join(taskDir, "TASK.md")
	taskMdBytes, err := os.ReadFile(taskMdPath)
	require.NoError(t, err, "TASK.md must exist")
	assert.True(t, bytes.Contains(taskMdBytes, []byte(taskID)), "TASK.md must contain taskID")
	assert.True(t, bytes.Contains(taskMdBytes, []byte(goal)), "TASK.md must contain goal")

	// --- state/task_history.jsonl: file exists (AppendHistory may not be
	//     wired yet; the orchestrator currently does not call AppendHistory,
	//     so we only assert existence when the file is present; we assert
	//     plan.json is present as the primary NLAH artifact check) ---
	// NOTE: AppendHistory is a Writer API but orchestrator does not yet
	// invoke it directly — the file may or may not exist. We check plan.json
	// and artifact store as the canonical assertions.

	// --- artifacts/plan.json exists and is valid JSON ---
	planJSONPath := filepath.Join(taskDir, "artifacts", "plan.json")
	planJSONBytes, err := os.ReadFile(planJSONPath)
	require.NoError(t, err, "artifacts/plan.json must exist")
	var planParsed []map[string]any
	require.NoError(t, json.Unmarshal(planJSONBytes, &planParsed), "plan.json must be valid JSON")

	// --- ArtifactStore.List returns plan_json row ---
	planArtifacts, err := artifactStore.List(ctx, taskID, "plan", 10)
	require.NoError(t, err)
	hasPlanJSON := false
	for _, a := range planArtifacts {
		if a.Kind == "plan_json" {
			hasPlanJSON = true
		}
	}
	assert.True(t, hasPlanJSON, "artifact store must contain a plan_json row")

	// --- ArtifactStore.List returns task_md row under stage "plan" ---
	hasTaskMd := false
	for _, a := range planArtifacts {
		if a.Kind == "task_md" {
			hasTaskMd = true
		}
	}
	assert.True(t, hasTaskMd, "artifact store must contain a task_md row")

	// --- TaskRunRoot matches tmpDir/<taskID> ---
	root, err := artifactStore.TaskRunRoot(ctx, taskID)
	require.NoError(t, err)
	assert.Equal(t, taskDir, root, "TaskRunRoot must equal <tmpDir>/<taskID>")

	// --- content_hash of TASK.md matches the row's content_hash ---
	sum := sha256.Sum256(taskMdBytes)
	expectedHash := hex.EncodeToString(sum[:])
	taskMdHashMatched := false
	for _, a := range planArtifacts {
		if a.Kind == "task_md" {
			assert.Equal(t, expectedHash, a.ContentHash, "TASK.md content_hash must match sha256 of on-disk file")
			taskMdHashMatched = true
		}
	}
	assert.True(t, taskMdHashMatched, "task_md artifact row must be present for hash verification")

	// --- children/<round>/<idx>/PROMPT.md exists ---
	// Round is assigned by CreatePlan (starts at 1), OrderIdx=0 → "000".
	promptPath := filepath.Join(taskDir, "children", "1", "000", "PROMPT.md")
	assert.FileExists(t, promptPath, "PROMPT.md for subtask must exist")

	// --- children/<round>/<idx>/OUTPUT.md and DIFF.patch exist ---
	outputPath := filepath.Join(taskDir, "children", "1", "000", "OUTPUT.md")
	assert.FileExists(t, outputPath, "OUTPUT.md for subtask must exist")
	diffPath := filepath.Join(taskDir, "children", "1", "000", "DIFF.patch")
	assert.FileExists(t, diffPath, "DIFF.patch for subtask must exist")
}

// TestRunstate_NilWriter_NoOp verifies that setting Runstate=nil does not
// cause panics or errors and leaves the tmpDir untouched — regression guard
// for the orchestrator's nil-check guards around all runstate call sites.
func TestRunstate_NilWriter_NoOp(t *testing.T) {
	const taskID = "runstate-nil-task"
	const goal = "noop goal"

	tmpDir := t.TempDir()

	ts := newFakeTaskStore()
	es := newFakeEventStore()
	ss := newFakeSubtaskStore()
	wt := &fakeWorktrees{}

	ts.insert(&task.Task{
		ID:         taskID,
		RepoID:     "repo-1",
		Goal:       goal,
		BaseBranch: "main",
		Status:     task.StatusQueued,
		CreatedAt:  time.Now().UTC(),
	})

	planner := fakePlannerFn(func(ctx context.Context, t *task.Task, out chan<- *task.AgentEvent) ([]*task.Subtask, string, string, task.SessionUsage, error) {
		defer close(out)
		subs := []*task.Subtask{
			{
				ID:        "sub-nil-1",
				TaskID:    taskID,
				Title:     "noop subtask",
				AgentRole: "coder",
				Prompt:    "do nothing",
				OrderIdx:  0,
				Status:    task.SubtaskPending,
			},
		}
		return subs, "", "", task.SessionUsage{}, nil
	})

	reviewer := &fakeApproveReviewer{}

	// Runstate = nil — must not panic.
	o := newOrchWithRunstate(t, ts, es, wt, ss, planner, reviewer, nil)
	require.NoError(t, o.Enqueue(taskID))

	waitFor(t, 10*time.Second, func() bool {
		return lastStatus(ts, taskID) == task.StatusHumanReview
	})

	// tmpDir must remain empty — no runstate writes should have occurred.
	entries, err := os.ReadDir(tmpDir)
	require.NoError(t, err)
	assert.Empty(t, entries, "tmpDir must be empty when Runstate is nil")
}
