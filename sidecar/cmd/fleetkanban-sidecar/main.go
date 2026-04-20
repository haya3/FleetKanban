//go:build windows

// Command fleetkanban-sidecar is the headless gRPC backend that the Flutter UI
// spawns as a child process. The UI side owns all window / DWM concerns;
// this binary has no window of its own.
//
// Protocol:
//
//  1. The parent (Flutter) starts this binary with --port=0 (default) and an
//     optional --log-level flag.
//  2. The sidecar listens on 127.0.0.1 on an OS-assigned port and emits a
//     single handshake line on stdout:
//     READY port=<N> token=<base64>\n
//     Any log output before the handshake line goes to stderr.
//  3. All gRPC calls MUST carry metadata "x-auth-token: <token>" matching the
//     handshake value, otherwise they receive PermissionDenied.
//  4. Shutdown is graceful: the parent calls SystemService.Shutdown, which
//     triggers graceful gRPC stop; if that does not return within 10s the
//     parent's Windows Job Object will kill the process.
//
// Only one sidecar per user may run at a time; the second instance exits
// immediately with a non-zero status to avoid two processes contending for
// the SQLite DB file.
package main

import (
	"context"
	"crypto/rand"
	"encoding/base64"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"log/slog"
	"net"
	"os"
	"path/filepath"
	"sync"
	"syscall"
	"time"

	"golang.org/x/sys/windows"
	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"

	"github.com/FleetKanban/fleetkanban/internal/app"
	"github.com/FleetKanban/fleetkanban/internal/branding"
	"github.com/FleetKanban/fleetkanban/internal/copilot"
	"github.com/FleetKanban/fleetkanban/internal/ipc"
	"github.com/FleetKanban/fleetkanban/internal/orchestrator"
	"github.com/FleetKanban/fleetkanban/internal/reaper"
	"github.com/FleetKanban/fleetkanban/internal/store"
	"github.com/FleetKanban/fleetkanban/internal/task"
	"github.com/FleetKanban/fleetkanban/internal/winapi"
	"github.com/FleetKanban/fleetkanban/internal/worktree"

	pb "github.com/FleetKanban/fleetkanban/internal/ipc/gen/fleetkanban/v1"
)

func main() {
	var (
		port     int
		logLevel string
	)
	flag.IntVar(&port, "port", 0, "TCP port to listen on (0 = OS-assigned)")
	flag.StringVar(&logLevel, "log-level", "info", "slog level: debug|info|warn|error")
	flag.Parse()

	// Log to stderr so stdout is reserved for the handshake line only.
	var lvl slog.Level
	_ = lvl.UnmarshalText([]byte(logLevel))
	logger := slog.New(slog.NewTextHandler(os.Stderr, &slog.HandlerOptions{Level: lvl}))
	slog.SetDefault(logger)

	if err := run(context.Background(), logger, port); err != nil {
		logger.Error("fatal", "err", err)
		os.Exit(1)
	}
}

