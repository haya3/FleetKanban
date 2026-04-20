//go:build windows

// Package copilot wraps the GitHub Copilot SDK for Go and exposes the Runtime
// / Runner / permission handler that the orchestrator and application layers
// need.
//
//   - client.go     : Runtime lifecycle (Start/Stop/CheckAuth/LaunchLogout/ReloadAuth)
//   - login.go      : LoginCoordinator — headless `copilot login` subprocess + device-code parse
//   - runner.go     : SDK-backed AgentRunner
//   - permission.go : path-guard logic + SDK PermissionHandlerFunc builder
//   - events.go     : SessionEvent → task.AgentEvent mapping
//   - prompt.go     : BuildPrompt helper
package copilot

import (
	"context"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"sync"
	"syscall"
	"time"

	copilot "github.com/github/copilot-sdk/go"
	"golang.org/x/sys/windows"
)

// AuthStatus is a snapshot of the Copilot SDK authentication state.
type AuthStatus struct {
	Authenticated bool      `json:"authenticated"`
	User          string    `json:"user,omitempty"`
	Message       string    `json:"message,omitempty"`
	CheckedAt     time.Time `json:"checkedAt"`
}

// ErrNotAuthenticated is returned by RunTask callers when the SDK reports no
// authenticated user. Distinct from runtime errors so the caller can
// transition the task to failed(auth).
var ErrNotAuthenticated = fmt.Errorf("copilot: not authenticated")

// RuntimeConfig configures a Runtime.
type RuntimeConfig struct {
	// GitHubToken is a PAT. When non-empty it takes priority over the logged-in
	// user stored by the gh CLI / Copilot extension.
	GitHubToken string
	// LogLevel for the embedded CLI server ("error", "warn", "info", "debug").
	// Defaults to "error" to keep the application logs clean.
	LogLevel string
}

// Runtime owns the single SDK Client and its lifecycle. It is safe for
// concurrent use after Start returns. ReloadAuth atomically swaps the
// underlying client so concurrent callers always see a started client.
type Runtime struct {
	mu     sync.RWMutex
	cfg    RuntimeConfig
	client *copilot.Client

	login *LoginCoordinator // nil until Start wires it
}

// NewRuntime constructs a Runtime. The SDK client is created immediately but
// the underlying CLI process is not started until Start is called.
func NewRuntime(cfg RuntimeConfig) *Runtime {
	if cfg.LogLevel == "" {
		cfg.LogLevel = "error"
	}
	r := &Runtime{
		cfg:    cfg,
		client: newSDKClient(cfg),
	}
	r.login = NewLoginCoordinator(r)
	return r
}

// BeginLogin delegates to the login coordinator. See LoginCoordinator.Begin.
func (r *Runtime) BeginLogin(ctx context.Context) (LoginChallenge, error) {
	return r.login.Begin(ctx)
}

// CancelLogin delegates to the login coordinator. See LoginCoordinator.Cancel.
func (r *Runtime) CancelLogin() { r.login.Cancel() }

// LoginSession returns the current login subprocess state. See
// LoginCoordinator.Session for the semantics; the UI polls this to drive
// the sign-in dialog without racing on stale SDK auth state.
func (r *Runtime) LoginSession() LoginSessionSnapshot { return r.login.Session() }

// newSDKClient builds a copilot.Client from cfg. Separated from NewRuntime
// so ReloadAuth can rebuild under lock.
func newSDKClient(cfg RuntimeConfig) *copilot.Client {
	opts := &copilot.ClientOptions{
		LogLevel:        cfg.LogLevel,
		UseLoggedInUser: copilot.Bool(true),
	}
	if cfg.GitHubToken != "" {
		opts.GitHubToken = cfg.GitHubToken
		// When a PAT is explicit we do not want to mix in stored credentials.
		opts.UseLoggedInUser = copilot.Bool(false)
	}
	return copilot.NewClient(opts)
}

