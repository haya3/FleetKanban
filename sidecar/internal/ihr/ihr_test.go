//go:build windows

package ihr

import (
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"testing"
)

// skillMDPath resolves the absolute path to harness-skill/SKILL.md relative
// to this test file's location in the source tree.
func skillMDPath(t *testing.T) string {
	t.Helper()
	_, file, _, ok := runtime.Caller(0)
	if !ok {
		t.Fatal("runtime.Caller failed")
	}
	// file: …/internal/ihr/ihr_test.go → up 4 levels to repo/sidecar root
	// then into harness-skill/SKILL.md
	root := filepath.Join(filepath.Dir(file), "..", "..", "harness-skill", "SKILL.md")
	abs, err := filepath.Abs(root)
	if err != nil {
		t.Fatalf("resolve SKILL.md path: %v", err)
	}
	return abs
}

// TestParseCharter_HappyPath reads the real SKILL.md from disk and verifies
// that all top-level Charter fields are populated correctly.
func TestParseCharter_HappyPath(t *testing.T) {
	path := skillMDPath(t)
	content, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("read SKILL.md: %v", err)
	}

	c, err := ParseCharter(content)
	if err != nil {
		t.Fatalf("ParseCharter: %v", err)
	}

	if c.HarnessVersion != 1 {
		t.Errorf("HarnessVersion: got %d, want 1", c.HarnessVersion)
	}

	wantStages := []string{"plan", "code", "review"}
	if len(c.Stages) != len(wantStages) {
		t.Errorf("Stages len: got %d, want %d", len(c.Stages), len(wantStages))
	} else {
		for i, s := range wantStages {
			if c.Stages[i] != s {
				t.Errorf("Stages[%d]: got %q, want %q", i, c.Stages[i], s)
			}
		}
	}

	if c.MaxReworkCount != 2 {
		t.Errorf("MaxReworkCount: got %d, want 2", c.MaxReworkCount)
	}

	for _, stage := range wantStages {
		if _, ok := c.Contracts[stage]; !ok {
			t.Errorf("Contracts[%q] missing", stage)
		}
	}

	if len(c.Transitions) == 0 {
		t.Error("Transitions: expected at least one entry")
	}

	if len(c.FailureTaxonomy) == 0 {
		t.Error("FailureTaxonomy: expected at least one entry")
	}

	if c.Body == "" {
		t.Error("Body: expected non-empty Markdown body")
	}

	if c.RawContent == "" {
		t.Error("RawContent: expected non-empty")
	}

	// Prompts section: the canonical SKILL.md ships a non-empty prompt
	// for every required stage. A missing entry here would mean the
	// charter is silently delegating that stage to DefaultPlanPrompt /
	// DefaultCodePrompt / DefaultReviewPrompt — defeating the whole
	// point of making SKILL.md the prompt source of truth.
	for _, stage := range wantStages {
		if p := c.PromptFor(stage); p == "" {
			t.Errorf("PromptFor(%q): empty — SKILL.md must ship a non-empty prompt for every required stage", stage)
		}
	}
}

// TestPromptFor_NilReceiver proves PromptFor is safe on a nil *Charter
// so main.go can pass charterHolder.Load() (which is nil before the
// first parse) directly into the StagePromptLookup closure without a
// guard. Regressing this re-introduces a startup-window nil-deref.
func TestPromptFor_NilReceiver(t *testing.T) {
	var c *Charter
	if got := c.PromptFor("plan"); got != "" {
		t.Errorf("nil *Charter.PromptFor: got %q, want empty", got)
	}
}

