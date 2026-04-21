# Adapter: extract_plan_json

**Type:** deterministic adapter (non-LLM)
**Stage:** plan (post-processing)
**Failure mode raised:** `plan_parse_error`

---

## Purpose

Extract the structured `PLAN_JSON` block from raw planner LLM output and
return it as a parsed Go value. This adapter is a pure function: given the
same raw string it always produces the same result or the same error.

---

## Expected input format

The planner is instructed to emit output in strict order:

```
PLAN_SUMMARY
...markdown content...

PLAN_JSON: {"subtasks":[...]}
```

The `PLAN_JSON:` prefix appears at the start of a line, followed by a single
space, followed by a JSON object on the same line (no line wrapping inside the
JSON object is required but must be valid JSON).

---

## Parsing algorithm

1. Scan the raw output line by line.
2. Find the first line that matches the regular expression:
   ```
   ^PLAN_JSON:\s+(\{.+\})\s*$
   ```
3. If no such line is found, raise `plan_parse_error` with message
   `"PLAN_JSON block not found in planner output"`.
4. Capture group 1 is the raw JSON string. Attempt `json.Unmarshal` into the
   `PlanJSON` struct (see schema below).
5. If unmarshal fails, raise `plan_parse_error` with message
   `"PLAN_JSON unmarshal failed: <underlying error>"`.
6. Validate that `plan.Subtasks` has at least one entry. If empty, raise
   `plan_parse_error` with message `"PLAN_JSON contains zero subtasks"`.
7. Return the parsed `PlanJSON` value.

---

## Output schema

```jsonc
{
  "subtasks": [
    {
      "id": "string",           // unique within the plan, e.g. "s1"
      "prompt": "string",       // Markdown; must contain **Goal:**, file list, **Done when:**
      "depends_on": ["string"]  // ids of upstream subtasks; empty array for roots
    }
  ]
}
```

---

## Error contract

| Condition | Error name | Retryable |
|-----------|-----------|-----------|
| `PLAN_JSON:` line absent | `plan_parse_error` | yes (1 retry) |
| JSON syntax error | `plan_parse_error` | yes (1 retry) |
| Zero subtasks | `plan_parse_error` | yes (1 retry) |
| Dependency cycle detected | `plan_parse_error` | yes (1 retry) |

---

## Notes

- The adapter does NOT call any LLM. If the planner output is structurally
  wrong, the harness re-invokes the planner (up to the retry budget) rather
  than attempting to repair the JSON.
- Dependency cycle detection should use a simple DFS; cycles indicate a
  planner hallucination and are not auto-corrected.
- The `PLAN_SUMMARY` block preceding `PLAN_JSON:` is extracted separately
  for display in the UI and is not validated by this adapter.
