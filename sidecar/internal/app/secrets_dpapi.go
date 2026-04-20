//go:build windows

package app

import (
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"github.com/FleetKanban/fleetkanban/internal/winapi"
)

// dpapiSecrets persists secrets under a directory, each one DPAPI-encrypted
// (CryptProtectData) scoped to the current user. The ciphertext is
// user-readable but opaque to any other account on the same machine.
//
// Layout (label-aware, supports multiple GitHub PATs):
//
//	<dir>/tokens/<label>.bin   — DPAPI-encrypted GitHub PAT per label
//	<dir>/active_token.txt     — UTF-8 label of the currently-active token
//
// Legacy single-token layout (kept readable for migration):
//
//	<dir>/github_pat.bin       — pre-multi-account PAT file. On first access
//	                             it is migrated into tokens/default.bin and
//	                             made the active label.
//
// Empty tokens are removed rather than stored as empty-ciphertext files. The
// "active" label may be empty when no tokens are stored.
type dpapiSecrets struct {
	dir string
}

// NewDPAPISecretStore returns a SecretStore that stores each secret as a
// DPAPI-encrypted file under dir. The directory is created on first write.
func NewDPAPISecretStore(dir string) (SecretStore, error) {
	if dir == "" {
		return nil, errors.New("app: DPAPI secret store requires a directory")
	}
	return &dpapiSecrets{dir: dir}, nil
}

const (
	legacyPATFile   = "github_pat.bin"
	tokensSubdir    = "tokens"
	activeLabelFile = "active_token.txt"
	tokenFileExt    = ".bin"
	// defaultMigrationLabel is the label assigned to the pre-existing single
	// PAT when migrating from the legacy layout.
	defaultMigrationLabel = "default"
)

func (s *dpapiSecrets) legacyPATPath() string { return filepath.Join(s.dir, legacyPATFile) }
func (s *dpapiSecrets) tokensDir() string     { return filepath.Join(s.dir, tokensSubdir) }
func (s *dpapiSecrets) activeLabelPath() string {
	return filepath.Join(s.dir, activeLabelFile)
}
func (s *dpapiSecrets) tokenPath(label string) string {
	return filepath.Join(s.tokensDir(), label+tokenFileExt)
}

// validLabel enforces a safe subset so labels cannot escape the tokens dir or
// collide with active_token.txt. ASCII letters, digits, '-', '_', '.' only.
func validLabel(label string) error {
	if label == "" {
		return errors.New("app: token label must be non-empty")
	}
	if len(label) > 64 {
		return errors.New("app: token label too long (max 64 chars)")
	}
	for _, r := range label {
		switch {
		case r >= 'a' && r <= 'z':
		case r >= 'A' && r <= 'Z':
		case r >= '0' && r <= '9':
		case r == '-' || r == '_' || r == '.':
		default:
			return fmt.Errorf("app: token label contains invalid character %q", r)
		}
	}
	if label == "." || label == ".." {
		return errors.New("app: token label must not be . or ..")
	}
	return nil
}

// migrateLegacyIfNeeded moves <dir>/github_pat.bin to tokens/default.bin and
// marks default active, when no tokens dir exists yet. A no-op afterwards.
// Safe to call on every read/write path.
func (s *dpapiSecrets) migrateLegacyIfNeeded() error {
	if _, err := os.Stat(s.tokensDir()); err == nil {
		return nil // already migrated (or multi-token store in use)
	} else if !errors.Is(err, os.ErrNotExist) {
		return fmt.Errorf("app: stat tokens dir: %w", err)
	}
	legacy, err := os.ReadFile(s.legacyPATPath())
	if err != nil {
		if errors.Is(err, os.ErrNotExist) {
			return nil
		}
		return fmt.Errorf("app: read legacy PAT: %w", err)
	}
	if err := os.MkdirAll(s.tokensDir(), 0o700); err != nil {
		return fmt.Errorf("app: mkdir tokens: %w", err)
	}
	dst := s.tokenPath(defaultMigrationLabel)
	if err := os.WriteFile(dst, legacy, 0o600); err != nil {
		return fmt.Errorf("app: migrate legacy PAT: %w", err)
	}
	if err := os.WriteFile(s.activeLabelPath(), []byte(defaultMigrationLabel), 0o600); err != nil {
		return fmt.Errorf("app: write active label: %w", err)
	}
	// Best-effort: remove the legacy file once the new copy is durable.
	_ = os.Remove(s.legacyPATPath())
	return nil
}

