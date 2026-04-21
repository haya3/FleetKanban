//go:build windows

// Package harnessembed holds the embedded harness-skill filesystem.
// It is a separate package so that the go:embed directive can reference
// the harness-skill directory that lives two levels up from internal/copilot
// but is a sibling of the module root — go:embed forbids ".." in paths, so
// the embedded content is mirrored here at build time via the seed directory.
//
// At build time the files under seed/ are a copy of harness-skill/ produced
// by "go generate ./..." (see doc.go). At runtime, bootstrap.go reads FS
// to seed the on-disk harness-skill/ if absent.
package harnessembed

import "embed"

// FS exposes the embedded seed content rooted at "seed/".
// Paths inside FS use the "seed/" prefix, e.g. "seed/SKILL.md".
//
//go:embed seed
var FS embed.FS
