//go:build windows

package ihr

import (
	"bufio"
	"context"
	"errors"
	"fmt"
	"log/slog"
	"strconv"
	"strings"
)

// MaxPatchLineChanges caps how many touched lines (added + removed) the
// Evolver accepts from a proposed unified diff. A larger change is almost
// always a sign the model hallucinated a wholesale rewrite rather than
// the surgical frontmatter tweak we ask for in the Copilot system prompt;
// refusing the patch and leaving the observation row unevolved is safer
// than applying a destructive diff and then hoping the user notices.
const MaxPatchLineChanges = 50

// PatchProposer is the LLM-side of the self-evolution loop. Implementations
// look at recent failed-review observations and return a unified diff
// proposing frontmatter-only changes to the active SKILL.md.
//
// Isolating the proposer behind an interface keeps Evolver independently
// testable (fakes in _test.go feed deterministic patches without needing
// Copilot auth) and leaves the door open for a Phi Silica / NPU-local
// proposer on supported hardware without rewriting Evolver.
type PatchProposer interface {
	// ProposePatch returns a unified diff string or "" when the proposer
	// declines (no useful suggestion, e.g. observations are too thin to
	// reason about). Errors are real failures — timeouts, malformed LLM
	// output, transport issues.
	ProposePatch(ctx context.Context, current Charter, observations []Observation) (string, error)
}

// Observation is the per-task failure context the Evolver bundles for the
// proposer. Keeping the struct small and explicit avoids leaking orchestrator
// types into ihr (and prevents the proposer prompt from ballooning on giant
// PlanJSON dumps — large prompts burn Copilot spend per attempt).
type Observation struct {
	TaskID       string
	ReworkRound  int
	FailureClass string
	FeedbackMD   string
}

// Evolver bundles recent pending observations for a task and asks an
// LLM-backed PatchProposer to propose a unified diff against the current
// SKILL.md. Instances are safe for concurrent use; state lives on the
// proposer or not at all.
type Evolver struct {
	proposer PatchProposer
	log      *slog.Logger
}

// NewEvolver returns an Evolver bound to proposer. log may be nil; a
// default slog logger is substituted so callers do not need a nil check
// on every warn path.
func NewEvolver(p PatchProposer, log *slog.Logger) *Evolver {
	if log == nil {
		log = slog.Default()
	}
	return &Evolver{proposer: p, log: log}
}

// Propose generates a patch candidate. Returns ("", nil) when the
// proposer declines (we treat "no suggestion" as a normal outcome — the
// observation row is already recorded and users can still rework SKILL.md
// by hand). Returns (patch, nil) on success. The caller is responsible
// for validating that the diff applies cleanly via ApplyPatch before
// storing proposed_patch / proposed_hash.
func (e *Evolver) Propose(ctx context.Context, cur Charter, obs []Observation) (string, error) {
	if e == nil || e.proposer == nil {
		return "", errors.New("ihr: evolver has no proposer")
	}
	if len(obs) == 0 {
		return "", nil
	}
	patch, err := e.proposer.ProposePatch(ctx, cur, obs)
	if err != nil {
		return "", fmt.Errorf("ihr: evolver: propose: %w", err)
	}
	return patch, nil
}

