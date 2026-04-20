# FleetKanban — UI (Flutter Windows desktop)

This directory holds the Flutter source for FleetKanban's UI
(`fleetkanban_ui.exe`). At launch it spawns the `fleetkanban-sidecar.exe`
binary built from `../sidecar/` as a child process and talks to it over
loopback gRPC.

For project overview and architecture, see the repository root's
[README.md](../README.md) and [docs/architecture.md](../docs/architecture.md).

## Layout

```
ui/
├── pubspec.yaml               # Flutter package definition (fluent_ui / grpc / riverpod, etc.)
├── analysis_options.yaml
├── lib/
│   ├── main.dart              # Entry point
│   ├── app/                   # App shell, routing, theme
│   ├── domain/                # UI-side domain models
│   ├── features/              # Per-screen (kanban / terminal / review / settings)
│   ├── infra/
│   │   └── ipc/               # gRPC client + sidecar supervisor + generated proto
│   └── theme/
└── windows/                   # `flutter create windows/` template
```

## Common Commands (run from the repository root)

| Command | What it does |
|---|---|
| `task flutter:pub` | `flutter pub get` |
| `task flutter:run` | Builds the sidecar then runs `flutter run -d windows` |
| `task flutter:build` | Windows release build with sidecar bundled |
| `task build:msix` | Generates the MSIX package |
| `task proto:gen:dart` | Regenerates Dart gRPC stubs into `lib/infra/ipc/generated/` |

## License

MIT — see [LICENSE](../LICENSE) at the repository root.
