package store

import (
	"context"
	"database/sql"
	"fmt"
)

// schemaMigrations is an ordered list of forward-only migrations.
// Each migration is applied inside a transaction and recorded in the
// schema_migrations table. Down migrations are intentionally absent:
// backward migrations are handled by an explicit DB dump / restore.
var schemaMigrations = []migration{
	{
		Version: 1,
		Name:    "initial",
		SQL: `
CREATE TABLE repositories (
    id                  TEXT    PRIMARY KEY,
    path                TEXT    NOT NULL UNIQUE,
    display_name        TEXT    NOT NULL,
    default_base_branch TEXT,
    created_at          TEXT    NOT NULL,
    last_used_at        TEXT
);

CREATE TABLE tasks (
    id            TEXT    PRIMARY KEY,
    repository_id TEXT    NOT NULL REFERENCES repositories(id) ON DELETE RESTRICT,
    goal          TEXT    NOT NULL,
    base_branch   TEXT    NOT NULL,
    branch        TEXT,
    worktree_path TEXT,
    branch_exists INTEGER NOT NULL DEFAULT 1,
    model         TEXT    NOT NULL DEFAULT '',
    status        TEXT    NOT NULL CHECK(status IN (
        'pending','running','awaiting_review',
        'completed','merged','aborted','cancelled','failed'
    )),
    error_code    TEXT    NOT NULL DEFAULT '',
    error_message TEXT    NOT NULL DEFAULT '',
    created_at    TEXT    NOT NULL,
    updated_at    TEXT    NOT NULL,
    started_at    TEXT,
    finished_at   TEXT
);
CREATE INDEX tasks_status_updated ON tasks(status, updated_at DESC);
CREATE INDEX tasks_repository      ON tasks(repository_id);

CREATE TABLE events (
    id         TEXT    NOT NULL PRIMARY KEY,
    task_id    TEXT    NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    seq        INTEGER NOT NULL,
    occurred_at TEXT   NOT NULL,
    kind       TEXT    NOT NULL,
    payload    TEXT    NOT NULL,
    UNIQUE(task_id, seq)
);
CREATE INDEX events_task_seq ON events(task_id, seq);

CREATE TABLE settings (
    key        TEXT PRIMARY KEY,
    value_json TEXT NOT NULL
);
`,
	},
	{
		Version: 2,
		Name:    "tasks_session_id",
		SQL: `
ALTER TABLE tasks ADD COLUMN session_id TEXT NOT NULL DEFAULT '';
`,
	},
	{
		// v3 replaces the legacy 4-state status vocabulary with the 6-column
		// Kanban model (planning → queued → in_progress → ai_review →
		// human_review → done) and introduces the `finalization` column to
		// distinguish Keep from Merged within Done. SQLite cannot alter a
		// CHECK constraint in place, so we rebuild the tasks table and
		// backfill the new columns from the old ones in the same migration.
		Version: 3,
		Name:    "tasks_6column_statuses",
		SQL: `
CREATE TABLE tasks_new (
    id            TEXT    PRIMARY KEY,
    repository_id TEXT    NOT NULL REFERENCES repositories(id) ON DELETE RESTRICT,
    goal          TEXT    NOT NULL,
    base_branch   TEXT    NOT NULL,
    branch        TEXT,
    worktree_path TEXT,
    branch_exists INTEGER NOT NULL DEFAULT 1,
    model         TEXT    NOT NULL DEFAULT '',
    status        TEXT    NOT NULL CHECK(status IN (
        'planning','queued','in_progress','ai_review','human_review',
        'done','aborted','cancelled','failed'
    )),
    finalization  TEXT    NOT NULL DEFAULT '' CHECK(finalization IN ('','keep','merged')),
    error_code    TEXT    NOT NULL DEFAULT '',
    error_message TEXT    NOT NULL DEFAULT '',
    session_id    TEXT    NOT NULL DEFAULT '',
    created_at    TEXT    NOT NULL,
    updated_at    TEXT    NOT NULL,
    started_at    TEXT,
    finished_at   TEXT
);

INSERT INTO tasks_new (
    id, repository_id, goal, base_branch, branch, worktree_path,
    branch_exists, model, status, finalization,
    error_code, error_message, session_id,
    created_at, updated_at, started_at, finished_at
)
SELECT
    id, repository_id, goal, base_branch, branch, worktree_path,
    branch_exists, model,
    CASE status
        WHEN 'pending'         THEN 'queued'
        WHEN 'running'         THEN 'in_progress'
        WHEN 'awaiting_review' THEN 'human_review'
        WHEN 'completed'       THEN 'done'
        WHEN 'merged'          THEN 'done'
        ELSE status
    END,
    CASE status
        WHEN 'completed' THEN 'keep'
        WHEN 'merged'    THEN 'merged'
        ELSE ''
    END,
    error_code, error_message, session_id,
    created_at, updated_at, started_at, finished_at
  FROM tasks;

DROP INDEX IF EXISTS tasks_status_updated;
DROP INDEX IF EXISTS tasks_repository;
DROP TABLE tasks;
ALTER TABLE tasks_new RENAME TO tasks;

CREATE INDEX tasks_status_updated ON tasks(status, updated_at DESC);
CREATE INDEX tasks_repository      ON tasks(repository_id);
`,
	},
	{
		// v4 adds the `review_feedback` column for the Human/AI Review
		// rework flow: reviewers can record why a task is being rerun,
		// and the orchestrator prepends that text to the next Copilot
		// prompt. Column is TEXT NOT NULL DEFAULT '' so existing rows
		// backfill cleanly without touching prior migrations.
		Version: 4,
		Name:    "tasks_review_feedback",
		SQL: `
ALTER TABLE tasks ADD COLUMN review_feedback TEXT NOT NULL DEFAULT '';
`,
	},
	{
		// v5 adds the `subtasks` table for manual subtask decomposition.
		// Subtasks are lightweight child items tied to a parent task
		// (CASCADE on parent delete). Status is a 3-value enum (todo /
		// doing / done) — intentionally simpler than the parent task
		// state machine because subtasks are user-managed checkpoints,
		// not independent Copilot runs. `order_idx` drives stable UI
		// ordering independent of id sort.
		Version: 5,
		Name:    "subtasks",
		SQL: `
CREATE TABLE subtasks (
    id         TEXT    PRIMARY KEY,
    task_id    TEXT    NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    title      TEXT    NOT NULL,
    status     TEXT    NOT NULL DEFAULT 'todo'
                         CHECK(status IN ('todo','doing','done')),
    order_idx  INTEGER NOT NULL DEFAULT 0,
    created_at TEXT    NOT NULL,
    updated_at TEXT    NOT NULL
);
CREATE INDEX subtasks_task_order ON subtasks(task_id, order_idx);
`,
	},
	{
		// v6 clears `repositories.default_base_branch` for all existing rows
		// to align the stored data with the new semantics: empty = auto-
		// detect mode (sidecar resolves origin/HEAD → main → master →
		// current HEAD at CreateTask time), non-empty = user-pinned.
		//
		// Pre-v6, registration captured whatever branch HEAD happened to
		// point at and stored it unconditionally — so repositories whose
		// initial branch was later renamed (master → main, legacy workflows
		// → trunk) would fail CreateTask with "base branch X does not
		// exist in repository". Clearing the column migrates every existing
		// repo into auto-detect mode; users can explicitly re-pin via the
		// Settings UI if they relied on a specific value.
		Version: 6,
		Name:    "repositories_clear_default_base_branch",
		SQL: `
UPDATE repositories SET default_base_branch = NULL;
`,
	},
	{
		// v8 extends subtasks for AI-authored plan execution. The planner
		// emits subtasks with an invented role (AgentRole) and a DAG
		// expressed via DependsOn; the executor runs them in topological
		// order. depends_on is stored as a JSON array of ULIDs in a single
		// TEXT column — Phase 1's DAGs are tiny (< 20 nodes), so a join
		// table is over-engineered. The status vocabulary loses `todo`
		// (replaced by `pending`, which carries the same "not started"
		// meaning but avoids the user-checklist connotation) and gains
		// `failed` so per-subtask error states can be persisted
		// independently of the parent task's state machine.
		//
		// SQLite cannot ALTER a CHECK constraint in place, so we rebuild
		// the subtasks table and backfill: todo rows map to pending, all
		// other existing statuses pass through unchanged. agent_role and
		// depends_on backfill empty for pre-v8 rows (legacy manual
		// subtasks predate the planner).
		Version: 8,
		Name:    "subtasks_planner_fields",
		SQL: `
CREATE TABLE subtasks_new (
    id         TEXT    PRIMARY KEY,
    task_id    TEXT    NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    title      TEXT    NOT NULL,
    agent_role TEXT    NOT NULL DEFAULT '',
    depends_on TEXT    NOT NULL DEFAULT '[]',
    status     TEXT    NOT NULL DEFAULT 'pending'
                         CHECK(status IN ('pending','doing','done','failed')),
    order_idx  INTEGER NOT NULL DEFAULT 0,
    created_at TEXT    NOT NULL,
    updated_at TEXT    NOT NULL
);

INSERT INTO subtasks_new (
    id, task_id, title, agent_role, depends_on,
    status, order_idx, created_at, updated_at
)
SELECT
    id, task_id, title, '', '[]',
    CASE status
        WHEN 'todo' THEN 'pending'
        ELSE status
    END,
    order_idx, created_at, updated_at
  FROM subtasks;

DROP INDEX IF EXISTS subtasks_task_order;
DROP TABLE subtasks;
ALTER TABLE subtasks_new RENAME TO subtasks;

CREATE INDEX subtasks_task_order ON subtasks(task_id, order_idx);
`,
	},
	{
		// v9 adds `rework_count` to tasks so the orchestrator can cap the
		// number of automatic ai_review → queued rework cycles per task.
		// Without a cap a misbehaving AI reviewer can burn unbounded
		// Copilot tokens re-running the same plan when the diff already
		// satisfies the reviewer's (phantom) complaint — observed on
		// task 01KPJ8PCE8B8TC3CXHAAKRXZ3J which looped 5+ times on
		// "CREATE TEST README" before we caught it.
		//
		// The counter is incremented in TaskStore.Transition when the
		// transition is ai_review→queued, and reset to 0 whenever a task
		// enters queued from any other source (human_review retry,
		// failed retry, aborted retry) or reaches a terminal status.
		// Pre-v9 rows backfill to 0 — they have no rework history recorded.
		Version: 9,
		Name:    "tasks_rework_count",
		SQL: `
ALTER TABLE tasks ADD COLUMN rework_count INTEGER NOT NULL DEFAULT 0;
`,
	},
	{
		// v10 records which model actually ran each stage so the UI can
		// surface Plan / Code / Review per-stage badges. `tasks.model`
		// predates this migration and continues to hold the Code-stage
		// default; `plan_model` and `review_model` are populated by the
		// planner and AI reviewer respectively when they run. Subtasks
		// get their own `code_model` so per-subtask overrides (e.g. a
		// researcher role using a cheaper model) are recorded alongside
		// the parent task's default rather than collapsing into one field.
		// All columns backfill to '' for pre-v10 rows — the UI renders
		// empty as "—" (no model recorded yet).
		Version: 10,
		Name:    "tasks_subtasks_stage_models",
		SQL: `
ALTER TABLE tasks    ADD COLUMN plan_model   TEXT NOT NULL DEFAULT '';
ALTER TABLE tasks    ADD COLUMN review_model TEXT NOT NULL DEFAULT '';
ALTER TABLE subtasks ADD COLUMN code_model   TEXT NOT NULL DEFAULT '';
`,
	},
	{
		// v11 introduces a per-task iteration counter ("round") on
		// subtasks so the UI can stack each rework cycle's plan side
		// by side with the previous one. Round 1 is the planner's
		// first decomposition; AI / Human REWORK and User Re-run
		// each create a fresh round at max+1, leaving the prior
		// round's subtasks intact for history. Existing rows
		// backfill to round 1 since they predate the iteration model.
		// The companion index is keyed (task_id, round) so listing
		// the latest round is a single index seek.
		Version: 11,
		Name:    "subtasks_round",
		SQL: `
ALTER TABLE subtasks ADD COLUMN round INTEGER NOT NULL DEFAULT 1;
CREATE INDEX subtasks_task_round ON subtasks(task_id, round);
`,
	},
	{
		// v12 gives each subtask a per-row `prompt` holding the concrete
		// instruction the planner wrote for that node. Before v12 the
		// executor only had the subtask title + agent role to infer
		// what to do, which left the Coder agent replanning on the
		// fly — burning tokens and producing inconsistent output. The
		// planner now emits a full instruction per subtask which
		// BuildSubtaskPrompt folds into the Copilot session prompt.
		// Existing rows backfill to empty; BuildSubtaskPrompt falls
		// back to the old title-only template when Prompt is empty.
		Version: 12,
		Name:    "subtasks_prompt",
		SQL: `
ALTER TABLE subtasks ADD COLUMN prompt TEXT NOT NULL DEFAULT '';
`,
	},
	{
		// v13 introduces the Context / Graph Memory subsystem. Structured
		// knowledge about each repository is stored as a property graph
		// (ctx_node + ctx_edge + ctx_closure), vector embeddings
		// (ctx_node_vec, BLOB-serialised float32 for pure-Go cosine
		// similarity since the embedded SQLite is modernc.org/sqlite
		// without CGO extension support), bi-temporal facts (ctx_fact),
		// a trust-gate pending queue (ctx_scratchpad), per-repo memory
		// settings (ctx_memory_settings), and an FTS5 mirror of node
		// text (ctx_node_fts) for BM25-ranked keyword search.
		//
		// Closure maintenance is performed from Go (internal/context/
		// graph) rather than SQL triggers because our graphs include
		// cycles (coAccessedWith) and rebuilding in Go with BFS is
		// simpler to reason about than recursive CTE triggers.
		//
		// All kind / rel / source_kind strings are free-form to mirror
		// AgentEvent.kind's proto convention: adding new categories
		// requires neither a schema change nor a proto bump. A small
		// set of canonical values are recognised by the retrieval and
		// injection layers; unknown values gracefully fall through.
		Version: 13,
		Name:    "context_graph_memory",
		SQL: `
CREATE TABLE ctx_node (
    id           TEXT    PRIMARY KEY,
    repo_id      TEXT    NOT NULL REFERENCES repositories(id) ON DELETE CASCADE,
    kind         TEXT    NOT NULL,
    label        TEXT    NOT NULL,
    content_md   TEXT    NOT NULL DEFAULT '',
    attrs_json   TEXT    NOT NULL DEFAULT '{}',
    source_kind  TEXT    NOT NULL,
    source_task_id    TEXT NOT NULL DEFAULT '',
    source_session_id TEXT NOT NULL DEFAULT '',
    confidence   REAL    NOT NULL DEFAULT 1.0,
    enabled      INTEGER NOT NULL DEFAULT 1 CHECK(enabled IN (0,1)),
    pinned       INTEGER NOT NULL DEFAULT 0 CHECK(pinned IN (0,1)),
    created_at   TEXT    NOT NULL,
    updated_at   TEXT    NOT NULL
);
CREATE INDEX ctx_node_repo_kind    ON ctx_node(repo_id, kind);
CREATE INDEX ctx_node_repo_updated ON ctx_node(repo_id, updated_at DESC);
CREATE INDEX ctx_node_repo_label   ON ctx_node(repo_id, label);

CREATE TABLE ctx_edge (
    id            TEXT    PRIMARY KEY,
    repo_id       TEXT    NOT NULL REFERENCES repositories(id) ON DELETE CASCADE,
    src_node_id   TEXT    NOT NULL REFERENCES ctx_node(id) ON DELETE CASCADE,
    dst_node_id   TEXT    NOT NULL REFERENCES ctx_node(id) ON DELETE CASCADE,
    rel           TEXT    NOT NULL,
    attrs_json    TEXT    NOT NULL DEFAULT '{}',
    created_at    TEXT    NOT NULL,
    UNIQUE(repo_id, src_node_id, dst_node_id, rel)
);
CREATE INDEX ctx_edge_src ON ctx_edge(src_node_id, rel);
CREATE INDEX ctx_edge_dst ON ctx_edge(dst_node_id, rel);
CREATE INDEX ctx_edge_repo_rel ON ctx_edge(repo_id, rel);

CREATE TABLE ctx_closure (
    repo_id       TEXT    NOT NULL,
    src_node_id   TEXT    NOT NULL,
    dst_node_id   TEXT    NOT NULL,
    depth         INTEGER NOT NULL,
    via_rel       TEXT    NOT NULL,
    PRIMARY KEY (repo_id, src_node_id, dst_node_id, via_rel)
);
CREATE INDEX ctx_closure_dst   ON ctx_closure(dst_node_id, depth);
CREATE INDEX ctx_closure_depth ON ctx_closure(repo_id, depth);

CREATE TABLE ctx_fact (
    id                TEXT    PRIMARY KEY,
    repo_id           TEXT    NOT NULL REFERENCES repositories(id) ON DELETE CASCADE,
    subject_node_id   TEXT    NOT NULL REFERENCES ctx_node(id) ON DELETE CASCADE,
    predicate         TEXT    NOT NULL,
    object_text       TEXT    NOT NULL,
    valid_from        TEXT    NOT NULL,
    valid_to          TEXT,
    supersedes        TEXT,
    created_at        TEXT    NOT NULL
);
CREATE INDEX ctx_fact_subject_from ON ctx_fact(subject_node_id, valid_from DESC);
CREATE INDEX ctx_fact_repo_active  ON ctx_fact(repo_id, valid_to);

CREATE TABLE ctx_scratchpad (
    id                    TEXT    PRIMARY KEY,
    repo_id               TEXT    NOT NULL REFERENCES repositories(id) ON DELETE CASCADE,
    proposed_kind         TEXT    NOT NULL,
    proposed_label        TEXT    NOT NULL,
    proposed_content_md   TEXT    NOT NULL DEFAULT '',
    proposed_attrs_json   TEXT    NOT NULL DEFAULT '{}',
    source_kind           TEXT    NOT NULL,
    source_ref            TEXT    NOT NULL DEFAULT '',
    signals_json          TEXT    NOT NULL DEFAULT '[]',
    confidence            REAL    NOT NULL DEFAULT 0.5,
    status                TEXT    NOT NULL DEFAULT 'pending'
                          CHECK(status IN ('pending','promoted','rejected','snoozed')),
    reject_reason         TEXT    NOT NULL DEFAULT '',
    snoozed_until         TEXT,
    promoted_node_id      TEXT,
    created_at            TEXT    NOT NULL,
    updated_at            TEXT    NOT NULL
);
CREATE INDEX ctx_scratchpad_repo_status  ON ctx_scratchpad(repo_id, status, updated_at DESC);
CREATE INDEX ctx_scratchpad_snoozed      ON ctx_scratchpad(status, snoozed_until);

CREATE TABLE ctx_node_vec (
    node_id     TEXT    PRIMARY KEY REFERENCES ctx_node(id) ON DELETE CASCADE,
    model       TEXT    NOT NULL,
    dim         INTEGER NOT NULL,
    vector      BLOB    NOT NULL,
    created_at  TEXT    NOT NULL
);
CREATE INDEX ctx_node_vec_model ON ctx_node_vec(model);

CREATE VIRTUAL TABLE ctx_node_fts USING fts5(
    label,
    content_md,
    repo_id UNINDEXED,
    content='ctx_node',
    content_rowid='rowid',
    tokenize='unicode61 remove_diacritics 2'
);

CREATE TABLE ctx_memory_settings (
    repo_id                      TEXT    PRIMARY KEY REFERENCES repositories(id) ON DELETE CASCADE,
    enabled                      INTEGER NOT NULL DEFAULT 0 CHECK(enabled IN (0,1)),
    embedding_provider           TEXT    NOT NULL DEFAULT 'ollama',
    embedding_model              TEXT    NOT NULL DEFAULT 'nomic-embed-text',
    embedding_dim                INTEGER NOT NULL DEFAULT 768,
    llm_provider                 TEXT    NOT NULL DEFAULT 'openai',
    llm_model                    TEXT    NOT NULL DEFAULT 'gpt-4o-mini',
    passive_token_budget         INTEGER NOT NULL DEFAULT 3000,
    top_k_neighbors              INTEGER NOT NULL DEFAULT 8,
    auto_promote_high_confidence INTEGER NOT NULL DEFAULT 0 CHECK(auto_promote_high_confidence IN (0,1)),
    auto_promote_threshold       REAL    NOT NULL DEFAULT 0.9,
    updated_at                   TEXT    NOT NULL
);

-- ctx_node_fts mirrors the ctx_node primary content. Triggers keep them
-- aligned so retrieval/search.go can issue FTS5 MATCH queries directly
-- without an explicit rebuild step.
CREATE TRIGGER ctx_node_ai AFTER INSERT ON ctx_node BEGIN
    INSERT INTO ctx_node_fts(rowid, label, content_md, repo_id)
    VALUES (new.rowid, new.label, new.content_md, new.repo_id);
END;
CREATE TRIGGER ctx_node_ad AFTER DELETE ON ctx_node BEGIN
    INSERT INTO ctx_node_fts(ctx_node_fts, rowid, label, content_md, repo_id)
    VALUES ('delete', old.rowid, old.label, old.content_md, old.repo_id);
END;
CREATE TRIGGER ctx_node_au AFTER UPDATE ON ctx_node BEGIN
    INSERT INTO ctx_node_fts(ctx_node_fts, rowid, label, content_md, repo_id)
    VALUES ('delete', old.rowid, old.label, old.content_md, old.repo_id);
    INSERT INTO ctx_node_fts(rowid, label, content_md, repo_id)
    VALUES (new.rowid, new.label, new.content_md, new.repo_id);
END;
`,
	},
}

