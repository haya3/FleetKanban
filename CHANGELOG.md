# Changelog

本プロジェクトのすべての重要な変更は本ファイルに記録されます。
記述形式は [Keep a Changelog](https://keepachangelog.com/ja/1.1.0/) に従い、
バージョン番号は [Semantic Versioning](https://semver.org/lang/ja/) に従います。

## [Unreleased]

### Added
- `CONTRIBUTING.md` / `CODE_OF_CONDUCT.md` / `SECURITY.md` を追加し、OSS として貢献・報告フローを明文化
- `.github/workflows/lint-test.yml` による CI (golangci-lint + Go unit tests + Flutter analyze)
- Issue / PR テンプレート (`.github/ISSUE_TEMPLATE/*.md`, `.github/PULL_REQUEST_TEMPLATE.md`)
- `repo/docs/` にアーキテクチャとロードマップを配置
- GitHub API の `401 Unauthorized` / `403 Forbidden` を `ErrInvalidToken` / `ErrInsufficientScopes` として区別

### Changed
- `SanitizeGoal` が改行をスペースに折り畳むよう変更。プロンプト構造の破壊を防止
- `ui/analysis_options.yaml` に lint ルールを追加 (cancel_subscriptions / close_sinks / unnecessary_await_in_return など)
- README に `## Contributing` / `## Security` 節を追加

## [0.1.0] - TBD

Phase 1 の初回公開リリース予定。以下を含みます。

- Go gRPC sidecar + Flutter (Windows desktop) UI の 2 プロセス構成
- git worktree を用いた並列タスク実行
- Copilot CLI を子プロセスとして起動、stdout/stderr を構造化イベントに解析
- SQLite (modernc.org/sqlite) によるローカル永続化
- Windows Job Object で子プロセス群を終結
- DPAPI による GitHub PAT 暗号化保存
- Courtroom (Judge / Proposer / Challenger) による三者討議型の品質保証

[Unreleased]: https://github.com/FleetKanban/fleetkanban/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/FleetKanban/fleetkanban/releases/tag/v0.1.0
