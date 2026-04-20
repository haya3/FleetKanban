//go:build windows

package copilot

import (
	"bufio"
	"context"
	"errors"
	"fmt"
	"io"
	"net/url"
	"os"
	"os/exec"
	"regexp"
	"sync"
	"syscall"
	"time"

	"golang.org/x/sys/windows"
)

// LoginChallenge is the data the UI needs to show a device-flow sign-in
// dialog: the 8-char code the user types into the verification page, and
// the pre-filled URL that the sidecar has already opened in the browser.
type LoginChallenge struct {
	UserCode        string
	VerificationURI string
	ExpiresIn       time.Duration
}

// LoginSessionState is the lifecycle of the `copilot login` subprocess
// tracked by a LoginCoordinator. The UI polls this (via
// Runtime.LoginSession) instead of CheckAuth so that stale "already
// authenticated" state from the currently-running SDK client cannot
// prematurely resolve the sign-in dialog: ReloadAuth — and therefore the
// transition of auth.getStatus to authenticated=true — only happens once
// the subprocess exits cleanly.
type LoginSessionState int

const (
	// LoginSessionIdle means no session is tracked: BeginLogin was never
	// called, or CancelLogin cleared the previous one.
	LoginSessionIdle LoginSessionState = iota
	// LoginSessionRunning means the subprocess is alive and the user is
	// expected to complete the device flow in the browser.
	LoginSessionRunning
	// LoginSessionSucceeded means the subprocess exited 0 and ReloadAuth
	// completed successfully.
	LoginSessionSucceeded
	// LoginSessionFailed means the subprocess exited non-zero or
	// ReloadAuth after a successful exit failed. ErrorMessage carries
	// the formatted reason.
	LoginSessionFailed
)

// LoginSessionSnapshot is a point-in-time view of LoginCoordinator state
// safe to hand out across the RPC boundary.
type LoginSessionSnapshot struct {
	State        LoginSessionState
	ErrorMessage string
}

// ErrLoginInProgress is returned by Begin when another login session is
// already running. The caller should Cancel first or reuse the existing
// session.
var ErrLoginInProgress = errors.New("copilot: another login is already in progress")

// ErrLoginTimeout is returned by Begin when the login subprocess does not
// emit a parseable device code within the read deadline.
var ErrLoginTimeout = errors.New("copilot: timed out waiting for device code")

// ErrLoginNoCLI is returned by Begin when the Copilot CLI binary cannot be
// resolved. Distinct from generic start failures so the caller can surface
// a clearer error.
var ErrLoginNoCLI = errors.New("copilot: no CLI binary available for login")

// deviceCodeLineRE matches the first stdout line of `copilot login`:
//
//	To authenticate, visit https://github.com/login/device and enter code XXXX-YYYY.
//
// Group 1 = verification URL, Group 2 = device code.
var deviceCodeLineRE = regexp.MustCompile(
	`visit\s+(https?://\S+?)\s+and\s+enter\s+code\s+([A-Z0-9]{4}-[A-Z0-9]{4})`,
)

// LoginCoordinator owns the `copilot login` subprocess lifecycle. Exactly
// one login can be in flight per coordinator; re-calling Begin while a
// session is live returns ErrLoginInProgress (the caller chose Cancel →
// Begin or reuse the existing challenge).
type LoginCoordinator struct {
	rt *Runtime

	mu      sync.Mutex
	current *loginSession
}

type loginSession struct {
	cmd       *exec.Cmd
	challenge LoginChallenge
	done      chan struct{} // closed when the subprocess has exited
	exitErr   error         // populated before done is closed
}

// NewLoginCoordinator wires a coordinator to an existing Runtime. After a
// successful login the coordinator calls Runtime.ReloadAuth so subsequent
// GetAuthStatus RPCs reflect the new credentials without a sidecar restart.
func NewLoginCoordinator(rt *Runtime) *LoginCoordinator {
	return &LoginCoordinator{rt: rt}
}

