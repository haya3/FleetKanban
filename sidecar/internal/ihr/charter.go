//go:build windows

// Package ihr implements the Intelligent Harness Runtime (IHR) for
// FleetKanban's Phase B NLAH integration (arXiv:2603.25723v1).
//
// The package is intentionally isolated: it reads a runtime charter from
// harness-skill/SKILL.md, evaluates YAML-defined stage transitions
// deterministically, and exposes a Runtime that Orchestrator will delegate
// to in a later integration phase. No LLM calls are made here.
package ihr

import (
	"bytes"
	"errors"
	"fmt"
	"strings"

	"gopkg.in/yaml.v3"
)

// Charter is the parsed form of harness-skill/SKILL.md.
// Callers construct one via ParseCharter and consult it for stage contracts,
// transitions, failure taxonomy, and runtime constants.
type Charter struct {
	HarnessVersion  int
	Stages          []string
	MaxReworkCount  int
	Contracts       map[string]StageContract // key: stage name
	Transitions     []Transition
	FailureTaxonomy map[string]FailurePolicy // key: failure_class
	// Prompts holds the per-stage system prompt that the copilot package
	// feeds into SDK CreateSession as SystemMessage.Content. Keys are the
	// stage names declared in Stages (plan / code / review). Charters that
	// omit a stage's entry fall back to the built-in Default*Prompt
	// constants in the copilot package — validation warns on the gap so
	// users know their edits have holes.
	Prompts         map[string]string
	Body            string                   // Markdown body after frontmatter
	RawContent      string                   // full bytes (for hashing)
}

// PromptFor returns the charter-defined system prompt for a stage. Empty
// string means the charter has no entry for that stage; callers should
// fall back to their built-in default.
func (c *Charter) PromptFor(stage string) string {
	if c == nil {
		return ""
	}
	return c.Prompts[stage]
}

// StageContract declares the typed inputs and outputs for a single stage.
type StageContract struct {
	In  []string
	Out []string
}

// Transition is one row in the transitions table. The When expression is
// stored verbatim; evaluation lives in interpreter.go.
type Transition struct {
	From string
	To   string
	When string
}

// FailurePolicy records the retry budget and escalation terminal for a
// named failure class.
type FailurePolicy struct {
	Retry    int
	Fallback string // human_review | failed | ...
}

// ValidationError collects human-readable parse and semantic problems.
// A nil pointer means no errors were found.
type ValidationError struct {
	Errors   []string
	Warnings []string
}

func (v *ValidationError) Error() string {
	return strings.Join(v.Errors, "; ")
}

// requiredStages are the canonical stage names that must appear in every
// valid charter (memory: feedback_fleetkanban_stage_naming.md).
var requiredStages = []string{"plan", "code", "review"}

// OrchestratorFailureClasses lists the failure_class strings the orchestrator
// currently emits when recording harness_attempt rows. Charter.Validate warns
// when any of these are missing from failure_taxonomy — that silent mismatch
// means the charter declares retry/fallback policy for a class nobody
// produces, or vice-versa the orchestrator generates a class the charter
// ignores. The list is the source of truth; orchestrator.go imports it to
// keep the two sides coupled at compile time rather than by loose strings.
//
// When the evolver / new stage hooks add new emit sites, append here so the
// validation warning trips on charters that forgot to describe the new class.
var OrchestratorFailureClasses = []string{
	"review_rework",
	"rework_cap_reached",
}

// validTerminals are the allowed destinations for terminal transitions.
var validTerminals = map[string]bool{
	"human_review": true,
	"failed":       true,
}

