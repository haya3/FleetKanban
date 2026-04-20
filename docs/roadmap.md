# Roadmap

This is the plan for adding features after Phase 1 (MVP). Completion of each
Phase assumes the acceptance criteria of the previous Phase are met. Schedules
are tentative and will be revisited when implementation starts.

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

- Store summaries of completed tasks, adopted architectural decisions, and
  failure cases with embeddings in SQLite + a vector extension (`sqlite-vss`)
- Search for similar past tasks on new-task submission and auto-inject them
  into the prompt

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