// Begin spawns `copilot login`, parses the device code from stdout, opens
// the verification URL (with user_code pre-filled) in the user's default
// browser, and returns the challenge. The subprocess keeps running in the
// background until the user completes auth or Cancel is called.
//
// The caller should poll Runtime.CheckAuth (or an equivalent RPC) to detect
// completion. The coordinator reloads the SDK client automatically on
// successful exit, so the poll will eventually report Authenticated=true.
func (lc *LoginCoordinator) Begin(ctx context.Context) (LoginChallenge, error) {
	lc.mu.Lock()
	if lc.current != nil {
		// If the previous subprocess has already exited, clear it and
		// proceed (common case: a prior login completed or was cancelled
		// asynchronously). Otherwise reject — the UI must explicitly Cancel.
		select {
		case <-lc.current.done:
			lc.current = nil
		default:
			lc.mu.Unlock()
			return LoginChallenge{}, ErrLoginInProgress
		}
	}
	lc.mu.Unlock()

	cliPath := resolveCLIPath()
	if cliPath == "" {
		return LoginChallenge{}, ErrLoginNoCLI
	}

	cmd := exec.Command(cliPath, "login")
	// `copilot login` resolves --config-dir to ~/.copilot by default; running
	// from the user's home directory keeps any stray relative-path reads
	// (telemetry, cache probes) inside a stable location instead of
	// whatever cwd the Flutter UI was launched with.
	if home, err := userHomeDir(); err == nil {
		cmd.Dir = home
	}
	cmd.SysProcAttr = &syscall.SysProcAttr{
		// Hide the console window for the detached CLI child. CREATE_NO_WINDOW
		// is sufficient — the subprocess does not need its own tty; we read
		// its stdout via a pipe.
		CreationFlags: windows.CREATE_NO_WINDOW | windows.CREATE_NEW_PROCESS_GROUP,
		HideWindow:    true,
	}

	stdout, err := cmd.StdoutPipe()
	if err != nil {
		return LoginChallenge{}, fmt.Errorf("copilot: stdout pipe: %w", err)
	}
	// copilot login writes the device-code line to stdout but may emit
	// informational lines to stderr; capture and discard to prevent a
	// full pipe buffer from blocking the child.
	stderrPipe, _ := cmd.StderrPipe()

	if err := cmd.Start(); err != nil {
		return LoginChallenge{}, fmt.Errorf("copilot: start login: %w", err)
	}

	sess := &loginSession{cmd: cmd, done: make(chan struct{})}

	// Drain stderr so the subprocess never blocks on a full pipe.
	if stderrPipe != nil {
		go func() { _, _ = io.Copy(io.Discard, stderrPipe) }()
	}

	// Parse stdout until we see the device-code line, then keep draining
	// so the subprocess can keep writing without blocking on a full pipe.
	type parseResult struct {
		ch  LoginChallenge
		err error
	}
	parsed := make(chan parseResult, 1)
	go func() {
		defer func() { _, _ = io.Copy(io.Discard, stdout) }()
		scanner := bufio.NewScanner(stdout)
		for scanner.Scan() {
			line := scanner.Text()
			if m := deviceCodeLineRE.FindStringSubmatch(line); m != nil {
				uri, err := buildVerificationURI(m[1], m[2])
				if err != nil {
					parsed <- parseResult{err: fmt.Errorf("copilot: build verification URI: %w", err)}
					return
				}
				parsed <- parseResult{ch: LoginChallenge{
					UserCode:        m[2],
					VerificationURI: uri,
					// The GitHub device flow default is 15 minutes; surface
					// that so the UI can show a countdown / refresh hint.
					ExpiresIn: 15 * time.Minute,
				}}
				return
			}
		}
		if err := scanner.Err(); err != nil {
			parsed <- parseResult{err: fmt.Errorf("copilot: read stdout: %w", err)}
			return
		}
		// Scanner reached EOF without a match — the subprocess exited
		// before emitting a device code (e.g. already logged in, or
		// network failure). Let the caller see the Wait error.
		parsed <- parseResult{err: io.EOF}
	}()

	// Watch the subprocess and reload auth on success.
	go func() {
		defer close(sess.done)
		sess.exitErr = cmd.Wait()
		if sess.exitErr == nil {
			// ReloadAuth uses the empty token path (UseLoggedInUser) because
			// `copilot login` has just written credentials to the system
			// credential store. Run in a fresh context: the caller's ctx may
			// have already been cancelled by the time auth completes.
			if rlErr := lc.rt.ReloadAuth(context.Background(), ""); rlErr != nil {
				// Reload failure is non-fatal here; the next login RPC will
				// retry, and GetAuthStatus will surface the problem.
				sess.exitErr = fmt.Errorf("copilot: reload auth after login: %w", rlErr)
			}
		}
	}()

	// Wait for either the device code, subprocess exit, ctx cancellation,
	// or a hard deadline.
	select {
	case r := <-parsed:
		if r.err != nil {
			// If parse failed because the process exited, include the
			// exit error for better diagnostics.
			<-sess.done
			if sess.exitErr != nil {
				return LoginChallenge{}, fmt.Errorf(
					"copilot: login subprocess exited before emitting device code: %w", sess.exitErr)
			}
			_ = cmd.Process.Kill()
			return LoginChallenge{}, r.err
		}
		sess.challenge = r.ch
		lc.mu.Lock()
		lc.current = sess
		lc.mu.Unlock()
		// Open the browser proactively so the user lands on the
		// pre-filled verification page without any extra click. Failures
		// are non-fatal: the UI also surfaces a button that reopens it.
		_ = openURLInBrowser(r.ch.VerificationURI)
		return r.ch, nil

	case <-sess.done:
		if sess.exitErr != nil {
			return LoginChallenge{}, fmt.Errorf(
				"copilot: login subprocess failed: %w", sess.exitErr)
		}
		// Exited with status 0 but no device code was emitted. Treat as
		// a protocol mismatch; the caller should retry or re-check auth.
		return LoginChallenge{}, errors.New(
			"copilot: login subprocess completed without emitting a device code")

	case <-ctx.Done():
		_ = cmd.Process.Kill()
		<-sess.done
		return LoginChallenge{}, ctx.Err()

	case <-time.After(30 * time.Second):
		_ = cmd.Process.Kill()
		<-sess.done
		return LoginChallenge{}, ErrLoginTimeout
	}
}

