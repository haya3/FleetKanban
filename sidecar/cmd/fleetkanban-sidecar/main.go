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
	"crypto/sha256"
	"database/sql"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"log/slog"
	"net"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"sync/atomic"
	"syscall"
	"time"

	"golang.org/x/sys/windows"
	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"

	"github.com/haya3/fleetkanban/internal/app"
	"github.com/haya3/fleetkanban/internal/branding"
	"github.com/haya3/fleetkanban/internal/copilot"
	"github.com/haya3/fleetkanban/internal/ctxmem"
	ctxanalyzer "github.com/haya3/fleetkanban/internal/ctxmem/analyzer"
	ctxcodegraph "github.com/haya3/fleetkanban/internal/ctxmem/codegraph"
	ctxembed "github.com/haya3/fleetkanban/internal/ctxmem/embed"
	ctxgraph "github.com/haya3/fleetkanban/internal/ctxmem/graph"
	ctxinject "github.com/haya3/fleetkanban/internal/ctxmem/inject"
	ctxobserver "github.com/haya3/fleetkanban/internal/ctxmem/observer"
	ctxpromo "github.com/haya3/fleetkanban/internal/ctxmem/promotion"
	ctxretrieval "github.com/haya3/fleetkanban/internal/ctxmem/retrieval"
	ctxstore "github.com/haya3/fleetkanban/internal/ctxmem/store"
	ctxsvc "github.com/haya3/fleetkanban/internal/ctxmem/svc"
	"github.com/haya3/fleetkanban/internal/ihr"
	"github.com/haya3/fleetkanban/internal/ipc"
	"github.com/haya3/fleetkanban/internal/orchestrator"
	"github.com/haya3/fleetkanban/internal/reaper"
	"github.com/haya3/fleetkanban/internal/runstate"
	"github.com/haya3/fleetkanban/internal/store"
	"github.com/haya3/fleetkanban/internal/task"
	"github.com/haya3/fleetkanban/internal/winapi"
	"github.com/haya3/fleetkanban/internal/worktree"

	pb "github.com/haya3/fleetkanban/internal/ipc/gen/fleetkanban/v1"
)

