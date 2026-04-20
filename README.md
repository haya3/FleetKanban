# FleetKanban

A **Windows 11-native** autonomous multi-agent development framework built
around the GitHub Copilot CLI.

The design rests on three pillars:

- **Agent substrate**: launch the **GitHub Copilot CLI** as a child process and
  stream-parse its stdout / stderr
- **Desktop stack**: **Flutter (Windows desktop) + Go gRPC sidecar** for native
  rendering and child-process isolation
- **Windows 11 only**: no compromises for multi-OS support — Job Object, Mica,
  Jump List, Toast, and DPAPI are called directly from Go

Users submit what they want as a task; agents plan, implement, and verify in
parallel on git worktrees, then integrate the result back into the main branch
under explicit user control.

## Intended Key Features

| Category | Feature | Phase |
| --- | --- | --- |
| Execution substrate | Task isolation via automatic git-worktree create/teardown | 1 |
| Execution substrate | Launch the Copilot CLI as a child process and stream-parse stdout / stderr | 1 |
| Execution substrate | Parallel execution of multiple tasks (goroutine + semaphore, configurable cap) | 1 |
| Execution substrate | Reliably terminate child processes via Windows Job Object | 1 |
| Persistence | Local storage of task state and logs (SQLite / `modernc.org/sqlite`) | 1 |
| UI | Kanban board and agent terminal in Flutter (Windows desktop) + fluent_ui | 1 |
| QA | Automated verification loop (build / test / lint) | 2 |
| Integration | GitHub integration, PR creation (manual trigger) | 2 |
| Knowledge | Multi-session memory (learning from past tasks) | 3 |

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

- **Framework**: [Flutter](https://flutter.dev) (Windows desktop) + [fluent_ui](https://pub.dev/packages/fluent_ui)
- **Distribution**: MSIX (`dart run msix:create`)

**IPC / Agent engine**

- **IPC**: gRPC over loopback (protobuf; schemas in `proto/fleetkanban/v1/`)
- **Copilot engine**: [GitHub Copilot CLI](https://github.com/github/copilot-cli) v1.0.29+ launched as a child process

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
│       ├── worktree/                # git worktree management
│       ├── orchestrator/            # parallel-execution control
│       ├── copilot/                 # Copilot SDK adapter
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
    └── bin/                         # fleetkanban-sidecar.exe
```

## Prerequisites

- **OS**: Windows 11 64-bit
- **Go**: 1.25+ (`winget install GoLang.Go` recommended)
- **Flutter**: 3.27+ — enable Windows desktop with `flutter config --enable-windows-desktop`
- **Git for Windows**: 2.45+ (worktree / longpaths enabled)
- **Visual Studio 2022 Build Tools**: C++ Desktop Development workload (required for Flutter Windows builds)
- **GitHub Copilot CLI**: v1.0.29+ — install via `winget install GitHub.CopilotCLI` or `npm i -g @github/copilot`, then run `copilot` and `/login`
- **GitHub Copilot subscription**: Individual / Business / Enterprise
- **PowerShell 7 (pwsh)**: required as the Copilot CLI's child shell — distinct from the bundled `powershell.exe` (5.1)
  - Install in advance: `winget install Microsoft.PowerShell`, or consent to install from the UI on first launch (winget requires user interaction)
  - CI / headless environments: set `FLEETKANBAN_SKIP_PWSH_CHECK=1` to skip the check

## Quick Start (Envisioned After Phase 1)

```powershell
# Toolchain (first time only)
go install github.com/go-task/task/v3/cmd/task@latest
task proto:tools          # buf / protoc-gen-* / protoc_plugin

# Fetch Flutter dependencies
task flutter:pub

# Dev mode (auto-build sidecar → launch Flutter on Windows desktop)
task flutter:run

# Distribution build (generate MSIX package)
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

> **SmartScreen.** Phase 1 ships without code signing, so Windows SmartScreen
> will show "Windows protected your PC" on first launch. Click "More info" →
> "Run anyway" to proceed. EV signing / Azure Trusted Signing is planned for
> Phase 2.

## Releases

FleetKanban is distributed via GitHub Releases as a Velopack-packaged Windows
installer. Grab `FleetKanban-Setup.exe` from the latest Release and run it;
the app self-updates on a one-click InfoBar prompt after that.

- [docs/release-process.md](./docs/release-process.md) — how to cut a release
  (version bump points, tag push, CI flow, rollback)
- [docs/signing-future.md](./docs/signing-future.md) — when and how to
  introduce code signing (Azure Trusted Signing vs SSL.com OV)

Tagging `v*` on this repository triggers `.github/workflows/release.yml`,
which builds the Flutter UI + Go sidecar, runs `vpk pack`, and uploads the
Setup / delta / full packages to the Release. Nothing else is automated —
version bumps, changelog edits, and tag pushes stay manual.

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for development-environment setup,
branching strategy, local verification (`task lint && task test`), and the
PR flow.

All communication on Issues / PRs / Discussions must follow
[Contributor Covenant v2.1](./CODE_OF_CONDUCT.md).

Deeper design material:

- [docs/architecture.md](./docs/architecture.md)
- [docs/roadmap.md](./docs/roadmap.md)

## Security

If you find a vulnerability, **do not open a public Issue**. Follow
[SECURITY.md](./SECURITY.md) and report non-publicly via GitHub Security
Advisories (the repository's Security tab) as the most reliable path.

## License

MIT — see [LICENSE](./LICENSE).
