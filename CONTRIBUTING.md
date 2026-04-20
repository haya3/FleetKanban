# Contributing to FleetKanban

FleetKanban への貢献に関心を持ってくださりありがとうございます。このドキュメントは
**Windows 11 64bit 環境を前提**に、開発フローをまとめたものです。macOS / Linux での
開発はサポート外です。

## 行動規範

本プロジェクトは [Contributor Covenant v2.1](./CODE_OF_CONDUCT.md) を採択しています。
Issue・PR・Discussions のやり取りは行動規範に従ってください。

## セキュリティ上の問題

脆弱性を発見した場合は public な Issue を立てず、[SECURITY.md](./SECURITY.md) の
手順に従って報告してください。

## 環境セットアップ

以下のツールを事前にインストールしてください。winget で一括セットアップ可能です。

```powershell
winget install GoLang.Go
winget install Microsoft.PowerShell
winget install Git.Git
winget install Microsoft.VisualStudio.2022.BuildTools --override "--wait --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"
winget install GitHub.CopilotCLI
# Flutter は公式の ZIP を推奨 (https://flutter.dev/)
```

Flutter 有効化:

```powershell
flutter config --enable-windows-desktop
flutter doctor
```

リポジトリ取得とツール導入:

```powershell
git clone https://github.com/FleetKanban/fleetkanban.git
cd fleetkanban

go install github.com/go-task/task/v3/cmd/task@latest
task proto:tools
task flutter:pub
```

## 開発フロー

### ブランチ戦略

- `main` を保護ブランチとして運用します
- 機能開発は `feature/<短い説明>` ブランチで行い、PR でマージします
- **自動 push / 自動 merge / 自動 PR 作成は恒久的に禁止**です。すべての push / PR は人間の
  明示操作で行ってください (エージェントが代理実行することも不可)

### コーディング規約

- Go: `go fmt` と `golangci-lint run ./...` を pass すること
- Dart: `flutter analyze` を pass し、`dart format .` 済みであること
- コメントは原則不要。**なぜ** そうしたのかが非自明なときのみ 1 行で残します
- 新機能を仮説で先取り実装しません (YAGNI)。今必要な分だけ実装します
- バグは**恒久的な修正**を第一候補にします。ワークアラウンドは明示要求時のみ

### ローカル検証

PR を出す前に以下が green であることを確認してください。

```powershell
task lint     # golangci-lint run ./...
task test     # Go unit tests (Copilot 認証不要)
cd ui; flutter analyze; cd ..
```

統合テストは Copilot 認証が必要なため opt-in です:

```powershell
$env:COPILOT_AUTH = "1"
task test:integration
```

### proto 変更時の注意

`proto/fleetkanban/v1/*.proto` を変更した場合、コード生成とバージョン更新が必要です。

```powershell
task proto:gen:all
```

加えて `sidecar/internal/branding/branding.go` の `ProtocolVersion` を bump してください。
UI と sidecar はハンドシェイク時にこの値で互換性を検証します。

### sidecar 変更時の注意

Go コードを変更したら、以下の 2 箇所に出力されるバイナリを両方更新してください。

- `build/bin/fleetkanban-sidecar.exe` (`task build:sidecar` が生成)
- `ui/build/windows/x64/runner/Debug/fleetkanban-sidecar.exe` (Flutter Debug 隣接)

`task flutter:run` は両方を自動でコピーしますが、sidecar 単体の検証中は手動コピーが必要です。

## PR の出し方

1. Issue を検索して重複がないか確認 (なければ Issue 作成から)
2. `main` から branch を切る
3. 変更を複数のコミットに分け、各コミットメッセージは **何を** ではなく **なぜ** を書く
4. `task lint && task test` が local で pass することを確認
5. PR template に沿って Summary / Test plan を記入
6. CI workflow (`.github/workflows/lint-test.yml`) が green になるまで修正

PR のレビューは 1〜3 営業日を目安に一次返信します。

## Issue を立てるとき

- **バグ報告**: `.github/ISSUE_TEMPLATE/bug_report.md` を使用してください。再現手順と
  `fleetkanban-sidecar.exe --version` の出力、Windows ビルド番号を含めてください
- **機能提案**: `.github/ISSUE_TEMPLATE/feature_request.md` を使用してください。
  Phase 1 / 2 / 3 のロードマップ ([docs/roadmap.md](./docs/roadmap.md)) を参照し、
  どの Phase に属する提案か書いてください

## ライセンス

貢献していただいたコードは [MIT License](./LICENSE) の下で配布されます。PR を提出した
時点で、あなたの貢献が MIT で配布されることに同意したものとみなします。