func main() {
	var (
		port     int
		logLevel string
	)
	flag.IntVar(&port, "port", 0, "TCP port to listen on (0 = OS-assigned)")
	flag.StringVar(&logLevel, "log-level", "info", "slog level: debug|info|warn|error")
	flag.Parse()

	// Log to stderr AND to a rolling file so planning / execution
	// traces can be tailed after the fact without relying on the UI's
	// in-memory ring buffer. stderr remains authoritative (stdout
	// stays reserved for the single handshake line); the file is a
	// passive mirror that callers can open with any text editor.
	var lvl slog.Level
	_ = lvl.UnmarshalText([]byte(logLevel))

	var logWriter io.Writer = os.Stderr
	if appData := os.Getenv("APPDATA"); appData != "" {
		logDir := filepath.Join(appData, branding.DataDirName, "logs")
		if err := os.MkdirAll(logDir, 0o755); err == nil {
			logPath := filepath.Join(logDir, "sidecar.log")
			if f, ferr := os.OpenFile(logPath,
				os.O_CREATE|os.O_APPEND|os.O_WRONLY, 0o644); ferr == nil {
				logWriter = io.MultiWriter(os.Stderr, f)
			}
		}
	}
	logger := slog.New(slog.NewTextHandler(logWriter, &slog.HandlerOptions{Level: lvl}))
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
		// and start with UseLoggedInUser. The UI will show "unauthenticated"
		// and the user can re-enter a supported token (gho_ / ghu_ / github_pat_).
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

	// Build the SettingsLookup that planner / runner / reviewer call at
	// session creation to fold the user's prompt + language overrides
	// into their system messages. Reads directly from the SettingsStore
	// so we avoid a back-reference into app.Service (which depends on
	// rt itself, creating a cycle if we used Service here).
	settingsForRuntime := func(ctx context.Context) (copilot.AgentSettings, error) {
		ss := store.NewSettingsStore(db)
		var out copilot.AgentSettings
		var v string
		if _, err := ss.GetJSON(ctx, "agent.output_language", &v); err == nil {
			out.OutputLanguage = v
		}
		return out, nil
	}

	// --- Context / Graph Memory subsystem ---------------------------------
	//
	// ctxmem is wired into the Copilot runtime (for Passive prompt
	// injection) and into the ipc server (for the ContextService /
	// ScratchpadService / OllamaService RPCs). Failures here degrade
	// gracefully: on an unreachable Ollama / OpenAI the registry simply
	// has no provider for that repo, and retrieval short-circuits to
	// an empty response.
	ctxStores := ctxstore.New(dbAdapter{db})
	ctxChanges := ctxmem.NewChangeBroker(0)
	ctxRegistry := ctxembed.NewRegistry()
	ctxGraph := ctxgraph.New(ctxStores.Nodes, ctxStores.Edges, ctxStores.Closure, db.Write())
	ctxSearcher := ctxretrieval.New(ctxStores.Nodes, ctxStores.Vectors, ctxStores.FTS, ctxGraph, ctxRegistry)
	ctxBuilder := ctxinject.New(ctxStores.Settings, ctxStores.Nodes, ctxStores.Facts, ctxSearcher)
	ctxGate := ctxpromo.New(ctxStores.Scratchpad, ctxStores.Nodes, ctxStores.Settings)
	ctxOllama := ctxembed.NewOllamaAdmin("")

	// Analyzer wiring — one-shot Copilot session over the registered
	// repository's root, parsed into pending scratchpad entries the
	// user promotes manually. Built before ctxsvc.New so the facade
	// receives it wired.
	analyzerRunner := &copilotAnalyzerAdapter{
		repoStore: store.NewRepositoryStore(db),
		runtime:   nil, // populated after rt is constructed below
	}
	ctxAnalyzer := ctxanalyzer.New(
		analyzerRunner,
		ctxStores.Scratchpad,
		ctxStores.Settings,
		log.With("component", "ctxmem-analyzer"),
	)

	ctxCodeIndex := ctxcodegraph.New(ctxStores.Nodes, ctxStores.Edges,
		log.With("component", "ctxmem-codegraph"))
	ctxRepoLookup := &ctxRepoPathAdapter{repoStore: store.NewRepositoryStore(db)}

	ctxService := ctxsvc.New(ctxsvc.Config{
		Stores:    ctxStores,
		Graph:     ctxGraph,
		Search:    ctxSearcher,
		Inject:    ctxBuilder,
		Gate:      ctxGate,
		Registry:  ctxRegistry,
		Changes:   ctxChanges,
		Ollama:    ctxOllama,
		Analyzer:  ctxAnalyzer,
		CodeIndex: ctxCodeIndex,
		Repos:     ctxRepoLookup,
		Logger:    log.With("component", "ctxmem"),
	})

	// Persist the full prompt + injected context for every subtask run so
	// the UI's Subtask Summary dialog can surface "what exactly did the
	// agent see?" without re-simulating. The recorder fetches the active
	// harness version on each call so rows stay pinned to the SKILL.md
	// snapshot that was live at execution time.
	subtaskContextStore := store.NewSubtaskContextStore(db)
	harnessStoreForRecorder := store.NewHarnessSkillStore(db)
	contextRecorder := app.NewSubtaskContextRecorder(
		subtaskContextStore,
		harnessStoreForRecorder,
		log.With("component", "subtask_context"),
	)

	// charterHolder carries the current IHR charter between the startup
	// parse (below, around the skill-root bootstrap) and the hot-reload
	// callback wired to HarnessServer. Copilot runtime's StagePrompts
	// lookup reads from it on every session creation so planner /
	// runner / reviewer pick up UpdateSkill edits without restart.
	// nil until the charter is first parsed — ResolveStagePrompt treats
	// an empty lookup return as "fall back to Default*Prompt", which is
	// the right behaviour during the pre-parse window.
	var charterHolder atomic.Pointer[ihr.Charter]
	stagePromptLookup := func(stage string) string {
		return charterHolder.Load().PromptFor(stage)
	}

	rt := copilot.NewRuntime(copilot.RuntimeConfig{
		LogLevel:        "error",
		GitHubToken:     initialToken,
		Settings:        settingsForRuntime,
		Memory:          ctxService,
		ContextRecorder: contextRecorder,
		StagePrompts:    stagePromptLookup,
	})
	if err := rt.Start(parent); err != nil {
		return fmt.Errorf("copilot runtime: %w", err)
	}
	// Back-fill the analyzer adapter with the started runtime.
	analyzerRunner.runtime = rt
	runner, err := rt.NewRunner(copilot.RunnerConfig{})
	if err != nil {
		rt.Stop()
		return fmt.Errorf("copilot runner: %w", err)
	}

	repoAdapter := &app.RepositoryAdapter{Store: store.NewRepositoryStore(db)}

	// Event broker fans orchestrator events out to WatchEvents subscribers.
	broker := ipc.NewEventBroker(0 /* default buffer */)

	// Start the ctxmem observer — listens on the event broker and
	// writes co-access scratchpad candidates for tasks whose repo
	// has Memory enabled. Also invokes the LLM summarizer per-task
	// for Decision candidates. Runs for the sidecar's lifetime.
	decisionSummarizer := &observerDecisionSummarizer{
		runtime:  rt,
		settings: ctxStores.Settings,
		log:      log.With("component", "ctxmem-summarizer"),
	}
	ctxObserver := ctxobserver.New(
		ctxStores.Scratchpad,
		ctxStores.Settings,
		broker,
		&observerTaskLookup{store: store.NewTaskStore(db)},
		ctxChanges,
		decisionSummarizer,
		ctxStores.Nodes,
		log.With("component", "ctxmem-observer"),
	)
	go ctxObserver.Start(parent)
	defer ctxObserver.Close()

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

	// NLAH file-backed durable state (arXiv:2603.25723v1 Phase A).
	// runs/ is created on demand by InitTaskDir; NewWriter does no FS work.
	artifactStore := store.NewArtifactStore(db)
	runsDir := filepath.Join(paths.DataDir, "runs")
	rsWriter := runstate.NewWriter(artifactStore, runsDir, log.With("component", "runstate"))
	defer func() {
		if err := rsWriter.Close(); err != nil {
			log.Warn("runstate close", "err", err)
		}
	}()

	// NLAH Phase B: seed harness-skill/ from the embedded defaults on first
	// launch. Subsequent launches are a no-op when the directory is present,
	// so user edits are preserved. The returned path points to the active
	// SKILL.md; HarnessService reads it for GetActiveSkill fallback.
	skillRoot := filepath.Join(paths.DataDir, "harness-skill")
	if _, _, err := copilot.BootstrapHarnessSkill(parent, skillRoot, log.With("component", "harness-bootstrap")); err != nil {
		log.Warn("harness-skill bootstrap", "err", err)
	}

	// "Togarishi" Windows 11 native integrations: Terminal profile fragment
	// and taskbar jump list Tasks category.  Both are best-effort — a failure
	// here must never prevent the sidecar's primary gRPC function from starting.
	if err := winapi.EnsureTerminalFragment(skillRoot); err != nil {
		log.Warn("terminal fragment", "err", err)
	}
	if exePath, exeErr := os.Executable(); exeErr != nil {
		log.Warn("jump list: os.Executable", "err", exeErr)
	} else if err := winapi.RegisterJumpList(exePath); err != nil {
		log.Warn("jump list", "err", err)
	}

	// Parse the active SKILL.md so the orchestrator can consult charter
	// policy (max_rework_count etc.) at runtime, and so Copilot session
	// creation picks up the charter's per-stage prompts via
	// stagePromptLookup (captured by the Copilot runtime above). A
	// malformed or missing file is non-fatal — the orchestrator falls
	// back to its hardcoded constants when charter is nil, and
	// ResolveStagePrompt falls back to DefaultPlanPrompt / DefaultCodePrompt
	// / DefaultReviewPrompt.
	var charter *ihr.Charter
	if skillBytes, err := os.ReadFile(filepath.Join(skillRoot, "SKILL.md")); err == nil {
		if c, perr := ihr.ParseCharter(skillBytes); perr == nil {
			charter = c
			charterHolder.Store(c)
		} else {
			log.Warn("charter parse", "err", perr)
		}
	}

	// NLAH Phase C: attempt records for failed reviews. Orchestrator
	// writes a row per AI rework so the UI Proposals view can surface
	// recurring failure classes.
	harnessAttemptStoreForOrch := store.NewHarnessAttemptStore(db)

	// Self-evolution: wrap the Copilot runtime's SDK client in a
	// patch-proposer so the orchestrator can asynchronously ask the LLM
	// for a unified diff against SKILL.md after a failed review. A nil
	// evolver is a valid configuration — observations are still recorded
	// but no patch proposal is generated.
	var evolver *ihr.Evolver
	if sdkClient := rt.Client(); sdkClient != nil {
		if proposer, pErr := ihr.NewCopilotProposer(ihr.CopilotProposerConfig{
			Client: sdkClient,
			Logger: log.With("component", "evolver-proposer"),
		}); pErr != nil {
			log.Warn("evolver: proposer init failed; self-evolution disabled", "err", pErr)
		} else {
			evolver = ihr.NewEvolver(proposer, log.With("component", "evolver"))
		}
	}

	orchCfg := orchestrator.Config{
		TaskStore:       store.NewTaskStore(db),
		EventStore:      store.NewEventStore(db),
		Repositories:    repoAdapter,
		Worktrees:       wtMgr,
		Runner:          runner,
		Reviewer:        reviewer,
		Planner:         planner,
		SubtaskStore:    subtaskStore,
		Runstate:        rsWriter,
		Charter:         charter,
		HarnessAttempts: harnessAttemptStoreForOrch,
		Evolver:         evolver,
		TaskMirror:      ctxTaskMirror{svc: ctxService},
		Logger:          log.With("component", "orch"),
		Sink:            broker.Sink(),
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
		SkillRoot:    skillRoot,
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
		Publish:      broker.Sink(),
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
		App:           svc,
		Broker:        broker,
		Housekeeping:  housekeepingDeps,
		ContextMemory: ctxService,
		// Embedding credentials come from the user's global secret
		// store. Phase 1 leaves OpenAI / Ollama credentials outside
		// the DPAPI secret store so a first-time user can still run
		// with Ollama defaults; the Settings UI will wire a full
		// credential flow in a follow-up.
		OllamaBaseURL: "",
		OpenAIAPIKey:  "",
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
	pb.RegisterContextServiceServer(grpcServer, ipcServer)
	pb.RegisterScratchpadServiceServer(grpcServer, ipcServer)
	pb.RegisterOllamaServiceServer(grpcServer, ipcServer)

	// NLAH Phase A: file-backed durable artifacts exposed over gRPC.
	// ArtifactServer reads the artifact SQL table + streams file bytes
	// from <DataDir>/runs/<taskId>/ with root-containment checks.
	pb.RegisterArtifactServiceServer(grpcServer, ipc.NewArtifactServer(artifactStore))

	// NLAH Phase B: HarnessService exposes SKILL.md versioning + editing
	// over gRPC. Active SKILL.md is stored at skillRoot/SKILL.md; every
	// UpdateSkill writes a row into harness_skill_version (migration v16)
	// so ListSkillVersions / RollbackSkill can walk history without FK
	// sentinel rows in tasks/repositories.
	// Hot-reload: when the user edits SKILL.md via the UI (UpdateSkill /
	// RollbackSkill), HarnessServer calls back here with the freshly parsed
	// charter so the running orchestrator sees the new policy on the very
	// next stage transition — no sidecar restart required.
	harnessSkillStore := store.NewHarnessSkillStore(db)

	// Hand-edit drift detection. When the disk SKILL.md hash does not
	// match the most-recent harness_skill_version row, the Harness pane
	// in the UI (which reads from the DB via GetActiveSkill) and the
	// running orchestrator (which parsed the disk file above) are out
	// of sync. This happens whenever a user edits SKILL.md with a text
	// editor instead of going through HarnessService.UpdateSkill, and
	// the EDITING NOTE in SKILL.md warns about it — but nothing
	// actually surfaces the condition, so the divergence stays
	// invisible until the user notices their UI changes don't match
	// runtime behaviour. A startup WARN at least turns this from
	// "silent" into "there's a log line when someone goes looking".
	// We do NOT auto-reconcile either way: picking disk would clobber
	// UI-saved versions the user expects to be active; picking DB
	// would clobber hand-edits the user explicitly made. Forcing the
	// user to resolve via UpdateSkill / restart (their choice) keeps
	// intent explicit.
	checkHarnessDrift(parent, harnessSkillStore, skillRoot, log)

	harnessSrv := ipc.NewHarnessServer(harnessSkillStore, skillRoot,
		log.With("component", "harness-service"),
		func(c *ihr.Charter) {
			// Order matters: publish to the Copilot runtime's lookup
			// first so any session created between the two stores sees
			// the new prompts; orchestrator charter swap second.
			charterHolder.Store(c)
			orch.SetCharter(c)
		})
	pb.RegisterHarnessServiceServer(grpcServer, harnessSrv)
	// NLAH Phase C: HarnessAttemptService records structured REWORK events
	// and exposes approve/reject for the UI. LLM patch generation and
	// SKILL.md application are deferred to Phase C LLM integration. The
	// same store is shared with the orchestrator above so the server and
	// the writer observe identical rows.
	// Approve-to-apply wire: when the user clicks Approve on a proposal
	// that carries a non-empty proposed_patch, HarnessAttemptServer calls
	// through to harnessSrv.ApplyEvolverPatch so the patch is applied to
	// SKILL.md and a new version is published atomically with the
	// decision flip. Without this wire (applier = nil), Approve would
	// only record the decision and leave SKILL.md untouched — a state
	// that would strand the user halfway through the self-evolution loop.
	harnessAttemptStore := harnessAttemptStoreForOrch
	pb.RegisterHarnessAttemptServiceServer(grpcServer,
		ipc.NewHarnessAttemptServer(harnessAttemptStore, harnessSrv))

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

// checkHarnessDrift emits a WARN when the on-disk SKILL.md hash does not
// match the most-recent harness_skill_version row. See the call site for
// rationale; this function is side-effect-free beyond logging.
func checkHarnessDrift(ctx context.Context, versions *store.HarnessSkillStore, skillRoot string, log *slog.Logger) {
	skillMdPath := filepath.Join(skillRoot, "SKILL.md")
	diskBytes, err := os.ReadFile(skillMdPath)
	if err != nil {
		// Missing disk file is already handled by BootstrapHarnessSkill;
		// if we're here and the read failed it's either a permissions
		// problem or a race with external tooling — neither is something
		// this check can remediate. Logging once is enough.
		log.Warn("harness drift: cannot read SKILL.md for drift check",
			"path", skillMdPath, "err", err)
		return
	}
	diskHash := sha256Hex(diskBytes)

	latest, err := versions.Latest(ctx)
	if errors.Is(err, store.ErrNoSkillVersion) {
		// Brand-new install: DB has no rows yet. That's expected; the
		// first UpdateSkill through the UI will seed the table. No drift.
		return
	}
	if err != nil {
		log.Warn("harness drift: cannot query latest harness_skill_version",
			"err", err)
		return
	}
	if diskHash == latest.ContentHash {
		return // aligned — the common case
	}
	log.Warn("harness drift: disk SKILL.md does not match latest harness_skill_version — UI and runtime will disagree",
		"disk_hash", diskHash,
		"db_hash", latest.ContentHash,
		"db_created_at", latest.CreatedAt,
		"db_created_by", latest.CreatedBy,
		"hint", "resolve by either hitting Save in the Harness pane (commits disk → DB) or RollbackSkill to the DB version (commits DB → disk), then restart")
}

// sha256Hex returns the hex-encoded SHA-256 of b. Duplicates contentHash
// from internal/ipc to avoid importing that package just for the helper.
func sha256Hex(b []byte) string {
	sum := sha256.Sum256(b)
	return hex.EncodeToString(sum[:])
}

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
		return branding.AppName + ": Awaiting Review", goal
	case task.StatusDone:
		return branding.AppName + ": Done", goal
	case task.StatusAborted:
		return branding.AppName + ": Aborted", goal
	case task.StatusFailed:
		msg := truncateRune(n.Err, 80)
		if msg == "" {
			msg = "task failed"
		}
		return branding.AppName + ": Failed", goal + "\n" + msg
	default:
		return branding.AppName, goal
	}
}