// Start connects to the embedded CLI server. The embedded CLI binary must have
// been registered by embeddedcli.Setup (called from the bundler-generated
// init() in cmd/fleetkanban-sidecar). This call blocks until the server is ready.
func (r *Runtime) Start(ctx context.Context) error {
	r.mu.RLock()
	c := r.client
	r.mu.RUnlock()
	return c.Start(ctx)
}

// Stop disconnects all sessions and shuts down the CLI server.
func (r *Runtime) Stop() {
	r.mu.RLock()
	c := r.client
	r.mu.RUnlock()
	_ = c.Stop()
}

// Client exposes the underlying SDK client for session creation. Callers that
// hold the returned pointer across a ReloadAuth may see a stopped client; the
// orchestrator acquires a fresh client at the start of each task via Client().
func (r *Runtime) Client() *copilot.Client {
	r.mu.RLock()
	defer r.mu.RUnlock()
	return r.client
}

// ReloadAuth swaps the SDK client's auth credentials at runtime: the old
// client is stopped and a new one constructed with the given token, then
// started. In-flight sessions on the old client are terminated abruptly —
// callers should avoid calling ReloadAuth while tasks are running.
//
// An empty token means "fall back to the CLI-logged-in user" (UseLoggedInUser).
func (r *Runtime) ReloadAuth(ctx context.Context, token string) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	// Stop the old client first so the CLI server exits cleanly.
	_ = r.client.Stop()
	r.cfg.GitHubToken = token
	next := newSDKClient(r.cfg)
	if err := next.Start(ctx); err != nil {
		// Best-effort recovery: restart the previous client so the runtime
		// stays usable. If that also fails, surface the original error.
		r.client = newSDKClient(r.cfg)
		_ = r.client.Start(ctx)
		return fmt.Errorf("copilot: reload auth: %w", err)
	}
	r.client = next
	return nil
}

// Model is the per-entry shape returned by Runtime.ListModels — a trimmed
// projection of the SDK's ModelInfo containing only the fields the
// Settings picker needs (ID for selection, Name for display, Multiplier
// for the Free/Premium badge). Defined here rather than re-exposing the
// SDK type so the proto/IPC layer never depends on copilot-sdk internals.
type Model struct {
	ID         string
	Name       string
	Multiplier float64
}

// ListModels returns the catalog the embedded CLI server reports as
// available for the current authenticated user. Callers use this to
// populate the Settings UI's model picker so we never offer an ID that the
// server will later reject with "Model X is not available". Multiplier
// drives the picker's "Free" (== 0) vs "Premium ×N" (>= 1) badge so the
// user can pick a model with full awareness of premium-request cost.
func (r *Runtime) ListModels(ctx context.Context) ([]Model, error) {
	r.mu.RLock()
	c := r.client
	r.mu.RUnlock()
	infos, err := c.ListModels(ctx)
	if err != nil {
		return nil, fmt.Errorf("copilot: list models: %w", err)
	}
	models := make([]Model, 0, len(infos))
	for _, m := range infos {
		if m.ID == "" {
			continue
		}
		mult := 0.0
		if m.Billing != nil {
			mult = m.Billing.Multiplier
		}
		models = append(models, Model{
			ID:         m.ID,
			Name:       m.Name,
			Multiplier: mult,
		})
	}
	return models, nil
}

// CheckAuth uses auth.getStatus (a side-effect-free RPC call introduced by the
// SDK) to determine whether the user is authenticated. It requires the client
// to already be started.
func (r *Runtime) CheckAuth(ctx context.Context) (AuthStatus, error) {
	r.mu.RLock()
	c := r.client
	r.mu.RUnlock()

	now := time.Now().UTC()
	resp, err := c.GetAuthStatus(ctx)
	if err != nil {
		return AuthStatus{
			Authenticated: false,
			Message:       fmt.Sprintf("auth status check failed: %v", err),
			CheckedAt:     now,
		}, nil
	}
	st := AuthStatus{
		Authenticated: resp.IsAuthenticated,
		CheckedAt:     now,
	}
	if resp.Login != nil {
		st.User = *resp.Login
	}
	if resp.StatusMessage != nil && !resp.IsAuthenticated {
		st.Message = *resp.StatusMessage
	}
	return st, nil
}

