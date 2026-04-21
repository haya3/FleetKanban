//go:build windows

package copilot

import "testing"

// TestResolveStagePrompt_Fallbacks nails down the three fallback cases
// main.go and the planner / runner / reviewer rely on:
//
//  1. nil lookup (bootstrap / tests without a wired charter) → fallback
//  2. lookup returns "" (charter is loaded but has no prompt for the
//     stage, or the holder is pre-charter-parse nil) → fallback
//  3. lookup returns non-empty → that string, addendum-free
func TestResolveStagePrompt_Fallbacks(t *testing.T) {
	cases := []struct {
		name     string
		lookup   StagePromptLookup
		stage    string
		fallback string
		want     string
	}{
		{
			name:     "nil lookup falls back",
			lookup:   nil,
			stage:    "plan",
			fallback: "FALLBACK",
			want:     "FALLBACK",
		},
		{
			name:     "empty return falls back",
			lookup:   func(string) string { return "" },
			stage:    "plan",
			fallback: "FALLBACK",
			want:     "FALLBACK",
		},
		{
			name:     "non-empty return wins",
			lookup:   func(s string) string { return "CHARTER-" + s },
			stage:    "code",
			fallback: "FALLBACK",
			want:     "CHARTER-code",
		},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			if got := ResolveStagePrompt(tc.lookup, tc.stage, tc.fallback); got != tc.want {
				t.Errorf("ResolveStagePrompt: got %q, want %q", got, tc.want)
			}
		})
	}
}