// --- Legacy single-token API (kept for back-compat) -----------------------

// GetGitHubToken returns the plaintext PAT of the currently-active label, or
// "" if no token is stored.
func (s *dpapiSecrets) GetGitHubToken() (string, error) {
	if err := s.migrateLegacyIfNeeded(); err != nil {
		return "", err
	}
	label, err := s.readActiveLabel()
	if err != nil {
		return "", err
	}
	if label == "" {
		return "", nil
	}
	return s.readTokenByLabel(label)
}

// SetGitHubToken replaces the active token. Passing an empty string removes
// the active token entirely (and clears the active label). If no label is
// active yet, this stores the token under "default" and makes it active.
func (s *dpapiSecrets) SetGitHubToken(token string) error {
	if err := s.migrateLegacyIfNeeded(); err != nil {
		return err
	}
	active, err := s.readActiveLabel()
	if err != nil {
		return err
	}
	if token == "" {
		if active == "" {
			return nil
		}
		if err := os.Remove(s.tokenPath(active)); err != nil && !errors.Is(err, os.ErrNotExist) {
			return fmt.Errorf("app: clear PAT: %w", err)
		}
		return s.writeActiveLabel("")
	}
	label := active
	if label == "" {
		label = defaultMigrationLabel
	}
	if err := s.writeToken(label, token); err != nil {
		return err
	}
	if active == "" {
		return s.writeActiveLabel(label)
	}
	return nil
}

// HasGitHubToken reports whether an active token is stored.
func (s *dpapiSecrets) HasGitHubToken() (bool, error) {
	if err := s.migrateLegacyIfNeeded(); err != nil {
		return false, err
	}
	label, err := s.readActiveLabel()
	if err != nil {
		return false, err
	}
	if label == "" {
		return false, nil
	}
	_, err = os.Stat(s.tokenPath(label))
	if err == nil {
		return true, nil
	}
	if errors.Is(err, os.ErrNotExist) {
		return false, nil
	}
	return false, err
}

// --- Multi-token label-aware API ------------------------------------------

// (TokenEntry is defined in service.go — shared by the SecretStore interface
// and the DPAPI implementation.)

// ListTokens returns every stored label in ascending order plus the
// currently active label ("" if none).
func (s *dpapiSecrets) ListTokens() ([]TokenEntry, string, error) {
	if err := s.migrateLegacyIfNeeded(); err != nil {
		return nil, "", err
	}
	active, err := s.readActiveLabel()
	if err != nil {
		return nil, "", err
	}
	entries, err := os.ReadDir(s.tokensDir())
	if err != nil {
		if errors.Is(err, os.ErrNotExist) {
			return nil, active, nil
		}
		return nil, "", fmt.Errorf("app: read tokens dir: %w", err)
	}
	out := make([]TokenEntry, 0, len(entries))
	for _, e := range entries {
		if e.IsDir() {
			continue
		}
		name := e.Name()
		if !strings.HasSuffix(name, tokenFileExt) {
			continue
		}
		label := strings.TrimSuffix(name, tokenFileExt)
		if err := validLabel(label); err != nil {
			continue // skip files with unexpected names
		}
		out = append(out, TokenEntry{Label: label, Active: label == active})
	}
	sort.Slice(out, func(i, j int) bool { return out[i].Label < out[j].Label })
	// If active points at a label we didn't find, clear it.
	if active != "" {
		found := false
		for _, e := range out {
			if e.Active {
				found = true
				break
			}
		}
		if !found {
			_ = s.writeActiveLabel("")
			active = ""
		}
	}
	return out, active, nil
}

// AddToken stores a new PAT under the given label. If setActive is true (or
// no label is currently active), the label also becomes the active one.
// Returns an error if the label is already in use — the caller must remove
// the existing label first to avoid accidental overwrites.
func (s *dpapiSecrets) AddToken(label, token string, setActive bool) error {
	if err := validLabel(label); err != nil {
		return err
	}
	if token == "" {
		return errors.New("app: token must be non-empty")
	}
	if err := s.migrateLegacyIfNeeded(); err != nil {
		return err
	}
	if _, err := os.Stat(s.tokenPath(label)); err == nil {
		return fmt.Errorf("app: token label %q already exists", label)
	} else if !errors.Is(err, os.ErrNotExist) {
		return fmt.Errorf("app: stat token file: %w", err)
	}
	if err := s.writeToken(label, token); err != nil {
		return err
	}
	active, err := s.readActiveLabel()
	if err != nil {
		return err
	}
	if setActive || active == "" {
		return s.writeActiveLabel(label)
	}
	return nil
}

