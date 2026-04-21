# Architecture

This document describes the overall technical design of FleetKanban. It separates
the parts to be completed in Phase 1 from those to be added incrementally in
Phase 2 and beyond.
The target OS is **Windows 11 (64-bit) only**, and **"optimizing for the native
Windows 11 experience"** is the highest-priority non-functional requirement.
We make no compromises for multi-OS support (all code assumes
`runtime.GOOS == "windows"`, and no build tags are provided for other OSes).

---

## 1. Design Goals

1. **Windows 11 Optimization (Top Priority)**
   Paths, filesystem, processes, Git, UI/fonts, notifications, and signing all
   use Windows 11-specific APIs as first-class citizens; no cross-OS abstraction
   layer is interposed. (Historical note: earlier drafts referenced a separate
   `phase1-spec.md` §9 for the Windows-specific details; that spec has been
   absorbed into this document and the relevant material now lives across §2.6,
   §5, §6, and §8. Stale `phase1-spec.md` mentions that still appear in source
   comments will be cleaned up in a follow-up pass.)
2. **Safe Isolation of the Agent Execution Substrate**
   Each task gets its own git worktree, and the Copilot CLI is launched as an
   independent child process with that worktree as its cwd. It does not affect
   the main branch or other tasks.
3. **Thin Adapter Layer Wrapping the Copilot CLI**
   Argument, environment variable, and session-event parsing logic for the
   Copilot SDK is confined to `internal/copilot`. The core models
   (`internal/task` / `internal/orchestrator`) only call it through the abstract
   `AgentRunner`.
4. **Flutter (Windows Desktop) UI First**
   No CLI is provided. From Phase 1, the Flutter app is the sole user interface;
   the backend is separated as a Go gRPC sidecar (Electron / Wails / Web UI are
   not adopted).
5. **Extensible Module Boundaries**
   An `AgentRunner` interface is provided to allow swapping in agent engines
   other than Copilot (e.g., a future alternative CLI).

---

## 2. Module Layout

```
┌─────────────────────────────────────────────────────────────────┐
│                fleetkanban_ui.exe (Flutter Windows)              │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │  Flutter UI (Dart / fluent_ui)                             │  │
│  │  Kanban / Terminal / Chat / Settings                       │  │
│  │                                                            │  │
│  │  lib/infra/ipc/sidecar_supervisor.dart                     │  │
│  │   ├─ launches sidecar as child process (awaits READY)      │  │
│  │   └─ gRPC client (loopback + x-auth-token metadata)        │  │
│  └──────────────────────────────┬─────────────────────────────┘  │
│                                 │ loopback gRPC (127.0.0.1:N)    │
└─────────────────────────────────┼────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────┐
│       fleetkanban-sidecar.exe (headless Go gRPC backend)         │
│                                                                  │
│  internal/ipc                                                    │
│   ├─ gRPC server (proto/fleetkanban/v1/fleetkanban.proto)        │
│   ├─ auth.go (x-auth-token metadata verification)                │
│   ├─ broker.go (AgentEvent fan-out → Dart stream)                │
│   └─ convert.go (Go domain types ↔ protobuf)                     │
│                                                                  │
│  internal/app                                                    │
│   └─ Service (domain use cases invoked via gRPC)                 │
│                                                                  │
│  internal/ ── orchestrator / task / store (SQLite) /             │
│               ctxmem / runstate / ihr / harnessembed / setup /   │
│               worktree / copilot / reaper / winapi / branding    │
└─────────────────────────────────┬────────────────────────────────┘
                                  │
                                  ▼
                 ┌────────────────────────────────────┐
                 │   Copilot CLI server subprocess    │
                 │   (managed by SDK over stdio)      │
                 │   cwd = <worktreePath>             │
                 └────────────────────────────────────┘
```

### 2.1 `internal/task`

- Pure domain types for Task / AgentEvent / TaskError (DB- and CLI-independent).
- State transition function (`Transition(old, new) error`) validates transitions.

### 2.2 `internal/store`

- SQLite persistence. Uses `modernc.org/sqlite` (pure Go, no CGO) via `database/sql`.
- Provides three repositories: `TaskStore` / `RepositoryStore` / `EventStore`.
- Writes are serialized on a single goroutine (serializer); concurrent reads are
  delegated to WAL.

### 2.3 `internal/worktree`

