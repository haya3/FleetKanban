# FleetKanban

A **Windows 11-native** autonomous multi-agent development framework built
around the GitHub Copilot CLI.
It is built from scratch on three design pillars:
(1) launching the **GitHub Copilot CLI** as a child process for the agent
execution substrate,
(2) adopting **Flutter (Windows desktop) + Go gRPC sidecar** at the desktop
layer, and
(3) a **Windows 11-only design that makes no compromises for multi-OS
support**.

Users simply submit what they want as a task, and agents plan, implement, and
verify in parallel on git worktrees, then safely integrate the result into the
main branch.

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

We actively adopt the latest stable versions (as of April 2026).

- **Backend language**: Go 1.25+ (headless gRPC sidecar)
- **UI framework**: [Flutter](https://flutter.dev) (Windows desktop) + [fluent_ui](https://pub.dev/packages/fluent_ui)
- **IPC**: gRPC over loopback (protobuf; schema in `proto/fleetkanban/v1/`)
- **Copilot engine**: [GitHub Copilot CLI](https://github.com/github/copilot-cli) v1.0.29+ launched as a child process
- **Persistence**: [`modernc.org/sqlite`](https://gitlab.com/cznic/sqlite) (pure Go, no CGO)
- **Windows API**: `golang.org/x/sys/windows` + direct syscalls (Job Object / Mica / Toast / Jump List / DPAPI)
- **Concurrency**: `golang.org/x/sync/semaphore`
- **ID generation**: `github.com/oklog/ulid/v2`
- **Logging**: standard `log/slog`
- **Test (Go)**: standard `testing` + `testify`
- **Test (Flutter)**: `flutter_test` + `integration_test`
- **Lint / Format (Go)**: `golangci-lint`
- **Lint / Format (Dart)**: `analysis_options.yaml` (`flutter analyze`)
- **Build tasks**: Taskfile (`go-task/task`) + [buf](https://buf.build) (proto generation)
- **Distribution format**: MSIX (`dart run msix:create`)
- **Target OS**: Windows 11 (64-bit) only. macOS / Linux are not supported

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
│   └── fleetkanban/v1/fleetkanban.proto
├── sidecar/                         # Go gRPC backend (headless)
│   ├── go.mod                       # module github.com/FleetKanban/fleetkanban
│   ├── cmd/fleetkanban-sidecar/     # entry + bundler-generated embedded CLI
│   └── internal/
│       ├── app/                     # domain services (invoked from gRPC)
│       ├── task/                    # Task model and state machine
│       ├── store/                   # SQLite (modernc)
│       ├── worktree/                # git worktree management
│       ├── orchestrator/            # parallel-execution control
│       ├── copilot/                 # Copilot SDK adapter
│       ├── ipc/                     # gRPC server / auth / event broker
│       ├── reaper/                  # process reclamation
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
- **Go**: 1.25+ (winget `GoLang.Go` recommended)
- **Flutter**: 3.27+ (enable Windows desktop: `flutter config --enable-windows-desktop`)
- **Git for Windows**: 2.45+ (enable worktree / longpaths)
- **GitHub Copilot CLI**: v1.0.29+. Install via `winget install GitHub.CopilotCLI` or `npm i -g @github/copilot`, then run `copilot` and use `/login` to authenticate against a GitHub Copilot subscription
- **GitHub Copilot subscription** (Individual / Business / Enterprise)
- **Visual Studio 2022 Build Tools**: required for Flutter Windows desktop builds (C++ Desktop Development workload)
- **PowerShell 7 (pwsh)**: required as the Copilot CLI's child shell. Distinct from the `powershell.exe` (5.1) that ships with Windows 11. Run `winget install Microsoft.PowerShell` in advance, or explicitly consent to install from the UI on first launch (winget does **not** run silently in the background; **we only execute via an RPC that involves user action**). In CI / headless environments, set `FLEETKANBAN_SKIP_PWSH_CHECK=1` to disable the check entirely.

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
2. Click "+ New Task", enter the goal (natural language), and pick a **base branch** (you can work on any branch, not just `main`)
3. Drag the card from `Pending` → `Running`, or press the `▶` button to start
4. Follow streaming logs and diffs in real time in the agent pane
5. On completion, the default is **`Keep`** (tear down the worktree but retain the `fleetkanban/<task-id>` branch). Optionally select `Merge` / `Discard` explicitly

> **Note**: The app never performs `git push` / PR creation / auto-merge.
> Reflecting changes to a remote and creating PRs are assumed to be done
> explicitly by the user with external tools (Git CLI / GitHub Desktop / IDE).

> **Note (SmartScreen)**: Phase 1 ships without code signing, so Windows
> SmartScreen will show the "Windows protected your PC" warning on first
> launch. Click "More info" → "Run anyway" to proceed. EV signing / Azure
> Trusted Signing is planned for Phase 2.

## Key Design Characteristics

| Item | FleetKanban |
| --- | --- |
| Agent engine | **GitHub Copilot CLI** launched as a child process |
| Authentication | GitHub Copilot subscription (Copilot CLI `/login`) |
| Extension | MCP configured via Copilot CLI's `~/.copilot/mcp-config.json` |
| Language / UI | **Flutter (Windows desktop) + Go gRPC sidecar** (native rendering, child-process isolation) |
| Windows-specific optimization | **Job Object / Mica / Jump List / Toast called directly from Go** |
| Supported OS | **Windows 11 64-bit only** (optimization is the goal) |
| Auto push / PR / merge | **Permanently disallowed** (always via explicit user action) |

## Contributing

If you are interested in contributing to FleetKanban, see
[CONTRIBUTING.md](./CONTRIBUTING.md). It covers development-environment
setup, branching strategy, local verification commands
(`task lint && task test`), and how to open a PR.

The code of conduct is [Contributor Covenant v2.1](./CODE_OF_CONDUCT.md).
All Issue / PR / Discussions communication must follow it.

The roadmap and architecture overview are here:

- [docs/architecture.md](./docs/architecture.md)
- [docs/roadmap.md](./docs/roadmap.md)

## Security

If you find a vulnerability, **do not open a public Issue**; follow
[SECURITY.md](./SECURITY.md) to report it non-publicly. Reporting via GitHub
Security Advisories (the repository's Security tab) is the most reliable path.

## License

MIT — see [LICENSE](./LICENSE).
