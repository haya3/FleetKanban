// Package analyzer runs a Copilot session against a registered
// repository and converts the output into scratchpad entries. The
// Copilot session itself is driven by callers (we accept a Runner
// interface rather than importing copilot, which would create a
// cycle through app); the analyzer handles prompt composition,
// response parsing, and scratchpad writes.
package analyzer

import (
	"context"
	"encoding/json"
	"fmt"
	"log/slog"
	"strings"

	"github.com/oklog/ulid/v2"

	"github.com/haya3/FleetKanban/internal/ctxmem"
	"github.com/haya3/FleetKanban/internal/ctxmem/store"
)

// SessionRunner runs a one-shot Copilot session in the given repo and
// returns the final assistant output. Implemented by the copilot
// package at wiring time; the analyzer does not import copilot.
//
// RepoPath is used by Analyze to stamp the absolute path into the user
// prompt so the LLM cannot confuse it with a similarly-named sibling
// repo. Returning an error is acceptable; Analyze then falls through
// to the un-stamped prompt.
//
// progress (when non-nil) is called for each SDK event worth surfacing
// — tool starts, LLM turns, intent updates — so the UI can render a
// rolling status log instead of a static spinner.
type SessionRunner interface {
	RunOneShot(ctx context.Context, repoID, model, prompt string, progress func(string)) (string, error)
	RepoPath(ctx context.Context, repoID string) (string, error)
}

// Analyzer composes the analysis prompt, invokes the session runner,
// and writes ScratchpadEntry rows for each extracted item.
type Analyzer struct {
	runner     SessionRunner
	scratchpad *store.ScratchpadStore
	settings   *store.SettingsStore
	log        *slog.Logger
}

// New returns an Analyzer.
func New(runner SessionRunner, scratchpad *store.ScratchpadStore, settings *store.SettingsStore, log *slog.Logger) *Analyzer {
	if log == nil {
		log = slog.Default()
	}
	return &Analyzer{runner: runner, scratchpad: scratchpad, settings: settings, log: log}
}

// Analyze runs the one-shot session and persists extracted entries.
// model overrides MemorySettings.LLMModel; pass "" to use the setting.
// progress forwards SDK-level activity to a caller-supplied reporter
// (typically the ChangeBroker) so the UI banner renders live status.
// nil is accepted — the session still runs but without live updates.
func (a *Analyzer) Analyze(ctx context.Context, repoID, model string, progress func(string)) error {
	set, err := a.settings.Get(ctx, repoID)
	if err != nil {
		return err
	}
	if model == "" {
		model = set.LLMModel
	}
	if a.runner == nil {
		return fmt.Errorf("ctxmem/analyzer: no session runner configured")
	}
	// Inject the absolute path so the LLM cannot silently switch to a
	// different repo via absolute path reads. The path lookup can fail
	// benignly (repo row missing mid-run); fall back to the generic
	// prompt in that case.
	repoPath, _ := a.runner.RepoPath(ctx, repoID)
	prompt := buildAnalyzerPrompt(repoPath)
	out, err := a.runner.RunOneShot(ctx, repoID, model, prompt, progress)
	if err != nil {
		return fmt.Errorf("ctxmem/analyzer: session: %w", err)
	}
	entries, err := parseAnalyzerOutput(out)
	if err != nil {
		return fmt.Errorf("ctxmem/analyzer: parse output: %w", err)
	}
	for _, e := range entries {
		e.ID = ulid.Make().String()
		e.RepoID = repoID
		e.SourceKind = ctxmem.SourceAnalyzer
		e.Status = ctxmem.ScratchpadPending
		if err := a.scratchpad.Create(ctx, e); err != nil {
			a.log.Warn("ctxmem/analyzer: persist entry", "err", err)
			continue
		}
	}
	return nil
}

// buildAnalyzerPrompt composes the user prompt with the target repo's
// absolute path hard-coded so the LLM cannot mistakenly analyze a
// sibling directory. Empty repoPath falls back to the generic phrasing
// (the session's WorkingDirectory still anchors view/edit tools).
func buildAnalyzerPrompt(repoPath string) string {
	scope := ""
	if repoPath != "" {
		scope = fmt.Sprintf(
			"Your target repository is located at the absolute path:\n\n  %s\n\n"+
				"Read ONLY files inside that directory. Do NOT use absolute paths "+
				"that escape this directory, even if the filesystem has sibling "+
				"projects. If you catch yourself reading a path outside the target, "+
				"stop immediately and explain the mistake in your output.\n\n",
			repoPath)
	}
	return scope + analysisPromptBody
}