- Wrapper for `git worktree add/remove/list`. Invokes `git` via `os/exec`.
- Per-repo `sync.Mutex` serializes `add` / `remove`.
- Orphan worktree reclamation at startup (see §4).

### 2.4 `internal/orchestrator`

- Task lifecycle management.
- Concurrency control: `golang.org/x/sync/semaphore` with a default of 4 and a
  cap of 12.
- Dispatches to `AgentRunner` and fans out AgentEvents (store write + delivery
  to Flutter via the gRPC broker).

### 2.5 `internal/copilot`

`AgentRunner` implementation based on the **GitHub Copilot SDK for Go**. Fully
migrated from direct CLI invocation to SDK-based invocation.

- **embedded CLI**: The bundler (`go tool bundler`) generates
  `sidecar/cmd/fleetkanban-sidecar/zcopilot_windows_amd64.go`, which passes the
  CLI binary to `embeddedcli.Setup` in `init()`. The SDK extracts it to
  `%LOCALAPPDATA%\copilot-sdk\` at startup.
- **Runtime** (`client.go`): Constructs a client with `copilot.NewClient` and
  starts the CLI server process with `Start(ctx)`. `Stop()` disconnects all
  sessions and terminates the server. `CheckAuth(ctx)` queries authentication
  status via the `auth.getStatus` RPC (side-effect free; `--list-env` parsing
  has been removed).
- **Runner** (`runner.go`): Implements `AgentRunner`. `CreateSession`
  establishes an SDK session; the `session.On(...)` event handler converts
  `SessionEvent` to `task.AgentEvent` and emits it on the out channel. Receiving
  `SessionIdle` marks session completion and fires `EventSessionIdle`.
- **permission handler** (`permission.go`): `NewPermissionHandler(worktreeRoot)`
  returns a `copilot.PermissionHandlerFunc`. It validates the `FileName` of
  Write requests with a `GetFinalPathNameByHandleW`-based guard and immediately
  rejects paths outside the worktree with `denied-by-rules`. Other kinds
  (Shell / Read / MCP, etc.) are approved.
- **Event conversion** (`events.go`): `MapSessionEvent(SessionEvent) *task.AgentEvent`
  is a pure function. A type switch maps `AssistantMessageDeltaData → assistant.delta`,
  `AssistantReasoningDeltaData → assistant.reasoning.delta`,
  `ToolExecutionStartData → tool.start`, `ToolExecutionCompleteData → tool.end`,
  and `SessionErrorData → error`.
- **Model resolution**: At startup, `client.ListModels(ctx)` is called and the
  first model matching the order `claude-sonnet-4.6 → claude-sonnet-4.5 → gpt-5`
  is selected.

### 2.6 `internal/winapi`

A thin package that calls Win32 APIs directly from Go. Combines
`golang.org/x/sys/windows` with raw syscalls. Covers only functionality that is
self-contained in the sidecar (UI flicker, Mica rendering, etc., are handled on
the Flutter side).

- **Job Object**: `CreateJobObjectW` + `SetInformationJobObject(JobObjectExtendedLimitInformation, JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE)`
  + `AssignProcessToJobObject`. When Flutter spawns the sidecar as a child
  process, Flutter attaches its own Job Object too; the sidecar side retains the
  file to guarantee termination of Copilot child processes (calls are minimal in
  Phase 1 since the SDK manages the server).
- **DPAPI**: Encrypts tokens such as GitHub PAT with `CryptProtectData` /
  `CryptUnprotectData` and stores them in `%APPDATA%\FleetKanban\settings.json`
  (user scope).
- **Toast**: Equivalent to WinRT `ToastNotificationManager`. In Phase 1, generates
  XML templates and dispatches via `IToastNotificationManagerStatics`.
- **AppUserModelID**: `SetCurrentProcessExplicitAppUserModelID(L"com.fleetkanban.desktop")`
  is called immediately after sidecar startup (required for grouping Toast
  notifications). The Flutter-side `fleetkanban_ui.exe` declares the same AUMID
  in its MSIX manifest.

### 2.7 `internal/app` (Domain Service)

- Exposes a `Service` type that bundles Orchestrator / Store / Copilot / Worktree
  on a per-use-case basis.
- Arguments and return values are pure Go types (protobuf-independent) and are
  only called from the gRPC layer.
- The `internal/ipc` side performs protobuf ↔ Go type conversion (`convert.go`).

### 2.8 `internal/ipc` (gRPC Server)

- The proto schema is `proto/fleetkanban/v1/fleetkanban.proto`; Go stubs are
  generated into `sidecar/internal/ipc/gen/fleetkanban/`.
- `server.go`: `grpc.NewServer` + unary/stream interceptors embed the token
  verification from `auth.go` and delegate to `app.Service`.
- `auth.go`: Constant-time compare (`crypto/subtle.ConstantTimeCompare`) between
  the base64 token generated at sidecar startup and `metadata["x-auth-token"]`.
- `broker.go`: Fans out `task.AgentEvent`s received on the Orchestrator's
  `EventSink` to each Dart client subscribed to the gRPC server-streaming RPC
  (`TaskService.WatchEvents`). Backpressure for slow subscribers is absorbed by
  a per-subscriber ring buffer.
- `convert.go`: Converts between protobuf and Go types (`pb.Task ↔ task.Task`,
  etc.).

### 2.9 `proto/fleetkanban/v1/`

- `fleetkanban.proto` — the single source of truth for the gRPC schema.
- `buf.gen.yaml` — Go generation (`protoc-gen-go` + `protoc-gen-go-grpc`).
- `buf.gen.dart.yaml` — Dart generation (`protoc_plugin`).
- `task proto:gen:all` regenerates both Go and Dart in one shot.

### 2.10 `ui/`

- Flutter 3.27+ (Windows desktop enabled).
- Main dependencies: [`fluent_ui`](https://pub.dev/packages/fluent_ui)
  (Windows 11 native-style UI), [`grpc`](https://pub.dev/packages/grpc) +
  `protobuf`, [`flutter_acrylic`](https://pub.dev/packages/flutter_acrylic)
  (Mica / Acrylic), [`window_manager`](https://pub.dev/packages/window_manager),
  [`graphview`](https://pub.dev/packages/graphview) (Sugiyama layout for the
  Subtask DAG), [`flutter_riverpod`](https://pub.dev/packages/flutter_riverpod) 3.x
  with `riverpod_generator` code generation. `xterm` is pinned in `pubspec.yaml`
  as a Phase D placeholder (interactive agent terminal is not wired in Phase 1;
  the `status/` feature shows a read-only streaming agent activity log instead).
- Directory layout (under `lib/`):
  - `app/` — `FluentApp` initialization, routing, theme, `version.dart`
    (sidecar protocol version the UI expects).
  - `domain/` — Dart-side domain types (Task / Subtask / AgentEvent, etc.;
    proto artifacts are projected into domain models).
  - `features/` — per-screen: `auth/`, `kanban/`, `context/`, `review/`,
    `harness/`, `insights/`, `worktrees/`, `housekeeping/`, `preconditions/`,
    `status/` (streaming agent activity log; read-only), `settings/`,
    `placeholder/` (ComingSoon stubs for later-phase features).
  - `infra/ipc/` — `SidecarSupervisor` (sidecar child-process management +
    handshake), gRPC client wrappers, and proto stubs under `generated/`.
  - `infra/platform/` — Win32 interop (e.g. `taskbar_overlay.dart`).
  - `theme/` — font and color tokens.
- Lint: `analysis_options.yaml` (based on `flutter_lints`).

---

## 3. Data Model (Overview)

### 3.1 Go Type Definitions (Excerpt)

```go
package task