func run(parent context.Context, log *slog.Logger, port int) error {
	// Single-instance guard: a named mutex scoped to the current user prevents
	// two sidecars from contending for the SQLite DB. Release on exit.
	rel, held, err := acquireSingletonMutex()
	if err != nil {
		return fmt.Errorf("singleton mutex: %w", err)
	}
	if !held {
		return errors.New("another fleetkanban-sidecar is already running")
	}
	defer rel()

	// Set AUMID so any Toast emitted by the orchestrator is grouped under the
	// Flutter UI's taskbar entry.
	if err := winapi.SetAppUserModelID(branding.AUMID); err != nil {
		log.Warn("SetAppUserModelID", "err", err)
	}

	paths, err := resolvePaths()
	if err != nil {
		return fmt.Errorf("resolve paths: %w", err)
	}
	log.Info("paths", "data", paths.DataDir, "db", paths.DB)

	// --- Backend wiring ------------------------------------------------------

	db, err := store.Open(parent, store.Options{Path: paths.DB})
	if err != nil {
		return fmt.Errorf("open db: %w", err)
	}
	// WAL teardown on exit: Close performs a passive checkpoint so the
	// -wal / -shm sidecar files collapse back into the main DB. Keeps
	// recovery tooling clean and avoids the on-disk residue every run
	// otherwise accumulated.
	defer func() { _ = db.Close() }()

	wtMgr, err := worktree.NewManager(worktree.Options{FallbackRoot: paths.Worktrees})
	if err != nil {
		return fmt.Errorf("worktree manager: %w", err)
	}

	secretsDir := filepath.Join(paths.DataDir, "secrets")
	secrets, err := app.NewDPAPISecretStore(secretsDir)
	if err != nil {
		return fmt.Errorf("secrets: %w", err)
	}
	var initialToken string
	if tok, tokErr := secrets.GetGitHubToken(); tokErr != nil {
		log.Warn("secrets: read GitHub PAT", "err", tokErr)
	} else if tok != "" {
		// Stored tokens may predate ValidateGitHubToken (e.g. a classic
		// `ghp_` PAT saved before the SDK allow-list was enforced).
		// Silently passing such a token to the SDK would produce opaque
		// auth failures at first RPC. Instead, clear it here, log loudly,
		// and start with UseLoggedInUser. The UI will show "未認証" and the
		// user can re-enter a supported token (gho_ / ghu_ / github_pat_).
		if vErr := app.ValidateGitHubToken(tok); vErr != nil {
			prefix := tok
			if len(prefix) > 4 {
				prefix = prefix[:4]
			}
			log.Warn(
				"secrets: stored GitHub token has unsupported prefix; clearing it",
				"prefix", prefix+"…", "err", vErr)
			if clrErr := secrets.SetGitHubToken(""); clrErr != nil {
				log.Warn("secrets: clear unsupported token", "err", clrErr)
			}
		} else {
			initialToken = tok
		}
	}

	rt := copilot.NewRuntime(copilot.RuntimeConfig{
		LogLevel:    "error",
		GitHubToken: initialToken,
	})
	if err := rt.Start(parent); err != nil {
		return fmt.Errorf("copilot runtime: %w", err)
	}
	runner, err := rt.NewRunner(copilot.RunnerConfig{})
	if err != nil {
		rt.Stop()
		return fmt.Errorf("copilot runner: %w", err)
	}

	repoAdapter := &app.RepositoryAdapter{Store: store.NewRepositoryStore(db)}

	// Event broker fans orchestrator events out to WatchEvents subscribers.
	broker := ipc.NewEventBroker(0 /* default buffer */)

	// AI Reviewer uses the same Copilot runtime as the runner. When the
	// reviewer fails to initialize (no auth, offline, model list failure),
	// we fall back to a nil interface — the orchestrator's pass-through
	// path keeps the pipeline functional and logs the reason once.
	//
	// The local var is typed as the interface so that a nil assignment
	// produces a true-nil interface (avoiding Go's "typed nil" gotcha
	// where (*T)(nil) != interface{}(nil) in reflection-aware code paths).
	var reviewer orchestrator.AIReviewer
	if rv, rerr := rt.NewReviewer(context.Background(), ""); rerr != nil {
		log.Warn("copilot: reviewer init failed; using pass-through", "err", rerr)
	} else {
		reviewer = rv
	}

	// Planner decomposes the task into a Subtask DAG on first run. Nil
	// interface on init failure keeps the orchestrator running without the
	// planning phase (tasks go straight from queued → in_progress).
	var planner orchestrator.Planner
	if pl, perr := rt.NewPlanner(context.Background(), ""); perr != nil {
		log.Warn("copilot: planner init failed; planning phase disabled", "err", perr)
	} else {
		planner = pl
	}

	subtaskStore := store.NewSubtaskStore(db)

	orchCfg := orchestrator.Config{
		TaskStore:    store.NewTaskStore(db),
		EventStore:   store.NewEventStore(db),
		Repositories: repoAdapter,
		Worktrees:    wtMgr,
		Runner:       runner,
		Reviewer:     reviewer,
		Planner:      planner,
		SubtaskStore: subtaskStore,
		Logger:       log.With("component", "orch"),
		Sink:         broker.Sink(),
		Notifier: func(n orchestrator.Notification) {
			go func() {
				title, body := buildToastContent(n)
				if err := winapi.ShowToast(winapi.Toast{Title: title, Body: body}); err != nil {
					log.Warn("ShowToast", "task", n.TaskID, "err", err)
				}
			}()
		},
	}
	orch, err := orchestrator.New(orchCfg)
	if err != nil {
		rt.Stop()
		return fmt.Errorf("orchestrator: %w", err)
	}

	svc, err := app.New(app.Config{
		DB:           db,
		Orchestrator: orch,
		Worktrees:    wtMgr,
		Runtime:      rt,
		Secrets:      secrets,
		Publish:      broker.Sink(),
		Logger:       log.With("component", "app"),
	})
	if err != nil {
		rt.Stop()
		return fmt.Errorf("service: %w", err)
	}

	// --- One-time startup housekeeping (identical to legacy main) -----------

	if gitCfg, gitErr := wtMgr.CheckGlobalConfig(parent); gitErr != nil {
		log.Warn("git config check", "err", gitErr)
	} else if !gitCfg.OK() {
		log.Warn("git config: required knobs not set",
			"core.longpaths", gitCfg.LongPathsVal, "core.autocrlf", gitCfg.AutoCRLFVal,
			"hint", `git config --global core.longpaths true && git config --global core.autocrlf false`)
	}
	if jlErr := svc.RefreshJumpList(parent); jlErr != nil {
		log.Warn("jump list refresh", "err", jlErr)
	}
	if initialAuth, authErr := rt.CheckAuth(parent); authErr != nil {
		log.Warn("copilot auth check", "err", authErr)
	} else {
		log.Info("copilot auth",
			"authenticated", initialAuth.Authenticated,
			"user", initialAuth.User,
			"message", initialAuth.Message)
	}

	taskStore := store.NewTaskStore(db)
	if recovered, rerr := taskStore.RecoverRunning(parent); rerr != nil {
		log.Warn("crash recovery", "err", rerr)
	} else if len(recovered) > 0 {
		log.Info("crash recovery: marked interrupted", "count", len(recovered), "ids", recovered)
	}
	settingsStore := store.NewSettingsStore(db)
	rpr, rerr := reaper.New(reaper.Config{
		Repositories: store.NewRepositoryStore(db),
		Tasks:        taskStore,
		Events:       store.NewEventStore(db),
		Worktrees:    wtMgr,
		ArchiveDir:   filepath.Join(paths.DataDir, "archive"),
		Logger:       log.With("component", "reaper"),
	})
	if rerr != nil {
		log.Warn("reaper init", "err", rerr)
		rpr = nil
	} else {
		runHousekeeping(parent, rpr, settingsStore, log)
	}

	// --- gRPC server --------------------------------------------------------

	listener, err := net.Listen("tcp", fmt.Sprintf("127.0.0.1:%d", port))
	if err != nil {
		rt.Stop()
		return fmt.Errorf("listen: %w", err)
	}

	token, err := randomToken()
	if err != nil {
		_ = listener.Close()
		rt.Stop()
		return fmt.Errorf("random token: %w", err)
	}

	unaryAuth, streamAuth := ipc.TokenInterceptors(token)
	copilotGate := ipc.CopilotAuthGateUnary(rt)
	grpcServer := grpc.NewServer(
		grpc.UnaryInterceptor(ipc.ChainUnary(unaryAuth, copilotGate)),
		grpc.StreamInterceptor(streamAuth),
	)

	var shutOnce sync.Once
	shutdownCh := make(chan struct{})

	// --- Housekeeping ticker (phase1-spec §3.1) ----------------------------
	// Reaper passes re-run every 24h in addition to the startup invocation so
	// the Merged-sweep (opt-in) and event archiving keep up with long-running
	// sessions. The goroutine exits on graceful shutdown or parent-ctx cancel.
	if rpr != nil {
		go func() {
			t := time.NewTicker(24 * time.Hour)
			defer t.Stop()
			for {
				select {
				case <-t.C:
					runHousekeeping(parent, rpr, settingsStore, log)
				case <-shutdownCh:
					return
				case <-parent.Done():
					return
				}
			}
		}()
	}

	var housekeepingDeps *ipc.HousekeepingDeps
	if rpr != nil {
		housekeepingDeps = &ipc.HousekeepingDeps{
			Settings:  settingsStore,
			Reaper:    rpr,
			Tasks:     taskStore,
			Repos:     store.NewRepositoryStore(db),
			Worktrees: wtMgr,
		}
	}

	ipcServer, err := ipc.NewServer(ipc.ServerConfig{
		App:          svc,
		Broker:       broker,
		Housekeeping: housekeepingDeps,
		ShutdownHook: func(ctx context.Context) error {
			// SystemService.Shutdown → trigger graceful close. We close the
			// channel and return immediately so the client does not block on
			// the teardown.
			shutOnce.Do(func() { close(shutdownCh) })
			return nil
		},
	})
	if err != nil {
		_ = listener.Close()
		rt.Stop()
		return fmt.Errorf("ipc server: %w", err)
	}

	pb.RegisterTaskServiceServer(grpcServer, ipcServer)
	pb.RegisterSubtaskServiceServer(grpcServer, ipcServer)
	pb.RegisterRepositoryServiceServer(grpcServer, ipcServer)
	pb.RegisterAuthServiceServer(grpcServer, ipcServer)
	pb.RegisterSystemServiceServer(grpcServer, ipcServer)
	pb.RegisterWorktreeServiceServer(grpcServer, ipcServer)
	pb.RegisterModelServiceServer(grpcServer, ipcServer)
	pb.RegisterHousekeepingServiceServer(grpcServer, ipcServer)
	pb.RegisterInsightsServiceServer(grpcServer, ipcServer)

	// Reflection lets grpcurl / Flutter devtools introspect services at runtime
	// without shipping the .proto files. The sidecar is loopback-only so the
	// schema exposure has no attack surface.
	reflection.Register(grpcServer)

	// Emit the single-line handshake on stdout. Unbuffered println to avoid
	// the parent deadlocking while reading. After this line, stdout is unused.
	assignedPort := listener.Addr().(*net.TCPAddr).Port
	fmt.Printf("READY port=%d token=%s\n", assignedPort, token)
	log.Info("gRPC server listening", "port", assignedPort)

	// Also persist the endpoint so a fresh Flutter process (e.g. after a
	// hot restart or crash recovery) can discover and reuse this sidecar
	// instead of spawning a second one that immediately deadlocks against
	// the singleton mutex. Best-effort: failures are logged, not fatal.
	endpointPath := filepath.Join(paths.DataDir, "sidecar-endpoint.json")
	if err := writeEndpointFile(endpointPath, assignedPort, token); err != nil {
		log.Warn("endpoint file write", "path", endpointPath, "err", err)
	} else {
		defer func() {
			if err := os.Remove(endpointPath); err != nil && !errors.Is(err, os.ErrNotExist) {
				log.Warn("endpoint file remove", "err", err)
			}
		}()
	}

	// Serve in a goroutine so we can also watch for Shutdown requests.
	serveErr := make(chan error, 1)
	go func() {
		serveErr <- grpcServer.Serve(listener)
	}()

	select {
	case <-shutdownCh:
		log.Info("shutdown requested; stopping gRPC")
	case err := <-serveErr:
		if err != nil {
			log.Error("gRPC serve", "err", err)
		}
	}

	// Graceful stop with a 10s cap; fall back to hard stop if clients are
	// stuck.
	done := make(chan struct{})
	go func() {
		grpcServer.GracefulStop()
		close(done)
	}()
	select {
	case <-done:
	case <-time.After(10 * time.Second):
		log.Warn("graceful stop timed out; forcing")
		grpcServer.Stop()
	}

	// Tear down backend in the reverse order of startup.
	shutCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err := svc.Shutdown(shutCtx); err != nil {
		log.Warn("service shutdown", "err", err)
	}
	rt.Stop()
	return nil
}

