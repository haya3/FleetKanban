// Package promotion implements the trust gate that moves scratchpad
// entries into the permanent ctx_node store. Manual promotion is the
// default; auto-promotion fires when MemorySettings.AutoPromoteHighConfidence
// is true and the entry's confidence >= AutoPromoteThreshold.
package promotion

import (
	"context"
	"errors"
	"fmt"

	"github.com/oklog/ulid/v2"

	"github.com/haya3/FleetKanban/internal/ctxmem"
	"github.com/haya3/FleetKanban/internal/ctxmem/store"
)

// Gate promotes scratchpad entries into ctx_node under the configured
// trust policy.
type Gate struct {
	scratchpad *store.ScratchpadStore
	nodes      *store.NodeStore
	settings   *store.SettingsStore
}

// New returns a Gate operating against the given stores.
func New(scratchpad *store.ScratchpadStore, nodes *store.NodeStore, settings *store.SettingsStore) *Gate {
	return &Gate{scratchpad: scratchpad, nodes: nodes, settings: settings}
}

// Promote transitions one scratchpad entry into a ctx_node. The new
// node carries source_kind = the scratchpad entry's source_kind so
// downstream consumers can still trace back the provenance after
// promotion.
//
// Dedup: if an enabled node with the same (kind, label) already
// exists in the repo, Promote re-uses it instead of creating a
// duplicate. The scratchpad entry is marked promoted with
// promoted_node_id pointing at the existing node so the UI still
// clears the pending card. Useful when the user repeats Analyze
// and re-promotes the "same" concept.
func (g *Gate) Promote(ctx context.Context, entryID string) (ctxmem.Node, error) {
	entry, err := g.scratchpad.Get(ctx, entryID)
	if err != nil {
		return ctxmem.Node{}, err
	}
	if entry.Status == ctxmem.ScratchpadPromoted {
		// Already done — look up the resulting node.
		if entry.PromotedNodeID == "" {
			return ctxmem.Node{}, fmt.Errorf("ctxmem/promotion: entry %s marked promoted but has no node", entryID)
		}
		return g.nodes.Get(ctx, entry.PromotedNodeID)
	}
	// Dedup against existing nodes.
	if existing, err := g.nodes.FindByLabel(ctx, entry.RepoID, entry.ProposedKind, entry.ProposedLabel); err == nil {
		if mErr := g.scratchpad.MarkPromoted(ctx, entryID, existing.ID); mErr != nil {
			return ctxmem.Node{}, mErr
		}
		return existing, nil
	} else if !errors.Is(err, ctxmem.ErrNotFound) {
		return ctxmem.Node{}, err
	}
	n := ctxmem.Node{
		ID:         ulid.Make().String(),
		RepoID:     entry.RepoID,
		Kind:       entry.ProposedKind,
		Label:      entry.ProposedLabel,
		ContentMD:  entry.ProposedContentMD,
		Attrs:      entry.ProposedAttrs,
		SourceKind: entry.SourceKind,
		Confidence: entry.Confidence,
		Enabled:    true,
		Pinned:     false,
	}
	if n.Attrs == nil {
		n.Attrs = map[string]string{}
	}
	n.Attrs["scratchpad_id"] = entry.ID
	if err := g.nodes.Create(ctx, n); err != nil {
		return ctxmem.Node{}, err
	}
	if err := g.scratchpad.MarkPromoted(ctx, entryID, n.ID); err != nil {
		return ctxmem.Node{}, err
	}
	return n, nil
}

// Reject moves the entry to rejected with an optional reason.
func (g *Gate) Reject(ctx context.Context, entryID, reason string) error {
	return g.scratchpad.MarkRejected(ctx, entryID, reason)
}

// EditAndPromote updates the proposed fields then promotes.
func (g *Gate) EditAndPromote(ctx context.Context, entryID, kind, label, content string, attrs map[string]string) (ctxmem.Node, error) {
	if err := g.scratchpad.ApplyEdits(ctx, entryID, kind, label, content, attrs); err != nil {
		return ctxmem.Node{}, err
	}
	return g.Promote(ctx, entryID)
}

// AutoPromoteIfEligible promotes the entry when its repo settings
// permit. Called by the analyzer / observer pipelines right after
// inserting the scratchpad row so high-confidence entries can bypass
// the trust gate if the user opts in.
func (g *Gate) AutoPromoteIfEligible(ctx context.Context, entryID string) (ctxmem.Node, bool, error) {
	entry, err := g.scratchpad.Get(ctx, entryID)
	if err != nil {
		return ctxmem.Node{}, false, err
	}
	set, err := g.settings.Get(ctx, entry.RepoID)
	if err != nil {
		return ctxmem.Node{}, false, err
	}
	if !set.AutoPromoteHighConfidence || entry.Confidence < set.AutoPromoteThreshold {
		return ctxmem.Node{}, false, nil
	}
	n, err := g.Promote(ctx, entryID)
	if err != nil {
		return ctxmem.Node{}, false, err
	}
	return n, true, nil
}