type Status string

// Kanban columns map 1:1 to primary statuses:
// planning / queued / in_progress / ai_review / human_review / done.
// Cancelled / Aborted / Failed are side branches, not columns.
const (
    StatusPlanning    Status = "planning"     // just created; editable, not yet queued
    StatusQueued      Status = "queued"       // user pressed Run; awaiting orchestrator pick
    StatusInProgress  Status = "in_progress"  // Copilot session active
    StatusAIReview    Status = "ai_review"    // automated verification (Phase 2 populates this stage)
    StatusHumanReview Status = "human_review" // awaiting user Keep / Merge / Discard decision
    StatusDone        Status = "done"         // finalized successfully; see Task.Finalization
    StatusCancelled   Status = "cancelled"    // Discard: worktree and branch both removed
    StatusAborted     Status = "aborted"      // User aborted during InProgress; worktree and branch kept
    StatusFailed      Status = "failed"       // Runtime error
)

// FinalizationKind distinguishes how a Done task was closed. Empty for
// non-Done statuses; required for Done.
type FinalizationKind string

const (
    FinalizationNone   FinalizationKind = ""       // non-Done status
    FinalizationKeep   FinalizationKind = "keep"   // worktree removed, branch preserved
    FinalizationMerged FinalizationKind = "merged" // merged into target branch; both removed
)

