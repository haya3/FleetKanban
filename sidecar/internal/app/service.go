// Package app composes the internal subsystems and exposes a typed surface
// that the gRPC layer (internal/ipc) translates into protobuf RPCs for the
// Flutter UI.
//
// Service is instantiated in cmd/fleetkanban-sidecar/main.go and wrapped by
// the gRPC server so the Dart client can drive it over loopback. The same
// methods can also be called programmatically or from tests without ever
// starting the UI.
package app

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log/slog"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/oklog/ulid/v2"

	"github.com/FleetKanban/fleetkanban/internal/copilot"
	"github.com/FleetKanban/fleetkanban/internal/orchestrator"
	"github.com/FleetKanban/fleetkanban/internal/store"
	"github.com/FleetKanban/fleetkanban/internal/task"
	"github.com/FleetKanban/fleetkanban/internal/winapi"
	"github.com/FleetKanban/fleetkanban/internal/worktree"
)

// CopilotRuntime is the subset of copilot.Runtime that Service needs.
// Using an interface allows tests to inject a stub without starting a real
// CLI server.
type CopilotRuntime interface {
	CheckAuth(ctx context.Context) (copilot.AuthStatus, error)
	// BeginLogin starts a device-flow login subprocess and returns the
	// device code + pre-filled verification URL. The subprocess keeps
	// running in the background; callers poll CheckAuth to detect
	// completion (the runtime reloads the SDK client automatically on
	// successful exit).
	BeginLogin(ctx context.Context) (copilot.LoginChallenge, error)
	// CancelLogin terminates the login subprocess started by BeginLogin,
	// if any. No-op otherwise.
	CancelLogin()
	// LoginSession reports the lifecycle state of the login subprocess so
	// the UI can drive the sign-in dialog off the subprocess itself rather
	// than off CheckAuth (whose view of auth may lag behind the new
	// credentials until ReloadAuth runs).
	LoginSession() copilot.LoginSessionSnapshot
	// LaunchLogout opens an interactive terminal so the user can type
	// /logout. The Copilot CLI has no headless logout subcommand, so this
	// is still an interactive flow.
	LaunchLogout(ctx context.Context) error
	// ReloadAuth swaps the SDK client's PAT at runtime. Empty token means
	// "fall back to the CLI-logged-in user".
	ReloadAuth(ctx context.Context, token string) error
	// ListModels returns the catalog the embedded CLI server currently
	// advertises (ID + display name + premium-request multiplier). Used
	// to drive the Settings model picker so the UI can render Free vs
	// Premium ×N badges next to each model.
	ListModels(ctx context.Context) ([]copilot.Model, error)
}

// TokenEntry is a labelled-PAT listing row. Value-object mirror of
// secrets_dpapi.TokenEntry so the interface does not leak DPAPI types.
type TokenEntry struct {
	Label  string
	Active bool
}

// SecretStore abstracts PAT persistence. The production implementation
// encrypts with DPAPI and writes under %APPDATA%\FleetKanban\secrets; tests
// can swap in an in-memory implementation.
//
// The store manages multiple labelled PATs, with exactly one "active" label
// fed into the Copilot SDK. The single-token helpers
// (Get/Set/HasGitHubToken) operate on the active label for back-compat.
type SecretStore interface {
	// Single-token, back-compatible shortcuts that operate on the active label.
	GetGitHubToken() (string, error)
	SetGitHubToken(token string) error
	HasGitHubToken() (bool, error)

	// Label-aware multi-token API.
	ListTokens() ([]TokenEntry, string, error)
	AddToken(label, token string, setActive bool) error
	RemoveToken(label string) error
	SetActiveToken(label string) error
}

// EventPublisher optionally receives events emitted from outside the
// orchestrator (e.g. SubmitReview producing a review.submitted event).
// Production wiring routes this through ipc.EventBroker.Publish so the
// gRPC WatchEvents stream forwards the event to every connected UI.
type EventPublisher func(e *task.AgentEvent)

// Service is the application-level facade. All frontend calls go through it.
type Service struct {
	db       *store.DB
	repo     *store.RepositoryStore
	tasks    *store.TaskStore
	subtasks *store.SubtaskStore
	events   *store.EventStore
	insights *store.InsightsStore
	orch     *orchestrator.Orchestrator
	wt       *worktree.Manager
	log      *slog.Logger
	runtime  CopilotRuntime
	secrets  SecretStore
	publish  EventPublisher
}

// Config bundles constructor dependencies.
type Config struct {
	DB           *store.DB
	Orchestrator *orchestrator.Orchestrator
	Worktrees    *worktree.Manager
	Runtime      CopilotRuntime
	Secrets      SecretStore    // optional; PAT APIs return ErrSecretsUnavailable when nil
	Publish      EventPublisher // optional; nil is fine but UI live-updates for
	// out-of-orchestrator events (reviews, subtasks) won't fire.
	Logger *slog.Logger
}

// ErrSecretsUnavailable is returned by the PAT APIs when no SecretStore was
// provided to New. Tests that do not need PAT management can leave it nil.
var ErrSecretsUnavailable = errors.New("app: secret store not configured")

// ErrUnsupportedToken is returned by the token-setting APIs when the caller
// supplies a token whose prefix is not one of the formats the Copilot SDK
// accepts (see https://github.com/github/copilot-sdk/blob/main/docs/auth/index.md
// §"Supported token types"). The SDK silently rejects classic `ghp_` PATs at
// runtime with an opaque auth failure, so we reject up front with a clear
// message — no silent fallback to UseLoggedInUser.
var ErrUnsupportedToken = errors.New(
	"app: unsupported GitHub token format — the Copilot SDK only accepts " +
		"gho_ (OAuth user access), ghu_ (GitHub App user access), or " +
		"github_pat_ (fine-grained PAT). Classic ghp_ PATs are not supported")

// supportedTokenPrefixes is the allow-list for GitHub tokens passed to the
// Copilot SDK. Sourced from the SDK auth docs. Order does not matter.
var supportedTokenPrefixes = []string{"gho_", "ghu_", "github_pat_"}

// ValidateGitHubToken enforces the SDK's token-prefix allow-list. An empty
// token is accepted (it signals "clear the stored token"); a non-empty token
// must start with one of the supported prefixes. Callers on the input path
// (SetGitHubToken / AddGitHubToken / SetActiveGitHubToken) use this to fail
// fast with ErrUnsupportedToken instead of storing a token the SDK will
// later reject.
func ValidateGitHubToken(token string) error {
	if token == "" {
		return nil
	}
	for _, p := range supportedTokenPrefixes {
		if strings.HasPrefix(token, p) {
			return nil
		}
	}
	return ErrUnsupportedToken
}

// New validates cfg and constructs a Service.
func New(cfg Config) (*Service, error) {
	if cfg.DB == nil || cfg.Orchestrator == nil || cfg.Worktrees == nil || cfg.Runtime == nil {
		return nil, errors.New("app: DB, Orchestrator, Worktrees, Runtime are required")
	}
	if cfg.Logger == nil {
		cfg.Logger = slog.Default()
	}
	return &Service{
		db:       cfg.DB,
		repo:     store.NewRepositoryStore(cfg.DB),
		tasks:    store.NewTaskStore(cfg.DB),
		subtasks: store.NewSubtaskStore(cfg.DB),
		events:   store.NewEventStore(cfg.DB),
		insights: store.NewInsightsStore(cfg.DB),
		orch:     cfg.Orchestrator,
		wt:       cfg.Worktrees,
		log:      cfg.Logger,
		runtime:  cfg.Runtime,
		secrets:  cfg.Secrets,
		publish:  cfg.Publish,
	}, nil
}

