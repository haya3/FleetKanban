# Adapter: parse_review_decision

**Type:** deterministic adapter (non-LLM)
**Stage:** review (post-processing)
**Failure mode raised:** `review_marker_missing`

---

## Purpose

Extract the terminal decision token (`APPROVE` or `REWORK:`) from raw reviewer
LLM output. This adapter is a pure function: given the same raw string it
always produces the same result or the same error.

---

## Expected input format

The reviewer is instructed to emit a Markdown summary followed by a single
terminal line that is exactly one of:

```
APPROVE
```

or

```
REWORK: <1-2 sentences of actionable feedback>
```

The marker must appear on its own line with no leading or trailing whitespace
other than the newline. It must be the last non-empty line of the output.

---

## Parsing algorithm

1. Split raw output into lines. Strip each line of trailing whitespace.
2. Working backwards from the last line, find the first non-empty line.
3. Check if that line equals `"APPROVE"` exactly (case-sensitive).
   - If yes: return decision `APPROVE`, feedback_md = everything before that line.
4. Check if that line starts with `"REWORK: "` (case-sensitive, note the
   trailing space after the colon).
   - If yes: return decision `REWORK`, rework_reason = substring after `"REWORK: "`,
     feedback_md = everything before that line.
5. If neither condition matches, raise `review_marker_missing` with message
   `"review output does not end with APPROVE or REWORK: marker"`.

---

## Output schema

```go
type ReviewDecision struct {
    Decision    string // "APPROVE" or "REWORK"
    ReworkReason string // non-empty only when Decision == "REWORK"
    FeedbackMd  string // Markdown block preceding the terminal line
}
```

---

## Error contract

| Condition | Error name | Retryable |
|-----------|-----------|-----------|
| Last non-empty line is neither `APPROVE` nor `REWORK: ...` | `review_marker_missing` | yes (1 retry) |
| Output is entirely empty | `review_marker_missing` | yes (1 retry) |

---

## Notes

- Case sensitivity is intentional and matches the reviewer system prompt
  contract. `approve` (lowercase) is not a valid marker and raises
  `review_marker_missing`.
- The `REWORK:` prefix must be followed by at least one non-whitespace
  character. A bare `REWORK:` with no reason text raises `review_marker_missing`
  because it is not actionable feedback.
- The `feedback_md` field is displayed verbatim on the AI Review card in the
  FleetKanban UI; it is not further parsed by the harness.
- This adapter does NOT call any LLM. A missing or malformed marker causes
  the harness to re-invoke the reviewer (up to the retry budget) with the
  same inputs, not to attempt auto-repair.