// TestParseCharter_StripsUTF8BOM proves ParseCharter accepts a SKILL.md
// that was saved with a UTF-8 BOM (Windows Notepad's default for UTF-8
// files). Without the BOM strip, splitFrontmatter would see 0xEF 0xBB 0xBF
// before "---" and reject the file as "missing opening frontmatter fence",
// which is a nonsense error that points nowhere near the actual cause.
func TestParseCharter_StripsUTF8BOM(t *testing.T) {
	bom := []byte{0xEF, 0xBB, 0xBF}
	rest := `---
harness_version: 1
stages: [plan, code, review]
max_rework_count: 2
contract:
  plan:
    in: [goal]
    out: [plan_json]
  code:
    in: [subtask_prompt]
    out: [diff]
  review:
    in: [diff]
    out: [decision]
transitions:
  - from: plan
    to: code
    when: plan_json.subtasks.length > 0
  - from: code
    to: review
    when: all_subtasks_terminal
  - from: review
    to: human_review
    when: decision == "APPROVE"
failure_taxonomy:
  plan_parse_error:
    retry: 1
    fallback: human_review
---
body`

	content := append(bom, []byte(rest)...)
	c, err := ParseCharter(content)
	if err != nil {
		t.Fatalf("ParseCharter with BOM: %v", err)
	}
	if c.HarnessVersion != 1 {
		t.Errorf("HarnessVersion: got %d, want 1", c.HarnessVersion)
	}
}

// TestValidate_WarnsOnMissingPrompt ensures charters saved without a
// prompt for a required stage produce a warning (not an error).
// Warning — not error — so pre-prompts-era charters already saved in
// harness_skill_version still parse; the runtime falls back to the
// Default*Prompt constants and the UI surfaces the warning.
func TestValidate_WarnsOnMissingPrompt(t *testing.T) {
	content := []byte(`---
harness_version: 1
stages: [plan, code, review]
max_rework_count: 2
contract:
  plan:
    in: [goal]
    out: [plan_json]
  code:
    in: [subtask_prompt]
    out: [diff]
  review:
    in: [diff]
    out: [decision]
transitions:
  - from: plan
    to: code
    when: plan_json.subtasks.length > 0
  - from: code
    to: review
    when: all_subtasks_terminal
  - from: review
    to: human_review
    when: decision == "APPROVE"
failure_taxonomy:
  plan_parse_error:
    retry: 1
    fallback: human_review
# No prompts: section at all.
---
body`)

	c, err := ParseCharter(content)
	if err != nil {
		t.Fatalf("ParseCharter: %v", err)
	}
	ve := c.Validate()
	if ve == nil {
		t.Fatal("expected ValidationError with warnings for missing prompts, got nil")
	}
	found := 0
	for _, w := range ve.Warnings {
		for _, stage := range []string{"plan", "code", "review"} {
			if strings.Contains(w, `prompts["`+stage+`"]`) && strings.Contains(w, "Default") {
				found++
			}
		}
	}
	if found != 3 {
		t.Errorf("expected 3 warnings (one per required stage), got %d — Warnings: %v", found, ve.Warnings)
	}
}

// minimalCharter builds a Charter directly from a minimal YAML snippet for
// unit-testing the interpreter without filesystem access.
func minimalCharter(t *testing.T, maxRework int) *Charter {
	t.Helper()
	yaml := []byte(`---
harness_version: 1
stages: [plan, code, review]
max_rework_count: ` + itoa(maxRework) + `
contract:
  plan:
    in: [goal]
    out: [plan_json]
  code:
    in: [subtask_prompt]
    out: [diff]
  review:
    in: [diff]
    out: [decision]
transitions:
  - from: plan
    to: code
    when: plan_json.subtasks.length > 0
  - from: code
    to: review
    when: all_subtasks_terminal
  - from: review
    to: code
    when: decision == "REWORK" && rework_count < max_rework_count
  - from: review
    to: human_review
    when: decision == "APPROVE" || rework_count >= max_rework_count
failure_taxonomy:
  plan_parse_error:
    retry: 1
    fallback: human_review
  subtask_timeout:
    retry: 0
    fallback: failed
---

# Minimal test charter
`)
	c, err := ParseCharter(yaml)
	if err != nil {
		t.Fatalf("minimalCharter: ParseCharter: %v", err)
	}
	return c
}

