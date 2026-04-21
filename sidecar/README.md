# FleetKanban — Sidecar (Go gRPC backend)

This directory holds the Go source for FleetKanban's headless backend
(`fleetkanban-sidecar.exe`). The Flutter UI (`../ui/`) launches it as a child
process and talks to it over loopback gRPC.

For project overview, setup, and architecture, see the repository root's
[README.md](../README.md) and [docs/architecture.md](../docs/architecture.md).

## Layout

```
sidecar/
├── cmd/
│   ├── fleetkanban-sidecar/   # Entry point + bundler-generated embedded CLI
│   └── dbquery/               # Local SQLite inspection helper
├── internal/
│   ├── app/                   # Domain service (invoked from gRPC)
│   ├── task/                  # Task / AgentEvent domain types + FSM
│   ├── store/                 # SQLite persistence (modernc.org/sqlite)
│   ├── ctxmem/                # Context / Graph Memory (closure tables +
│   │                          #   float32 BLOB embeddings with in-Go cosine
│   │                          #   similarity + FTS5 + RRF, three-tier
│   │                          #   prompt injection)
│   ├── runstate/              # NLAH file-backed durable state
│   │                          #   (TASK.md / task_history.jsonl / artifacts)
│   ├── ihr/                   # Intelligent Harness Runtime
│   │                          #   (charter-driven deterministic stage engine)
│   ├── harnessembed/          # go:embed mirror of harness-skill/
│   ├── orchestrator/          # Parallel execution + lifecycle
│   ├── copilot/               # GitHub Copilot SDK adapter
│   ├── worktree/              # git worktree management
│   ├── ipc/                   # gRPC server + auth + event broker
│   ├── reaper/                # Orphan child-process reclamation
│   ├── setup/                 # Runtime-dependency checks (pwsh 7+)
│   ├── winapi/                # Windows 11 APIs (DPAPI / Toast / AUMID / Mica)
│   └── branding/              # App identifiers (incl. ProtocolVersion)
├── go.mod                     # module github.com/haya3/fleetkanban
└── go.sum
```

## Common Commands (run from the repository root)

| Command | What it does |
|---|---|
| `task test` | Unit tests (no network, CI-friendly) |
| `task test:integration` | Integration tests (requires `COPILOT_AUTH=1`, local only) |
| `task lint` | `golangci-lint run` |
| `task build:sidecar` | Produces `../build/bin/fleetkanban-sidecar.exe` |
| `task proto:gen` | Regenerates the Go stubs from `../proto/fleetkanban/v1/*.proto` |

## gRPC Contract

The proto definition is `../proto/fleetkanban/v1/fleetkanban.proto` (the
single source of truth across languages). Go stubs are generated into
`internal/ipc/gen/`, and Dart stubs into `../ui/lib/infra/ipc/generated/`.
Use `task proto:gen:all` to regenerate both at once.

## License

MIT — see [LICENSE](../LICENSE) at the repository root.
