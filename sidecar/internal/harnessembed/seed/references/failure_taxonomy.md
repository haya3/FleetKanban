# Failure Taxonomy

This table enumerates the named failure modes recognised by the FleetKanban
harness. Each mode maps to a retry budget and a fallback state. The harness
raises a typed error by name; adapters and the orchestrator match on the name
to apply the correct policy.

| Name | Detection | Fallback | Retry | Example |
|------|-----------|----------|-------|---------|
| `plan_parse_error` | The `extract_plan_json` adapter cannot locate a well-formed `PLAN_JSON:` block in planner output, or the JSON is syntactically invalid. | `human_review` | 1 | Planner emits prose explanation instead of the required JSON block; or produces `PLAN_JSON: null`. |
| `subtask_timeout` | A single Code-stage LLM invocation exceeds the configured per-subtask deadline without producing a terminal summary. | `failed` | 0 | Network partition mid-stream; model hangs on a large file read loop. |
| `review_marker_missing` | The `parse_review_decision` adapter finds neither `APPROVE` nor `REWORK:` on a standalone line in reviewer output. | `human_review` | 1 | Reviewer writes "I would approve this" inline within a paragraph instead of the required terminal marker line. |

## Policy notes

- **Retry budget** counts invocations of the same stage for the same input.
  A retry of 1 means the stage runs at most twice (original + one retry).
- **`human_review` fallback** surfaces the task to the UI with a warning
  banner so the user can inspect raw output and decide whether to re-trigger
  or close the task.
- **`failed` fallback** marks the task as unrecoverable. The orchestrator
  records the failure reason in the task's audit log and stops processing.
- New failure modes must be added to both this table and the
  `failure_taxonomy` map in `SKILL.md` frontmatter to remain in sync.