type ErrorCode string

const (
    ErrCodeNone          ErrorCode = ""
    ErrCodeRuntime       ErrorCode = "runtime"        // Copilot CLI exit non-zero or unexpected
    ErrCodeInterrupted   ErrorCode = "interrupted"    // crash recovery: running at app crash
    ErrCodePathEscape    ErrorCode = "path_escape"    // attempted write outside worktree
    ErrCodeMergeConflict ErrorCode = "merge_conflict" // reserved for merge operation failures
    ErrCodeTimeout       ErrorCode = "timeout"
    ErrCodeAuth          ErrorCode = "auth"           // Copilot CLI not authenticated
    ErrCodeAIReview      ErrorCode = "ai_review"      // automated verification failed (Phase 2)
)

type Task struct {
    ID             string           // ULID
    RepoID         string           // FK repositories.id
    Goal           string
    BaseBranch     string
    Branch         string           // fleetkanban/<ID>
    WorktreePath   string
    Model          string           // Code-stage model (primary Copilot CLI identifier)
    PlanModel      string           // model that actually ran the Plan stage ("" if none)
    ReviewModel    string           // model that actually ran the Review stage ("" if none)
    Status         Status
    Finalization   FinalizationKind // set only when Status == StatusDone
    ErrorCode      ErrorCode        // set only when Status == StatusFailed
    ErrorMessage   string
    SessionID      string           // Copilot SDK session identifier
    BranchExists   bool             // false once reaper detects external branch deletion
    ReviewFeedback string           // most recent reviewer feedback; prepended on rework
    ReworkCount    int              // AI Review → Queued auto-rework counter (capped to prevent loops)
    CreatedAt      time.Time
    UpdatedAt      time.Time
    StartedAt      *time.Time       // first StatusInProgress entry
    FinishedAt     *time.Time       // most recent review/terminal entry (cleared on rework)
}
```

Subtasks are a separate first-class model (see §2.4 and §3.4). The planner
emits a DAG; `Subtask.DependsOn` is a JSON array of ULIDs stored in a single
column (Phase 1 DAGs are < 20 nodes, so a join table is over-engineered).
Status vocabulary: `pending / doing / done / failed`. Each subtask also
records the `CodeModel` it ran with and a `Round` counter so successive
rework iterations stack side by side in the UI instead of overwriting.

On the Dart side, proto artifacts (`pb.Task`, etc.) are projected into domain
models (`lib/domain/`) for use; exchange with Flutter uses protobuf
exclusively.

### 3.2 AgentEvent

The `events` table and the on-wire `AgentEvent` message use a free-form
`kind TEXT` string rather than a fixed enum. This matches the proto
convention (adding a new category requires no schema change or proto
bump) and lets us extend the vocabulary gracefully as Phase 2+ stages
surface new event kinds. Representative kinds emitted today:

- `assistant.delta`, `assistant.reasoning.delta`
- `tool.start`, `tool.end`
- `permission.request`, `session.idle`
- `review.submitted`, `stage.transition`, `subtask.started`
- `error`, `security.path_escape`

```go
type AgentEvent struct {
    ID         string    // ULID
    TaskID     string
    Seq        int64
    OccurredAt time.Time
    Kind       string    // free-form; see representative kinds above
    Payload    string    // JSON-encoded kind-specific fields
}
```

The SDK's `SessionEvent` is normalized into `AgentEvent`s (see §5) and
fanned out to Flutter as a gRPC `WatchEvents` server-streaming RPC.

### 3.3 Data Storage Location

The default root for data is `%APPDATA%\FleetKanban\` (resolved via
`os.UserConfigDir()` at sidecar startup). If a Folder Redirection in an
enterprise environment returns a UNC path, it falls back to
`%LOCALAPPDATA%\FleetKanban\`.

```
%APPDATA%\FleetKanban\
├── fleetkanban.db         # SQLite main database (repositories / tasks / events / settings tables)
├── settings.json          # DPAPI-encrypted PAT / UI settings
├── logs\
│   └── <task-id>.jsonl    # Raw agent-event log (secondary debug output)
└── worktrees\             # Fallback when the target repo's parent is not writable
    └── <repo-hash>\<task-id>\
