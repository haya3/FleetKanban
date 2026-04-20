package codegraph

import (
	"os"
	"regexp"
	"strings"
)

// ImportRef is one resolved import as the indexer converts it into an
// edge. TargetRel is the repo-relative path the import points to;
// empty when resolution failed (the edge is dropped silently).
type ImportRef struct {
	SourceRel string
	TargetRel string
	Via       string // "relative" | "package"
}

// ExtractImports returns the list of imports declared inside one
// file. Resolution against the repository tree is left to the caller
// (in indexer.go) — this function's job is to pull the raw
// references out of the source, not to match them to FileEntry
// objects. Files whose language has no parser are skipped silently.
func ExtractImports(entry FileEntry) ([]string, error) {
	content, err := os.ReadFile(entry.AbsPath)
	if err != nil {
		return nil, err
	}
	src := string(content)
	switch entry.Language {
	case "Go":
		return parseGoImports(src), nil
	case "TypeScript", "JavaScript":
		return parseJSImports(src), nil
	case "Python":
		return parsePythonImports(src), nil
	case "Dart":
		return parseDartImports(src), nil
	case "Rust":
		return parseRustImports(src), nil
	case "Java", "Kotlin":
		return parseJavaImports(src), nil
	}
	return nil, nil
}

// Go: `import "path"` or multi-line `import ( "a" ; "b" )`.
var goImportRe = regexp.MustCompile(`(?m)^\s*(?:import\s+(?:[a-zA-Z_][\w]*\s+)?)?"([^"]+)"`)

func parseGoImports(src string) []string {
	// Restrict to a lightweight scan of the first import block rather
	// than every quoted string in the file. Handling `import(...)` is
	// the common case; bare `import "x"` falls into the same regex.
	var out []string
	inBlock := false
	for _, line := range strings.Split(src, "\n") {
		trim := strings.TrimSpace(line)
		if !inBlock {
			if strings.HasPrefix(trim, "import (") {
				inBlock = true
				continue
			}
			if strings.HasPrefix(trim, "import ") {
				if m := quoteBody.FindStringSubmatch(trim); len(m) > 1 {
					out = append(out, m[1])
				}
				continue
			}
			if strings.HasPrefix(trim, "package ") {
				continue
			}
			if trim != "" && !strings.HasPrefix(trim, "//") {
				break // past header — bail out
			}
		} else {
			if trim == ")" {
				inBlock = false
				break
			}
			if m := quoteBody.FindStringSubmatch(trim); len(m) > 1 {
				out = append(out, m[1])
			}
		}
	}
	_ = goImportRe
	return out
}

var quoteBody = regexp.MustCompile(`"([^"]+)"`)

// JS/TS: `import x from 'y'`, `import 'y'`, `require('y')`, dynamic imports.
var jsImportRe = regexp.MustCompile(`(?m)(?:^|\s)(?:import\s+(?:[^'"\n]+?\s+from\s+)?|require\s*\(\s*|import\s*\(\s*)['"]([^'"]+)['"]`)

func parseJSImports(src string) []string {
	matches := jsImportRe.FindAllStringSubmatch(src, -1)
	out := make([]string, 0, len(matches))
	for _, m := range matches {
		if len(m) > 1 && m[1] != "" {
			out = append(out, m[1])
		}
	}
	return out
}

// Python: `import x`, `from x import y`, supports dotted modules.
var pyImportRe = regexp.MustCompile(`(?m)^\s*(?:from\s+([\w.]+)\s+import|import\s+([\w.]+))`)

func parsePythonImports(src string) []string {
	matches := pyImportRe.FindAllStringSubmatch(src, -1)
	out := make([]string, 0, len(matches))
	for _, m := range matches {
		if len(m) > 1 && m[1] != "" {
			out = append(out, m[1])
		} else if len(m) > 2 && m[2] != "" {
			out = append(out, m[2])
		}
	}
	return out
}

// Dart: `import 'package:foo/bar.dart'` or `import 'relative.dart'`.
var dartImportRe = regexp.MustCompile(`(?m)^\s*import\s+['"]([^'"]+)['"]`)

func parseDartImports(src string) []string {
	matches := dartImportRe.FindAllStringSubmatch(src, -1)
	out := make([]string, 0, len(matches))
	for _, m := range matches {
		if len(m) > 1 {
			out = append(out, m[1])
		}
	}
	return out
}

// Rust: `use a::b::c;` (simplified — we only care about the crate
// root). Grab the first path segment to match against repo crates.
var rustUseRe = regexp.MustCompile(`(?m)^\s*use\s+([\w:]+)`)

func parseRustImports(src string) []string {
	matches := rustUseRe.FindAllStringSubmatch(src, -1)
	out := make([]string, 0, len(matches))
	for _, m := range matches {
		if len(m) > 1 {
			out = append(out, m[1])
		}
	}
	return out
}

// Java / Kotlin: `import com.foo.Bar;`.
var javaImportRe = regexp.MustCompile(`(?m)^\s*import\s+(?:static\s+)?([\w.]+)\s*;?`)

func parseJavaImports(src string) []string {
	matches := javaImportRe.FindAllStringSubmatch(src, -1)
	out := make([]string, 0, len(matches))
	for _, m := range matches {
		if len(m) > 1 {
			out = append(out, m[1])
		}
	}
	return out
}