// ApplyPatch applies a unified diff to content and returns the new bytes.
// The parser handles only the subset of unified-diff features we ask the
// LLM to emit:
//
//   - A single file's worth of hunks (the leading "--- a/…" / "+++ b/…"
//     header lines are optional and ignored — we apply in-memory, not
//     against a path).
//   - "@@ -a,b +c,d @@" hunk headers (b / d default to 1 when omitted).
//   - Body lines prefixed with one of ' ', '-', '+'. A "\ No newline at
//     end of file" marker is tolerated but does not currently flip the
//     trailing-newline invariant.
//
// The patch is rejected when:
//
//   - The header line counts don't match the supplied +/- / context
//     lines in the hunk body (malformed @@ meta — a classic LLM
//     hallucination failure mode).
//   - The context lines do not match the corresponding lines in content
//     (the hunk is stale w.r.t. the current SKILL.md — we refuse rather
//     than fuzzy-patch).
//   - The sum of added + removed lines exceeds MaxPatchLineChanges (a
//     wholesale rewrite is never what this loop wants).
//
// Returning err without mutating content is the default path for any
// unexpected shape — the Evolver caller logs and stores the observation
// unchanged so the user can still review the raw feedback.
func ApplyPatch(content []byte, unifiedDiff string) ([]byte, error) {
	if strings.TrimSpace(unifiedDiff) == "" {
		return nil, errors.New("ihr: apply patch: empty diff")
	}
	hunks, err := parseHunks(unifiedDiff)
	if err != nil {
		return nil, err
	}
	if len(hunks) == 0 {
		return nil, errors.New("ihr: apply patch: no hunks")
	}

	// Count touched lines up front so a huge diff is rejected before we
	// mutate anything.
	touched := 0
	for _, h := range hunks {
		for _, l := range h.body {
			if len(l) == 0 {
				continue
			}
			switch l[0] {
			case '+', '-':
				touched++
			}
		}
	}
	if touched > MaxPatchLineChanges {
		return nil, fmt.Errorf("ihr: apply patch: %d changed lines exceeds cap %d",
			touched, MaxPatchLineChanges)
	}

	// Normalise to \n; splitKeepEmpty preserves a trailing empty element
	// when content ends with a newline so we can round-trip.
	normalised := strings.ReplaceAll(string(content), "\r\n", "\n")
	lines := strings.Split(normalised, "\n")

	// Apply hunks in source order. Each hunk's @@ header gives us the
	// 1-based starting line in the OLD file; we translate to a 0-based
	// slice index on the working `lines` buffer, adjusting for the net
	// add/remove delta of earlier hunks so subsequent hunks still line
	// up against what's actually in the buffer.
	delta := 0
	for hi, h := range hunks {
		// Old-side start; @@ uses 1-based indexing. oldStart==0 with
		// oldCount==0 is a valid marker for "append to an empty file";
		// we treat it as index 0.
		idx := h.oldStart - 1
		if h.oldStart == 0 {
			idx = 0
		}
		idx += delta
		if idx < 0 || idx > len(lines) {
			return nil, fmt.Errorf("ihr: apply patch: hunk %d starts at out-of-range line %d (buffer=%d)",
				hi, h.oldStart, len(lines))
		}

		// Walk the hunk body, splicing the new content into `lines`.
		cursor := idx
		newLines := make([]string, 0, len(h.body))
		for _, l := range h.body {
			if len(l) == 0 {
				// A genuinely empty body line is treated as a context
				// line containing "" — rare, but some formatters emit
				// it for a blank source line.
				if cursor >= len(lines) {
					return nil, fmt.Errorf("ihr: apply patch: hunk %d context past EOF", hi)
				}
				if lines[cursor] != "" {
					return nil, fmt.Errorf("ihr: apply patch: hunk %d context mismatch at line %d: want %q got %q",
						hi, cursor+1, "", lines[cursor])
				}
				newLines = append(newLines, "")
				cursor++
				continue
			}
			op, payload := l[0], l[1:]
			switch op {
			case ' ':
				if cursor >= len(lines) {
					return nil, fmt.Errorf("ihr: apply patch: hunk %d context past EOF", hi)
				}
				if lines[cursor] != payload {
					return nil, fmt.Errorf("ihr: apply patch: hunk %d context mismatch at line %d: want %q got %q",
						hi, cursor+1, payload, lines[cursor])
				}
				newLines = append(newLines, payload)
				cursor++
			case '-':
				if cursor >= len(lines) {
					return nil, fmt.Errorf("ihr: apply patch: hunk %d delete past EOF", hi)
				}
				if lines[cursor] != payload {
					return nil, fmt.Errorf("ihr: apply patch: hunk %d delete mismatch at line %d: want %q got %q",
						hi, cursor+1, payload, lines[cursor])
				}
				cursor++ // drop: advance over old line, don't emit
			case '+':
				newLines = append(newLines, payload)
			case '\\':
				// "\ No newline at end of file" — ignore; our split
				// already models the trailing-newline case via an empty
				// final element.
				continue
			default:
				return nil, fmt.Errorf("ihr: apply patch: hunk %d unknown op %q", hi, string(op))
			}
		}

		// Splice: replace lines[idx:cursor] with newLines.
		replaced := cursor - idx
		out := make([]string, 0, len(lines)-replaced+len(newLines))
		out = append(out, lines[:idx]...)
		out = append(out, newLines...)
		out = append(out, lines[cursor:]...)
		delta += len(newLines) - replaced
		lines = out
	}

	return []byte(strings.Join(lines, "\n")), nil
}

// hunk captures one @@...@@ block. body retains the original prefix byte
// (' ', '+', '-') on each line so ApplyPatch can dispatch on op without
// re-parsing.
type hunk struct {
	oldStart, oldCount int
	newStart, newCount int
	body               []string
}