type migration struct {
	Version int
	Name    string
	SQL     string
}

// migrate brings the database schema up to the latest version. It is
// idempotent: applied versions are skipped.
func migrate(ctx context.Context, db *sql.DB) error {
	if _, err := db.ExecContext(ctx, `
CREATE TABLE IF NOT EXISTS schema_migrations (
    version    INTEGER PRIMARY KEY,
    name       TEXT    NOT NULL,
    applied_at TEXT    NOT NULL
);`); err != nil {
		return fmt.Errorf("store: create schema_migrations: %w", err)
	}

	applied, err := loadApplied(ctx, db)
	if err != nil {
		return err
	}

	for _, m := range schemaMigrations {
		if _, ok := applied[m.Version]; ok {
			continue
		}
		if err := applyMigration(ctx, db, m); err != nil {
			return fmt.Errorf("store: migration %d (%s) failed: %w", m.Version, m.Name, err)
		}
	}
	return nil
}

func loadApplied(ctx context.Context, db *sql.DB) (map[int]struct{}, error) {
	rows, err := db.QueryContext(ctx, `SELECT version FROM schema_migrations`)
	if err != nil {
		return nil, fmt.Errorf("store: load schema_migrations: %w", err)
	}
	defer rows.Close()

	applied := map[int]struct{}{}
	for rows.Next() {
		var v int
		if err := rows.Scan(&v); err != nil {
			return nil, err
		}
		applied[v] = struct{}{}
	}
	return applied, rows.Err()
}

func applyMigration(ctx context.Context, db *sql.DB, m migration) error {
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}
	defer func() { _ = tx.Rollback() }()

	if _, err := tx.ExecContext(ctx, m.SQL); err != nil {
		return fmt.Errorf("apply: %w", err)
	}
	if _, err := tx.ExecContext(ctx,
		`INSERT INTO schema_migrations(version, name, applied_at) VALUES(?, ?, ?)`,
		m.Version, m.Name, nowUTC()); err != nil {
		return fmt.Errorf("record: %w", err)
	}
	return tx.Commit()
}
