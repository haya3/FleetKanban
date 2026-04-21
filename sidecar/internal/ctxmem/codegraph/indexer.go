package codegraph

import (
	"context"
	"fmt"
	"log/slog"
	"path"
	"strings"
	"time"

	"github.com/oklog/ulid/v2"

	"github.com/haya3/fleetkanban/internal/ctxmem"
	"github.com/haya3/fleetkanban/internal/ctxmem/store"
)

// Indexer persists the scan result into ctx_node + ctx_edge. It is
// the bridge between the pure-parse Scan/ExtractImports helpers and
// the ctxmem stores.
type Indexer struct {
	nodes *store.NodeStore
	edges *store.EdgeStore
	log   *slog.Logger
}

// New returns an Indexer ready to run against the given stores.
func New(nodes *store.NodeStore, edges *store.EdgeStore, log *slog.Logger) *Indexer {
	if log == nil {
		log = slog.Default()
	}
	return &Indexer{nodes: nodes, edges: edges, log: log}
}

// Rebuild scans repoPath and upserts File nodes + imports edges for
// the given repoID. Existing nodes with matching (repo, kind,
// label) are reused so user-facing metadata (pinned, confidence) is
// preserved. Edges are upserted via the unique constraint on (repo,
// src, dst, rel).
//
// Returns (nodesCreated, nodesUpdated, edgesCreated, error). The
// caller publishes change events — the indexer stays data-only.
func (i *Indexer) Rebuild(ctx context.Context, repoID, repoPath string) (IndexResult, error) {
	files, err := Scan(repoPath)
	if err != nil {
		return IndexResult{}, err
	}
	res := IndexResult{FilesScanned: len(files)}

	// Build File nodes keyed by repo-relative path.
	pathToNode := make(map[string]ctxmem.Node, len(files))
	for _, f := range files {
		label := f.RelPath
		// Dedup against existing enabled node with same label so
		// pinned / confidence user tweaks survive.
		existing, err := i.nodes.FindByLabel(ctx, repoID, ctxmem.NodeKindFile, label)
		if err == nil {
			// Refresh content / attrs but keep ID + pinned state.
			existing.ContentMD = fileContent(f)
			existing.Attrs = fileAttrs(f)
			if err := i.nodes.Update(ctx, existing); err != nil {
				i.log.Warn("codegraph: refresh file node", "err", err, "path", label)
				continue
			}
			pathToNode[label] = existing
			res.NodesUpdated++
			continue
		}
		n := ctxmem.Node{
			ID:         ulid.Make().String(),
			RepoID:     repoID,
			Kind:       ctxmem.NodeKindFile,
			Label:      label,
			ContentMD:  fileContent(f),
			Attrs:      fileAttrs(f),
			SourceKind: ctxmem.SourceStaticAnalysis,
			Confidence: 1.0,
			Enabled:    true,
		}
		if err := i.nodes.Create(ctx, n); err != nil {
			i.log.Warn("codegraph: create file node", "err", err, "path", label)
			continue
		}
		pathToNode[label] = n
		res.NodesCreated++
	}

	// Second pass: parse imports, resolve to repo-relative paths,
	// upsert edges. Resolution is purely path-based — we don't
	// attempt to follow module manifests (go.mod, tsconfig paths
	// etc.) because the false-positive cost is low and the
	// implementation cost of proper resolution is high.
	for _, f := range files {
		src, ok := pathToNode[f.RelPath]
		if !ok {
			continue
		}
		refs, err := ExtractImports(f)
		if err != nil {
			continue
		}
		for _, ref := range refs {
			target := resolveImport(f, ref, pathToNode)
			if target == "" {
				continue
			}
			dst, ok := pathToNode[target]
			if !ok {
				continue
			}
			edge := ctxmem.Edge{
				ID:        ulid.Make().String(),
				RepoID:    repoID,
				SrcNodeID: src.ID,
				DstNodeID: dst.ID,
				Rel:       ctxmem.EdgeRelImports,
				Attrs:     map[string]string{"from_language": f.Language, "raw_ref": ref},
				CreatedAt: time.Now().UTC(),
			}
			if err := i.edges.UpsertByTuple(ctx, edge); err != nil {
				i.log.Warn("codegraph: upsert edge", "err", err)
				continue
			}
			res.EdgesCreated++
		}
	}

	return res, nil
}

// IndexResult is the summary Rebuild returns.
type IndexResult struct {
	FilesScanned int
	NodesCreated int
	NodesUpdated int
	EdgesCreated int
}

func fileContent(f FileEntry) string {
	return fmt.Sprintf("Source file: `%s`\n\n- Language: %s\n- Size: %d KB",
		f.RelPath, f.Language, f.SizeKB)
}

func fileAttrs(f FileEntry) map[string]string {
	return map[string]string{
		"path":     f.RelPath,
		"language": f.Language,
		"size_kb":  fmt.Sprintf("%d", f.SizeKB),
	}
}

// resolveImport turns a raw import reference into a repo-relative
// path present in pathToNode, or "" when the reference cannot be
// matched. Handles:
//
//   - Relative paths ("./foo", "../bar/baz") for JS/TS/Dart/Python
//   - Suffix match against repo-relative paths (for absolute/package
//     imports whose trailing components overlap a real file — e.g.
//     a Go import "github.com/haya3/fleetkanban/internal/x"
//     matching "internal/x/x.go" inside the repo)
func resolveImport(src FileEntry, ref string, idx map[string]ctxmem.Node) string {
	// 1. Relative imports: resolve against src's directory.
	if strings.HasPrefix(ref, "./") || strings.HasPrefix(ref, "../") {
		dir := path.Dir(src.RelPath)
		candidate := path.Clean(path.Join(dir, ref))
		// Try with common extensions appended (many langs omit them).
		if _, ok := idx[candidate]; ok {
			return candidate
		}
		for ext := range sourceExtensions {
			if _, ok := idx[candidate+ext]; ok {
				return candidate + ext
			}
			indexFile := path.Join(candidate, "index"+ext)
			if _, ok := idx[indexFile]; ok {
				return indexFile
			}
		}
		return ""
	}

	// 2. Dart package imports: "package:myapp/foo/bar.dart" →
	//    "lib/foo/bar.dart" under the conventional flutter layout.
	if strings.HasPrefix(ref, "package:") {
		trimmed := strings.TrimPrefix(ref, "package:")
		if i := strings.Index(trimmed, "/"); i >= 0 {
			sub := trimmed[i+1:]
			candidate := "lib/" + sub
			if _, ok := idx[candidate]; ok {
				return candidate
			}
		}
		return ""
	}

	// 3. Suffix match: the most lenient fallback. Convert dots to
	//    slashes (Python / Java / Kotlin) and check whether any
	//    known file path ends with "<ref>.<ext>" or "<ref>/..." .
	//    Works for Go too — an import path's tail usually matches
	//    the internal package directory.
	slashRef := strings.ReplaceAll(ref, ".", "/")
	slashRef = strings.TrimSuffix(slashRef, "/")
	if slashRef == "" {
		return ""
	}
	for p := range idx {
		if strings.HasSuffix(p, "/"+slashRef) {
			return p
		}
		// Also match without extension — e.g. ref "internal/x/foo"
		// against file "internal/x/foo.go"
		pnoext := strings.TrimSuffix(p, path.Ext(p))
		if strings.HasSuffix(pnoext, "/"+slashRef) {
			return p
		}
	}
	return ""
}