// --- helpers ---------------------------------------------------------------

// runHousekeeping executes one pass of every reaper background job: orphan
// worktree cleanup, branch-existence refresh, event archiving, and the opt-in
// Merged-sweep (phase1-spec §3.1). Errors are logged rather than returned so
// callers inside a ticker keep running.
func runHousekeeping(
	ctx context.Context,
	rpr *reaper.Service,
	settings *store.SettingsStore,
	log *slog.Logger,
) {
	if stats, err := rpr.ReapOnce(ctx); err != nil {
		log.Warn("reaper: ReapOnce", "err", err, "stats", stats)
	} else if stats.WorktreesRemoved > 0 {
		log.Info("reaper: removed orphan worktrees", "count", stats.WorktreesRemoved)
	}
	if err := rpr.UpdateBranchExistence(ctx); err != nil {
		log.Warn("reaper: UpdateBranchExistence", "err", err)
	}
	if stats, err := rpr.ArchiveOldEvents(ctx, 0); err != nil {
		log.Warn("reaper: ArchiveOldEvents", "err", err, "stats", stats)
	} else if stats.TasksArchived > 0 {
		log.Info("reaper: archived old events",
			"tasks", stats.TasksArchived, "events", stats.EventsPurged)
	}
	days, _, err := settings.GetInt(ctx, reaper.SettingAutoSweepMergedDays, 0)
	if err != nil {
		log.Warn("reaper: read auto_sweep_merged_days", "err", err)
	} else if days > 0 {
		stats, sweepErr := rpr.SweepMergedBranches(ctx, time.Duration(days)*24*time.Hour)
		if sweepErr != nil {
			log.Warn("reaper: SweepMergedBranches", "err", sweepErr, "stats", stats)
		} else if stats.BranchesDeleted > 0 {
			log.Info("reaper: swept merged branches",
				"deleted", stats.BranchesDeleted,
				"skipped", stats.BranchesSkipped,
				"considered", stats.Considered)
		}
	}
}