// dbAdapter wraps *store.DB to satisfy ctxmem/store.DB. The wrapper
// exists so the ctxmem store package does not import store (which
// would create a sibling-package import cycle).
type dbAdapter struct {
	db *store.DB
}

func (a dbAdapter) Write() *sql.DB { return a.db.Write() }
func (a dbAdapter) Read() *sql.DB  { return a.db.Read() }

// ctxRepoPathAdapter implements ctxmem/svc.RepoPathLookup. Kept
// local to main.go so the svc package stays free of the store
// dependency (which would create a sibling-import cycle).
type ctxRepoPathAdapter struct {
	repoStore *store.RepositoryStore
}

func (a *ctxRepoPathAdapter) Path(ctx context.Context, repoID string) (string, error) {
	repo, err := a.repoStore.Get(ctx, repoID)
	if err != nil {
		return "", err
	}
	return repo.Path, nil
}

// ctxTaskMirror implements orchestrator.TaskMirror by delegating to
// ctxsvc.Service.IngestTaskAsNode. Lives in main.go so the
// orchestrator package does not depend on ctxmem (the adapter is
// constructed at wiring time only, not referenced from orchestrator
// logic). Idempotent: IngestTaskAsNode derives node ID from task ID.
type ctxTaskMirror struct {
	svc *ctxsvc.Service
}