```

The default placement for task worktrees is directly under the target
repository's parent directory:

```
<repo-parent>\
├── <repo-name>\           # The target repository
└── .fleetkanban-worktrees\
    └── <task-id>\         # Working tree for each task (fleetkanban/<task-id> branch)
```

### 3.4 SQLite Schema

The live schema is defined forward-only by `sidecar/internal/store/migrations.go`
(v18 as of this writing); the summary below captures the current shape.
Future migrations update this section when they land.

```sql
CREATE TABLE repositories (
  id                  TEXT PRIMARY KEY,              -- ULID
  path                TEXT NOT NULL UNIQUE,          -- absolute path (lowercased)
  display_name        TEXT NOT NULL,
  default_base_branch TEXT,                          -- empty = auto-detect mode
  created_at          TEXT NOT NULL,
  last_used_at        TEXT
);

CREATE TABLE tasks (
  id              TEXT PRIMARY KEY,
  repository_id   TEXT NOT NULL REFERENCES repositories(id) ON DELETE RESTRICT,
  goal            TEXT NOT NULL,
  base_branch     TEXT NOT NULL,
  branch          TEXT,                              -- fleetkanban/<id>
  worktree_path   TEXT,
  branch_exists   INTEGER NOT NULL DEFAULT 1,        -- 0 if externally deleted
  model           TEXT NOT NULL DEFAULT '',          -- Code-stage model
  plan_model      TEXT NOT NULL DEFAULT '',          -- model that ran Plan
  review_model    TEXT NOT NULL DEFAULT '',          -- model that ran Review
  status          TEXT NOT NULL CHECK(status IN (
    'planning','queued','in_progress','ai_review','human_review',
    'done','aborted','cancelled','failed'
  )),
  finalization    TEXT NOT NULL DEFAULT '' CHECK(finalization IN ('','keep','merged')),
  error_code      TEXT NOT NULL DEFAULT '',
  error_message   TEXT NOT NULL DEFAULT '',
  session_id      TEXT NOT NULL DEFAULT '',
  review_feedback TEXT NOT NULL DEFAULT '',          -- prepended on rework
  rework_count    INTEGER NOT NULL DEFAULT 0,        -- ai_review→queued auto-rework cap
  created_at      TEXT NOT NULL,
  updated_at      TEXT NOT NULL,
  started_at      TEXT,
  finished_at     TEXT
);
CREATE INDEX tasks_status_updated ON tasks(status, updated_at DESC);
CREATE INDEX tasks_repository     ON tasks(repository_id);

