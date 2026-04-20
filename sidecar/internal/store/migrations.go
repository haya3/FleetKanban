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