func (m ctxTaskMirror) IngestTask(ctx context.Context, repoID, taskID, goal, summary string) error {
	if m.svc == nil {
		return nil
	}
	_, err := m.svc.IngestTaskAsNode(ctx, repoID, taskID, goal, summary)
	return err
}

// observerTaskLookup implements ctxmem/observer.TaskLookup by calling
// TaskStore.Get to resolve a task id to its repo id. Declared here so
// the observer package does not import store (which avoids a cycle
// through app once app depends on observer in a later phase).
type observerTaskLookup struct {
	store *store.TaskStore
}

func (l *observerTaskLookup) RepoIDForTask(ctx context.Context, taskID string) (string, error) {
	t, err := l.store.Get(ctx, taskID)
	if err != nil {
		return "", err
	}
	return t.RepoID, nil
}

func (l *observerTaskLookup) TaskInfo(ctx context.Context, taskID string) (ctxobserver.TaskInfo, error) {
	t, err := l.store.Get(ctx, taskID)
	if err != nil {
		return ctxobserver.TaskInfo{}, err
	}
	return ctxobserver.TaskInfo{
		RepoID:       t.RepoID,
		Goal:         t.Goal,
		WorktreePath: t.WorktreePath,
	}, nil
}

// observerDecisionSummarizer wraps the Copilot runtime to satisfy
// ctxmem/observer.TaskSummarizer. Gated on Memory being enabled
// for the repo — the adapter checks ctx_memory_settings.enabled
// before invoking the LLM, so a Memory-off repo pays no cost.
type observerDecisionSummarizer struct {
	runtime  *copilot.Runtime
	settings *ctxstore.SettingsStore
	log      *slog.Logger
}