// Cancel terminates the running login subprocess, if any. No-op when no
// session is live. Waits for the subprocess to fully exit before returning
// so the coordinator never leaks a zombie child.
func (lc *LoginCoordinator) Cancel() {
	lc.mu.Lock()
	sess := lc.current
	lc.current = nil
	lc.mu.Unlock()

	if sess == nil {
		return
	}
	select {
	case <-sess.done:
		return
	default:
	}
	_ = sess.cmd.Process.Kill()
	<-sess.done
}

// Session returns the current subprocess state. The state is derived from
// the tracked session + its done channel — we do not maintain a separate
// mutable field. `done` is closed strictly after `exitErr` is written, so
// reading exitErr after observing done is closed is race-free (the channel
// close synchronises the writes).
func (lc *LoginCoordinator) Session() LoginSessionSnapshot {
	lc.mu.Lock()
	sess := lc.current
	lc.mu.Unlock()

	if sess == nil {
		return LoginSessionSnapshot{State: LoginSessionIdle}
	}
	select {
	case <-sess.done:
		if sess.exitErr != nil {
			return LoginSessionSnapshot{
				State:        LoginSessionFailed,
				ErrorMessage: sess.exitErr.Error(),
			}
		}
		return LoginSessionSnapshot{State: LoginSessionSucceeded}
	default:
		return LoginSessionSnapshot{State: LoginSessionRunning}
	}
}

// buildVerificationURI appends ?user_code=XXXX-YYYY&skip_account_picker=true
// to GitHub's verification URL so the browser page is fully pre-filled. If
// raw already has query params, they are preserved.
func buildVerificationURI(raw, code string) (string, error) {
	u, err := url.Parse(raw)
	if err != nil {
		return "", err
	}
	q := u.Query()
	q.Set("user_code", code)
	// Skips the "choose account" prompt when the user is already signed
	// into a single GitHub account; harmless otherwise.
	q.Set("skip_account_picker", "true")
	u.RawQuery = q.Encode()
	return u.String(), nil
}

// userHomeDir is a package-local alias kept so tests can swap it without
// shadowing os.UserHomeDir globally.
var userHomeDir = os.UserHomeDir
