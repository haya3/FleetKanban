//go:build windows

package task

import (
	"encoding/json"
	"os"
	"path/filepath"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestDnDEdgesMatchSidecarGraph is the drift-detector between the UI's
// drag-and-drop edges (declared in repo/shared/kanban_dnd_edges.json)
// and the authoritative state machine in transition.go.
//
// Without this, ui/lib/features/kanban/providers.dart:canTransition and
// sidecar/internal/task/transition.go:allowedTransitions live in two
// separate files with no coupling — a Kanban card that the UI happily
// lets the user drag could be silently rejected by the sidecar with
// "illegal transition" at commit time. The shared JSON is the contract
// both sides agree to; breaking it fails this test.
//
// When you need to loosen DnD semantics (or tighten the state machine),
// edit shared/kanban_dnd_edges.json + transition.go together.
func TestDnDEdgesMatchSidecarGraph(t *testing.T) {
	path := findSharedFile(t, "kanban_dnd_edges.json")
	raw, err := os.ReadFile(path)
	require.NoError(t, err, "shared DnD edges JSON must exist at %s", path)

	var contract struct {
		Edges []struct {
			FromStatus    string `json:"from_status"`
			TargetColumn  string `json:"target_column"`
			SidecarTo     string `json:"sidecar_to"`
			Action        string `json:"action"`
		} `json:"edges"`
		DraggableStatuses []string `json:"draggable_statuses"`
	}
	require.NoError(t, json.Unmarshal(raw, &contract),
		"shared DnD edges JSON must be well-formed")
	require.NotEmpty(t, contract.Edges, "at least one DnD edge must be declared")

	validStatus := map[Status]struct{}{
		StatusPlanning:    {},
		StatusQueued:      {},
		StatusInProgress:  {},
		StatusAIReview:    {},
		StatusHumanReview: {},
		StatusDone:        {},
		StatusCancelled:   {},
		StatusAborted:     {},
		StatusFailed:      {},
	}

	for _, e := range contract.Edges {
		from := Status(e.FromStatus)
		to := Status(e.SidecarTo)

		if _, ok := validStatus[from]; !ok {
			t.Errorf("DnD edge references unknown from_status %q", e.FromStatus)
			continue
		}
		if _, ok := validStatus[to]; !ok {
			t.Errorf("DnD edge references unknown sidecar_to %q", e.SidecarTo)
			continue
		}
		assert.Truef(t, CanTransition(from, to),
			"shared DnD edge %s -> %s (column %s, action %s) is NOT legal in sidecar transition graph; either allow the edge in transition.go:allowedTransitions or remove it from shared/kanban_dnd_edges.json",
			e.FromStatus, e.SidecarTo, e.TargetColumn, e.Action)
	}

	for _, s := range contract.DraggableStatuses {
		if _, ok := validStatus[Status(s)]; !ok {
			t.Errorf("draggable_statuses references unknown status %q", s)
		}
	}
}

// findSharedFile walks up from the test working directory until it finds
// the repo root (identified by the Taskfile.yml sibling of shared/) and
// returns the absolute path of the named file inside shared/.
func findSharedFile(t *testing.T, name string) string {
	t.Helper()
	wd, err := os.Getwd()
	require.NoError(t, err)
	dir := wd
	for range 8 {
		candidate := filepath.Join(dir, "shared", name)
		if _, err := os.Stat(candidate); err == nil {
			return candidate
		}
		parent := filepath.Dir(dir)
		if parent == dir {
			break
		}
		dir = parent
	}
	t.Fatalf("cannot locate shared/%s relative to %s", name, wd)
	return ""
}