func itoa(n int) string {
	if n == 0 {
		return "0"
	}
	s := ""
	neg := n < 0
	if neg {
		n = -n
	}
	for n > 0 {
		s = string(rune('0'+n%10)) + s
		n /= 10
	}
	if neg {
		return "-" + s
	}
	return s
}

// TestNextStage_Plan2Code verifies plan → code when subtask count > 0.
func TestNextStage_Plan2Code(t *testing.T) {
	c := minimalCharter(t, 2)
	s := StageState{
		CurrentStage:     "plan",
		PlanSubtaskCount: 3,
	}
	next, terminal, err := c.NextStage(s)
	if err != nil {
		t.Fatalf("NextStage: %v", err)
	}
	if next != "code" {
		t.Errorf("next: got %q, want %q", next, "code")
	}
	if terminal {
		t.Error("terminal: got true, want false")
	}
}

// TestNextStage_Review2Code_Rework verifies review → code on REWORK with
// rework_count below the maximum.
func TestNextStage_Review2Code_Rework(t *testing.T) {
	c := minimalCharter(t, 2)
	s := StageState{
		CurrentStage: "review",
		Decision:     "REWORK",
		ReworkCount:  1, // 1 < 2
	}
	next, terminal, err := c.NextStage(s)
	if err != nil {
		t.Fatalf("NextStage: %v", err)
	}
	if next != "code" {
		t.Errorf("next: got %q, want %q", next, "code")
	}
	if terminal {
		t.Error("terminal: got true, want false")
	}
}

// TestNextStage_Review2Human_MaxRework verifies that review → human_review
// when rework_count has reached the maximum, even on REWORK decision.
func TestNextStage_Review2Human_MaxRework(t *testing.T) {
	c := minimalCharter(t, 2)
	s := StageState{
		CurrentStage: "review",
		Decision:     "REWORK",
		ReworkCount:  2, // 2 >= 2
	}
	next, terminal, err := c.NextStage(s)
	if err != nil {
		t.Fatalf("NextStage: %v", err)
	}
	if next != "human_review" {
		t.Errorf("next: got %q, want %q", next, "human_review")
	}
	if !terminal {
		t.Error("terminal: got false, want true")
	}
}

// TestNextStage_Review2Human_Approve verifies that review → human_review on
// APPROVE regardless of rework count.
func TestNextStage_Review2Human_Approve(t *testing.T) {
	c := minimalCharter(t, 2)
	s := StageState{
		CurrentStage: "review",
		Decision:     "APPROVE",
		ReworkCount:  0,
	}
	next, terminal, err := c.NextStage(s)
	if err != nil {
		t.Fatalf("NextStage: %v", err)
	}
	if next != "human_review" {
		t.Errorf("next: got %q, want %q", next, "human_review")
	}
	if !terminal {
		t.Error("terminal: got false, want true")
	}
}

// TestValidate_MissingStage verifies that Validate returns an error when a
// required stage ('code') is absent from the stages list.
func TestValidate_MissingStage(t *testing.T) {
	raw := []byte(`---
harness_version: 1
stages: [plan, review]
max_rework_count: 2
contract:
  plan:
    in: [goal]
    out: [plan_json]
  review:
    in: [diff]
    out: [decision]
transitions:
  - from: plan
    to: review
    when: plan_json.subtasks.length > 0
  - from: review
    to: human_review
    when: decision == "APPROVE"
failure_taxonomy:
  plan_parse_error:
    retry: 1
    fallback: human_review
---
`)
	_, err := ParseCharter(raw)
	if err == nil {
		t.Fatal("ParseCharter: expected error for missing stage 'code', got nil")
	}
	if !contains(err.Error(), "code") {
		t.Errorf("error should mention missing stage 'code': %v", err)
	}
}

func contains(s, sub string) bool {
	return len(s) >= len(sub) && (s == sub || len(sub) == 0 ||
		func() bool {
			for i := 0; i <= len(s)-len(sub); i++ {
				if s[i:i+len(sub)] == sub {
					return true
				}
			}
			return false
		}())
}
