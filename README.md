# FleetKanban

**English** | [日本語](./README.ja.md) | [简体中文](./README.zh-CN.md) | [Русский](./README.ru.md) | [Español](./README.es.md) | [Deutsch](./README.de.md) | [Português (BR)](./README.pt-BR.md)

<!-- TODO(phase1): replace with docs/screenshots/hero-kanban-board.png -->
<p align="center">
  <img src="docs/screenshots/coming-soon.png"
       alt="FleetKanban Kanban board with multiple AI tasks running in parallel (screenshot coming in Phase 1)"
       width="880">
</p>

<p align="center">
  <b>Autonomous multi-agent task runner for your Windows 11 desktop.</b><br>
  Describe what you want. It plans, runs tasks in parallel on isolated git worktrees,
  and hands every diff back to you for the final call.
</p>

<p align="center">
  <a href="#download"><img src="https://img.shields.io/badge/Download-Windows%2011-0078D4?logo=windows11&logoColor=white" alt="Download for Windows 11"></a>
  <img src="https://img.shields.io/badge/status-Early%20Preview-orange" alt="Early Preview">
  <img src="https://img.shields.io/badge/license-MIT-blue" alt="MIT License">
  <img src="https://img.shields.io/badge/platform-Windows%2011%20only-blue" alt="Windows 11 only">
</p>

---

## Why FleetKanban

- **Plan → parallel execute → you approve.** The AI plans the implementation, runs up to 12 tasks in parallel on isolated git worktrees, and leaves the final **Keep / Merge / Discard** call to you.
- **Never writes to your remote.** No `git push`, no PR creation, no auto-merge — remote writes only happen when you do them yourself.
- **No telemetry. Safe for the enterprise.** No usage analytics, no crash reports, no phone-home. The only outbound traffic is the Copilot API calls your agents make — safe to roll out behind an enterprise boundary.
- **A real Windows 11 app.** Mica / Acrylic, Jump List, toast notifications, taskbar progress — built with Flutter desktop, not Electron.

## Download

- Latest build: [GitHub Releases](https://github.com/haya3/FleetKanban/releases/latest) → `com.fleetkanban.FleetKanban-win-Setup.exe`
- You need: **Windows 11 64-bit** · **GitHub Copilot subscription** · **Git for Windows**
- After install, the app **updates itself with one click** from an in-app InfoBar.

> **Early Preview.** FleetKanban is in Phase 1 development. Until the first tagged release lands, see [CONTRIBUTING.md](./CONTRIBUTING.md) to build from source today.

> **SmartScreen.** Phase 1 ships unsigned, so Windows SmartScreen will show "Windows protected your PC" on first launch. Click "More info" → "Run anyway" to proceed. EV / Azure Trusted Signing is planned for Phase 2.

## How it works

1. **Describe your task in natural language**
   For example: *"Update the sidebar to support dark mode."*
   <!-- TODO(phase1): replace with docs/screenshots/how-1-new-task.png -->
   <img src="docs/screenshots/coming-soon.png" alt="New task dialog on the Kanban board" width="720">

2. **The AI plans and splits it into a subtask DAG**
   The Plan stage produces an execution plan and breaks the work into parallel / serial subtasks, visualised with a Sugiyama layout.
   <!-- TODO(phase1): replace with docs/screenshots/how-2-subtask-dag.png -->
   <img src="docs/screenshots/coming-soon.png" alt="Subtask DAG visualisation showing parallel and serial dependencies" width="720">

3. **Parallel execution on isolated git worktrees**
   4 tasks in parallel by default, up to 12. Each subtask runs in its own git worktree — your `main` branch stays clean and tasks never collide.
   <!-- TODO(phase1): replace with docs/screenshots/how-3-parallel-running.png -->
   <img src="docs/screenshots/coming-soon.png" alt="Multiple AI tasks running in parallel on the Kanban board" width="720">

4. **AI Review → Human Review**
   After the AI self-reviews, you read the diff and choose **Keep / Merge / Discard**. Nothing auto-merges.
   <!-- TODO(phase1): replace with docs/screenshots/how-4-diff-review.png -->
   <img src="docs/screenshots/coming-soon.png" alt="Diff review pane with Keep, Merge, and Discard actions" width="720">

## What makes FleetKanban different

FleetKanban takes a deliberately different path from Claude Code, Cursor, and GitHub Copilot Workspace:

- **Native Windows 11 desktop.** Not a web IDE, not a VS Code fork. Fluent Design, Mica, Jump List, and taskbar progress are all first-class.
- **Many tasks in parallel, fully isolated.** Run several independent tasks against the same repository at once — branches and working trees never collide.
- **Fully local.** Task state, logs, and the repository knowledge base live in SQLite under `%APPDATA%`. Your code doesn't get shipped to a cloud service (Copilot API traffic is the same as any other Copilot client).
- **A designable agent runtime (IHR).** The Intelligent Harness Runtime drives Plan / Code / Review stage transitions from a YAML charter you can hot-edit from the UI. Behaviour is designed, not hidden.
- **Property graph + FTS5 + embeddings.** FleetKanban indexes your repo as a Context / Graph Memory and injects only the relevant context into each agent session, in three tiers (Passive / Reactive / Active) fused with RRF.

## Requirements

- Windows 11 64-bit
- GitHub Copilot subscription (Individual, Business, or Enterprise)
- Git for Windows 2.45+
- PowerShell 7 (the app offers a one-click install on first launch if it's missing)

Full prerequisites and CI skip flags live in [CONTRIBUTING.md](./CONTRIBUTING.md#environment-setup).

## FAQ

- **Does my code get sent to the cloud?** Task state, logs, and the knowledge index are all stored locally in SQLite. When the agent runs, the Copilot SDK talks to the GitHub Copilot API just like any other Copilot client — nothing else leaves your machine.
- **Does FleetKanban collect telemetry?** No. There is no usage analytics, no crash reporting, and no phone-home endpoint. The only outbound traffic from the app is the Copilot API calls the agent makes during task execution (same as any other Copilot client) plus the version check the in-app update prompt performs against GitHub Releases. This makes FleetKanban safe to deploy in enterprise environments — pair it with a Copilot Business or Enterprise subscription and your code stays inside the enterprise boundary.
- **Will it push to my remote by itself?** No. `git push`, PR creation, and auto-merge are simply not implemented. Pushing and opening PRs is something you do explicitly, using the Git CLI, GitHub Desktop, or your IDE.
- **Does it work on macOS / Linux?** No. FleetKanban is Windows 11 64-bit only — permanently.

## Documentation & Links

- [docs/architecture.md](./docs/architecture.md) — internal architecture
- [docs/roadmap.md](./docs/roadmap.md) — Phase 2 / 3 plans
- [CHANGELOG.md](./CHANGELOG.md) — version history
- [CONTRIBUTING.md](./CONTRIBUTING.md) — build & development flow (for developers who want to try it from source)
- [CODE_OF_CONDUCT.md](./CODE_OF_CONDUCT.md)

## Security

If you find a vulnerability, **do not open a public Issue.** Follow the procedure in [SECURITY.md](./SECURITY.md) and report non-publicly via GitHub Security Advisories (the repository's Security tab).

## License

MIT — see [LICENSE](./LICENSE).
