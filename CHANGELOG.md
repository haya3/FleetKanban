# Changelog

All notable changes to this project are recorded in this file.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and version numbers follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.1.0] - 2026-04-22

First public release of Phase 1. Distributed as a **source-only GitHub Release** — no prebuilt binaries are published until a code-signing certificate is in place (see `docs/signing-future.md`). Users build from source with `scripts/build-from-source.ps1`; the in-app 1-click updater continues to work via the self-built install feed (`update-feed.txt`).

### Added
- Two-process architecture: Go gRPC sidecar + Flutter (Windows desktop) UI
- Parallel task execution using git worktree
- Launching the Copilot CLI as a child process and parsing stdout/stderr into structured events
- Local persistence via SQLite (`modernc.org/sqlite`)
- Terminating child processes via Windows Job Object
- DPAPI-encrypted storage of GitHub PATs
- Three-party deliberation-based QA via Courtroom (Judge / Proposer / Challenger)
- Velopack packaging pipeline: `task release:pack`, `cliff.toml` for release notes
- In-app one-click update flow (`ui/lib/app/updater/`) with "Update available" InfoBar in the shell
- **Self-built install feed** (`3175c6f`): `scripts/build-from-source.ps1` one-shot bootstrap (winget + go install + dotnet tool + dart pub) writes `update-feed.txt`, so source-built installs receive updates from `build/release/` instead of GitHub. Settings → "Pull & rebuild from source" streams the build log inline.
- `branding.AppVersion` / `appVersion` constants so the About dialog and updater share a single semver source
- `CONTRIBUTING.md` / `CODE_OF_CONDUCT.md` / `SECURITY.md` to document contribution and reporting flows as an OSS project
- CI via `.github/workflows/lint-test.yml` (golangci-lint + Go unit tests + Flutter analyze)
- Issue / PR templates (`.github/ISSUE_TEMPLATE/*.md`, `.github/PULL_REQUEST_TEMPLATE.md`)
- Architecture and roadmap docs placed under `repo/docs/`
- `docs/release-process.md` and `docs/signing-future.md`

### Changed
- Go module path renamed to `github.com/haya3/FleetKanban` (mixed-case canonical)
- `.github/workflows/release.yml` switched to **source-only**: tag push publishes release notes + GitHub auto-attached source archives only. Velopack pack / binary upload paths are retired until signing is available.
- Replaced unmaintained `bitsdojo_window` with `window_manager 0.5.1`
- Replaced discontinued `flutter_markdown` with `flutter_markdown_plus`
- Migrated to `flutter_riverpod 3.3.1` with `riverpod_generator`
- Pinned `win32` on 5.15.0 pending 6.x compatibility review
- `SanitizeGoal` now folds newlines into spaces to prevent prompt-structure corruption
- Added lint rules to `ui/analysis_options.yaml` (`cancel_subscriptions` / `close_sinks` / `unnecessary_await_in_return`, etc.)
- README rewritten as a user-facing pitch across 7 languages with no-telemetry / enterprise-safe framing
- Distinguish GitHub API `401 Unauthorized` / `403 Forbidden` as `ErrInvalidToken` / `ErrInsufficientScopes`
- Bumped `ProtocolVersion` 33 → 34 (substantial `.proto` additions across `fleetkanban.proto`, `housekeeping.proto`, `insights.proto`)

[Unreleased]: https://github.com/haya3/FleetKanban/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/haya3/FleetKanban/releases/tag/v0.1.0