// githubDeviceURL is the standing URL users visit to enter the device code
// emitted by the Copilot CLI's /login. Opening it proactively from the app
// removes the "look at the URL in the terminal, then type it into a browser"
// step so the UX is closer to a native OAuth dialog.
// LaunchLogout opens an interactive terminal running the embedded Copilot
// CLI so the user can type "/logout". The CLI has no headless logout
// subcommand, so this interactive path is still required for sign-out; the
// corresponding login flow has been replaced by LoginCoordinator.Begin,
// which runs `copilot login` headless and drives the UI with a proper
// dialog (no terminal window required for sign-in).
func (r *Runtime) LaunchLogout(_ context.Context) error {
	return r.launchInteractive("FleetKanban: Copilot /logout")
}

// openURLInBrowser shells out to `cmd /c start <url>` to open the user's
// default browser. We go through cmd.exe's built-in `start` because it
// resolves URL protocol handlers correctly and does not block. The first
// "" is the window-title argument `start` expects when the target is quoted.
func openURLInBrowser(url string) error {
	if err := startDetached(false, "", "cmd.exe", "/c", "start", "", url); err != nil {
		return fmt.Errorf("copilot: open browser: %w", err)
	}
	return nil
}

// launchInteractive spawns Windows Terminal (or plain cmd.exe as a
// fallback) with the embedded Copilot CLI attached. Used by LaunchLogout;
// the login flow is handled headless by LoginCoordinator.Begin and does
// not spawn a terminal at all.
//
// The spawned terminal's working directory is forced to the user's home
// directory. Without this, the terminal (and the Copilot CLI inside it)
// would inherit the sidecar's cwd — which is whatever the Flutter UI was
// launched with (e.g. `...\build\windows\x64\runner\Debug`) — and the
// CLI would treat that path as the "project" under analysis. User home is
// a neutral, predictable location for auth-only sessions.
func (r *Runtime) launchInteractive(title string) error {
	cliPath := resolveCLIPath()
	if cliPath == "" {
		return fmt.Errorf("copilot: no CLI binary available for login")
	}
	home, _ := os.UserHomeDir() // empty on failure — startDetached ignores empty Dir

	// On Windows 11, `wt.exe` under %LOCALAPPDATA%\Microsoft\WindowsApps\ is
	// a zero-byte App Execution Alias (a reparse point the Store installs).
	// Go's os/exec fork/exec cannot traverse those aliases — the system
	// surfaces it as "Access is denied" — but cmd.exe's `start` built-in
	// resolves them correctly because it goes through the shell. So we
	// always go through cmd.exe here. The first `""` is the (empty) window
	// title argument that `start` expects when the next token is quoted.
	if _, wtErr := exec.LookPath("wt.exe"); wtErr == nil {
		args := []string{"/c", "start", "", "wt.exe", "new-tab"}
		if home != "" {
			// wt.exe ignores the caller's cwd for new tabs unless we pass
			// --startingDirectory explicitly. Setting cmd.exe's cwd (below)
			// is not enough for this path.
			args = append(args, "--startingDirectory", home)
		}
		args = append(args, "--title", title, cliPath)
		if err := startDetached(true, home, "cmd.exe", args...); err != nil {
			return fmt.Errorf("copilot: launch via wt.exe: %w", err)
		}
		return nil
	}

	if err := startDetached(true, home, "cmd.exe", "/c",
		"start", "", "cmd", "/k", cliPath); err != nil {
		return fmt.Errorf("copilot: launch via cmd start: %w", err)
	}
	return nil
}