// analysisPromptBody is the body of the analyzer user prompt — format
// instructions only. The repo-scoping preamble is prepended at call
// time by buildAnalyzerPrompt so the path is not duplicated across
// test fixtures that don't need it.
const analysisPromptBody = `You are a code-auditing AI. Produce a structured summary of the target repository's architectural intent. Respond with a SINGLE JSON document and no prose outside it, of the form:

{
  "entries": [
    {
      "kind": "Concept|Decision|Constraint|Module",
      "label": "short human-readable label",
      "content_md": "Markdown body with detail (1-3 short paragraphs). Reference actual file paths from the target repository.",
      "signals": ["brief reason 1", "brief reason 2"],
      "confidence": 0.0 to 1.0,
      "attrs": {"optional": "metadata"}
    }
  ]
}

Cover: language / framework stack, build / test / lint commands, key modules and what they do, explicit architectural constraints (e.g. "writes outside worktree denied"), recurring conventions (naming, structure, error handling), and any decision records you find (CHANGELOG, decision documents, prominent comments). Do NOT invent decisions that aren't supported by the files you read. Do NOT carry over knowledge from previous sessions or other repositories — only what you observe in the target repository's files. Prefer fewer high-confidence entries over many speculative ones.`

type analyzerEntry struct {
	Kind       string   `json:"kind"`
	Label      string   `json:"label"`
	ContentMD  string   `json:"content_md"`
	Signals    []string `json:"signals"`
	Confidence float32  `json:"confidence"`
	// Attrs is deliberately `any`-valued: the LLM frequently emits
	// arrays or objects as attribute values despite the
	// map[string]string contract advertised in the prompt. We accept
	// whatever shape comes back and stringify each value for the
	// scratchpad row.
	Attrs map[string]any `json:"attrs,omitempty"`
}

type analyzerOutput struct {
	Entries []analyzerEntry `json:"entries"`
}

// parseAnalyzerOutput pulls the JSON block from the session output
// and maps each entry to a ScratchpadEntry. Tolerates leading/trailing
// non-JSON content (the LLM commonly emits a preamble + ```json
// fenced block + trailing prose despite the explicit "single JSON
// document, no prose" instruction).
//
// Strategy: seek the first '{' and hand the remaining bytes to
// json.Decoder, which reads exactly one top-level value and then
// stops — trailing fences / markdown don't affect it. Falling back
// on json.Unmarshal of a best-effort slice was too fragile because
// LastIndex('}') could land inside a string value that happened to
// contain a literal brace (e.g. a code example in content_md).
func parseAnalyzerOutput(raw string) ([]ctxmem.ScratchpadEntry, error) {
	raw = strings.TrimSpace(raw)
	if raw == "" {
		return nil, nil
	}
	first := strings.Index(raw, "{")
	if first < 0 {
		return nil, fmt.Errorf("ctxmem/analyzer: no JSON object in output")
	}
	dec := json.NewDecoder(strings.NewReader(raw[first:]))
	var parsed analyzerOutput
	if err := dec.Decode(&parsed); err != nil {
		return nil, fmt.Errorf("ctxmem/analyzer: unmarshal: %w", err)
	}
	out := make([]ctxmem.ScratchpadEntry, 0, len(parsed.Entries))
	for _, e := range parsed.Entries {
		if e.Label == "" || e.Kind == "" {
			continue
		}
		out = append(out, ctxmem.ScratchpadEntry{
			ProposedKind:      e.Kind,
			ProposedLabel:     e.Label,
			ProposedContentMD: e.ContentMD,
			ProposedAttrs:     stringifyAttrs(e.Attrs),
			Signals:           e.Signals,
			Confidence:        clamp01(e.Confidence),
		})
	}
	return out, nil
}

// stringifyAttrs coerces any-valued attribute map entries to string.
// Strings pass through; numbers / bools use Go's default formatting;
// slices and maps round-trip through json.Marshal so the scratchpad
// row preserves full structure as a JSON literal. Nil values yield
// an empty string.
func stringifyAttrs(in map[string]any) map[string]string {
	if len(in) == 0 {
		return nil
	}
	out := make(map[string]string, len(in))
	for k, v := range in {
		switch tv := v.(type) {
		case nil:
			out[k] = ""
		case string:
			out[k] = tv
		case float64:
			out[k] = fmt.Sprintf("%g", tv)
		case bool:
			if tv {
				out[k] = "true"
			} else {
				out[k] = "false"
			}
		default:
			b, err := json.Marshal(tv)
			if err != nil {
				out[k] = fmt.Sprintf("%v", tv)
			} else {
				out[k] = string(b)
			}
		}
	}
	return out
}

func clamp01(f float32) float32 {
	if f < 0 {
		return 0
	}
	if f > 1 {
		return 1
	}
	return f
}