// RemoveToken deletes the PAT for the given label. If it was the active
// token, the active label is cleared (leaving the caller to pick another).
func (s *dpapiSecrets) RemoveToken(label string) error {
	if err := validLabel(label); err != nil {
		return err
	}
	if err := s.migrateLegacyIfNeeded(); err != nil {
		return err
	}
	if err := os.Remove(s.tokenPath(label)); err != nil && !errors.Is(err, os.ErrNotExist) {
		return fmt.Errorf("app: remove PAT: %w", err)
	}
	active, err := s.readActiveLabel()
	if err != nil {
		return err
	}
	if active == label {
		return s.writeActiveLabel("")
	}
	return nil
}

// SetActiveToken marks label as the active PAT. The label must exist.
func (s *dpapiSecrets) SetActiveToken(label string) error {
	if err := validLabel(label); err != nil {
		return err
	}
	if err := s.migrateLegacyIfNeeded(); err != nil {
		return err
	}
	if _, err := os.Stat(s.tokenPath(label)); err != nil {
		if errors.Is(err, os.ErrNotExist) {
			return fmt.Errorf("app: token label %q does not exist", label)
		}
		return fmt.Errorf("app: stat token file: %w", err)
	}
	return s.writeActiveLabel(label)
}

// --- low-level helpers ----------------------------------------------------

func (s *dpapiSecrets) readActiveLabel() (string, error) {
	data, err := os.ReadFile(s.activeLabelPath())
	if err != nil {
		if errors.Is(err, os.ErrNotExist) {
			return "", nil
		}
		return "", fmt.Errorf("app: read active label: %w", err)
	}
	return strings.TrimSpace(string(data)), nil
}

// writeActiveLabel atomically writes (or clears) the active-label marker.
func (s *dpapiSecrets) writeActiveLabel(label string) error {
	if label == "" {
		if err := os.Remove(s.activeLabelPath()); err != nil && !errors.Is(err, os.ErrNotExist) {
			return fmt.Errorf("app: clear active label: %w", err)
		}
		return nil
	}
	if err := os.MkdirAll(s.dir, 0o700); err != nil {
		return fmt.Errorf("app: mkdir secrets: %w", err)
	}
	tmp := s.activeLabelPath() + ".tmp"
	if err := os.WriteFile(tmp, []byte(label), 0o600); err != nil {
		return fmt.Errorf("app: write active label: %w", err)
	}
	if err := os.Rename(tmp, s.activeLabelPath()); err != nil {
		_ = os.Remove(tmp)
		return fmt.Errorf("app: rename active label: %w", err)
	}
	return nil
}

// readTokenByLabel returns the plaintext PAT for a label. Missing file → "".
func (s *dpapiSecrets) readTokenByLabel(label string) (string, error) {
	if err := validLabel(label); err != nil {
		return "", err
	}
	data, err := os.ReadFile(s.tokenPath(label))
	if err != nil {
		if errors.Is(err, os.ErrNotExist) {
			return "", nil
		}
		return "", fmt.Errorf("app: read PAT: %w", err)
	}
	plain, err := winapi.UnprotectBytes(data)
	if err != nil {
		return "", fmt.Errorf("app: decrypt PAT: %w", err)
	}
	return string(plain), nil
}

func (s *dpapiSecrets) writeToken(label, token string) error {
	if err := os.MkdirAll(s.tokensDir(), 0o700); err != nil {
		return fmt.Errorf("app: mkdir tokens: %w", err)
	}
	ciphertext, err := winapi.ProtectBytes([]byte(token))
	if err != nil {
		return fmt.Errorf("app: encrypt PAT: %w", err)
	}
	tmp := s.tokenPath(label) + ".tmp"
	if err := os.WriteFile(tmp, ciphertext, 0o600); err != nil {
		return fmt.Errorf("app: write PAT: %w", err)
	}
	if err := os.Rename(tmp, s.tokenPath(label)); err != nil {
		_ = os.Remove(tmp)
		return fmt.Errorf("app: rename PAT: %w", err)
	}
	return nil
}