// startDetached launches `name args...` with a new process group (and, for
// interactive terminals, a new console) and detaches it from the parent's
// Win32 Job Object via CREATE_BREAKAWAY_FROM_JOB so the child outlives
// FleetKanban. When dir is non-empty, the child's working directory is set
// to dir; otherwise it inherits from the sidecar.
//
// Deliberately uses exec.Command (not exec.CommandContext): the spawned
// process must outlive the gRPC request that triggered it. Binding to the
// request ctx would cause Go's exec package to TerminateProcess on cmd.exe
// as soon as the RPC response is sent — which, in practice, happens before
// cmd.exe's `start` built-in has had time to launch wt.exe, so the user
// sees no terminal window and no error (the "ボタンを押しても何もならない"
// symptom).
//
// If the parent Job lacks JOB_OBJECT_LIMIT_BREAKAWAY_OK the kernel returns
// ERROR_ACCESS_DENIED from CreateProcess; in that case we retry without the
// breakaway bit. The child then stays in the Job and gets torn down with
// the UI, which is not ideal (the /login terminal closes when the user
// quits FleetKanban mid-flow) but is strictly better than the operation
// failing outright. The Flutter runner should set BREAKAWAY_OK on the Job
// (see ui/windows/runner/main.cpp) so the fallback is only reached under
// unusual hosting scenarios.
func startDetached(newConsole bool, dir, name string, args ...string) error {
	base := uint32(windows.CREATE_NEW_PROCESS_GROUP)
	if newConsole {
		base |= windows.CREATE_NEW_CONSOLE
	}

	try := func(flags uint32) error {
		cmd := exec.Command(name, args...)
		cmd.SysProcAttr = &syscall.SysProcAttr{CreationFlags: flags}
		cmd.Dir = dir
		if err := cmd.Start(); err != nil {
			return err
		}
		go func() { _ = cmd.Wait() }()
		return nil
	}

	err := try(base | windows.CREATE_BREAKAWAY_FROM_JOB)
	if err == nil {
		return nil
	}
	if !errors.Is(err, windows.ERROR_ACCESS_DENIED) {
		return err
	}
	// Job refused the breakaway. Retry without it — the child joins the
	// parent Job instead of running free, which is acceptable for a
	// one-off interactive terminal.
	return try(base)
}

// NewRunner constructs a Runner that uses this Runtime's Client.
func (r *Runtime) NewRunner(cfg RunnerConfig) (*Runner, error) {
	r.mu.RLock()
	c := r.client
	r.mu.RUnlock()
	return newRunner(c, cfg)
}

// resolveCLIPath returns the path to the Copilot CLI binary.
//
// Priority:
//  1. COPILOT_CLI_PATH environment variable (explicit override)
//  2. The versioned binary installed by the bundler in the user cache dir
//     (copilot-sdk subdirectory, matching the embeddedcli install convention)
//  3. "copilot" / "copilot.exe" on PATH
func resolveCLIPath() string {
	if p := os.Getenv("COPILOT_CLI_PATH"); p != "" {
		return p
	}

	// The bundler installs into <UserCacheDir>/copilot-sdk/copilot_<ver>.exe
	// (or copilot.exe when no version suffix). Scan the directory for any
	// copilot*.exe and return the first match.
	if cacheDir, err := os.UserCacheDir(); err == nil {
		sdkDir := filepath.Join(cacheDir, "copilot-sdk")
		if entries, err := os.ReadDir(sdkDir); err == nil {
			for _, e := range entries {
				name := e.Name()
				if !e.IsDir() && (name == "copilot.exe" || (len(name) > 12 && name[:7] == "copilot" && filepath.Ext(name) == ".exe")) {
					return filepath.Join(sdkDir, name)
				}
			}
		}
	}

	if p, err := exec.LookPath("copilot"); err == nil {
		return p
	}
	return ""
}
