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

## Environment Setup

Install the following tools beforehand. winget can install them in one shot.

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
