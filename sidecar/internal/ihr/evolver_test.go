//go:build windows

package ihr

import (
	"context"
	"errors"
	"strings"
	"testing"
)

// fakeProposer returns a canned patch to test Evolver.Propose without
// needing a Copilot runtime.
type fakeProposer struct {
	patch   string
	err     error
	calls   int
	lastObs []Observation
}

func (f *fakeProposer) ProposePatch(_ context.Context, _ Charter, obs []Observation) (string, error) {
	f.calls++
	f.lastObs = obs
	return f.patch, f.err
}

func TestApplyPatch_HappyPath(t *testing.T) {
	// Change max_rework_count: 2 → 3.
	original := []byte("---\nharness_version: 1\nmax_rework_count: 2\nstages: [plan]\n---\nbody\n")
	diff := "" +
		"--- a/SKILL.md\n" +
		"+++ b/SKILL.md\n" +
		"@@ -2,3 +2,3 @@\n" +
		" harness_version: 1\n" +
		"-max_rework_count: 2\n" +
		"+max_rework_count: 3\n" +
		" stages: [plan]\n"

	got, err := ApplyPatch(original, diff)
	if err != nil {
		t.Fatalf("ApplyPatch: %v", err)
	}
	if !strings.Contains(string(got), "max_rework_count: 3") {
		t.Fatalf("patched content missing new value: %q", got)
	}
	if strings.Contains(string(got), "max_rework_count: 2") {
		t.Fatalf("patched content retained old value: %q", got)
	}
}

func TestApplyPatch_StaleContext(t *testing.T) {
	// Context line claims "harness_version: 1" but the real file says "2".
	original := []byte("---\nharness_version: 2\nmax_rework_count: 2\n---\n")
	diff := "" +
		"@@ -1,3 +1,3 @@\n" +
		" ---\n" +
		"-harness_version: 1\n" +
		"+harness_version: 3\n"

	if _, err := ApplyPatch(original, diff); err == nil {
		t.Fatalf("expected stale-context error, got nil")
	}
}

func TestApplyPatch_HugeChange_Rejected(t *testing.T) {
	var b strings.Builder
	b.WriteString("@@ -1,0 +1,")
	// 60 added lines — exceeds MaxPatchLineChanges (50).
	b.WriteString("60 @@\n")
	for i := 0; i < 60; i++ {
		b.WriteString("+line\n")
	}
	if _, err := ApplyPatch([]byte(""), b.String()); err == nil {
		t.Fatalf("expected cap-exceeded error, got nil")
	} else if !strings.Contains(err.Error(), "exceeds cap") {
		t.Fatalf("expected cap-exceeded error, got %v", err)
	}
}

func TestApplyPatch_NoHunk(t *testing.T) {
	if _, err := ApplyPatch([]byte("hello"), "no hunk here"); err == nil {
		t.Fatalf("expected error on diff with no @@ header")
	}
}

func TestApplyPatch_MalformedHeader(t *testing.T) {
	if _, err := ApplyPatch([]byte("x\n"), "@@ broken @@\n x\n"); err == nil {
		t.Fatalf("expected error on malformed header")
	}
}

func TestApplyPatch_HeaderCountMismatch(t *testing.T) {
	// Header claims 3 old lines but only 1 is present.
	diff := "@@ -1,3 +1,3 @@\n a\n"
	if _, err := ApplyPatch([]byte("a\n"), diff); err == nil {
		t.Fatalf("expected error on header/body mismatch")
	}
}

func TestEvolver_Propose_PassesObservations(t *testing.T) {
	fp := &fakeProposer{patch: "@@ -1,1 +1,1 @@\n-a\n+b\n"}
	e := NewEvolver(fp, nil)
	obs := []Observation{{TaskID: "t1", ReworkRound: 1, FailureClass: "review_rework", FeedbackMD: "please fix X"}}
	got, err := e.Propose(context.Background(), Charter{}, obs)
	if err != nil {
		t.Fatalf("Propose: %v", err)
	}
	if got != fp.patch {
		t.Fatalf("Propose returned %q, want %q", got, fp.patch)
	}
	if fp.calls != 1 {
		t.Fatalf("proposer called %d times, want 1", fp.calls)
	}
	if len(fp.lastObs) != 1 || fp.lastObs[0].TaskID != "t1" {
		t.Fatalf("proposer received wrong observations: %+v", fp.lastObs)
	}
}

func TestEvolver_Propose_EmptyObservations(t *testing.T) {
	fp := &fakeProposer{patch: "unused"}
	e := NewEvolver(fp, nil)
	got, err := e.Propose(context.Background(), Charter{}, nil)
	if err != nil {
		t.Fatalf("Propose with empty obs: %v", err)
	}
	if got != "" {
		t.Fatalf("Propose with empty obs returned %q, want empty", got)
	}
	if fp.calls != 0 {
		t.Fatalf("proposer should not be called with empty observations")
	}
}

func TestEvolver_Propose_PropagatesError(t *testing.T) {
	sentinel := errors.New("boom")
	fp := &fakeProposer{err: sentinel}
	e := NewEvolver(fp, nil)
	obs := []Observation{{TaskID: "t1"}}
	if _, err := e.Propose(context.Background(), Charter{}, obs); err == nil {
		t.Fatalf("expected error from proposer")
	} else if !errors.Is(err, sentinel) {
		t.Fatalf("expected wrapped sentinel, got %v", err)
	}
}

func TestEvolver_Propose_NilProposer(t *testing.T) {
	e := &Evolver{}
	if _, err := e.Propose(context.Background(), Charter{}, []Observation{{TaskID: "t"}}); err == nil {
		t.Fatalf("expected error with nil proposer")
	}
}

func TestApplyPatch_FencedDiff(t *testing.T) {
	original := []byte("a\nb\nc\n")
	diff := "```diff\n@@ -1,3 +1,3 @@\n a\n-b\n+B\n c\n```\n"
	got, err := ApplyPatch(original, diff)
	if err != nil {
		t.Fatalf("ApplyPatch fenced: %v", err)
	}
	if !strings.Contains(string(got), "\nB\n") {
		t.Fatalf("fenced diff not applied: %q", got)
	}
}
