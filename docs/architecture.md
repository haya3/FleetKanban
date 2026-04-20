# アーキテクチャ設計

本書は FleetKanban 全体の技術設計を示します。Phase 1 で完成させる部分と、
Phase 2 以降に段階的に追加する部分を分けて記載します。
対象 OS は **Windows 11（64bit）専用**で、**「Windows 11 ネイティブ体験に最適化すること」を最上位の非機能要件**とします。マルチ OS 対応のための妥協を一切しません（`runtime.GOOS == "windows"` 前提で全コードを書き、他 OS 向け build tag を一切用意しない）。

---

## 1. 設計目標

1. **Windows 11 最適化（最優先）**
   パス・ファイルシステム・プロセス・Git・UI/フォント・通知・署名まで Windows 11 固有 API を第一級で扱い、クロス OS 抽象層は挟まない。詳細は [phase1-spec.md §9](./phase1-spec.md#9-windows-11-最適化) を参照。
2. **エージェント実行基盤の安全な隔離**
   タスクごとに git worktree を切り、Copilot CLI は各 worktree を cwd とした独立子プロセスで起動する。メインブランチや他タスクの作業に影響を与えない。
3. **Copilot CLI を薄くラップするアダプタ層**
   Copilot SDK の引数・環境変数・セッションイベント解析ロジックを `internal/copilot` に閉じ込め、コアモデル（`internal/task` / `internal/orchestrator`）からは抽象 `AgentRunner` 経由でしか呼ばない。
4. **Flutter (Windows desktop) UI ファースト**
   CLI は提供しない。Phase 1 から Flutter アプリを唯一のユーザーインターフェースとし、バックエンドは Go gRPC sidecar として分離する（Electron / Wails / Web UI は不採用）。
5. **拡張可能なモジュール境界**
   Copilot 以外のエージェントエンジン（例: 将来の別 CLI）を差し替え可能にする `AgentRunner` インターフェースを設ける。

---

## 2. モジュール構成

```
┌─────────────────────────────────────────────────────────────────┐
│                fleetkanban_ui.exe (Flutter Windows)                │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │  Flutter UI (Dart / fluent_ui)                             │  │
│  │  Kanban / Terminal / Chat / Settings                       │  │
│  │                                                            │  │
│  │  lib/infra/ipc/sidecar_supervisor.dart                     │  │
│  │   ├─ sidecar を子プロセス起動（READY ハンドシェイク受信）  │  │
│  │   └─ gRPC client（loopback + x-auth-token メタデータ）     │  │
│  └──────────────────────────────┬─────────────────────────────┘  │
│                                 │ loopback gRPC (127.0.0.1:N)    │
└─────────────────────────────────┼────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────┐
│          fleetkanban-sidecar.exe (headless Go gRPC backend)        │
│                                                                  │
│  internal/ipc                                                    │
│   ├─ gRPC サーバ（proto/fleetkanban/v1/fleetkanban.proto）           │
│   ├─ auth.go（x-auth-token メタデータ検証）                      │
│   ├─ broker.go（AgentEvent fan-out → Dart ストリーム）           │
│   └─ convert.go（Go ドメイン型 ↔ protobuf）                      │
│                                                                  │
│  internal/app                                                    │
│   └─ Service（gRPC から呼ばれるドメインユースケース集約）        │
│                                                                  │
│  internal/ ── orchestrator / task / store (SQLite) /             │
│               worktree / copilot / reaper / winapi / branding    │
└─────────────────────────────────┬────────────────────────────────┘
                                  │
                                  ▼
                 ┌────────────────────────────────────┐
                 │   Copilot CLI server サブプロセス  │
                 │   (SDK が stdio transport で管理)  │
                 │   cwd = <worktreePath>             │
                 └────────────────────────────────────┘
```

### 2.1 `internal/task`

- Task / AgentEvent / TaskError の **純粋なドメイン型**（DB・CLI に非依存）
- 状態遷移関数（`Transition(old, new) error`）で遷移の妥当性を検査

### 2.2 `internal/store`

- SQLite 永続化。`modernc.org/sqlite`（pure Go、CGO 不要）を `database/sql` 経由で利用
- `TaskStore` / `RepositoryStore` / `EventStore` の 3 リポジトリを提供
- 書き込みは単一 goroutine（serializer）に直列化し、並列読み取りは WAL に委ねる

### 2.3 `internal/worktree`

- `git worktree add/remove/list` のラッパー。`os/exec` で `git` を呼ぶ
- per-repo `sync.Mutex` で `add` / `remove` を直列化
- 起動時の孤児 worktree 回収（§4 参照）

### 2.4 `internal/orchestrator`

- タスクのライフサイクル管理
- 並列度制御: `golang.org/x/sync/semaphore` で既定 4、上限 12
- `AgentRunner` へのディスパッチ、AgentEvent の fan-out（store 書き込み + gRPC broker 経由で Flutter に配信）

### 2.5 `internal/copilot`

`AgentRunner` の **GitHub Copilot SDK for Go** 実装。CLI 直駆動から SDK 経由に全面移行済み。

- **embedded CLI**: bundler（`go tool bundler`）が `sidecar/cmd/fleetkanban-sidecar/zcopilot_windows_amd64.go` を生成し、CLI バイナリを `init()` で `embeddedcli.Setup` に渡す。SDK が起動時に `%LOCALAPPDATA%\copilot-sdk\` へ展開する
- **Runtime** (`client.go`): `copilot.NewClient` でクライアントを構築し、`Start(ctx)` で CLI サーバープロセスを立ち上げる。`Stop()` で全セッションを切断してサーバーを終了する。`CheckAuth(ctx)` は `auth.getStatus` RPC で認証状態を取得する（副作用なし、`--list-env` パース廃止）
- **Runner** (`runner.go`): `AgentRunner` を実装。`CreateSession` で SDK セッションを確立し、`session.On(...)` イベントハンドラで `SessionEvent` を `task.AgentEvent` に変換して out チャネルに送出。`SessionIdle` 受信をもってセッション完了とし `EventSessionIdle` を発火する
- **permission handler** (`permission.go`): `NewPermissionHandler(worktreeRoot)` が `copilot.PermissionHandlerFunc` を返す。Write リクエストの `FileName` を `GetFinalPathNameByHandleW` ベースの Guard で検証し、worktree 外パスを `denied-by-rules` で即座に拒否。Shell / Read / MCP など他の Kind は承認する
- **イベント変換** (`events.go`): `MapSessionEvent(SessionEvent) *task.AgentEvent` は純粋関数。型スイッチで `AssistantMessageDeltaData → assistant.delta`、`AssistantReasoningDeltaData → assistant.reasoning.delta`、`ToolExecutionStartData → tool.start`、`ToolExecutionCompleteData → tool.end`、`SessionErrorData → error` にマップする
- **model 解決**: 起動時に `client.ListModels(ctx)` で取得し `claude-sonnet-4.6 → claude-sonnet-4.5 → gpt-5` の順で最初に一致するモデルを選択する

### 2.6 `internal/winapi`

Go から Win32 API を直接呼ぶ薄いパッケージ。`golang.org/x/sys/windows` と生 syscall の組み合わせ。sidecar 側で完結する機能のみを担う（UI チラつき・Mica 等の描画は Flutter 側で扱う）。

- **Job Object**: `CreateJobObjectW` + `SetInformationJobObject(JobObjectExtendedLimitInformation, JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE)` + `AssignProcessToJobObject`。Flutter 側から sidecar を子プロセス起動するときは Flutter 側でも Job Object を張り、sidecar 側では Copilot 子プロセスの確実な終結に備えてファイルを保持する（Phase 1 では SDK がサーバ管理するため呼び出しは最小限）
- **DPAPI**: GitHub PAT 等のトークンを `CryptProtectData` / `CryptUnprotectData` で暗号化して `%APPDATA%\FleetKanban\settings.json` に保存（ユーザースコープ）
- **Toast**: WinRT `ToastNotificationManager` 相当。Phase 1 では XML テンプレートを生成して `IToastNotificationManagerStatics` 経由で発行
- **AppUserModelID**: `SetCurrentProcessExplicitAppUserModelID(L"com.fleetkanban.desktop")` を sidecar 起動直後に呼ぶ（Toast 通知のグルーピングに必須）。Flutter 側の `fleetkanban_ui.exe` も同じ AUMID を MSIX マニフェストで宣言する

### 2.7 `internal/app`（ドメインサービス）

- ユースケース単位で Orchestrator / Store / Copilot / Worktree を束ねる `Service` 型を公開
- 引数・返り値は Go 純粋型（protobuf 非依存）で、gRPC 層からのみ呼ばれる想定
- `internal/ipc` 側で protobuf ↔ Go 型の変換（`convert.go`）を行う

### 2.8 `internal/ipc`（gRPC サーバ）

- proto スキーマは `proto/fleetkanban/v1/fleetkanban.proto`、Go スタブは `sidecar/internal/ipc/gen/fleetkanban/` に生成
- `server.go`: `grpc.NewServer` + unary/stream interceptor で `auth.go` のトークン検証を組み込み、`app.Service` に委譲
- `auth.go`: sidecar 起動時に生成した base64 トークンと `metadata["x-auth-token"]` を定時比較（`crypto/subtle.ConstantTimeCompare`）
- `broker.go`: Orchestrator の `EventSink` で受けた `task.AgentEvent` を gRPC の server-streaming RPC（`SubscribeEvents`）を購読している各 Dart クライアントに fan-out。購読が追いつかない時のバックプレッシャは per-subscriber リングバッファで吸収
- `convert.go`: protobuf と Go 型の変換（`pb.Task ↔ task.Task` 等）

### 2.9 `proto/fleetkanban/v1/`

- `fleetkanban.proto` — gRPC スキーマの唯一の情報源
- `buf.gen.yaml` — Go 向け生成（`protoc-gen-go` + `protoc-gen-go-grpc`）
- `buf.gen.dart.yaml` — Dart 向け生成（`protoc_plugin`）
- `task proto:gen:all` で Go / Dart 両方を一括再生成

### 2.10 `ui/`

- Flutter 3.27+（Windows desktop 有効化）
- 主要依存: [`fluent_ui`](https://pub.dev/packages/fluent_ui)（Windows 11 ネイティブ風 UI）、[`grpc`](https://pub.dev/packages/grpc) + `protobuf`、[`flutter_acrylic`](https://pub.dev/packages/flutter_acrylic)（Mica / Acrylic）、[`window_manager`](https://pub.dev/packages/window_manager)、[`xterm`](https://pub.dev/packages/xterm)、[`riverpod`](https://pub.dev/packages/riverpod) 系状態管理（Phase 1 実装時に確定）
- ディレクトリ構成（`lib/` 配下）:
  - `app/` — `MaterialApp` / `FluentApp` 初期化、ルーティング、テーマ
  - `domain/` — Dart 側のドメイン型（Task / AgentEvent 等、proto 生成物を domain モデルに投影）
  - `features/` — 画面単位（`kanban/` / `agent_terminal/` / `review/` / `settings/`）
  - `infra/ipc/` — `SidecarSupervisor`（sidecar 子プロセス管理 + ハンドシェイク）、gRPC クライアントラッパ、`generated/` 以下に proto スタブ
  - `theme/` — フォント・色トークン
- Lint: `analysis_options.yaml`（`flutter_lints` ベース）

---

## 3. データモデル（概要）

### 3.1 Go 型定義（抜粋）

```go
package task

type Status string

const (
    StatusPending        Status = "pending"
    StatusRunning        Status = "running"
    StatusAwaitingReview Status = "awaiting_review"
    StatusCompleted      Status = "completed"  // Keep 済: worktree 撤去、branch 保持
    StatusMerged         Status = "merged"     // ユーザー明示 Merge、worktree+branch 削除
    StatusAborted        Status = "aborted"    // 中断: worktree+branch 保持（diff 確認用）
    StatusCancelled      Status = "cancelled"  // Discard: worktree+branch 削除
    StatusFailed         Status = "failed"     // timeout / runtime / interrupted
)

type ErrorCode string

const (
    ErrTimeout          ErrorCode = "timeout"
    ErrInterrupted      ErrorCode = "interrupted"      // クラッシュリカバリ
    ErrRuntime          ErrorCode = "runtime"          // CLI 例外・パース失敗など
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

// 生イベントの JSONL パスは %APPDATA%\FleetKanban\logs\<task-id>.jsonl で
// 暗黙に決まる（Task 型・DB には持たない）。
```

Dart 側では proto 生成物（`pb.Task` など）を domain モデル（`lib/domain/`）に投影して利用する。JSON タグは sidecar 内部ログ / デバッグ専用で、Flutter とのやり取りは protobuf のみ。

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

SDK の `SessionEvent` をパースして上記 Event に正規化し（§5 参照）、gRPC `SubscribeEvents` の stream で Flutter に配信する。

### 3.3 データ保存先

データ保存先の既定ルートは `%APPDATA%\FleetKanban\` とします（sidecar 起動時に `os.UserConfigDir()` で解決）。Enterprise 環境の Folder Redirection により UNC パスが返る場合は `%LOCALAPPDATA%\FleetKanban\` へフォールバックします。

```
%APPDATA%\FleetKanban\
├── fleetkanban.db           # SQLite 本体（repositories / tasks / events / settings テーブル）
├── settings.json          # DPAPI で暗号化された PAT / UI 設定
├── logs\
│   └── <task-id>.jsonl    # エージェントイベントの生ログ（デバッグ用の副次出力）
└── worktrees\             # 対象リポジトリ親が書き込み不可の場合のフォールバック用
    └── <repo-hash>\<task-id>\
```

タスク worktree の既定配置は対象リポジトリの親ディレクトリ直下:

```
<repo-parent>\
├── <repo-name>\           # 対象リポジトリ本体
└── .fleetkanban-worktrees\
    └── <task-id>\         # 各タスクの作業ツリー（fleetkanban/<task-id> ブランチ）
```

### 3.4 SQLite スキーマ

```sql
CREATE TABLE repositories (
  id TEXT PRIMARY KEY,              -- ULID
  path TEXT NOT NULL UNIQUE,        -- 絶対パス（lowercase 正規化済）
  display_name TEXT NOT NULL,       -- UI 表示名（ユーザー編集可）
  default_base_branch TEXT,         -- 検出値。上書き可
  created_at TEXT NOT NULL,
  last_used_at TEXT
);

CREATE TABLE tasks (
  id TEXT PRIMARY KEY,
  goal TEXT NOT NULL,
  repository_id TEXT NOT NULL REFERENCES repositories(id) ON DELETE RESTRICT,
  base_branch TEXT NOT NULL,
  worktree_path TEXT,
  branch TEXT,                      -- fleetkanban/<id>。completed / aborted / failed 後も保持
  branch_exists INTEGER DEFAULT 1,  -- 0 なら外部削除済
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

起動時に必ず以下の PRAGMA を適用する（書き込み並列性と耐障害性のため）。

```sql
PRAGMA journal_mode = WAL;
PRAGMA synchronous  = NORMAL;
PRAGMA busy_timeout = 5000;
PRAGMA foreign_keys = ON;
PRAGMA auto_vacuum  = INCREMENTAL;
```

`modernc.org/sqlite` は `database/sql` 互換。`sql.DB` を単一コネクションに制限（`SetMaxOpenConns(1)`）して書き込み直列化を担保する一方で、読み取り専用クエリは別 `sql.DB` を張って WAL の並列読みを活かす。sidecar は単一インスタンス制約（2 重起動時は即座に非 0 で終了）があるため、SQLite の file-based lock も二重防御として機能する。

---

## 4. タスクのライフサイクル

```
  pending
     │   Kanban で Run ボタン or カードドラッグ
     ▼
  [WorktreeManager.Create (base_branch)]
     │
     ▼
  running  ──── Copilot SDK セッションが SessionEvent をストリーム
     │
     ├─ 正常終了 ──▶ awaiting_review
     │                    │  ユーザー選択（既定: Keep）
     │      ┌─────────────┼─────────────────┐
     │      ▼             ▼                 ▼
     │   completed      merged           cancelled
     │   (branch keep)  (branch gone)    (worktree+branch gone)
     │   worktree rm    worktree rm       ← Discard
     │
     ├─ timeout ─▶ failed(code=timeout)   worktree / branch 保持
     ├─ 例外 ───▶ failed(code=runtime)   worktree / branch 保持
     └─ 中断(■) ─▶ aborted                worktree / branch 保持（diff 確認用）

  クラッシュリカバリ: 起動時に running だったタスクは
    failed(code=interrupted) に遷移（§3.3 / phase1-spec §3.4 参照）
```

**重要**: Phase 1 ではマージの自動化は行わない。`awaiting_review` から `merged` へはユーザー明示操作でのみ遷移し、**既定の終点は `completed`（ブランチ保持）**。アプリは `git push` を一切行わず、PR 作成も Phase 2 で導入予定の手動トリガ機能まで実装しない。

`aborted` と `cancelled` は Kanban 上の同一列（Cancelled 列）で表示されるが、DB / Task 型では別ステータスとして保持する（前者はブランチが残るため Merge / 複製の候補になり、後者は消えている）。

### 4.1 孤児 worktree の回収（起動時）

1. 登録リポジトリごとに `git worktree list --porcelain` を実行
2. `fleetkanban/` プレフィックスのブランチを持つ worktree のうち、DB に該当タスクが無いものを抽出
3. `git worktree remove --force` + `git branch -D` でクリーンアップ
4. 逆に DB 側で `running` だったタスクはクラッシュリカバリとして `failed(code=interrupted)` に遷移させる

---

## 5. Copilot SDK 統合ポイント

`internal/copilot` の SDK 版利用イメージ:

```go
// Runtime は sidecar の main.go で一度だけ生成・起動する。
rt := copilot.NewRuntime(copilot.RuntimeConfig{LogLevel: "error"})
_ = rt.Start(ctx)
defer rt.Stop()

// Runner は orchestrator に渡す AgentRunner。
runner, _ := rt.NewRunner(copilot.RunnerConfig{})

// Run の内部（簡略）:
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
// SessionIdle → EventSessionIdle を発火して return nil
```

### 5.1 SDK イベントと AgentEvent のマッピング

SDK は型付き `SessionEvent` をストリーミングする。`MapSessionEvent` がこれを `task.AgentEvent` に変換する:

| SDK SessionEventType            | task.AgentEvent.Kind              |
| ------------------------------- | --------------------------------- |
| `assistant.message_delta`       | `assistant.delta`（DeltaContent） |
| `assistant.reasoning_delta`     | `assistant.reasoning.delta`       |
| `tool.execution_start`          | `tool.start`                      |
| `tool.execution_complete`       | `tool.end`                        |
| `assistant.message`（Content非空）| `assistant.delta`（final）       |
| `session.error`                 | `error`                           |
| `session.idle`                  | runner が `session.idle` を発火   |

ANSI 除去・正規表現パースは全廃。

### 5.2 権限制御（`OnPermissionRequest`）

SDK セッション作成時に `OnPermissionRequest: trackingHandler` を渡す。ハンドラは:

1. `req.Kind == Write` かつ `req.FileName` が worktree 外 → `denied-by-rules` を返し、`security.path_escape` イベントをチャネルに送出
2. それ以外の Kind（Shell / Read / MCP / URL / Memory / Hook / CustomTool）→ `approved` を返す
3. Guard は `GetFinalPathNameByHandleW` でシンボリックリンク・UNC・大文字小文字を正規化してから prefix 判定する

### 5.3 停止（Cancel）

`ctx.WithTimeout` によるタイムアウトまたは `ctx.Cancel` が発生した場合、`session.Disconnect()` を呼んでから `ctx.Err()` を返す。SDK がサーバープロセスを管理するため、`TerminateProcess` / Job Object 操作は不要になった。

### 5.4 認証

- `Runtime.CheckAuth(ctx)` が `auth.getStatus` RPC を呼ぶ（`GetAuthStatusResponse.IsAuthenticated` / `Login` を返す）。副作用なし
- `Runtime.LaunchLogin(ctx)` が embedded CLI パス（`COPILOT_CLI_PATH` 環境変数 → `%LOCALAPPDATA%\copilot-sdk\copilot_<ver>.exe` → PATH上の `copilot`）を特定し、`wt.exe` / `cmd.exe /c start` 経由で独立コンソールを開いてユーザーが `/login` を実行できるようにする
- PAT が設定にあれば `ClientOptions.GitHubToken` に渡し、`UseLoggedInUser` を `false` に設定する。PAT の保存は DPAPI で暗号化（`internal/app/secrets_dpapi.go`）

### 5.5 並列度制御

- Orchestrator 側のセマフォ（既定 `concurrency = 4`）により同時実行数を制御
- SDK が CLI サーバーとの通信を内部でシリアライズするため、adapter 層でのレート制限管理は不要

---

## 6. プロセスモデル

```
fleetkanban_ui.exe  (Flutter / Windows desktop)
 ├─ Dart isolate (main)
 │   ├─ fluent_ui ウィジェットツリー
 │   ├─ Riverpod / Provider による状態管理
 │   └─ infra/ipc/sidecar_supervisor.dart
 │       ├─ Process.start("fleetkanban-sidecar.exe", ["--port=0"])
 │       ├─ stdout "READY port=<N> token=<base64>" をパース
 │       ├─ Job Object に sidecar をアサイン（UI プロセス終了で連鎖 kill）
 │       └─ grpc ClientChannel で 127.0.0.1:<N> に接続
 │           └─ 全 RPC が metadata "x-auth-token: <token>" を付与
 │
 └─ (子プロセス)
     fleetkanban-sidecar.exe  (headless Go gRPC backend)
      ├─ Go main goroutine
      │   ├─ internal/ipc.Server (grpc.NewServer + interceptor で auth 検証)
      │   ├─ copilot.Runtime (SDK Client + embedded CLI server プロセス)
      │   │   └─ stdio transport で JSON-RPC 通信
      │   ├─ Orchestrator
      │   │   ├─ Semaphore (既定 4)
      │   │   └─ task goroutine * N
      │   │       ├─ worktree.Create / worktree.Remove
      │   │       ├─ copilot.Runner.Run
      │   │       │   ├─ SDK CreateSession / session.On / session.Send
      │   │       │   └─ Event fan-out (store + broker.Publish)
      │   │       └─ permission handler (Guard による worktree 検証)
      │   ├─ store.DB (SQLite: modernc)
      │   ├─ reaper.Service (孤児子プロセス回収)
      │   └─ winapi (AUMID / Toast / DPAPI)
      │
      └─ (孫プロセス)
          copilot CLI server  (SDK が embedded CLI として管理)
           └─ cwd = <worktreePath>（セッション毎に指定）
```

**起動・終了の信頼性担保**:
- Flutter 側の `SidecarSupervisor` は sidecar を子プロセス起動した直後に Job Object へアサインし、UI プロセスが落ちた場合でも sidecar が連鎖 kill されることを OS が保証する
- sidecar は単一インスタンス制約（2 重起動時は即座に非 0 で終了）を SQLite ファイルロックで実現
- Graceful shutdown は `SystemService.Shutdown` RPC → gRPC graceful stop → 10s 以内に終わらなければ Flutter 側 Job Object が強制終了
- SDK が embedded CLI サーバーを stdio transport で管理するため、sidecar 側で Copilot 孫プロセスへの Job Object アサインは不要（SDK 内部で完結）

---

## 7. 非目標（Phase 1 では扱わない）

- Copilot の自動マージ・コンフリクト解消
- リモート（GitHub / GitLab）への PR 自動作成
- 複数リポジトリをまたぐタスク
- ユーザー認証・マルチユーザー対応
- Web UI / CLI の提供（Flutter デスクトップアプリのみ）
- macOS / Linux サポート（恒久的にやらない）

これらは [roadmap.md](./roadmap.md) を参照してください。

---

## 8. リスクと未決事項

| # | 項目 | 現状の想定 |
| --- | --- | --- |
| R1 | Flutter Windows desktop の日本語 IME 周り | `fluent_ui` の `TextBox` で `composition*` イベントを検証。Kanban 入力・検索など IME 必須箇所は integration_test で `enterText` を使った回帰テストを組む |
| R2 | SDK (public preview) の破壊的 API 変更 | `go.mod` で `github.com/github/copilot-sdk/go` をピン留め。変換層 (`events.go`) と `Runtime` ラッパー (`client.go`) に吸収する |
| R3 | embedded CLI バイナリのダウンロード失敗（CI 環境・オフライン） | `go tool bundler` が失敗した場合は PATH 上の `copilot` にフォールバックする。CI では bundler 実行をキャッシュ可能な step として分離する |
| R4 | Windows の長パス / CRLF / シンボリックリンク | `core.longpaths=true` と `core.autocrlf=false` を前提とし、worktree 親ディレクトリ名を短い固定値 `.fleetkanban-worktrees`（フォールバック時は `%APPDATA%\FleetKanban\worktrees\`）に統一する |
| R5 | SQLite 書き込み競合 | 書き込み専用 `sql.DB` を `SetMaxOpenConns(1)` で直列化、読み取りは別 `sql.DB`（WAL 並列）で捌く |
| R6 | SDK が `claude-sonnet-4.6` を未サポートの場合 | 起動時 `ListModels` で確認し、`claude-sonnet-4.5 → gpt-5` の順でフォールバックする |
| R7 | Flutter ↔ sidecar ハンドシェイク失敗（OS 側の EDR がブロック等） | sidecar が 5s 以内に READY 行を stdout に出さなければ UI が `SidecarStartupFailed` を表示。sidecar 側は stderr に構造化ログを吐く（フォールバック用） |
| R8 | SDK 認証判定の信頼性 | `auth.getStatus` RPC は SDK が提供する公式 API であり、`--list-env` 出力の正規表現パースより信頼性が高い。`Runtime.Start` 後に呼び出す必要がある |
| R9 | loopback gRPC の秘匿性 | sidecar 起動時に生成する base64 トークンを `x-auth-token` メタデータで検証（`subtle.ConstantTimeCompare`）。localhost 外接続は `net.Listen("tcp", "127.0.0.1:0")` で物理的に排除 |
