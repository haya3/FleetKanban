# FleetKanban — Sidecar (Go gRPC backend)

このディレクトリは FleetKanban の headless バックエンド (`fleetkanban-sidecar.exe`) の Go ソースです。Flutter UI (`../ui/`) から子プロセス起動され、loopback gRPC で通信します。

プロジェクト全体の概要・セットアップ・アーキテクチャはリポジトリルートの [README.md](../README.md) と [docs/architecture.md](../docs/architecture.md) を参照してください。

## このディレクトリの構成

```
sidecar/
├── cmd/fleetkanban-sidecar/    # エントリポイント、bundler 生成の embedded CLI
├── internal/
│   ├── app/                   # ドメインサービス（gRPC から呼ばれる）
│   ├── task/                  # Task / AgentEvent ドメイン型
│   ├── store/                 # SQLite 永続化（modernc.org/sqlite）
│   ├── orchestrator/          # 並列実行 + ライフサイクル
│   ├── copilot/               # GitHub Copilot SDK アダプタ
│   ├── worktree/              # git worktree 管理
│   ├── ipc/                   # gRPC サーバ + 認証 + イベントブローカ
│   ├── reaper/                # 孤児子プロセス回収
│   ├── winapi/                # Windows 11 固有 API（DPAPI / Toast / AUMID）
│   └── branding/              # アプリ識別子
├── go.mod                     # module github.com/FleetKanban/fleetkanban
└── go.sum
```

## よく使うコマンド（ルートから実行）

| コマンド | 何をするか |
|---|---|
| `task test` | 単体テスト（ネットワーク不要、CI 向け） |
| `task test:integration` | 統合テスト（`COPILOT_AUTH=1` 必須、ローカル専用） |
| `task lint` | `golangci-lint run` |
| `task build:sidecar` | `../build/bin/fleetkanban-sidecar.exe` を生成 |
| `task proto:gen` | `../proto/fleetkanban/v1/*.proto` から Go スタブを再生成 |

## gRPC 契約

proto 定義は `../proto/fleetkanban/v1/fleetkanban.proto`（全言語共通の唯一の情報源）。Go スタブは `internal/ipc/gen/` に生成され、Dart スタブは `../ui/lib/infra/ipc/generated/` に生成されます。両方を一括再生成するには `task proto:gen:all`。

## ライセンス

MIT — リポジトリルートの [LICENSE](../LICENSE) を参照。