type paths struct {
	DataDir   string
	DB        string
	Worktrees string
}

func resolvePaths() (paths, error) {
	root, err := os.UserConfigDir()
	if err != nil {
		return paths{}, err
	}
	base := filepath.Join(root, branding.DataDirName)
	if isUNC(base) {
		local, lerr := os.UserCacheDir()
		if lerr == nil {
			base = filepath.Join(local, branding.DataDirName)
		}
	}
	return paths{
		DataDir:   base,
		DB:        filepath.Join(base, branding.DBFileName),
		Worktrees: filepath.Join(base, "worktrees"),
	}, nil
}

func isUNC(p string) bool {
	return len(p) >= 2 && p[0] == '\\' && p[1] == '\\'
}

func randomToken() (string, error) {
	var b [32]byte
	if _, err := rand.Read(b[:]); err != nil {
		return "", err
	}
	return base64.RawURLEncoding.EncodeToString(b[:]), nil
}

// acquireSingletonMutex creates (or opens) a per-user named mutex. Returns a
// release callback, a held flag (false if another process already owns it),
// and any creation error. The mutex name is prefixed with "Local\" so it is
// scoped to the current session (not Global) — we do not want two users to
// contend on a single machine.
func acquireSingletonMutex() (release func(), held bool, err error) {
	name, err := syscall.UTF16PtrFromString(`Local\FleetKanban_Sidecar_Singleton`)
	if err != nil {
		return nil, false, err
	}
	h, err := windows.CreateMutex(nil, true, name)
	if err != nil {
		// If the mutex already exists and is owned, CreateMutex returns a
		// valid handle plus ERROR_ALREADY_EXISTS. We still need to close the
		// handle in that case.
		if errors.Is(err, windows.ERROR_ALREADY_EXISTS) && h != 0 {
			windows.CloseHandle(h)
			return nil, false, nil
		}
		return nil, false, fmt.Errorf("CreateMutex: %w", err)
	}
	release = func() {
		windows.ReleaseMutex(h)
		windows.CloseHandle(h)
	}
	return release, true, nil
}