// ParseCharter reads the full content of a SKILL.md file, splits the YAML
// frontmatter (delimited by "---\n") from the Markdown body, unmarshals the
// frontmatter, and validates the resulting structure.
//
// Returns a non-nil error if the frontmatter cannot be parsed or the charter
// fails structural validation.
func ParseCharter(content []byte) (*Charter, error) {
	fm, body, err := splitFrontmatter(content)
	if err != nil {
		return nil, fmt.Errorf("ihr: split frontmatter: %w", err)
	}

	raw := new(rawCharter)
	if err := yaml.Unmarshal(fm, raw); err != nil {
		return nil, fmt.Errorf("ihr: unmarshal frontmatter YAML: %w", err)
	}

	c := &Charter{
		HarnessVersion:  raw.HarnessVersion,
		Stages:          raw.Stages,
		MaxReworkCount:  raw.MaxReworkCount,
		Contracts:       make(map[string]StageContract, len(raw.Contract)),
		Transitions:     make([]Transition, 0, len(raw.Transitions)),
		FailureTaxonomy: make(map[string]FailurePolicy, len(raw.FailureTaxonomy)),
		Prompts:         make(map[string]string, len(raw.Prompts)),
		Body:            body,
		RawContent:      string(content),
	}

	for stage, prompt := range raw.Prompts {
		c.Prompts[stage] = prompt
	}

	for stage, rc := range raw.Contract {
		c.Contracts[stage] = StageContract{In: rc.In, Out: rc.Out}
	}
	for _, rt := range raw.Transitions {
		c.Transitions = append(c.Transitions, Transition{
			From: rt.From,
			To:   rt.To,
			When: rt.When,
		})
	}
	for class, rp := range raw.FailureTaxonomy {
		c.FailureTaxonomy[class] = FailurePolicy{
			Retry:    rp.Retry,
			Fallback: rp.Fallback,
		}
	}

	if ve := c.Validate(); ve != nil && len(ve.Errors) > 0 {
		return nil, fmt.Errorf("ihr: invalid charter: %w", ve)
	}
	return c, nil
}

// Validate re-runs the semantic checks on the charter. Returns nil when the
// charter is clean. Used by HarnessService.ValidateSkill RPC.
func (c *Charter) Validate() *ValidationError {
	var ve ValidationError

	// 1. Required stages present.
	stageSet := make(map[string]bool, len(c.Stages))
	for _, s := range c.Stages {
		stageSet[s] = true
	}
	for _, req := range requiredStages {
		if !stageSet[req] {
			ve.Errors = append(ve.Errors,
				fmt.Sprintf("required stage %q not declared in stages", req))
		}
	}

	// Build full valid node set: declared stages + terminals.
	validNodes := make(map[string]bool, len(c.Stages)+len(validTerminals))
	for _, s := range c.Stages {
		validNodes[s] = true
	}
	for t := range validTerminals {
		validNodes[t] = true
	}

	// 2. Transition from/to validity.
	for i, tr := range c.Transitions {
		if !validNodes[tr.From] {
			ve.Errors = append(ve.Errors,
				fmt.Sprintf("transition[%d]: unknown from stage %q", i, tr.From))
		}
		if !validNodes[tr.To] {
			ve.Errors = append(ve.Errors,
				fmt.Sprintf("transition[%d]: unknown to stage %q", i, tr.To))
		}
		if tr.When == "" {
			ve.Warnings = append(ve.Warnings,
				fmt.Sprintf("transition[%d] from=%q to=%q: empty when expression", i, tr.From, tr.To))
		}
	}

	// 3. Reachability: plan must be able to reach at least one terminal.
	if len(ve.Errors) == 0 { // skip if earlier errors may corrupt graph
		if !reachable(c.Transitions, "plan", validTerminals) {
			ve.Errors = append(ve.Errors,
				"no path from stage \"plan\" to a terminal (human_review or failed)")
		}
	}

	// 4. max_rework_count positive.
	if c.MaxReworkCount <= 0 {
		ve.Errors = append(ve.Errors,
			fmt.Sprintf("max_rework_count must be > 0, got %d", c.MaxReworkCount))
	}

	// 5. failure_taxonomy fallbacks are valid terminals.
	for class, fp := range c.FailureTaxonomy {
		if fp.Fallback != "" && !validTerminals[fp.Fallback] && !stageSet[fp.Fallback] {
			ve.Errors = append(ve.Errors,
				fmt.Sprintf("failure_taxonomy[%q]: fallback %q is not a valid stage or terminal",
					class, fp.Fallback))
		}
	}

	// 6a. Every required stage should have a non-empty entry in prompts.
	// Missing entries are warnings, not errors: the copilot runtime falls
	// back to its built-in Default*Prompt constants so the pipeline keeps
	// working, but the charter is not actually driving that stage's
	// behaviour — the author almost certainly didn't mean that.
	for _, req := range requiredStages {
		if strings.TrimSpace(c.Prompts[req]) == "" {
			ve.Warnings = append(ve.Warnings,
				fmt.Sprintf("prompts[%q] is empty; stage will run with the built-in Default%sPrompt fallback", req, capitalise(req)))
		}
	}

	// 6. Every class the orchestrator emits must appear in failure_taxonomy.
	// This keeps SKILL.md declarative coverage in sync with Go-side recording.
	// Missing entries are warnings (not errors) so charter authors can still
	// save-in-progress edits that have not yet filled in the new policy.
	for _, class := range OrchestratorFailureClasses {
		if _, ok := c.FailureTaxonomy[class]; !ok {
			ve.Warnings = append(ve.Warnings,
				fmt.Sprintf("failure_taxonomy missing entry for orchestrator-emitted class %q (retry/fallback policy will be undefined for this failure mode)", class))
		}
	}

	if len(ve.Errors) == 0 && len(ve.Warnings) == 0 {
		return nil
	}
	return &ve
}

