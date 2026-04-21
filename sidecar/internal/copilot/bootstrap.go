//go:build windows

package copilot

import (
	"context"
	"fmt"
	"io"
	"io/fs"
	"log/slog"
	"os"
	"path/filepath"

	"github.com/FleetKanban/fleetkanban/internal/harnessembed"
)

// BootstrapHarnessSkill seeds <skillRoot>/ from the embedded defaults
// when the directory is absent. Returns the absolute path to the seeded
// (or pre-existing) SKILL.md so callers can read it for parsing.
//
// Behaviour:
//   - If skillRoot does not exist, all files from the embedded seed are
//     written to disk and seeded=true is returned.
//   - If skillRoot already exists (user may have edited the files), nothing
//     is written; seeded=false is returned and the existing SKILL.md path
//     is returned unchanged.
//   - Individual files that exist inside an otherwise-present skillRoot are
//     never overwritten (tampered files are preserved).
//
// skillRoot is typically <repoRoot>/harness-skill. The caller is responsible
// for resolving it to an absolute path before calling this function.
func BootstrapHarnessSkill(ctx context.Context, skillRoot string, log *slog.Logger) (skillMdPath string, seeded bool, err error) {
	skillMdPath = filepath.Join(skillRoot, "SKILL.md")

	if _, statErr := os.Stat(skillRoot); statErr == nil {
		// Directory already exists — honour any user edits, touch nothing.
		log.InfoContext(ctx, "harness-skill already present, skipping seed", "path", skillRoot)
		return skillMdPath, false, nil
	} else if !os.IsNotExist(statErr) {
		return "", false, fmt.Errorf("bootstrap: stat skillRoot %q: %w", skillRoot, statErr)
	}

	log.InfoContext(ctx, "harness-skill absent, seeding from embedded defaults", "path", skillRoot)

	seedFS, err := fs.Sub(harnessembed.FS, "seed")
	if err != nil {
		return "", false, fmt.Errorf("bootstrap: open embedded seed FS: %w", err)
	}

	if err := writeEmbeddedFS(ctx, seedFS, skillRoot, log); err != nil {
		return "", false, fmt.Errorf("bootstrap: write seed to %q: %w", skillRoot, err)
	}

	log.InfoContext(ctx, "harness-skill seeded successfully", "path", skillRoot)
	return skillMdPath, true, nil
}

// writeEmbeddedFS walks srcFS and writes every file into destRoot,
// creating intermediate directories as needed.
// Files that already exist at the destination are skipped (not overwritten).
func writeEmbeddedFS(ctx context.Context, srcFS fs.FS, destRoot string, log *slog.Logger) error {
	return fs.WalkDir(srcFS, ".", func(path string, d fs.DirEntry, walkErr error) error {
		if walkErr != nil {
			return walkErr
		}
		if err := ctx.Err(); err != nil {
			return err
		}

		destPath := filepath.Join(destRoot, filepath.FromSlash(path))

		if d.IsDir() {
			return os.MkdirAll(destPath, 0o755)
		}

		// Skip if destination file already exists (preserve user edits).
		if _, statErr := os.Stat(destPath); statErr == nil {
			log.DebugContext(ctx, "seed: file already exists, skipping", "file", destPath)
			return nil
		}

		if err := writeSeedFile(srcFS, path, destPath); err != nil {
			return fmt.Errorf("seed file %q: %w", path, err)
		}
		log.DebugContext(ctx, "seed: wrote file", "file", destPath)
		return nil
	})
}

// ReadActiveSkillMD returns the SKILL.md bytes the planner / runner /
// reviewer are currently running against. Priority order:
//
//  1. skillRoot/SKILL.md on disk (the user's live copy, possibly edited)
//  2. the embedded seed copy (first-boot fallback, when BootstrapHarnessSkill
//     has not run yet or the disk copy was deleted out from under us)
//
// Used by app.Service.GetSubtaskContext to surface the charter body in the
// Subtask Summary dialog when a given run had no harness_skill_version
// row (brand-new install, or user never hit "Save" in the harness editor).
// Empty string + nil error means neither source exists — caller treats
// that as "no harness content recorded".
func ReadActiveSkillMD(skillRoot string) (string, error) {
	if skillRoot != "" {
		diskPath := filepath.Join(skillRoot, "SKILL.md")
		if data, err := os.ReadFile(diskPath); err == nil {
			return string(data), nil
		} else if !os.IsNotExist(err) {
			return "", fmt.Errorf("read active SKILL.md: %w", err)
		}
	}
	data, err := fs.ReadFile(harnessembed.FS, "seed/SKILL.md")
	if err != nil {
		if os.IsNotExist(err) {
			return "", nil
		}
		return "", fmt.Errorf("read embedded SKILL.md: %w", err)
	}
	return string(data), nil
}

// writeSeedFile copies a single file from srcFS at srcPath to destPath.
func writeSeedFile(srcFS fs.FS, srcPath, destPath string) error {
	src, err := srcFS.Open(srcPath)
	if err != nil {
		return fmt.Errorf("open embedded %q: %w", srcPath, err)
	}
	defer src.Close()

	dst, err := os.OpenFile(destPath, os.O_CREATE|os.O_EXCL|os.O_WRONLY, 0o644)
	if err != nil {
		if os.IsExist(err) {
			// Race: another goroutine or process created it first — that's fine.
			return nil
		}
		return fmt.Errorf("create %q: %w", destPath, err)
	}
	defer dst.Close()

	if _, err := io.Copy(dst, src); err != nil {
		return fmt.Errorf("copy to %q: %w", destPath, err)
	}
	return nil
}
