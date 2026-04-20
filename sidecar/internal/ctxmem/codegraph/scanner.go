// Package codegraph walks a registered repository and produces File
// nodes + imports edges directly from the source tree, independent of
// the LLM analyzer. This gives the Context graph a dependable
// skeleton — language-recognised files with their static dependency
// wiring — before any observer or manual promotion fills in the
// higher-level Concepts / Decisions.
//
// Parsing is intentionally shallow: per-language regex extracts
// import module references. A real compiler would be ideal but adds
// significant build complexity for modest marginal value at our scale.
// When the regex matches something that is not actually an import
// (e.g. a string containing the word "import") the cost is a benign
// extra edge pointing at a nonexistent file, which the next rebuild
// drops.
package codegraph

import (
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"strings"
)

// sourceExtensions lists the file extensions the scanner recognises as
// source / doc files worth representing as ctx_node.File. The list is
// conservative — adding an extension here means every repo that
// contains such files picks up those nodes on the next rebuild.
var sourceExtensions = map[string]string{
	".go":    "Go",
	".ts":    "TypeScript",
	".tsx":   "TypeScript",
	".js":    "JavaScript",
	".jsx":   "JavaScript",
	".mjs":   "JavaScript",
	".cjs":   "JavaScript",
	".dart":  "Dart",
	".py":    "Python",
	".rs":    "Rust",
	".java":  "Java",
	".kt":    "Kotlin",
	".swift": "Swift",
	".cs":    "C#",
	".cpp":   "C++",
	".cc":    "C++",
	".cxx":   "C++",
	".c":     "C",
	".h":     "C",
	".hpp":   "C++",
	".rb":    "Ruby",
	".md":    "Markdown",
	".proto": "Protobuf",
	".sql":   "SQL",
	".yaml":  "YAML",
	".yml":   "YAML",
	".toml":  "TOML",
}

// skipDirs are directories we never descend into regardless of depth.
// Covers package managers, build outputs, VCS metadata, and common
// tool caches. A per-repo .gitignore would be ideal but adds
// complexity — the hardcoded list covers ~95% of real repos.
var skipDirs = map[string]struct{}{
	".git":         {},
	"node_modules": {},
	"vendor":       {},
	"dist":         {},
	"build":        {},
	"target":       {},
	"bin":          {},
	"obj":          {},
	".venv":        {},
	"venv":         {},
	"__pycache__":  {},
	".dart_tool":   {},
	".next":        {},
	".nuxt":        {},
	".gradle":      {},
	".idea":        {},
	".vscode":      {},
	".pub-cache":   {},
	".fleetkanban-worktrees": {},
}

// maxFiles caps the scanner output so an accidentally huge repo
// does not flood the node table. 5000 is enough for virtually any
// single codebase; the rebuild refreshes the graph each time so
// hitting the cap is not a one-way problem.
const maxFiles = 5000

// FileEntry describes one source / doc file discovered by the scanner.
type FileEntry struct {
	RelPath  string // forward-slash separated, relative to repo root
	AbsPath  string // OS-native absolute path
	Language string // "Go" / "TypeScript" / ... — from sourceExtensions
	SizeKB   int
}

// Scan walks repoPath recursively and returns source files under
// maxFiles. The caller is responsible for persistence; Scan is
// side-effect free.
func Scan(repoPath string) ([]FileEntry, error) {
	if repoPath == "" {
		return nil, fmt.Errorf("codegraph: repoPath is empty")
	}
	info, err := os.Stat(repoPath)
	if err != nil {
		return nil, fmt.Errorf("codegraph: stat repo: %w", err)
	}
	if !info.IsDir() {
		return nil, fmt.Errorf("codegraph: %s is not a directory", repoPath)
	}

	var out []FileEntry
	err = filepath.WalkDir(repoPath, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			// Tolerant: keep walking; transient permission denials
			// on a Windows file don't abort the whole scan.
			if d != nil && d.IsDir() {
				return fs.SkipDir
			}
			return nil
		}
		if d.IsDir() {
			if _, skip := skipDirs[d.Name()]; skip {
				return fs.SkipDir
			}
			// Also skip hidden dirs except explicitly known ones
			// like ".github" so CI config is still captured.
			if strings.HasPrefix(d.Name(), ".") && d.Name() != "." && d.Name() != ".github" {
				return fs.SkipDir
			}
			return nil
		}
		ext := strings.ToLower(filepath.Ext(d.Name()))
		lang, ok := sourceExtensions[ext]
		if !ok {
			return nil
		}
		rel, relErr := filepath.Rel(repoPath, path)
		if relErr != nil {
			return nil
		}
		rel = filepath.ToSlash(rel)
		info, _ := d.Info()
		size := 0
		if info != nil {
			size = int(info.Size() / 1024)
		}
		out = append(out, FileEntry{
			RelPath:  rel,
			AbsPath:  path,
			Language: lang,
			SizeKB:   size,
		})
		if len(out) >= maxFiles {
			return fs.SkipAll
		}
		return nil
	})
	if err != nil {
		return nil, fmt.Errorf("codegraph: walk: %w", err)
	}
	return out, nil
}