// writeEndpointFile atomically writes the handshake details so a newly-
// starting UI process can reconnect to this sidecar without going through
// Process.start / stdout parsing. Written to a temp file first, then
// renamed so a partial read never surfaces a truncated token.
func writeEndpointFile(path string, port int, token string) error {
	payload := struct {
		Port      int    `json:"port"`
		Token     string `json:"token"`
		PID       int    `json:"pid"`
		StartedAt int64  `json:"started_at"`
	}{
		Port:      port,
		Token:     token,
		PID:       os.Getpid(),
		StartedAt: time.Now().Unix(),
	}
	data, err := json.Marshal(payload)
	if err != nil {
		return err
	}
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return err
	}
	tmp := path + ".tmp"
	if err := os.WriteFile(tmp, data, 0o600); err != nil {
		return err
	}
	return os.Rename(tmp, path)
}

// buildToastContent formats the notification payload for Windows toast
// delivery. Kept local so the orchestrator stays UI-agnostic.
func buildToastContent(n orchestrator.Notification) (title, body string) {
	goal := truncateRune(n.Goal, 60)
	switch n.Status {
	case task.StatusHumanReview:
		return branding.AppName + ": レビュー待ち", goal
	case task.StatusDone:
		return branding.AppName + ": 完了", goal
	case task.StatusAborted:
		return branding.AppName + ": 中断", goal
	case task.StatusFailed:
		msg := truncateRune(n.Err, 80)
		if msg == "" {
			msg = "タスクが失敗しました"
		}
		return branding.AppName + ": 失敗", goal + "\n" + msg
	default:
		return branding.AppName, goal
	}
}

func truncateRune(s string, n int) string {
	r := []rune(s)
	if len(r) <= n {
		return s
	}
	return string(r[:n]) + "…"
}