CREATE TABLE subtasks (
  id         TEXT PRIMARY KEY,
  task_id    TEXT NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  title      TEXT NOT NULL,
  agent_role TEXT NOT NULL DEFAULT '',               -- planner-assigned specialist role
  depends_on TEXT NOT NULL DEFAULT '[]',             -- JSON array of subtask ULIDs (DAG edges)
  prompt     TEXT NOT NULL DEFAULT '',               -- planner-authored per-node instruction
  status     TEXT NOT NULL DEFAULT 'pending'
             CHECK(status IN ('pending','doing','done','failed')),
  order_idx  INTEGER NOT NULL DEFAULT 0,
  round      INTEGER NOT NULL DEFAULT 1,             -- rework iteration counter
  code_model TEXT NOT NULL DEFAULT '',               -- model that ran this subtask's code stage
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
CREATE INDEX subtasks_task_order ON subtasks(task_id, order_idx);
CREATE INDEX subtasks_task_round ON subtasks(task_id, round);

CREATE TABLE events (
  id          TEXT NOT NULL PRIMARY KEY,
  task_id     TEXT NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  seq         INTEGER NOT NULL,
  occurred_at TEXT NOT NULL,
  kind        TEXT NOT NULL,                         -- free-form (see §3.2)
  payload     TEXT NOT NULL,                         -- JSON-encoded kind-specific fields
  UNIQUE(task_id, seq)
);
CREATE INDEX events_task_seq ON events(task_id, seq);

CREATE TABLE settings (
  key        TEXT PRIMARY KEY,
  value_json TEXT NOT NULL
);

-- Context / Graph Memory (ctxmem) tables — property graph + retrieval.
-- ctx_node / ctx_edge / ctx_closure: graph structure
-- ctx_fact: bi-temporal facts (valid_from / valid_to)
-- ctx_scratchpad: trust-gated pending queue for proposed nodes
-- ctx_node_vec: float32 BLOB embeddings (pure-Go cosine similarity; sqlite-vec
--   extension is not used because modernc.org/sqlite runs without CGO)
-- ctx_node_fts: FTS5 virtual table mirroring ctx_node for BM25 keyword search
-- ctx_memory_settings: per-repo embedding / LLM / budget configuration
-- See sidecar/internal/store/migrations.go v13 for the exact definitions.

-- NLAH runstate tables — artifacts indexed on top of on-disk files.
-- artifact: index of files under <DataDir>\runs\<taskId>\
--   stages: plan / code / review / harness / attempt
-- task_run_root: per-task absolute FS root (survives DataDir relocation)
-- harness_attempt: self-evolution patch proposals (Phase C; human-gated)
-- harness_skill_version: SKILL.md version history (Phase B)
-- subtask_context: per-round prompt ingredient snapshot for the Subtask
--   Summary dialog (system / user prompt, plan summary, memory block, ...)
-- See migrations.go v14 / v15 / v16 / v18.
```

The following PRAGMAs are always applied at startup (for write concurrency and
fault tolerance):

```sql
PRAGMA journal_mode = WAL;
PRAGMA synchronous  = NORMAL;
PRAGMA busy_timeout = 5000;
PRAGMA foreign_keys = ON;
PRAGMA auto_vacuum  = INCREMENTAL;
```

`modernc.org/sqlite` is `database/sql`-compatible. Restricting `sql.DB` to a
single connection (`SetMaxOpenConns(1)`) guarantees write serialization, while
read-only queries run on a separate `sql.DB` to exploit WAL concurrent reads.
The sidecar has a single-instance constraint (an attempt to double-launch exits
immediately with non-zero), so SQLite's file-based lock also acts as a second
line of defense.

---

## 4. Task Lifecycle

The primary Kanban path has six columns; Cancelled / Aborted / Failed are
side branches surfaced elsewhere in the UI.

```
  planning
     │   User edits goal / model / base branch, then presses Run.
     ▼
  queued
     │   Orchestrator picks the next task (semaphore-gated).
     ▼
  [Planner — Copilot session drafts the subtask DAG]
     │
     ▼
  in_progress  ──── Copilot SDK executes subtasks in topological order
     │
     ▼
  ai_review    ──── Automated verification (Phase 2 populates this stage;
     │              Phase 1 short-circuits straight to human_review).
     │              If the AI reviewer rejects, the orchestrator re-queues
     │              the task up to MaxReworkCount times (rework_count++).
     ▼
  human_review ──── User picks Keep / Merge / Discard
     │
     │   ┌──────────────────┬───────────────────┐
     ▼   ▼                  ▼                   ▼
  done (keep)           done (merged)        cancelled
  worktree removed,     merged into base,    Discard:
  branch preserved      both removed         worktree+branch removed

  Side branches (any in_progress-or-later state):
   ├─ timeout  ─▶ failed(code=timeout)           worktree / branch kept
   ├─ runtime  ─▶ failed(code=runtime)           worktree / branch kept
   ├─ crash    ─▶ failed(code=interrupted)       crash recovery at startup
   └─ user ■   ─▶ aborted                        worktree / branch kept
                  (non-terminal; user may subsequently finalize as
                   done-keep, done-merged, or cancelled)
```

**Important**: Phase 1 does not automate merging. Transitioning to
`done(merged)` happens only via explicit user action, and **the default
endpoint is `done(keep)` (branch retained)**. The app never performs
`git push`, and PR creation is not implemented until the manual trigger
feature planned for Phase 2.

`aborted` and `cancelled` are kept as distinct statuses in the DB / Task
type: `aborted` retains its branch and is thus still a candidate for a
later Keep / Merge / Discard decision; `cancelled` has been erased.

### 4.1 Orphan Worktree Reclamation (Startup)

1. Run `git worktree list --porcelain` for each registered repository.
2. Among worktrees whose branches have the `fleetkanban/` prefix, extract those
   without a corresponding task in the DB.
3. Clean up with `git worktree remove --force` + `git branch -D`.
4. Conversely, tasks that were `running` on the DB side transition to
   `failed(code=interrupted)` as crash recovery.

---

## 5. Copilot SDK Integration Points

Sketch of SDK-based usage of `internal/copilot`:

```go
// Runtime is created and started exactly once in the sidecar's main.go.
rt := copilot.NewRuntime(copilot.RuntimeConfig{LogLevel: "error"})
_ = rt.Start(ctx)
defer rt.Stop()

// Runner is the AgentRunner passed to the orchestrator.
runner, _ := rt.NewRunner(copilot.RunnerConfig{})

// Internals of Run (simplified):
session, _ := client.CreateSession(ctx, &copilot.SessionConfig{
    Model:               model,
    Streaming:           true,
    WorkingDirectory:    t.WorktreePath,
    OnPermissionRequest: trackingHandler, // Guard + security event emission
})
session.On(func(e copilot.SessionEvent) {
    if ae := MapSessionEvent(e); ae != nil {
        out <- ae
    }
})
session.Send(ctx, copilot.MessageOptions{Prompt: BuildPrompt(t)})
// Fire EventSessionIdle on SessionIdle and return nil.
```

### 5.1 Mapping SDK Events to AgentEvents

The SDK streams typed `SessionEvent`s. `MapSessionEvent` converts them to
`task.AgentEvent`:

| SDK SessionEventType                   | task.AgentEvent.Kind               |
| -------------------------------------- | ---------------------------------- |
| `assistant.message_delta`              | `assistant.delta` (DeltaContent)   |
| `assistant.reasoning_delta`            | `assistant.reasoning.delta`        |
| `tool.execution_start`                 | `tool.start`                       |
| `tool.execution_complete`              | `tool.end`                         |
| `assistant.message` (Content != empty) | `assistant.delta` (final)          |
| `session.error`                        | `error`                            |
| `session.idle`                         | runner fires `session.idle`        |

ANSI stripping and regex parsing have been entirely removed.

### 5.2 Permission Control (`OnPermissionRequest`)

`OnPermissionRequest: trackingHandler` is passed when the SDK session is
created. The handler:

1. For `req.Kind == Write` and `req.FileName` outside the worktree, returns
   `denied-by-rules` and emits a `security.path_escape` event on the channel.
2. For other kinds (Shell / Read / MCP / URL / Memory / Hook / CustomTool),
   returns `approved`.
3. The guard normalizes symlinks, UNC, and case via `GetFinalPathNameByHandleW`
   before performing the prefix check.

### 5.3 Stopping (Cancel)

On `ctx.WithTimeout` or `ctx.Cancel`, `session.Disconnect()` is called and
`ctx.Err()` is returned. Because the SDK manages the server process,
`TerminateProcess` / Job Object operations are no longer required.

### 5.4 Authentication

- `Runtime.CheckAuth(ctx)` calls the `auth.getStatus` RPC (returns
  `GetAuthStatusResponse.IsAuthenticated` / `Login`). Side-effect free.
- `Runtime.LaunchLogin(ctx)` identifies the embedded CLI path
  (`COPILOT_CLI_PATH` environment variable → `%LOCALAPPDATA%\copilot-sdk\copilot_<ver>.exe`
  → `copilot` on PATH) and opens an independent console via `wt.exe` /
  `cmd.exe /c start` so that the user can run `/login`.
- If a PAT is configured, it is passed via `ClientOptions.GitHubToken` and
  `UseLoggedInUser` is set to `false`. PAT storage is DPAPI-encrypted
  (`internal/app/secrets_dpapi.go`).

### 5.5 Concurrency Control

- The orchestrator's semaphore (default `concurrency = 4`) controls simultaneous
  executions.
- Because the SDK serializes communication with the CLI server internally, no
  rate-limit management is required at the adapter layer.

---

## 6. Process Model

```
fleetkanban_ui.exe  (Flutter / Windows desktop)
 ├─ Dart isolate (main)
 │   ├─ fluent_ui widget tree
 │   ├─ state management via Riverpod / Provider
 │   └─ infra/ipc/sidecar_supervisor.dart
 │       ├─ Process.start("fleetkanban-sidecar.exe", ["--port=0"])
 │       ├─ parses stdout line "READY port=<N> token=<base64>"
 │       ├─ assigns sidecar to Job Object (chain-kill on UI exit)
 │       └─ connects to 127.0.0.1:<N> via grpc ClientChannel
 │           └─ all RPCs attach metadata "x-auth-token: <token>"
 │
 └─ (child process)
     fleetkanban-sidecar.exe  (headless Go gRPC backend)
      ├─ Go main goroutine
      │   ├─ internal/ipc.Server (grpc.NewServer + interceptor for auth validation)
      │   ├─ copilot.Runtime (SDK Client + embedded CLI server process)
      │   │   └─ JSON-RPC communication over stdio transport
      │   ├─ Orchestrator
      │   │   ├─ Semaphore (default 4)
      │   │   └─ task goroutine * N
      │   │       ├─ worktree.Create / worktree.Remove
      │   │       ├─ copilot.Runner.Run
      │   │       │   ├─ SDK CreateSession / session.On / session.Send
      │   │       │   └─ Event fan-out (store + broker.Publish)
      │   │       └─ permission handler (worktree validation via Guard)
      │   ├─ store.DB (SQLite: modernc)
      │   ├─ reaper.Service (orphan child-process reclamation)
      │   └─ winapi (AUMID / Toast / DPAPI)
      │
      └─ (grandchild process)
          copilot CLI server  (managed by SDK as embedded CLI)
           └─ cwd = <worktreePath> (specified per session)
```

**Startup / shutdown reliability guarantees**:
- Immediately after spawning the sidecar, the Flutter-side `SidecarSupervisor`
  assigns it to a Job Object, so the OS guarantees the sidecar is chain-killed
  even if the UI process dies.
- The sidecar enforces a single-instance constraint (double launch exits
  immediately with non-zero) via a SQLite file lock.
- Graceful shutdown: `SystemService.Shutdown` RPC → gRPC graceful stop; if it
  does not complete within 10 s, the Flutter-side Job Object force-terminates.
- Because the SDK manages the embedded CLI server via stdio transport, there is
  no need to assign a Job Object to the Copilot grandchild process on the
  sidecar side (it is handled inside the SDK).

---

## 7. Non-Goals (Not Handled in Phase 1)

- Automated merge / conflict resolution by Copilot
- Automatic PR creation against remotes (GitHub / GitLab)
- Tasks spanning multiple repositories
- User authentication / multi-user support
- Providing a Web UI / CLI (Flutter desktop app only)
- macOS / Linux support (permanently off the table)

See [roadmap.md](./roadmap.md) for these.

---

## 8. Risks and Open Items

| # | Item | Current Assumption |
| --- | --- | --- |
| R1 | Japanese IME on Flutter Windows desktop | Verify `composition*` events in `fluent_ui`'s `TextBox`. For IME-critical surfaces like Kanban input and search, build regression tests using `enterText` in integration_test |
| R2 | Breaking API changes in the SDK (public preview) | Pin `github.com/github/copilot-sdk/go` in `go.mod`. Absorb changes in the conversion layer (`events.go`) and the `Runtime` wrapper (`client.go`) |
| R3 | Embedded CLI binary download failure (CI / offline) | Fall back to `copilot` on PATH if `go tool bundler` fails. In CI, isolate the bundler step so it can be cached |
| R4 | Windows long paths / CRLF / symlinks | Assume `core.longpaths=true` and `core.autocrlf=false`; unify worktree parent-directory name to the short fixed string `.fleetkanban-worktrees` (or `%APPDATA%\FleetKanban\worktrees\` on fallback) |
| R5 | SQLite write contention | Serialize a write-only `sql.DB` with `SetMaxOpenConns(1)`; handle reads on a separate `sql.DB` (concurrent WAL reads) |
| R6 | SDK not supporting `claude-sonnet-4.6` | Verify at startup with `ListModels` and fall back in the order `claude-sonnet-4.5 → gpt-5` |
| R7 | Flutter ↔ sidecar handshake failure (e.g., OS-side EDR blocking) | If the sidecar does not emit the READY line to stdout within 5 s, the UI shows `SidecarStartupFailed`. The sidecar writes structured logs to stderr (for fallback) |
| R8 | ~~Reliability of SDK auth detection~~ (resolved) | Addressed: `auth.getStatus` SDK RPC replaced `--list-env` regex parsing. Documented here for historical context; no ongoing mitigation required. |
| R9 | Confidentiality of loopback gRPC | Verify the base64 token generated at sidecar startup via the `x-auth-token` metadata (`subtle.ConstantTimeCompare`). Non-localhost connections are physically excluded by `net.Listen("tcp", "127.0.0.1:0")` |