// --- YAML raw types -------------------------------------------------------

type rawCharter struct {
	HarnessVersion  int                       `yaml:"harness_version"`
	Stages          []string                  `yaml:"stages"`
	MaxReworkCount  int                       `yaml:"max_rework_count"`
	Contract        map[string]rawContract    `yaml:"contract"`
	Transitions     []rawTransition           `yaml:"transitions"`
	FailureTaxonomy map[string]rawFailPolicy  `yaml:"failure_taxonomy"`
	Prompts         map[string]string         `yaml:"prompts"`
}

type rawContract struct {
	In  []string `yaml:"in"`
	Out []string `yaml:"out"`
}

type rawTransition struct {
	From string `yaml:"from"`
	To   string `yaml:"to"`
	When string `yaml:"when"`
}

type rawFailPolicy struct {
	Retry    int    `yaml:"retry"`
	Fallback string `yaml:"fallback"`
}

// --- helpers --------------------------------------------------------------

// splitFrontmatter extracts the YAML block between the leading "---\n" fence
// and the next "---\n" fence, returning (yaml bytes, markdown body, error).
func splitFrontmatter(content []byte) (fm []byte, body string, err error) {
	const fence = "---\n"
	const fenceNoNL = "---"

	// Strip UTF-8 BOM: Windows Notepad / older editors add 0xEF 0xBB 0xBF
	// at the head of UTF-8 files by default. Without this the subsequent
	// HasPrefix(fence) check would fail on hand-edited SKILL.md and we'd
	// reject it as "missing opening frontmatter fence" — a nonsense error
	// that points nowhere near the actual cause.
	content = bytes.TrimPrefix(content, []byte{0xEF, 0xBB, 0xBF})

	// Normalise CRLF.
	content = bytes.ReplaceAll(content, []byte("\r\n"), []byte("\n"))

	if !bytes.HasPrefix(content, []byte(fence)) && !bytes.HasPrefix(content, []byte(fenceNoNL)) {
		return nil, "", errors.New("missing opening frontmatter fence (---)")
	}

	// Skip the opening fence line.
	rest := content
	if idx := bytes.IndexByte(rest, '\n'); idx >= 0 {
		rest = rest[idx+1:]
	} else {
		return nil, "", errors.New("malformed frontmatter: no newline after opening fence")
	}

	// Find the closing fence.
	closingFence := []byte("\n---\n")
	idx := bytes.Index(rest, closingFence)
	if idx < 0 {
		// Also accept closing fence at end of file without trailing newline.
		closingFenceEOF := []byte("\n---")
		idx = bytes.LastIndex(rest, closingFenceEOF)
		if idx < 0 {
			return nil, "", errors.New("missing closing frontmatter fence (---)")
		}
		fm = rest[:idx]
		body = ""
		return fm, body, nil
	}

	fm = rest[:idx]
	body = string(rest[idx+len(closingFence):])
	return fm, body, nil
}

// capitalise returns s with its first ASCII letter upper-cased. Used for
// building Default*Prompt fallback names in validation messages.
func capitalise(s string) string {
	if s == "" {
		return s
	}
	b := []byte(s)
	if b[0] >= 'a' && b[0] <= 'z' {
		b[0] -= 'a' - 'A'
	}
	return string(b)
}

// reachable performs a breadth-first search from start through the transition
// graph, returning true if any terminal node is reachable.
func reachable(transitions []Transition, start string, terminals map[string]bool) bool {
	visited := make(map[string]bool)
	queue := []string{start}
	for len(queue) > 0 {
		cur := queue[0]
		queue = queue[1:]
		if visited[cur] {
			continue
		}
		visited[cur] = true
		if terminals[cur] {
			return true
		}
		for _, tr := range transitions {
			if tr.From == cur && !visited[tr.To] {
				queue = append(queue, tr.To)
			}
		}
	}
	return false
}
