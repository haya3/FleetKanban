# FleetKanban

GitHub Copilot CLI を中核に据えた、**Windows 11 ネイティブ**の自律型マルチエージェント開発フレームワークです。
以下 3 点を設計の柱とし、ゼロから構築します。
(1) エージェント実行基盤として **GitHub Copilot CLI** を子プロセス起動、
(2) デスクトップ層に **Flutter (Windows desktop) + Go gRPC sidecar** を採用、
(3) マルチ OS 対応の妥協を**一切しない Windows 11 専用設計**。

ユーザーは「やりたいこと」をタスクとして投入するだけで、エージェントが
git worktree 上で並列に計画・実装・検証を行い、結果を安全にメインブランチに統合します。

## 想定する主要機能

| 区分 | 機能 | Phase |
| --- | --- | --- |
| 実行基盤 | git worktree 自動作成・破棄によるタスク隔離 | 1 |
| 実行基盤 | Copilot CLI を子プロセス起動し、stdout / stderr をストリーム解析 | 1 |
| 実行基盤 | 複数タスクの並列実行（goroutine + semaphore、上限設定あり） | 1 |
| 実行基盤 | Windows Job Object で子プロセス群を確実に終結 | 1 |
| 永続化 | タスク状態・ログのローカル保存 (SQLite / `modernc.org/sqlite`) | 1 |
| UI | Flutter (Windows desktop) + fluent_ui による Kanban ボード、エージェントターミナル | 1 |
| 品質保証 | 自動検証ループ（build / test / lint） | 2 |
| 統合 | GitHub 連携、PR 作成（手動トリガ） | 2 |
| 知識 | マルチセッションメモリ（過去タスクからの学習） | 3 |

## 技術スタック

最新安定版を積極的に採用します（2026 年 4 月時点）。