// parseHunks extracts every @@ block from the diff. File headers
// (---/+++), "diff --git", and "index …" lines are tolerated and
// ignored — we only care about the hunks.
func parseHunks(diff string) ([]hunk, error) {
	// Strip a surrounding ```diff … ``` fence if the caller forgot to.
	diff = stripDiffFence(diff)

	sc := bufio.NewScanner(strings.NewReader(diff))
	// Allow long lines — SKILL.md prose can exceed bufio's 64 KiB default.
	sc.Buffer(make([]byte, 0, 64*1024), 1024*1024)
	var (
		out     []hunk
		current *hunk
		sawAny  bool
	)
	flush := func() {
		if current != nil {
			out = append(out, *current)
			current = nil
		}
	}
	for sc.Scan() {
		line := sc.Text()
		switch {
		case strings.HasPrefix(line, "@@"):
			flush()
			h, err := parseHunkHeader(line)
			if err != nil {
				return nil, err
			}
			current = &h
			sawAny = true
		case strings.HasPrefix(line, "---"), strings.HasPrefix(line, "+++"),
			strings.HasPrefix(line, "diff "), strings.HasPrefix(line, "index "):
			// file header noise — ignore
			continue
		default:
			if current == nil {
				// Pre-header preamble (e.g. commit message) is fine —
				// just skip until the first @@.
				continue
			}
			current.body = append(current.body, line)
		}
	}
	if err := sc.Err(); err != nil {
		return nil, fmt.Errorf("ihr: apply patch: scan diff: %w", err)
	}
	flush()
	if !sawAny {
		return nil, errors.New("ihr: apply patch: no @@ hunk header found")
	}
	// Validate each hunk body length against the header counts.
	for i, h := range out {
		got := 0
		gotMinus := 0
		gotPlus := 0
		for _, l := range h.body {
			if len(l) == 0 {
				got++
				gotMinus++
				gotPlus++
				continue
			}
			switch l[0] {
			case ' ':
				got++
				gotMinus++
				gotPlus++
			case '-':
				gotMinus++
			case '+':
				gotPlus++
			case '\\':
				// no-op
			default:
				return nil, fmt.Errorf("ihr: apply patch: hunk %d: stray body line %q", i, l)
			}
		}
		_ = got
		if gotMinus != h.oldCount {
			return nil, fmt.Errorf("ihr: apply patch: hunk %d header says -%d but body has %d old lines",
				i, h.oldCount, gotMinus)
		}
		if gotPlus != h.newCount {
			return nil, fmt.Errorf("ihr: apply patch: hunk %d header says +%d but body has %d new lines",
				i, h.newCount, gotPlus)
		}
	}
	return out, nil
}

// parseHunkHeader parses "@@ -a,b +c,d @@ optional section heading"
// into a hunk with zero body. ",b" and ",d" default to 1 when omitted.
func parseHunkHeader(line string) (hunk, error) {
	// Expect at least "@@ -<old> +<new> @@".
	rest := strings.TrimPrefix(line, "@@")
	end := strings.Index(rest, "@@")
	if end < 0 {
		return hunk{}, fmt.Errorf("ihr: apply patch: malformed hunk header %q", line)
	}
	meta := strings.TrimSpace(rest[:end])
	fields := strings.Fields(meta)
	if len(fields) < 2 {
		return hunk{}, fmt.Errorf("ihr: apply patch: malformed hunk header %q", line)
	}
	old := fields[0]
	nw := fields[1]
	if !strings.HasPrefix(old, "-") || !strings.HasPrefix(nw, "+") {
		return hunk{}, fmt.Errorf("ihr: apply patch: malformed hunk header %q", line)
	}
	oldStart, oldCount, err := parseRange(old[1:])
	if err != nil {
		return hunk{}, fmt.Errorf("ihr: apply patch: hunk old range %q: %w", old, err)
	}
	newStart, newCount, err := parseRange(nw[1:])
	if err != nil {
		return hunk{}, fmt.Errorf("ihr: apply patch: hunk new range %q: %w", nw, err)
	}
	return hunk{
		oldStart: oldStart, oldCount: oldCount,
		newStart: newStart, newCount: newCount,
	}, nil
}

// parseRange parses "a,b" or bare "a". Bare "a" means count=1.
func parseRange(s string) (start, count int, err error) {
	if i := strings.IndexByte(s, ','); i >= 0 {
		start, err = strconv.Atoi(s[:i])
		if err != nil {
			return 0, 0, err
		}
		count, err = strconv.Atoi(s[i+1:])
		if err != nil {
			return 0, 0, err
		}
		return start, count, nil
	}
	start, err = strconv.Atoi(s)
	if err != nil {
		return 0, 0, err
	}
	return start, 1, nil
}

// stripDiffFence removes a surrounding ```diff … ``` (or bare ``` … ```)
// fence. The Copilot proposer prompt asks for a fenced block, and the
// regex extractor in copilot_proposer.go pulls the inner body — but some
// callers (tests, manual pastes) may hand us a fenced string directly.
func stripDiffFence(s string) string {
	t := strings.TrimSpace(s)
	if !strings.HasPrefix(t, "```") {
		return s
	}
	// Drop the first line (the opening fence, e.g. "```diff") and the
	// closing fence if present.
	if nl := strings.IndexByte(t, '\n'); nl >= 0 {
		t = t[nl+1:]
	}
	if idx := strings.LastIndex(t, "```"); idx >= 0 {
		t = t[:idx]
	}
	return t
}
