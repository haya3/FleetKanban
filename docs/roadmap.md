# Roadmap

This is the plan for adding features after Phase 1 (MVP). Completion of each
Phase assumes the acceptance criteria of the previous Phase are met. Schedules
are tentative and will be revisited when implementation starts.

---

## Technical debt carried from Phase 1

These do not block Phase 2 but should be retired opportunistically.

- **Replace `flutter_riverpod/legacy.dart` StateProviders with `@riverpod`
  state classes.** `paneIndexProvider`, `selectedRepoIdProvider`,
  `selectedTaskIdProvider`, `selectedContextRepoProvider`,
  `contextSearchQueryProvider`, and about five more sit in the legacy
  namespace today because riverpod 3 moved `StateProvider` out of the
  main API. The code-gen equivalent is a small `@riverpod class Foo`
  with a `set(value)` method; callers change from
  `ref.read(p.notifier).state = v` to `ref.read(p.notifier).set(v)`.
- **Bump `win32` to 6.x and rewrite `taskbar_overlay.dart`.** Blocked
  previously by `bitsdojo_window` (now removed in v0.1.1). `win32` 6
  drops `COMObject` and does not ship an `ITaskbarList3` binding, so the
  262 lines of FFI in `ui/lib/infra/platform/taskbar_overlay.dart` need
  to be rewritten on top of the new `IUnknown implements ComInterface`
  abstraction (self-authored `ITaskbarList3` class). Scheduled for
  `release/v0.1.2`.
- **Re-enable `riverpod_lint` + `custom_lint`.** Currently omitted
  because `custom_lint 0.8.1` needs analyzer ^8 while `riverpod_lint
  3.1.3` needs analyzer ^9. Restore once `custom_lint` publishes an
  analyzer-9 compatible build.
- **Add `dart run build_runner build` drift check in
  `.github/workflows/lint-test.yml`.** We commit `*.g.dart` outputs, so
  CI should fail when they go stale relative to the `@riverpod` sources.

---

## Phase 2 — Quality Assurance & External Integrations

**Aim**: Let users verify agent output without manual work and push it to
GitHub.

### 2.1 Automated Verification Loop

- Run `build` / `test` / `lint` automatically inside the worktree before
  completing a task
- On failure, feed the logs back into the Copilot session and retry up to N
  times (default 3)
- Verification commands are configurable per repository (presets: Node /
  Python / .NET / Go)
- The UI shows the result of each step in a "Verification" tab

### 2.2 GitHub Integration (all triggered by **explicit user action**)

**Policy**: The app will not autonomously perform `git push` / PR creation /
Issue close in Phase 2 or later. Every action is triggered by explicit user
action (button click) and disabled by default.

- Associate a repository with a GitHub remote. `push` runs only when the user
  explicitly selects **"Push this branch"** from the task menu.
- Similarly, create a PR from the "Create Pull Request..." menu with the user
  confirming the PR body (draft generation is automatic; **creation is
  manually approved**).
  - Embed the agent's summary and diff highlights in the PR body draft.
- Issue sync: a feature to import GitHub Issues as tasks. **Auto-close on
  completion is disabled by default**; opt-in only.

### 2.3 Chat Interface

- A "Codebase Chat" tab alongside the Kanban
- Free-form questions against the repository (one-off sessions, not tasks)

---

## Phase 3 — Knowledge & Optimization

**Aim**: Learn from past tasks to plan and implement better.

### 3.1 Multi-Session Memory

Phase 1 already provides the storage and retrieval substrate (see
[architecture.md §3.4](./architecture.md#34-sqlite-schema) — `ctx_node`
+ closure tables + `ctx_node_vec` float32 BLOB embeddings with in-Go
cosine similarity + FTS5, fused via RRF). Phase 3 layers the automation
on top:

- At task finalization, automatically distill summaries of completed
  tasks, adopted architectural decisions, and failure cases into
  `ctx_node` entries (with embeddings) — today users promote manually
  via the scratchpad
- On new-task submission, search for similar past tasks / decisions /
  failures across the per-repo Context Memory and auto-inject the
  top-k hits into the Planner prompt without an explicit user action
- Surface "this task looks like X from three weeks ago — here's how
  it went" hints in the New Task dialog

### 3.2 Automated Conflict Resolution

- Pass conflicts from `merge` to a dedicated session and propose a resolution
- The user approves/rejects the proposed resolution in the UI

### 3.3 Roadmap / Spec View

- Automatically decompose large goals into multiple tasks
- Display a dependency graph and suggest a completion order

### 3.4 Profiling and Optimization

- Measure memory usage for long-running sessions
- Auto-select Copilot models (lightweight model for easy tasks)

---

## Items for Future Consideration (Phase TBD)

- GUI configuration screen for MCP servers (currently config-file editing)
- Team-sharing mode (local-only → shared SQLite or server-backed)
- Presets for specialized agents such as test-generation agents
- Plugin system (user-defined custom agents / tools)

Note: macOS / Linux are confirmed out of scope and will not be reconsidered.