// --- Insights --------------------------------------------------------------

// GetInsights returns the aggregate dashboard payload for the Insights
// pane. `repoID` scopes the query to one repository; empty spans all
// registered repositories and populates the per-repo breakdown.
func (s *Service) GetInsights(ctx context.Context, repoID string) (*store.InsightsSummary, error) {
	return s.insights.GetSummary(ctx, repoID)
}

// --- Repositories ----------------------------------------------------------

// ErrWSLPathRejected is returned when RegisterRepository is called with a
// path that lives inside the Windows Subsystem for Linux filesystem
// (\\wsl$\ or \\wsl.localhost\). Git worktree operations over the WSL P9
// bridge are unreliable, so Phase 1 explicitly refuses to register them.
var ErrWSLPathRejected = errors.New("app: WSL paths are not supported (\\\\wsl$ or \\\\wsl.localhost)")

// ErrNotAGitRepo is returned when RegisterRepository is called on a path
// that exists but isn't a git working tree. The UI catches this sentinel
// and offers to `git init` the directory before retrying the registration.
var ErrNotAGitRepo = errors.New("app: directory is not a git repository")

// RegisterRepositoryInput captures the full registration payload, including
// the opt-in `initialize_if_empty` flag used by the UI's "Initialize this
// folder as a git repository?" prompt.
type RegisterRepositoryInput struct {
	Path              string
	DisplayName       string
	InitializeIfEmpty bool
}

// RegisterRepository adds a git repository to the workspace. When the path
// is not yet a git worktree the call fails with ErrNotAGitRepo unless the
// caller opts in via InitializeIfEmpty, in which case we run `git init`
// first and then proceed with the normal registration flow.
//
// DefaultBaseBranch is left empty on purpose: new repositories start in
// auto-detection mode (see CreateTask / worktree.ResolveDefaultBranch).
// The user can pin a specific branch later via UpdateDefaultBaseBranch.
func (s *Service) RegisterRepository(ctx context.Context, in RegisterRepositoryInput) (*store.Repository, error) {
	if isWSLPath(in.Path) {
		return nil, ErrWSLPathRejected
	}
	isRepo, err := s.wt.IsGitRepo(ctx, in.Path)
	if err != nil {
		return nil, fmt.Errorf("app: inspect path: %w", err)
	}
	if !isRepo {
		if !in.InitializeIfEmpty {
			return nil, ErrNotAGitRepo
		}
		if err := s.wt.Init(ctx, in.Path); err != nil {
			return nil, fmt.Errorf("app: git init: %w", err)
		}
	}
	r, err := s.repo.Create(ctx, store.RepositoryInput{
		ID:                ulid.Make().String(),
		Path:              in.Path,
		DisplayName:       in.DisplayName,
		DefaultBaseBranch: "",
	})
	if err != nil {
		return nil, err
	}
	// Best-effort: keep the Jump List in sync so the new repo shows up under
	// "Recent" without waiting for the next app restart. Failures here never
	// surface to the caller.
	if jlErr := s.RefreshJumpList(ctx); jlErr != nil {
		s.log.Debug("app: RefreshJumpList after register", "err", jlErr)
	}
	return r, nil
}