func (s *observerDecisionSummarizer) Summarize(ctx context.Context, repoID, worktreePath, goal string, files []string) (string, error) {
	if s.runtime == nil {
		return "", fmt.Errorf("decision summarizer: runtime not started")
	}
	set, err := s.settings.Get(ctx, repoID)
	if err != nil {
		return "", err
	}
	if !set.Enabled {
		return "", nil
	}
	if worktreePath == "" || goal == "" {
		return "", nil
	}
	model := set.LLMModel
	if model == "gpt-4o-mini" {
		model = ""
	}
	analyzer, err := s.runtime.NewAnalyzer(ctx, model)
	if err != nil {
		return "", err
	}
	return analyzer.SummarizeTask(ctx, worktreePath, model, goal, files)
}

// copilotAnalyzerAdapter implements ctxmem/analyzer.SessionRunner by
// resolving a repo id to its on-disk path and dispatching to the
// Copilot runtime's Analyzer. The runtime field is populated after
// rt.Start so the adapter can be constructed before rt is ready.
type copilotAnalyzerAdapter struct {
	repoStore *store.RepositoryStore
	runtime   *copilot.Runtime
}

// RepoPath satisfies ctxmem/analyzer.SessionRunner — returns the
// absolute repository path resolved from the store.
func (a *copilotAnalyzerAdapter) RepoPath(ctx context.Context, repoID string) (string, error) {
	repo, err := a.repoStore.Get(ctx, repoID)
	if err != nil {
		return "", err
	}
	return repo.Path, nil
}

