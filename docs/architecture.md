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
   layer is interposed. See [phase1-spec.md §9](./phase1-spec.md#9-windows-11-optimization)
   for details.
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
  (`SubscribeEvents`). Backpressure for slow subscribers is absorbed by a
  per-subscriber ring buffer.
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
  [`xterm`](https://pub.dev/packages/xterm), [`riverpod`](https://pub.dev/packages/riverpod)-based
  state management (finalized during Phase 1 implementation).
- Directory layout (under `lib/`):
  - `app/` — `MaterialApp` / `FluentApp` initialization, routing, theme.
  - `domain/` — Dart-side domain types (Task / AgentEvent, etc.; proto artifacts
    are projected into domain models).
  - `features/` — per-screen (`kanban/` / `agent_terminal/` / `review/` /
    `settings/`).
  - `infra/ipc/` — `SidecarSupervisor` (sidecar child-process management +
    handshake), gRPC client wrappers, and proto stubs under `generated/`.
  - `theme/` — font and color tokens.
- Lint: `analysis_options.yaml` (based on `flutter_lints`).

---

## 3. Data Model (Overview)

### 3.1 Go Type Definitions (Excerpt)

```go
package task

type Status string

const (
    StatusPending        Status = "pending"
    StatusRunning        Status = "running"
    StatusAwaitingReview Status = "awaiting_review"
    StatusCompleted      Status = "completed"  // Kept: worktree removed, branch retained
    StatusMerged         Status = "merged"     // explicit user merge, worktree+branch deleted
    StatusAborted        Status = "aborted"    // aborted: worktree+branch retained (for diff review)
    StatusCancelled      Status = "cancelled"  // Discard: worktree+branch deleted
    StatusFailed         Status = "failed"     // timeout / runtime / interrupted
)

type ErrorCode string

const (
    ErrTimeout          ErrorCode = "timeout"
    ErrInterrupted      ErrorCode = "interrupted"      // crash recovery
    ErrRuntime          ErrorCode = "runtime"          // CLI exception, parse failure, etc.
    ErrPermissionDenied ErrorCode = "permission_denied"
)

type Task struct {
    ID           string     `json:"id"`           // ULID
    Goal         string     `json:"goal"`
    RepositoryID string     `json:"repositoryId"`
    BaseBranch   string     `json:"baseBranch"`
    WorktreePath string     `json:"worktreePath,omitempty"`
    Branch       string     `json:"branch,omitempty"` // fleetkanban/<id>
    BranchExists bool       `json:"branchExists"`
    Status       Status     `json:"status"`
    CreatedAt    time.Time  `json:"createdAt"`
    UpdatedAt    time.Time  `json:"updatedAt"`
    StartedAt    *time.Time `json:"startedAt,omitempty"`
    FinishedAt   *time.Time `json:"finishedAt,omitempty"`
    SessionID    string     `json:"sessionId,omitempty"` // COPILOT_AGENT_SESSION_ID
    Error        *Error     `json:"error,omitempty"`
}

type Error struct {
    Code    ErrorCode `json:"code"`
    Message string    `json:"message"`
    Stack   string    `json:"stack,omitempty"`
}

// The JSONL path for raw events is implicitly determined as
// %APPDATA%\FleetKanban\logs\<task-id>.jsonl (not stored in the Task type or DB).
```

On the Dart side, proto artifacts (`pb.Task`, etc.) are projected into domain
models (`lib/domain/`) for use. JSON tags are for sidecar-internal logs /
debugging only; exchange with Flutter uses protobuf exclusively.

### 3.2 AgentEvent

```go
package task

type EventType string

const (
    EventAssistantDelta    EventType = "assistant.delta"
    EventAssistantMessage  EventType = "assistant.message"
    EventReasoningDelta    EventType = "assistant.reasoning.delta"
    EventToolStart         EventType = "tool.start"
    EventToolEnd           EventType = "tool.end"
    EventPermissionRequest EventType = "permission.request"
    EventSessionIdle       EventType = "session.idle"
    EventError             EventType = "error"
)

type Event struct {
    Type   EventType       `json:"type"`
    TaskID string          `json:"taskId"`
    Seq    int64           `json:"seq"`
    TS     time.Time       `json:"ts"`
    Data   json.RawMessage `json:"data,omitempty"`
}
```

The SDK's `SessionEvent` is parsed and normalized into the above Event (see §5),
then delivered to Flutter as a gRPC `SubscribeEvents` stream.

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

```sql
CREATE TABLE repositories (
  id TEXT PRIMARY KEY,              -- ULID
  path TEXT NOT NULL UNIQUE,        -- absolute path (normalized to lowercase)
  display_name TEXT NOT NULL,       -- UI display name (user-editable)
  default_base_branch TEXT,         -- detected value; overridable
  created_at TEXT NOT NULL,
  last_used_at TEXT
);

CREATE TABLE tasks (
  id TEXT PRIMARY KEY,
  goal TEXT NOT NULL,
  repository_id TEXT NOT NULL REFERENCES repositories(id) ON DELETE RESTRICT,
  base_branch TEXT NOT NULL,
  worktree_path TEXT,
  branch TEXT,                      -- fleetkanban/<id>; retained after completed / aborted / failed
  branch_exists INTEGER DEFAULT 1,  -- 0 if externally deleted
  status TEXT NOT NULL CHECK(status IN (
    'pending','running','awaiting_review',
    'completed','merged','aborted','cancelled','failed'
  )),
  session_id TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  started_at TEXT,
  finished_at TEXT,
  error_json TEXT                   -- JSON: { code, message, stack? }
);
CREATE INDEX tasks_status_updated ON tasks(status, updated_at DESC);
CREATE INDEX tasks_repository ON tasks(repository_id);

CREATE TABLE events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  task_id TEXT NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  seq INTEGER NOT NULL,
  ts TEXT NOT NULL,
  payload_json TEXT NOT NULL
);
CREATE INDEX events_task_seq ON events(task_id, seq);

CREATE TABLE settings (
  key TEXT PRIMARY KEY,
  value_json TEXT NOT NULL
);
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

```
  pending
     │   Run button in Kanban or card drag
     ▼
  [WorktreeManager.Create (base_branch)]
     │
     ▼
  running  ──── Copilot SDK session streams SessionEvents
     │
     ├─ normal exit ──▶ awaiting_review
     │                    │  user choice (default: Keep)
     │      ┌─────────────┼─────────────────┐
     │      ▼             ▼                 ▼
     │   completed      merged           cancelled
     │   (branch keep)  (branch gone)    (worktree+branch gone)
     │   worktree rm    worktree rm       ← Discard
     │
     ├─ timeout ─▶ failed(code=timeout)    worktree / branch retained
     ├─ exception ─▶ failed(code=runtime)  worktree / branch retained
     └─ abort (■) ─▶ aborted               worktree / branch retained (for diff review)

  Crash recovery: tasks that were running at startup transition to
    failed(code=interrupted) (see §3.3 / phase1-spec §3.4).
```

**Important**: Phase 1 does not automate merging. Transitioning from
`awaiting_review` to `merged` happens only via explicit user action, and
**the default endpoint is `completed` (branch retained)**. The app never
performs `git push`, and PR creation is not implemented until the manual
trigger feature planned for Phase 2.

`aborted` and `cancelled` appear in the same Kanban column (Cancelled column)
but are kept as distinct statuses in the DB / Task type (the former retains its
branch and is thus a candidate for Merge / duplication; the latter has been
erased).

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
| R8 | Reliability of SDK auth detection | The `auth.getStatus` RPC is an official SDK-provided API and is more reliable than regex parsing `--list-env` output. Must be called after `Runtime.Start` |
| R9 | Confidentiality of loopback gRPC | Verify the base64 token generated at sidecar startup via the `x-auth-token` metadata (`subtle.ConstantTimeCompare`). Non-localhost connections are physically excluded by `net.Listen("tcp", "127.0.0.1:0")` |