- **バックエンド言語**: Go 1.25 以上（ヘッドレス gRPC sidecar）
- **UI フレームワーク**: [Flutter](https://flutter.dev)（Windows desktop） + [fluent_ui](https://pub.dev/packages/fluent_ui)
- **IPC**: gRPC over loopback（protobuf、スキーマは `proto/fleetkanban/v1/`）
- **Copilot エンジン**: [GitHub Copilot CLI](https://github.com/github/copilot-cli) v1.0.29+ を子プロセス起動
- **永続化**: [`modernc.org/sqlite`](https://gitlab.com/cznic/sqlite)（pure Go、CGO 不要）
- **Windows API**: `golang.org/x/sys/windows` + 直接 syscall（Job Object / Mica / Toast / Jump List / DPAPI）
- **並列制御**: `golang.org/x/sync/semaphore`
- **ID 生成**: `github.com/oklog/ulid/v2`
- **ロギング**: 標準 `log/slog`
- **テスト (Go)**: 標準 `testing` + `testify`
- **テスト (Flutter)**: `flutter_test` + `integration_test`
- **Lint / Format (Go)**: `golangci-lint`
- **Lint / Format (Dart)**: `analysis_options.yaml`（`flutter analyze`）
- **ビルドタスク**: Taskfile (`go-task/task`) + [buf](https://buf.build)（proto 生成）
- **配布形式**: MSIX（`dart run msix:create`）
- **対象 OS**: Windows 11（64bit）のみ。macOS / Linux はサポート外

## プロジェクト構成

```
FleetKanban/
├── README.md
├── LICENSE
├── CONTRIBUTING.md                  # 開発者向け貢献ガイド
├── CODE_OF_CONDUCT.md               # Contributor Covenant v2.1
├── SECURITY.md                      # 脆弱性報告フロー
├── CHANGELOG.md                     # リリースノート
├── Taskfile.yml                     # ルートから全タスク実行（sidecar / ui 横断）
├── .github/                         # Issue / PR テンプレ、CI workflow
├── docs/                            # architecture.md / roadmap.md
├── proto/                           # sidecar と ui の契約（唯一の情報源）
│   ├── buf.yaml / buf.gen.yaml / buf.gen.dart.yaml
│   └── fleetkanban/v1/fleetkanban.proto
├── sidecar/                         # Go gRPC バックエンド（ヘッドレス）
│   ├── go.mod                       # module github.com/FleetKanban/fleetkanban
│   ├── cmd/fleetkanban-sidecar/       # エントリ + bundler 生成 embedded CLI
│   └── internal/
│       ├── app/                     # ドメインサービス（gRPC から利用）
│       ├── task/                    # Task モデル・ステートマシン
│       ├── store/                   # SQLite (modernc)
│       ├── worktree/                # git worktree 管理
│       ├── orchestrator/            # 並列実行制御
│       ├── copilot/                 # Copilot SDK アダプタ
│       ├── ipc/                     # gRPC サーバ / 認証 / イベントブローカ
│       ├── reaper/                  # プロセス回収
│       ├── winapi/                  # Windows 11 固有機能
│       └── branding/                # アプリ識別子
├── ui/                              # Flutter UI（Windows desktop）
│   ├── pubspec.yaml
│   ├── windows/
│   └── lib/                         # app / domain / features / infra / theme
└── build/
    └── bin/                         # fleetkanban-sidecar.exe
```

## 前提条件

- **OS**: Windows 11 64bit
- **Go**: 1.25 以上（winget `GoLang.Go` 推奨）
- **Flutter**: 3.27 以上（Windows desktop を有効化: `flutter config --enable-windows-desktop`）
- **Git for Windows**: 2.45 以上（worktree / longpaths 有効化）
- **GitHub Copilot CLI**: v1.0.29 以上。`winget install GitHub.CopilotCLI` または `npm i -g @github/copilot` でインストール後、`copilot` 起動時に `/login` で GitHub Copilot サブスクリプションに認証
- **GitHub Copilot サブスクリプション**（Individual / Business / Enterprise）
- **Visual Studio 2022 Build Tools**: Flutter Windows desktop のビルドに必要（C++ デスクトップ開発ワークロード）
- **PowerShell 7 (pwsh)**: Copilot CLI の子シェルとして要求されます。Windows 11 既定の `powershell.exe` (5.1) とは別物です。事前に `winget install Microsoft.PowerShell` を実行しておくか、初回起動時に UI から install を明示的に承諾してください（裏で winget は走りません。**ユーザ操作のある RPC でのみ実行します**）。CI / headless 環境では `FLEETKANBAN_SKIP_PWSH_CHECK=1` で検出自体を無効化できます

## クイックスタート（Phase 1 完成後のイメージ）

```powershell
# ツールチェイン（初回のみ）
go install github.com/go-task/task/v3/cmd/task@latest
task proto:tools          # buf / protoc-gen-* / protoc_plugin

# Flutter 依存取得
task flutter:pub

# 開発モード起動（sidecar を自動ビルド → Flutter を Windows desktop で起動）
task flutter:run

# 配布用ビルド（MSIX パッケージを生成）
task build:msix
```

起動後は Kanban ボードから:

1. 対象の git リポジトリを選ぶ
2. 「+ 新規タスク」でゴール（自然言語）＋**ベースブランチ**を選択（`main` に限らず任意のブランチ上で作業できる）
3. カードを `Pending` → `Running` にドラッグ、または `▶` ボタンで実行開始
4. エージェント画面でストリーミングログと diff をリアルタイムに確認
5. 完了後は既定で **`Keep`**（worktree だけ撤去、`fleetkanban/<task-id>` ブランチは保持）。必要に応じて `Merge` / `Discard` を明示選択

> **注**: アプリは `git push` / PR 作成 / 自動マージを一切行いません。リモートへの反映・PR 化は外部ツール（Git CLI / GitHub Desktop / IDE）でユーザーが明示的に行う前提です。

> **注 (SmartScreen)**: Phase 1 はコード署名無しで配布するため、初回起動時に Windows SmartScreen が「Windows によって PC が保護されました」の警告を出します。「詳細情報」→「実行」で続行してください。Phase 2 以降で EV 署名 / Azure Trusted Signing を導入予定です。

## 設計上の主な特徴

| 項目 | FleetKanban |
| --- | --- |
| エージェントエンジン | **GitHub Copilot CLI** を子プロセスで起動 |
| 認証 | GitHub Copilot サブスクリプション（Copilot CLI の `/login`） |
| 拡張 | MCP は Copilot CLI の `~/.copilot/mcp-config.json` で構成 |
| 本体言語 / UI | **Flutter (Windows desktop) + Go gRPC sidecar**（ネイティブ描画、子プロセス分離） |
| Windows 固有最適化 | **Job Object / Mica / Jump List / Toast を Go から直接** |
| 対応 OS | **Windows 11 64bit 専用**（最適化が目的） |
| 自動 push / PR / merge | **恒久的に禁止**（すべてユーザー明示操作） |

## Contributing

FleetKanban への貢献に関心を持ってくださる方は [CONTRIBUTING.md](./CONTRIBUTING.md) を
参照してください。開発環境のセットアップ手順、ブランチ戦略、ローカル検証コマンド
(`task lint && task test`)、PR の出し方をまとめています。

行動規範は [Contributor Covenant v2.1](./CODE_OF_CONDUCT.md) を採択しています。
Issue / PR / Discussions のやり取りは行動規範に従ってください。

ロードマップとアーキテクチャ概要は以下にあります:

- [docs/architecture.md](./docs/architecture.md)
- [docs/roadmap.md](./docs/roadmap.md)

## Security

脆弱性を発見した場合は **public な Issue を立てず**、
[SECURITY.md](./SECURITY.md) の手順に従って non-public に報告してください。
GitHub Security Advisories (リポジトリの Security タブ) から報告するのが最も確実です。

## ライセンス

MIT — [LICENSE](./LICENSE) を参照。