// RunOneShot satisfies ctxmem/analyzer.SessionRunner.
func (a *copilotAnalyzerAdapter) RunOneShot(ctx context.Context, repoID, model, prompt string, progress func(string)) (string, error) {
	if a.runtime == nil {
		return "", fmt.Errorf("copilot analyzer adapter: runtime not started yet")
	}
	repo, err := a.repoStore.Get(ctx, repoID)
	if err != nil {
		return "", fmt.Errorf("copilot analyzer adapter: lookup repo: %w", err)
	}
	// Legacy default: v13 migration shipped ctx_memory_settings.llm_model
	// defaulting to "gpt-4o-mini" but Copilot's catalog does not include
	// that id on most plans. Treat it as empty so the adapter falls
	// through to auto-resolve.
	if model == "gpt-4o-mini" {
		model = ""
	}
	analyzer, err := a.runtime.NewAnalyzer(ctx, model)
	if err != nil {
		return "", err
	}
	out, err := analyzer.Analyze(ctx, repo.Path, model, prompt, progress)
	if err != nil && isModelUnavailable(err) && model != "" {
		// User-configured model not available. Retry once with
		// auto-resolve (first Copilot-advertised model) so the
		// user sees a successful run instead of a hard failure.
		fallbackAnalyzer, ferr := a.runtime.NewAnalyzer(ctx, "")
		if ferr != nil {
			return "", err
		}
		return fallbackAnalyzer.Analyze(ctx, repo.Path, "", prompt, progress)
	}
	return out, err
}

// isModelUnavailable recognises the Copilot SDK's "Model not available"
// error so the adapter can retry with auto-resolve instead of failing
// the whole analyzer session.
func isModelUnavailable(err error) bool {
	if err == nil {
		return false
	}
	msg := err.Error()
	return strings.Contains(msg, "is not available") ||
		strings.Contains(msg, "not available") ||
		strings.Contains(msg, "unknown model")
}

func truncateRune(s string, n int) string {
	r := []rune(s)
	if len(r) <= n {
		return s
	}
	return string(r[:n]) + "…"
}