// isWSLPath reports whether path points inside the WSL virtual file system.
// Checks are case-insensitive and tolerate both forward and backward slashes.
func isWSLPath(path string) bool {
	p := strings.ToLower(strings.ReplaceAll(path, "/", "\\"))
	return strings.HasPrefix(p, `\\wsl$\`) || strings.HasPrefix(p, `\\wsl.localhost\`)
}

// ListRepositories returns all registered repositories.
func (s *Service) ListRepositories(ctx context.Context) ([]*store.Repository, error) {
	return s.repo.List(ctx)
}

// BranchList is the payload returned by ListBranches. DefaultBranch is
// the result of the auto-detect resolver at call time and may be empty
// (unborn HEAD). Branches never includes FleetKanban's own
// `fleetkanban/*` task branches — those are internal churn. HasCommits
// lets the UI detect a freshly `git init`'d repository and surface the
// "Create initial commit" action before the user hits CreateTask.
type BranchList struct {
	Branches      []string
	DefaultBranch string
	HasCommits    bool
}

// ListBranches returns the base-branch candidates the user should see when
// creating a task against repoID. The list is de-duplicated and filtered:
// `fleetkanban/*` task branches are removed; the auto-detect default (when
// present) is hoisted to the front so the UI can make it the ComboBox's
// initial selection.
func (s *Service) ListBranches(ctx context.Context, repoID string) (*BranchList, error) {
	if repoID == "" {
		return nil, errors.New("app: repository id is required")
	}
	repo, err := s.repo.Get(ctx, repoID)
	if err != nil {
		return nil, err
	}
	raw, err := s.wt.ListBranches(ctx, repo.Path)
	if err != nil {
		return nil, fmt.Errorf("app: list branches: %w", err)
	}
	// Default branch may fail (unborn HEAD) — surface that as empty rather
	// than failing the whole call; the UI still needs the list so the user
	// can pin one.
	def, derr := s.wt.ResolveDefaultBranch(ctx, repo.Path)
	if derr != nil && !errors.Is(derr, worktree.ErrNoDefaultBranch) {
		return nil, fmt.Errorf("app: resolve default branch: %w", derr)
	}

	filtered := make([]string, 0, len(raw))
	seen := make(map[string]bool, len(raw))
	// Hoist def to the front if it's in the list.
	if def != "" {
		filtered = append(filtered, def)
		seen[def] = true
	}
	for _, b := range raw {
		if strings.HasPrefix(b, worktree.BranchPrefix) {
			continue
		}
		if seen[b] {
			continue
		}
		filtered = append(filtered, b)
		seen[b] = true
	}
	has, herr := s.wt.HasCommits(ctx, repo.Path)
	if herr != nil {
		return nil, fmt.Errorf("app: probe repository HEAD: %w", herr)
	}
	return &BranchList{Branches: filtered, DefaultBranch: def, HasCommits: has}, nil
}

// CreateInitialCommit seeds a registered but empty repository with a single
// empty commit so task creation's base-branch auto-detect has something to
// work with. Returns the refreshed Repository row (last_used_at is not
// touched; the commit is seeding, not usage). Fails with
// ErrRepositoryAlreadyHasCommits when the repo already has history, so the
// UI doesn't hide button accidentally calling it twice.
func (s *Service) CreateInitialCommit(ctx context.Context, repoID string) (*store.Repository, error) {
	if repoID == "" {
		return nil, errors.New("app: repository id is required")
	}
	repo, err := s.repo.Get(ctx, repoID)
	if err != nil {
		return nil, err
	}
	has, err := s.wt.HasCommits(ctx, repo.Path)
	if err != nil {
		return nil, fmt.Errorf("app: probe repository HEAD: %w", err)
	}
	if has {
		return nil, ErrRepositoryAlreadyHasCommits
	}
	if err := s.wt.CreateInitialCommit(ctx, repo.Path); err != nil {
		return nil, fmt.Errorf("app: create initial commit: %w", err)
	}
	return repo, nil
}

// ErrRepositoryAlreadyHasCommits is returned by CreateInitialCommit when
// the repository already has at least one commit on HEAD. Surfaced as
// FailedPrecondition over gRPC so the UI can refresh its cached state
// instead of retrying.
var ErrRepositoryAlreadyHasCommits = errors.New("app: repository already has commits")

// UpdateDefaultBaseBranch pins (or clears) a repository's default base
// branch. Empty `branch` clears the pin — the repository returns to
// auto-detection mode at the next CreateTask call. Non-empty values are
// validated against refs/heads/ before being persisted; the caller can
// rely on "no error returned" ⇒ "the branch exists right now".
func (s *Service) UpdateDefaultBaseBranch(ctx context.Context, id, branch string) (*store.Repository, error) {
	if id == "" {
		return nil, errors.New("app: repository id is required")
	}
	repo, err := s.repo.Get(ctx, id)
	if err != nil {
		return nil, err
	}
	if branch != "" {
		ok, err := s.wt.BranchExists(ctx, repo.Path, branch)
		if err != nil {
			return nil, fmt.Errorf("app: validate pin branch %q: %w", branch, err)
		}
		if !ok {
			return nil, fmt.Errorf("app: branch %q does not exist in repository", branch)
		}
	}
	if err := s.repo.UpdateDefaultBaseBranch(ctx, id, branch); err != nil {
		return nil, fmt.Errorf("app: update default base branch: %w", err)
	}
	return s.repo.Get(ctx, id)
}

// FoundRepository is one row of a ScanGitRepositories result.
type FoundRepository struct {
	Path              string
	DefaultBranch     string
	AlreadyRegistered bool
}

// scanDefaultMaxDepth caps how deep ScanGitRepositories recurses when the
// caller passes 0. Three is enough for `C:\src\<group>\<project>` layouts
// without stepping into node_modules / vendor trees where .git directories
// pile up from vendored submodules.
const scanDefaultMaxDepth = 3

// ScanGitRepositories walks rootPath up to maxDepth levels looking for
// `.git` entries. Returns the root-is-repo flag separately so the UI can
// short-circuit to a single registration path when the user happens to
// pick the repo itself.
func (s *Service) ScanGitRepositories(ctx context.Context, rootPath string, maxDepth int) (found []FoundRepository, rootIsRepo bool, err error) {
	if rootPath == "" {
		return nil, false, errors.New("app: ScanGitRepositories: path is required")
	}
	if isWSLPath(rootPath) {
		return nil, false, ErrWSLPathRejected
	}
	if maxDepth <= 0 {
		maxDepth = scanDefaultMaxDepth
	}
	abs, err := filepath.Abs(rootPath)
	if err != nil {
		return nil, false, fmt.Errorf("app: abs: %w", err)
	}
	rootIsRepo, err = s.wt.IsGitRepo(ctx, abs)
	if err != nil {
		return nil, false, err
	}

	existing, lerr := s.repo.List(ctx)
	if lerr != nil {
		return nil, rootIsRepo, fmt.Errorf("app: list existing: %w", lerr)
	}
	registered := make(map[string]bool, len(existing))
	for _, r := range existing {
		registered[strings.ToLower(filepath.Clean(r.Path))] = true
	}

	hits := make([]string, 0, 8)
	walkForGitDirs(abs, abs, maxDepth, &hits)

	out := make([]FoundRepository, 0, len(hits))
	for _, p := range hits {
		fr := FoundRepository{
			Path:              p,
			AlreadyRegistered: registered[strings.ToLower(filepath.Clean(p))],
		}
		// Detect the default branch; failures are non-fatal (leave empty
		// so the UI falls back to HEAD at registration time).
		if br, berr := s.wt.CurrentBranch(ctx, p); berr == nil {
			fr.DefaultBranch = br
		}
		out = append(out, fr)
	}
	return out, rootIsRepo, nil
}

// walkForGitDirs recursively appends any directory whose child `.git` is a
// directory or a gitfile (the form produced by submodules/worktrees). Stops
// descending into a hit so nested submodules don't spam the result.
func walkForGitDirs(root, current string, depthLeft int, out *[]string) {
	if depthLeft < 0 {
		return
	}
	gitEntry := filepath.Join(current, ".git")
	if info, err := os.Stat(gitEntry); err == nil {
		if info.IsDir() || info.Mode().IsRegular() {
			// Don't include the root itself in this list — the UI treats
			// root-is-repo separately so it can preserve the "single repo
			// registration" UX instead of showing a one-item multi-select.
			if filepath.Clean(current) != filepath.Clean(root) {
				*out = append(*out, current)
			}
			// Don't descend further: nested submodules are noise for the
			// "I have several repos side-by-side" use case this is for.
			return
		}
	}
	entries, err := os.ReadDir(current)
	if err != nil {
		return
	}
	for _, e := range entries {
		if !e.IsDir() {
			continue
		}
		if shouldSkipDir(e.Name()) {
			continue
		}
		walkForGitDirs(root, filepath.Join(current, e.Name()), depthLeft-1, out)
	}
}

// shouldSkipDir filters obvious heavy/irrelevant directories before we even
// stat their children. The list is intentionally conservative — when in
// doubt we descend, since users occasionally nest repos under odd names.
func shouldSkipDir(name string) bool {
	switch name {
	case "node_modules", "vendor", "dist", "build", "target",
		"out", ".venv", "venv", ".next", ".nuxt", ".cache",
		"__pycache__", ".gradle", ".idea", ".vscode":
		return true
	}
	// Dotted directories other than known project ones are skipped.
	if strings.HasPrefix(name, ".") && name != ".git" {
		return true
	}
	return false
}

// RefreshJumpList rebuilds the Windows Jump List from the registered
// repositories, ordered by last-used descending so the most recent repo
// appears first. Safe to call on a machine without a taskbar (WinPE,
// session 0, etc.) — the underlying Shell API is a no-op in that case.
func (s *Service) RefreshJumpList(ctx context.Context) error {
	repos, err := s.repo.List(ctx)
	if err != nil {
		return fmt.Errorf("app: RefreshJumpList list: %w", err)
	}
	paths := make([]string, 0, len(repos))
	for _, r := range repos {
		paths = append(paths, r.Path)
	}
	return winapi.RefreshJumpList(paths)
}

// --- Worktrees -------------------------------------------------------------

// WorktreeInfo is one row surfaced by ListWorktrees. It joins
// `git worktree list --porcelain` output with the tasks table so the UI can
// distinguish active tasks from orphan worktrees (branch exists on disk but
// no DB row) without re-running the join client-side.
type WorktreeInfo struct {
	RepositoryID   string
	RepositoryPath string
	Path           string // absolute worktree directory
	Branch         string // full refname, e.g. "refs/heads/fleetkanban/01J…"
	PathExists     bool
	IsPrimary      bool   // true for the repo's main working tree
	TaskID         string // empty unless branch is under fleetkanban/
	TaskStatus     string // empty unless the task row exists in DB
	HEAD           string
}

// ListWorktrees enumerates every worktree across all registered repositories.
// Failing to list one repo (e.g. the repo was deleted externally) is logged
// and the scan continues — the user needs to see the rest so they can clean up.
func (s *Service) ListWorktrees(ctx context.Context) ([]WorktreeInfo, error) {
	repos, err := s.repo.List(ctx)
	if err != nil {
		return nil, fmt.Errorf("app: list repositories: %w", err)
	}
	var out []WorktreeInfo
	for _, r := range repos {
		infos, err := s.wt.List(ctx, r.Path)
		if err != nil {
			s.log.Warn("app: ListWorktrees per-repo failure", "repo", r.Path, "err", err)
			continue
		}
		repoAbs := strings.ToLower(filepath.Clean(r.Path))
		for _, info := range infos {
			wi := WorktreeInfo{
				RepositoryID:   r.ID,
				RepositoryPath: r.Path,
				Path:           info.Path,
				Branch:         info.Branch,
				HEAD:           info.HEAD,
				IsPrimary:      strings.EqualFold(filepath.Clean(info.Path), repoAbs),
			}
			if _, statErr := os.Stat(info.Path); statErr == nil {
				wi.PathExists = true
			}
			if id := info.TaskID(); id != "" {
				wi.TaskID = id
				if t, terr := s.tasks.Get(ctx, id); terr == nil && t != nil {
					wi.TaskStatus = string(t.Status)
				}
			}
			out = append(out, wi)
		}
	}
	return out, nil
}

// RemoveWorktreeInput describes a worktree cleanup requested by the UI.
type RemoveWorktreeInput struct {
	RepositoryID string
	WorktreePath string
	// DeleteBranch is only honored for fleetkanban/<id> worktrees; the primary
	// repo worktree is never removed even if the caller passes its path.
	DeleteBranch bool
}

// ErrPrimaryWorktreeProtected guards against accidentally trying to remove
// the main checkout of a registered repository.
var ErrPrimaryWorktreeProtected = errors.New("app: cannot remove the primary worktree of a repository")

// RemoveWorktree removes a worktree directory (and optionally its branch)
// from the repository. If the worktree is a fleetkanban/<id> worktree the
// matching task row is transitioned to cancelled so the Kanban reflects the
// cleanup. Orphan worktrees (no matching task row) are silently tolerated.
func (s *Service) RemoveWorktree(ctx context.Context, in RemoveWorktreeInput) error {
	if in.RepositoryID == "" || in.WorktreePath == "" {
		return errors.New("app: RepositoryID and WorktreePath are required")
	}
	r, err := s.repo.Get(ctx, in.RepositoryID)
	if err != nil {
		return fmt.Errorf("app: repository lookup: %w", err)
	}
	if strings.EqualFold(filepath.Clean(in.WorktreePath), filepath.Clean(r.Path)) {
		return ErrPrimaryWorktreeProtected
	}

	taskID := extractTaskID(in.WorktreePath)
	mode := worktree.KeepBranch
	if in.DeleteBranch && taskID != "" {
		mode = worktree.DeleteBranch
	}
	// A task ID is required by worktree.Manager.Remove even when we keep the
	// branch (it is used only for DeleteBranch). Fall back to a placeholder
	// derived from the directory name so orphan directories are still removable.
	idArg := taskID
	if idArg == "" {
		idArg = filepath.Base(in.WorktreePath)
	}
	if err := s.wt.Remove(ctx, r.Path, in.WorktreePath, idArg, mode); err != nil {
		return err
	}
	if taskID != "" {
		if t, terr := s.tasks.Get(ctx, taskID); terr == nil && t != nil && !t.Status.IsTerminal() {
			if trErr := s.tasks.Transition(ctx, taskID, t.Status, task.StatusCancelled,
				task.ErrCodeNone, "", task.FinalizationNone); trErr != nil {
				s.log.Warn("RemoveWorktree: transition to cancelled", "task", taskID, "err", trErr)
			}
		}
	}
	return nil
}

// extractTaskID pulls the task ID out of a worktree path of the form
// <root>\<task-id>. Returns "" when the directory name does not look like a
// ULID; callers should fall back to treating it as an orphan directory.
func extractTaskID(wtPath string) string {
	base := filepath.Base(filepath.Clean(wtPath))
	if len(base) == 26 { // ULID canonical length
		return base
	}
	return ""
}

// --- Tasks -----------------------------------------------------------------

// CreateTaskInput is the payload from the frontend's "+ New Task" form.
type CreateTaskInput struct {
	RepositoryID string
	Goal         string
	BaseBranch   string // optional; see CreateTask doc for resolution rules
	Model        string // optional; falls back to Runner.Config.Model — Code stage
	PlanModel    string // optional; planner falls back to its own default when empty
	ReviewModel  string // optional; AI reviewer falls back to its own default when empty
}

// CreateTask persists a new Queued task. The orchestrator is not invoked
// until the user explicitly calls Run.
//
// Base-branch resolution is three-tiered so the UI (and tests) can opt into
// the level of control they want:
//
//  1. in.BaseBranch is non-empty — used as-is and validated. Missing → error.
//  2. repo.DefaultBaseBranch is non-empty (user pin) — used as-is and
//     validated. Missing → error that names the pinned branch, so the user
//     knows to update the pin in Settings rather than "why did my task
//     fail?".
//  3. Auto-detect via worktree.ResolveDefaultBranch (origin/HEAD → main
//     → master → HEAD). Surfaces ErrNoDefaultBranch for unborn-HEAD repos.
func (s *Service) CreateTask(ctx context.Context, in CreateTaskInput) (*task.Task, error) {
	if in.RepositoryID == "" || in.Goal == "" {
		return nil, errors.New("app: RepositoryID and Goal are required")
	}
	repo, err := s.repo.Get(ctx, in.RepositoryID)
	if err != nil {
		return nil, fmt.Errorf("app: repository lookup: %w", err)
	}

	base, err := s.resolveBaseBranch(ctx, repo, in.BaseBranch)
	if err != nil {
		return nil, err
	}

	id := ulid.Make().String()
	t := &task.Task{
		ID:          id,
		RepoID:      repo.ID,
		Goal:        in.Goal,
		BaseBranch:  base,
		Branch:      worktree.BranchPrefix + id,
		Model:       in.Model,
		PlanModel:   in.PlanModel,
		ReviewModel: in.ReviewModel,
		Status:      task.StatusQueued,
		CreatedAt:   time.Now().UTC(),
	}
	if err := s.tasks.Create(ctx, t); err != nil {
		return nil, err
	}
	return t, nil
}

// resolveBaseBranch implements the three-tier base-branch pick documented
// on CreateTask. Factored out so UpdateDefaultBaseBranch can share the
// "validate that a branch exists" step without duplicating the worktree.
func (s *Service) resolveBaseBranch(ctx context.Context, repo *store.Repository, explicit string) (string, error) {
	if explicit != "" {
		ok, err := s.wt.BranchExists(ctx, repo.Path, explicit)
		if err != nil {
			return "", fmt.Errorf("app: validate base branch %q: %w", explicit, err)
		}
		if !ok {
			return "", fmt.Errorf("app: base branch %q does not exist in repository", explicit)
		}
		return explicit, nil
	}
	if repo.DefaultBaseBranch != "" {
		ok, err := s.wt.BranchExists(ctx, repo.Path, repo.DefaultBaseBranch)
		if err != nil {
			return "", fmt.Errorf("app: validate pinned base branch %q: %w", repo.DefaultBaseBranch, err)
		}
		if !ok {
			// Stay strict: the user explicitly pinned this branch and we
			// should not silently pick a different one. The message tells
			// them where to fix it.
			return "", fmt.Errorf(
				"app: pinned base branch %q does not exist in repository; update or clear the pin in Settings",
				repo.DefaultBaseBranch)
		}
		return repo.DefaultBaseBranch, nil
	}
	br, err := s.wt.ResolveDefaultBranch(ctx, repo.Path)
	if err != nil {
		if errors.Is(err, worktree.ErrNoDefaultBranch) {
			return "", fmt.Errorf(
				"app: could not determine a base branch (repository has no commits or is on detached HEAD); pin a branch in Settings")
		}
		return "", fmt.Errorf("app: auto-detect base branch: %w", err)
	}
	return br, nil
}

// ListTasks returns tasks filtered by repo and/or status.
func (s *Service) ListTasks(ctx context.Context, f store.ListFilter) ([]*task.Task, error) {
	return s.tasks.List(ctx, f)
}

// GetTask loads one task by ID.
func (s *Service) GetTask(ctx context.Context, id string) (*task.Task, error) {
	return s.tasks.Get(ctx, id)
}

// GetTaskDiff returns the unified diff of the task's branch against its
// base branch. Empty string means no changes yet; callers should surface
// that to the user as "no diff".
//
// Primary path executes `git diff` inside the task's worktree. When the
// worktree directory is missing (Finalize Keep/Merge/Discard removed it,
// or the user deleted it externally) the call falls back to running the
// diff from the main repository against the preserved task branch. This
// keeps "completed" tasks' Files (diff) view usable as long as the branch
// itself still exists.
func (s *Service) GetTaskDiff(ctx context.Context, id string) (string, error) {
	t, err := s.tasks.Get(ctx, id)
	if err != nil {
		return "", err
	}
	if t.WorktreePath == "" {
		return "", errors.New("app: task has no worktree; diff unavailable")
	}
	if t.BaseBranch == "" {
		return "", errors.New("app: task has no base branch recorded")
	}
	out, err := s.wt.Diff(ctx, t.WorktreePath, t.BaseBranch)
	if err == nil {
		return out, nil
	}
	if !errors.Is(err, worktree.ErrWorktreeMissing) {
		return "", err
	}
	// Worktree directory is gone. Fall back to the main repository +
	// preserved task branch.
	if t.Branch == "" {
		return "", errors.New("app: worktree missing and task has no recorded branch; diff unavailable")
	}
	repo, err := s.repo.Get(ctx, t.RepoID)
	if err != nil {
		return "", fmt.Errorf("app: worktree missing and repo lookup failed: %w", err)
	}
	exists, err := s.wt.BranchExists(ctx, repo.Path, t.Branch)
	if err != nil {
		return "", fmt.Errorf("app: worktree missing; branch existence check failed: %w", err)
	}
	if !exists {
		return "", fmt.Errorf("app: worktree and branch %s are both gone; diff unavailable", t.Branch)
	}
	return s.wt.DiffBranch(ctx, repo.Path, t.BaseBranch, t.Branch)
}

// RunTask enqueues a task for execution.
//
// For tasks already in StatusQueued (the default post-CreateTask state)
// this is a direct hand-off to the orchestrator. For tasks in StatusAborted
// or StatusFailed — i.e. the "re-run" flow from the Kanban's Done column —
// the service first transitions them back to StatusQueued (preserving the
// worktree) and then enqueues. Planning / InProgress / AIReview /
// HumanReview are rejected with InvalidArgument so the UI surfaces a
// clear "already running" or "awaiting review" error instead of silently
// failing at orchestrator Enqueue time.
//
// Auth is checked up front: an unauthenticated SDK short-circuits the
// request and transitions the task to failed(auth) so the Kanban reflects
// the block reason immediately.
func (s *Service) RunTask(ctx context.Context, id string) error {
	st, err := s.runtime.CheckAuth(ctx)
	if err != nil {
		return fmt.Errorf("app: auth check: %w", err)
	}
	if !st.Authenticated {
		// Try the transition from whatever status the task is currently in —
		// the run was requested from an aborted/failed card just as often as
		// from a queued one, and "auth failed → stays in same state" is a
		// worse UX than always landing on failed(auth). IsTerminal() already
		// covers done/cancelled/failed so no extra status check is needed.
		t, terr := s.tasks.Get(ctx, id)
		if terr == nil && !t.Status.IsTerminal() {
			if trErr := s.tasks.Transition(ctx, id,
				t.Status, task.StatusFailed,
				task.ErrCodeAuth,
				firstNonEmpty(st.Message, "Copilot is not authenticated"),
				task.FinalizationNone); trErr != nil {
				s.log.Warn("RunTask: auth-failure transition", "task", id, "err", trErr)
			}
		}
		return copilot.ErrNotAuthenticated
	}

	// If the task isn't already queued, promote it so the orchestrator's
	// `queued → in_progress` transition succeeds.
	t, err := s.tasks.Get(ctx, id)
	if err != nil {
		return err
	}
	switch t.Status {
	case task.StatusQueued:
		// nothing to do
	case task.StatusAborted, task.StatusFailed:
		if err := s.tasks.Transition(ctx, id, t.Status, task.StatusQueued,
			task.ErrCodeNone, "", task.FinalizationNone); err != nil {
			return fmt.Errorf("app: rerun transition: %w", err)
		}
		s.appendStatusEvent(ctx, id, t.Status, task.StatusQueued)
	default:
		return fmt.Errorf("app: cannot run a task in status %s", t.Status)
	}
	return s.orch.Enqueue(id)
}

// CheckCopilotAuth returns the current authentication state as reported by the
// SDK's auth.getStatus RPC.
func (s *Service) CheckCopilotAuth(ctx context.Context) (copilot.AuthStatus, error) {
	return s.runtime.CheckAuth(ctx)
}

// ListCopilotModels surfaces the live model catalog from the Copilot SDK so
// the Settings UI can offer a fresh picker instead of hard-coding IDs that
// may have been rotated out server-side. Each entry carries the premium-
// request multiplier so the picker can flag Free vs Premium ×N.
func (s *Service) ListCopilotModels(ctx context.Context) ([]copilot.Model, error) {
	return s.runtime.ListModels(ctx)
}

// BeginCopilotLogin kicks off a headless device-flow login. See
// copilot.LoginCoordinator.Begin for the full contract. The UI displays the
// returned UserCode / VerificationURI and polls CheckCopilotAuth until the
// user completes authentication in the browser.
func (s *Service) BeginCopilotLogin(ctx context.Context) (copilot.LoginChallenge, error) {
	return s.runtime.BeginLogin(ctx)
}

// CancelCopilotLogin terminates an in-flight login subprocess, if any. The
// UI calls this when the user dismisses the sign-in dialog.
func (s *Service) CancelCopilotLogin(_ context.Context) error {
	s.runtime.CancelLogin()
	return nil
}

// GetCopilotLoginSession reports the state of the login subprocess tracked
// by BeginCopilotLogin. See CopilotRuntime.LoginSession for semantics; the
// sign-in dialog polls this RPC to decide when to close.
func (s *Service) GetCopilotLoginSession(_ context.Context) copilot.LoginSessionSnapshot {
	return s.runtime.LoginSession()
}

// StartCopilotLogout launches an interactive terminal. The user is expected
// to type "/logout" — the Copilot CLI has no headless logout subcommand.
// Re-login afterwards should go through BeginCopilotLogin; this RPC is
// kept only for the logout case.
func (s *Service) StartCopilotLogout(ctx context.Context) error {
	return s.runtime.LaunchLogout(ctx)
}

// ReloadCopilotAuth restarts the embedded CLI server so it re-reads the
// on-disk OAuth token store, then reports the fresh auth status. The
// onboarding UI calls this after the user completes /login in the spawned
// terminal — the long-running CLI server would otherwise keep reporting the
// pre-login state until the sidecar restarted. The reload is bounded in
// cost (one stop + start of the CLI subprocess) and idempotent, so calling
// it redundantly is safe.
//
// The active PAT (if any) is preserved: we pass the current configured
// token back into ReloadAuth so PAT users do not lose their explicit
// override just because they triggered a re-check.
func (s *Service) ReloadCopilotAuth(ctx context.Context) (copilot.AuthStatus, error) {
	tok, err := s.secrets.GetGitHubToken()
	if err != nil {
		// Falling back to an empty token here matches the startup path in
		// cmd/fleetkanban-sidecar/main.go: when the secret store errors we
		// prefer UseLoggedInUser over aborting the whole reload.
		s.log.Warn("ReloadCopilotAuth: secret read", "err", err)
		tok = ""
	}
	if rlErr := s.runtime.ReloadAuth(ctx, tok); rlErr != nil {
		return copilot.AuthStatus{}, fmt.Errorf("reload auth: %w", rlErr)
	}
	return s.runtime.CheckAuth(ctx)
}

// firstNonEmpty returns the first non-empty string from the arguments.
func firstNonEmpty(vals ...string) string {
	for _, v := range vals {
		if v != "" {
			return v
		}
	}
	return ""
}

// CancelTask requests an in-flight task to abort.
// CancelTask aborts an in-flight task or, when the orchestrator has no
// record (e.g. the task row was left in_progress by a previous sidecar
// run that crashed), directly transitions the task to aborted so the UI's
// Stop button never surfaces a confusing "task not running" error for
// state the user can see on screen.
func (s *Service) CancelTask(ctx context.Context, id string) error {
	if err := s.orch.Cancel(id); err == nil {
		return nil
	} else if !errors.Is(err, orchestrator.ErrNotRunning) {
		return err
	}
	// Fallback path: orchestrator has no live session for this task.
	t, terr := s.tasks.Get(ctx, id)
	if terr != nil {
		return terr
	}
	switch t.Status {
	case task.StatusInProgress, task.StatusAIReview:
		return s.tasks.Transition(ctx, id, t.Status, task.StatusAborted,
			task.ErrCodeNone, "", task.FinalizationNone)
	case task.StatusPlanning, task.StatusQueued:
		return s.tasks.Transition(ctx, id, t.Status, task.StatusCancelled,
			task.ErrCodeNone, "", task.FinalizationNone)
	default:
		return nil // already terminal; nothing to do
	}
}

// --- Settings --------------------------------------------------------------

// SetConcurrency updates the orchestrator's concurrent-task limit. The value
// is clamped to [orchestrator.ConcurrencyMin, orchestrator.ConcurrencyMax].
// Returns the effective value.
func (s *Service) SetConcurrency(_ context.Context, n int) (int, error) {
	return s.orch.SetConcurrency(n), nil
}

// GetConcurrency returns the orchestrator's current concurrent-task limit.
func (s *Service) GetConcurrency(_ context.Context) (int, error) {
	return s.orch.Concurrency(), nil
}

// CheckGitConfig surfaces the user's global git configuration state for the
// knobs FleetKanban requires (phase1-spec §9.1). The frontend displays a
// warning banner when any field is not OK.
func (s *Service) CheckGitConfig(ctx context.Context) (worktree.GlobalConfigStatus, error) {
	return s.wt.CheckGlobalConfig(ctx)
}

// HasGitHubToken reports whether a PAT is persisted. The token itself is
// never returned to the frontend — only the boolean "configured" signal.
func (s *Service) HasGitHubToken(_ context.Context) (bool, error) {
	if s.secrets == nil {
		return false, nil
	}
	return s.secrets.HasGitHubToken()
}

// SetGitHubToken persists (or clears) the active PAT. Passing an empty string
// deletes the active token (but leaves other labelled tokens intact). The
// token is DPAPI-encrypted at rest; it is never logged or echoed back to the
// caller. After storing, the Copilot SDK client is hot-reloaded so the new
// credential takes effect immediately.
func (s *Service) SetGitHubToken(ctx context.Context, token string) error {
	if s.secrets == nil {
		return ErrSecretsUnavailable
	}
	if err := ValidateGitHubToken(token); err != nil {
		return err
	}
	if err := s.secrets.SetGitHubToken(token); err != nil {
		return err
	}
	return s.runtime.ReloadAuth(ctx, token)
}

// ListGitHubTokens returns every stored labelled PAT (label + active flag).
// Token values themselves are never surfaced. The second return value is the
// currently-active label ("" when no tokens exist).
func (s *Service) ListGitHubTokens(_ context.Context) ([]TokenEntry, string, error) {
	if s.secrets == nil {
		return nil, "", ErrSecretsUnavailable
	}
	return s.secrets.ListTokens()
}

// AddGitHubToken stores a new PAT under label. When setActive is true, the
// label is also made the active one and the SDK client is hot-reloaded.
func (s *Service) AddGitHubToken(ctx context.Context, label, token string, setActive bool) error {
	if s.secrets == nil {
		return ErrSecretsUnavailable
	}
	if err := ValidateGitHubToken(token); err != nil {
		return err
	}
	if err := s.secrets.AddToken(label, token, setActive); err != nil {
		return err
	}
	// If this label became active (either because setActive=true or because
	// it was the first token), reload the runtime.
	_, active, lerr := s.secrets.ListTokens()
	if lerr != nil {
		return lerr
	}
	if active == label {
		return s.runtime.ReloadAuth(ctx, token)
	}
	return nil
}

// RemoveGitHubToken deletes the PAT for the given label. If it was the
// active one, the SDK client falls back to CLI-logged-in auth (empty token).
func (s *Service) RemoveGitHubToken(ctx context.Context, label string) error {
	if s.secrets == nil {
		return ErrSecretsUnavailable
	}
	// Detect whether we need to reload auth *before* removing, because after
	// removal the active label may have been cleared.
	_, activeBefore, lerr := s.secrets.ListTokens()
	if lerr != nil {
		return lerr
	}
	if err := s.secrets.RemoveToken(label); err != nil {
		return err
	}
	if activeBefore == label {
		return s.runtime.ReloadAuth(ctx, "")
	}
	return nil
}

// SetActiveGitHubToken marks label as the active PAT and hot-reloads the SDK
// client so the new credential takes effect without a sidecar restart.
//
// The stored token is re-validated before activation. This catches tokens
// that were persisted before ValidateGitHubToken existed (e.g. legacy
// classic `ghp_` PATs); the user gets ErrUnsupportedToken instead of a
// silent SDK-level auth failure at the next RPC.
func (s *Service) SetActiveGitHubToken(ctx context.Context, label string) error {
	if s.secrets == nil {
		return ErrSecretsUnavailable
	}
	if err := s.secrets.SetActiveToken(label); err != nil {
		return err
	}
	tok, err := s.secrets.GetGitHubToken()
	if err != nil {
		return err
	}
	if err := ValidateGitHubToken(tok); err != nil {
		return err
	}
	return s.runtime.ReloadAuth(ctx, tok)
}

// FinalizeTask applies the post-run choice (Keep / Merge / Discard).
func (s *Service) FinalizeTask(ctx context.Context, id string, action orchestrator.Finalization) error {
	return s.orch.Finalize(ctx, id, action)
}

// ErrTaskStillRunning is returned by DeleteTask when the target task is in
// a non-terminal, non-review state. Callers should call CancelTask first
// and wait for the task to settle before retrying the delete.
var ErrTaskStillRunning = errors.New("app: task is still running; cancel it before deleting")

// DeleteTask removes a task row and its worktree from disk. The branch is
// preserved by default so any committed work survives; pass deleteBranch
// =true to remove it as well. Events are removed by DB cascade on row
// delete. Subtasks are also cascade-deleted by the schema.
//
// Rejects in_progress / ai_review tasks with ErrTaskStillRunning — the
// caller must cancel them first. Terminal / review / queued / planning
// tasks are accepted.
func (s *Service) DeleteTask(ctx context.Context, id string, deleteBranch bool) error {
	if id == "" {
		return errors.New("app: DeleteTask: id is required")
	}
	t, err := s.tasks.Get(ctx, id)
	if err != nil {
		return err
	}

	// Block deletion of tasks the orchestrator is actively running.
	// Review states are allowed: they're not running, just awaiting a
	// decision, and the user may want to prune them rather than
	// Keep/Discard.
	switch t.Status {
	case task.StatusInProgress:
		return ErrTaskStillRunning
	case task.StatusAIReview:
		// If an AI reviewer goroutine is active, cancel it first so it
		// doesn't mutate the task row after we delete it. Best-effort:
		// Cancel returns nil when nothing is registered.
		_ = s.orch.Cancel(id)
	}

	// Remove the worktree if one exists. Missing directory is not an
	// error — the reaper or a prior Finalize may already have cleared it.
	if t.WorktreePath != "" && t.Branch != "" {
		repo, rerr := s.repo.Get(ctx, t.RepoID)
		if rerr == nil {
			mode := worktree.KeepBranch
			if deleteBranch {
				mode = worktree.DeleteBranch
			}
			if wtErr := s.wt.Remove(ctx, repo.Path, t.WorktreePath, id, mode); wtErr != nil {
				// Surface the git/fs error; the DB row stays so a retry
				// works. Swallowing the error would leave orphan
				// worktrees behind.
				return fmt.Errorf("app: delete worktree: %w", wtErr)
			}
		} else {
			s.log.Warn("app: DeleteTask: repo lookup failed, skipping worktree removal",
				"task", id, "err", rerr)
		}
	}

	return s.tasks.Delete(ctx, id)
}

// ErrTaskBranchAlreadyRemoved is returned by DeleteTaskBranch when the
// task has no branch to delete — either BranchExists=false (already gone)
// or Branch="" (never had one). Distinguished from generic errors so the
// UI can silently refresh instead of surfacing a scare.
var ErrTaskBranchAlreadyRemoved = errors.New("app: task branch already removed")

// DeleteTaskBranch removes the fleetkanban/<id> branch for a task that has
// already been finalized. Intended for the Housekeeping UI's Stale list
// "Discard" action, where the user has confirmed they no longer want the
// branch kicking around.
//
// Valid starting states: Done (post-Keep finalize) and Aborted. For
// Aborted the existing FinalizeTask(discard=true) remains the canonical
// path — DeleteTaskBranch is the only option for Done tasks where the
// worktree is already gone and the branch is the only thing left.
//
// Force-deletes via `git branch -D`: the UI's confirmation dialog is
// responsible for making sure the user understands unmerged work on the
// branch will be lost.
func (s *Service) DeleteTaskBranch(ctx context.Context, id string) error {
	if id == "" {
		return errors.New("app: DeleteTaskBranch: id is required")
	}
	t, err := s.tasks.Get(ctx, id)
	if err != nil {
		return err
	}
	switch t.Status {
	case task.StatusDone, task.StatusAborted:
	default:
		return fmt.Errorf("app: DeleteTaskBranch: task %s is in status %s; use FinalizeTask or DeleteTask instead",
			id, t.Status)
	}
	if t.Branch == "" || !t.BranchExists {
		return ErrTaskBranchAlreadyRemoved
	}
	repo, err := s.repo.Get(ctx, t.RepoID)
	if err != nil {
		return fmt.Errorf("app: DeleteTaskBranch: repo lookup: %w", err)
	}

	if err := s.wt.DeleteBranch(ctx, repo.Path, t.Branch); err != nil {
		return fmt.Errorf("app: DeleteTaskBranch: %w", err)
	}
	if err := s.tasks.SetBranchExists(ctx, id, false); err != nil {
		// Branch is already gone from git at this point; a DB error here
		// would leave the row stale but next reaper pass will fix it.
		s.log.Warn("DeleteTaskBranch: SetBranchExists failed",
			"task", id, "err", err)
	}

	// Audit row: mirrors the reaper's housekeeping.branch_gc events so the
	// Housekeeping UI can render manual and automatic deletions in one log.
	payload, mErr := json.Marshal(struct {
		Branch string `json:"branch"`
		Base   string `json:"base"`
		Reason string `json:"reason"`
	}{Branch: t.Branch, Base: t.BaseBranch, Reason: "user-discard"})
	if mErr == nil {
		seq, seqErr := s.events.NextSeq(ctx, id)
		if seqErr == nil {
			_ = s.events.Append(ctx, &task.AgentEvent{
				ID:         ulid.Make().String(),
				TaskID:     id,
				Seq:        seq,
				Kind:       task.EventHousekeepingBranchGC,
				Payload:    string(payload),
				OccurredAt: time.Now().UTC(),
			})
		}
	}
	return nil
}

// --- Review ---------------------------------------------------------------

// ReviewAction is the reviewer's verdict on an ai_review or human_review task.
type ReviewAction int

const (
	ReviewApprove ReviewAction = iota + 1
	ReviewRework
	ReviewReject
)

// SubmitReview records the reviewer's verdict, persists feedback, appends a
// review.submitted event, and advances the task through the state machine.
//
// Action semantics (action × current status matrix):
//   - ReviewApprove on ai_review    → ai_review → human_review
//   - ReviewApprove on human_review → InvalidArgument; callers should use
//     FinalizeTask(keep=true) instead. We refuse here because "approve"
//     from human_review is ambiguous — the canonical finalize path both
//     transitions AND removes the worktree, which review cannot do.
//   - ReviewRework                  → queued; feedback is stored and will be
//     injected into the next Copilot prompt. Valid from both review states.
//   - ReviewReject on ai_review     → failed(ai_review)
//   - ReviewReject on human_review  → InvalidArgument; use FinalizeTask
//     (keep=false) to Discard instead
func (s *Service) SubmitReview(ctx context.Context, id string, action ReviewAction, feedback string) error {
	if id == "" {
		return errors.New("app: SubmitReview: id is required")
	}
	t, err := s.tasks.Get(ctx, id)
	if err != nil {
		return err
	}
	if t.Status != task.StatusAIReview && t.Status != task.StatusHumanReview {
		return fmt.Errorf("app: cannot review a task in status %s", t.Status)
	}

	// Pre-flight action/status compatibility checks. Done before any
	// mutation so a rejected call never touches feedback or events.
	switch action {
	case ReviewApprove:
		if t.Status != task.StatusAIReview {
			return errors.New("app: approve is only valid from ai_review (use FinalizeTask for human_review)")
		}
	case ReviewReject:
		if t.Status != task.StatusAIReview {
			return errors.New("app: reject is only valid from ai_review (use FinalizeTask(keep=false) for human_review)")
		}
	case ReviewRework:
		if strings.TrimSpace(feedback) == "" {
			return errors.New("app: rework requires non-empty feedback")
		}
	default:
		return fmt.Errorf("app: unknown review action %d", action)
	}

	// For rework, persist the feedback *before* the transition so the
	// rework row has it visible to any concurrent reader the moment
	// status flips to queued. Approve/reject do not take feedback onto
	// the task row — their outcome is encoded in the status itself.
	if action == ReviewRework {
		t.ReviewFeedback = feedback
		if err := s.tasks.UpdateFields(ctx, t); err != nil {
			return fmt.Errorf("app: persist feedback: %w", err)
		}
	}

	// Append the review event (history for the Logs tab) only once we
	// know the action is legal for the current status.
	s.appendReviewEvent(ctx, t, action, feedback)

	var next task.Status
	var errCode task.ErrorCode
	var errMsg string
	switch action {
	case ReviewApprove:
		next = task.StatusHumanReview
	case ReviewRework:
		next = task.StatusQueued
	case ReviewReject:
		next = task.StatusFailed
		errCode = task.ErrCodeAIReview
		errMsg = feedback
	}

	fromStatus := t.Status
	if err := s.tasks.Transition(ctx, id, t.Status, next, errCode, errMsg, task.FinalizationNone); err != nil {
		return fmt.Errorf("app: review transition: %w", err)
	}
	s.appendStatusEvent(ctx, t.ID, fromStatus, next)

	// After a rework transition, re-enqueue so the orchestrator picks the
	// task up without the user having to press Run again.
	if action == ReviewRework {
		if err := s.orch.Enqueue(id); err != nil &&
			!errors.Is(err, orchestrator.ErrAlreadyRunning) {
			s.log.Warn("app: SubmitReview rework enqueue", "task", id, "err", err)
		}
	}
	return nil
}

// appendStatusEvent persists a kind="status" event and forwards it via the
// broker so WatchEvents subscribers refetch the tasks list. Uses
// AppendAutoSeq for race-safety against concurrent runner writers.
func (s *Service) appendStatusEvent(ctx context.Context, taskID string, from, to task.Status) {
	ev := &task.AgentEvent{
		ID:      ulid.Make().String(),
		TaskID:  taskID,
		Kind:    task.EventStatus,
		Payload: fmt.Sprintf(`{"from":%q,"to":%q}`, from, to),
	}
	if err := s.events.AppendAutoSeq(ctx, ev); err != nil {
		s.log.Warn("app: status event append", "task", taskID, "err", err)
		return
	}
	if s.publish != nil {
		s.publish(ev)
	}
}

// appendReviewEvent persists a review.submitted event and forwards it to the
// broker (when available) so the WatchEvents stream sees it. Uses
// AppendAutoSeq so the seq assignment is atomic against any concurrent
// runner event writer. Failures are logged and swallowed — the review
// transition itself is the source of truth.
func (s *Service) appendReviewEvent(ctx context.Context, t *task.Task, action ReviewAction, feedback string) {
	actionName := "approve"
	switch action {
	case ReviewRework:
		actionName = "rework"
	case ReviewReject:
		actionName = "reject"
	}
	payload := fmt.Sprintf(`{"action":%q,"feedback":%q}`, actionName, feedback)
	ev := &task.AgentEvent{
		ID:      ulid.Make().String(),
		TaskID:  t.ID,
		Kind:    task.EventReviewSubmitted,
		Payload: payload,
	}
	if err := s.events.AppendAutoSeq(ctx, ev); err != nil {
		s.log.Warn("app: review event append", "task", t.ID, "err", err)
		return
	}
	if s.publish != nil {
		s.publish(ev)
	}
}

// --- Subtasks -------------------------------------------------------------

// ListSubtasks returns every subtask of parentID ordered by order_idx.
func (s *Service) ListSubtasks(ctx context.Context, parentID string) ([]*task.Subtask, error) {
	if parentID == "" {
		return nil, errors.New("app: ListSubtasks: task_id is required")
	}
	return s.subtasks.ListByTask(ctx, parentID)
}

// CreateSubtaskInput is the payload for inserting a subtask. The planner
// supplies AgentRole and DependsOn; the legacy manual-add UI leaves them
// empty and will be retired once the Plan phase ships.
type CreateSubtaskInput struct {
	TaskID    string
	Title     string
	AgentRole string
	DependsOn []string
	Status    task.SubtaskStatus // "" → pending
	OrderIdx  int                // <= 0 → append at end
}

// CreateSubtask inserts a new subtask under the parent task. When OrderIdx <=
// 0 the service queries the current max and appends; explicit indices are
// honored as-is so the planner can pre-compute positions for bulk imports.
func (s *Service) CreateSubtask(ctx context.Context, in CreateSubtaskInput) (*task.Subtask, error) {
	if in.TaskID == "" || strings.TrimSpace(in.Title) == "" {
		return nil, errors.New("app: CreateSubtask: task_id and title are required")
	}
	// Verify the parent exists so we surface NotFound promptly.
	if _, err := s.tasks.Get(ctx, in.TaskID); err != nil {
		return nil, fmt.Errorf("app: parent task lookup: %w", err)
	}
	status := in.Status
	if status == "" {
		status = task.SubtaskPending
	}
	idx := in.OrderIdx
	if idx <= 0 {
		maxIdx, err := s.subtasks.MaxOrderIdx(ctx, in.TaskID)
		if err != nil {
			return nil, err
		}
		idx = maxIdx + 1
	}
	sub := &task.Subtask{
		ID:        ulid.Make().String(),
		TaskID:    in.TaskID,
		Title:     strings.TrimSpace(in.Title),
		AgentRole: strings.TrimSpace(in.AgentRole),
		DependsOn: in.DependsOn,
		Status:    status,
		OrderIdx:  idx,
		CreatedAt: time.Now().UTC(),
	}
	if err := s.subtasks.Create(ctx, sub); err != nil {
		return nil, err
	}
	return sub, nil
}

// UpdateSubtaskInput is the payload for a partial subtask edit.
type UpdateSubtaskInput struct {
	ID     string
	Title  string             // "" leaves title untouched
	Status task.SubtaskStatus // "" leaves status untouched
}

// UpdateSubtask applies title/status changes to an existing subtask. Missing
// fields are left unchanged so the UI can toggle a checkbox without having to
// re-send the title.
func (s *Service) UpdateSubtask(ctx context.Context, in UpdateSubtaskInput) (*task.Subtask, error) {
	if in.ID == "" {
		return nil, errors.New("app: UpdateSubtask: id is required")
	}
	sub, err := s.subtasks.Get(ctx, in.ID)
	if err != nil {
		return nil, err
	}
	if t := strings.TrimSpace(in.Title); t != "" {
		sub.Title = t
	}
	if in.Status != "" {
		if !in.Status.Valid() {
			return nil, fmt.Errorf("app: invalid subtask status %q", in.Status)
		}
		sub.Status = in.Status
	}
	if err := s.subtasks.Update(ctx, sub); err != nil {
		return nil, err
	}
	return sub, nil
}

// DeleteSubtask removes a subtask row.
func (s *Service) DeleteSubtask(ctx context.Context, id string) error {
	if id == "" {
		return errors.New("app: DeleteSubtask: id is required")
	}
	return s.subtasks.Delete(ctx, id)
}

// ReorderSubtasks persists a new 0-based ordering for the given parent.
func (s *Service) ReorderSubtasks(ctx context.Context, parentID string, ids []string) error {
	if parentID == "" || len(ids) == 0 {
		return errors.New("app: ReorderSubtasks: task_id and ids are required")
	}
	return s.subtasks.Reorder(ctx, parentID, ids)
}

// --- Events ----------------------------------------------------------------

// TaskEvents loads events for a task from seq+1 onwards, capped at limit.
// Used by the frontend when it attaches late to an already-running session.
func (s *Service) TaskEvents(ctx context.Context, taskID string, sinceSeq int64, limit int) ([]*task.AgentEvent, error) {
	return s.events.ListByTask(ctx, taskID, sinceSeq, limit)
}

// --- Lifecycle -------------------------------------------------------------

// Shutdown tears the service down: stops the orchestrator and closes the DB.
func (s *Service) Shutdown(ctx context.Context) error {
	if err := s.orch.Shutdown(ctx); err != nil {
		s.log.Warn("app: orchestrator shutdown", "err", err)
	}
	return s.db.Close()
}
