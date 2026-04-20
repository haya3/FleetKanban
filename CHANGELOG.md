# Changelog

All notable changes to this project are recorded in this file.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and version numbers follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- Added `CONTRIBUTING.md` / `CODE_OF_CONDUCT.md` / `SECURITY.md` to document contribution and reporting flows as an OSS project
- CI via `.github/workflows/lint-test.yml` (golangci-lint + Go unit tests + Flutter analyze)
- Issue / PR templates (`.github/ISSUE_TEMPLATE/*.md`, `.github/PULL_REQUEST_TEMPLATE.md`)
- Architecture and roadmap docs placed under `repo/docs/`
- Distinguish GitHub API `401 Unauthorized` / `403 Forbidden` as `ErrInvalidToken` / `ErrInsufficientScopes`

### Changed
- `SanitizeGoal` now folds newlines into spaces to prevent prompt-structure corruption
- Added lint rules to `ui/analysis_options.yaml` (cancel_subscriptions / close_sinks / unnecessary_await_in_return, etc.)
- Added `## Contributing` / `## Security` sections to the README

## [0.1.0] - TBD

Planned first public release of Phase 1. Includes the following:

- Two-process architecture: Go gRPC sidecar + Flutter (Windows desktop) UI
- Parallel task execution using git worktree
- Launching the Copilot CLI as a child process and parsing stdout/stderr into structured events
- Local persistence via SQLite (modernc.org/sqlite)
- Terminating child processes via Windows Job Object
- DPAPI-encrypted storage of GitHub PATs
- Three-party deliberation-based QA via Courtroom (Judge / Proposer / Challenger)

[Unreleased]: https://github.com/FleetKanban/fleetkanban/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/FleetKanban/fleetkanban/releases/tag/v0.1.0
