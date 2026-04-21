# Contributing to FleetKanban

Thanks for your interest in contributing to FleetKanban. This document
summarizes the development workflow **assuming a Windows 11 64-bit
environment**. Development on macOS / Linux is not supported.

## Code of Conduct

This project adopts the [Contributor Covenant v2.1](./CODE_OF_CONDUCT.md).
All Issue, PR, and Discussions activity must follow it.

## Security Issues

If you discover a vulnerability, do not open a public Issue. Follow the
procedure in [SECURITY.md](./SECURITY.md) instead.

## Tech Stack

Latest stable versions as of April 2026.

**Backend (Go sidecar)**

- **Language**: Go 1.25+ (headless gRPC sidecar)
- **Concurrency**: `golang.org/x/sync/semaphore`
- **Persistence**: [`modernc.org/sqlite`](https://gitlab.com/cznic/sqlite) (pure Go, no CGO)
- **Windows API**: `golang.org/x/sys/windows` + direct syscalls (Job Object / Mica / Toast / Jump List / DPAPI)
- **ID generation**: `github.com/oklog/ulid/v2`
- **Logging**: standard `log/slog`

**UI (Flutter)**

- **Framework**: [Flutter](https://flutter.dev) 3.27+ (Windows desktop) + [fluent_ui](https://pub.dev/packages/fluent_ui) 4.x
- **State management**: [flutter_riverpod](https://pub.dev/packages/flutter_riverpod) 3.3+ with `riverpod_generator` code generation (`@riverpod`-annotated Notifier / AsyncNotifier / StreamProvider)
- **Window chrome**: [flutter_acrylic](https://pub.dev/packages/flutter_acrylic) (Mica / Acrylic), [window_manager](https://pub.dev/packages/window_manager) (frameless window, min size — replaces the discontinued `bitsdojo_window`), [system_theme](https://pub.dev/packages/system_theme) (OS accent colour)
- **Subtask DAG layout**: [graphview](https://pub.dev/packages/graphview) (Sugiyama); node rendering is handled by fluent_ui
- **Markdown rendering**: [flutter_markdown_plus](https://pub.dev/packages/flutter_markdown_plus) (drop-in fork of `flutter_markdown` after upstream archival in 2025)
- **Native folder picker**: [file_selector](https://pub.dev/packages/file_selector) (IFileOpenDialog)
- **Distribution**: [Velopack](https://velopack.io) (`vpk pack` → `Setup.exe` + delta packages + one-click in-app updater); MSIX (`dart run msix:create`) available as a fallback

**IPC / Agent engine**

- **IPC**: gRPC over loopback (protobuf; schemas in `proto/fleetkanban/v1/`)
- **Copilot engine**: [`github.com/github/copilot-sdk/go`](https://github.com/github/copilot-sdk) — in-process Go SDK; the agent runtime binary ships with the installer, no separate install required

**Tooling**

- **Test**: Go `testing` + `testify`; Flutter `flutter_test` + `integration_test`
- **Lint / Format**: `golangci-lint` (Go); `analysis_options.yaml` via `flutter analyze` (Dart)
- **Build tasks**: Taskfile ([`go-task/task`](https://taskfile.dev)) + [buf](https://buf.build) for proto generation
- **Target OS**: Windows 11 (64-bit) only — macOS / Linux are not supported

## Project Layout

```
FleetKanban/
├── README.md
├── LICENSE
├── CONTRIBUTING.md                  # contributor guide
├── CODE_OF_CONDUCT.md               # Contributor Covenant v2.1
├── SECURITY.md                      # vulnerability-reporting flow
├── CHANGELOG.md                     # release notes
├── Taskfile.yml                     # cross-package task runner (sidecar / ui)
├── .github/                         # Issue / PR templates, CI workflow
├── docs/                            # architecture.md / roadmap.md
├── proto/                           # contract between sidecar and ui (source of truth)
│   ├── buf.yaml / buf.gen.yaml / buf.gen.dart.yaml
│   └── fleetkanban/v1/              # fleetkanban.proto / housekeeping.proto / insights.proto
├── sidecar/                         # Go gRPC backend (headless)
│   ├── go.mod                       # module github.com/FleetKanban/fleetkanban
│   ├── cmd/
│   │   ├── fleetkanban-sidecar/     # entry + bundler-generated embedded CLI
│   │   └── dbquery/                 # local SQLite inspection helper
│   └── internal/
│       ├── app/                     # domain services (invoked from gRPC)
│       ├── task/                    # Task model and state machine
│       ├── store/                   # SQLite (modernc)
│       ├── ctxmem/                  # Context / Graph Memory (closure tables + float32 BLOB embeddings with in-Go cosine similarity + FTS5 + RRF, three-tier prompt injection)
│       ├── runstate/                # NLAH file-backed durable state (TASK.md / task_history.jsonl / children / artifacts)
│       ├── worktree/                # git worktree management
│       ├── orchestrator/            # parallel-execution control
│       ├── copilot/                 # Copilot SDK adapter
│       ├── harnessembed/            # go:embed mirror of harness-skill/ (seeded at startup)
│       ├── ihr/                     # Intelligent Harness Runtime — charter-driven deterministic stage engine
│       ├── ipc/                     # gRPC server / auth / event broker
│       ├── reaper/                  # process reclamation
│       ├── setup/                   # runtime-dependency checks (pwsh / winget)
│       ├── winapi/                  # Windows 11-specific features
│       └── branding/                # app identifiers
├── ui/                              # Flutter UI (Windows desktop)
│   ├── pubspec.yaml
│   ├── windows/
│   └── lib/                         # app / domain / features / infra / theme
└── build/
    ├── bin/                         # fleetkanban-sidecar.exe
    └── release/                     # Velopack output (Setup.exe / Portable.zip / *.nupkg / RELEASES)
```

## Environment Setup

### Prerequisites

- **OS**: Windows 11 64-bit
- **Go**: 1.25+ (`winget install GoLang.Go` recommended)
- **Flutter**: 3.27+ — enable Windows desktop with `flutter config --enable-windows-desktop`
- **Git for Windows**: 2.45+ (worktree / longpaths enabled)
- **Visual Studio 2022 Build Tools**: C++ Desktop Development workload (required for Flutter Windows builds)
- **GitHub Copilot subscription**: Individual / Business / Enterprise
- **PowerShell 7 (pwsh)**: required because the Copilot SDK's embedded agent runtime shells out to `pwsh.exe` for tool invocations — distinct from the bundled `powershell.exe` (5.1)
  - Install in advance: `winget install Microsoft.PowerShell`, or consent to install from the UI on first launch (winget requires user interaction)
  - CI / headless environments: set `FLEETKANBAN_SKIP_PWSH_CHECK=1` to skip the check

### One-shot bootstrap

winget can install most of the toolchain in one go:

```powershell
winget install GoLang.Go
winget install Microsoft.PowerShell
winget install Git.Git
winget install Microsoft.VisualStudio.2022.BuildTools --override "--wait --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"
winget install GitHub.CopilotCLI
# Flutter: the official ZIP is recommended (https://flutter.dev/)
```

Enable Flutter:

```powershell
flutter config --enable-windows-desktop
flutter doctor
```

Clone the repository and bootstrap tooling:

```powershell
git clone https://github.com/FleetKanban/fleetkanban.git
cd fleetkanban

go install github.com/go-task/task/v3/cmd/task@latest
task proto:tools
task flutter:pub
```

## Build & Run

```powershell
# Dev mode (auto-build sidecar → launch Flutter on Windows desktop)
task flutter:run

# Sidecar only
task build:sidecar

# Distribution build (Velopack Setup.exe + delta packages)
task build:release

# MSIX fallback
task build:msix
```

After launch, from the Kanban board:

1. Select the target git repository
2. Click **"+ New Task"**, enter the goal (natural language), and pick a **base branch** (any branch, not just `main`)
3. Drag the card from `Pending` → `Running`, or press the `▶` button to start
4. Follow streaming logs and diffs in real time in the agent pane
5. On completion, the default is **`Keep`** (tear down the worktree but retain the `fleetkanban/<task-id>` branch). Optionally choose `Merge` / `Discard` explicitly

> **No automatic remote writes.** The app never performs `git push`, PR
> creation, or auto-merge. Pushing and opening PRs is done explicitly by the
> user with external tools (Git CLI / GitHub Desktop / IDE).

## Development Workflow

### Branching Strategy

- `main` is operated as a protected branch.
- Feature work happens on a `feature/<short-description>` branch and merges
  via PR.
- **Automatic push / merge / PR creation is permanently forbidden.** Every
  push and PR must be performed by an explicit human action (agents may not
  perform them on your behalf).

### Coding Conventions

- Go: must pass `go fmt` and `golangci-lint run ./...`.
- Dart: must pass `flutter analyze` and be formatted with `dart format .`.
- Avoid comments by default. Add a single line only when **why** is
  non-obvious.
- Don't speculatively implement future features (YAGNI). Implement only what
  is needed now.
- Prefer **permanent fixes** for bugs. Workarounds only on explicit request.

### Local Verification

Confirm the following are green before opening a PR:

```powershell
task lint     # golangci-lint run ./...
task test     # Go unit tests (no Copilot auth required)
cd ui; flutter analyze; cd ..
```

Integration tests require Copilot auth and are opt-in:

```powershell
$env:COPILOT_AUTH = "1"
task test:integration
```

### When Changing proto

Changing `proto/fleetkanban/v1/*.proto` requires code regeneration and a
version bump.

```powershell
task proto:gen:all
```

Also bump `ProtocolVersion` in `sidecar/internal/branding/branding.go`. The
UI and sidecar verify compatibility against this value during the handshake.

### When Changing sidecar

After changing Go code, update the binaries in **both** of these locations:

- `build/bin/fleetkanban-sidecar.exe` (produced by `task build:sidecar`)
- `ui/build/windows/x64/runner/Debug/fleetkanban-sidecar.exe`
  (next to the Flutter Debug runner)

`task flutter:run` copies both automatically, but a manual copy is required
when verifying the sidecar in isolation.

## How to Open a PR

1. Search Issues for duplicates (open one first if none exists).
2. Branch off `main`.
3. Split the change into multiple commits and write each commit message in
   terms of **why**, not **what**.
4. Confirm `task lint && task test` passes locally.
5. Follow the PR template and fill in Summary / Test plan.
6. Iterate until the CI workflow (`.github/workflows/lint-test.yml`) is green.

We aim to acknowledge PR reviews within 1–3 business days.

## Filing Issues

- **Bug reports**: use `.github/ISSUE_TEMPLATE/bug_report.md`. Include
  reproduction steps, the output of `fleetkanban-sidecar.exe --version`, and
  your Windows build number.
- **Feature requests**: use `.github/ISSUE_TEMPLATE/feature_request.md`.
  Reference the Phase 1 / 2 / 3 roadmap ([docs/roadmap.md](./docs/roadmap.md))
  and state which Phase the proposal belongs to.

## License

Code contributions are distributed under the [MIT License](./LICENSE). By
submitting a PR you agree that your contribution will be distributed under
the MIT License.
