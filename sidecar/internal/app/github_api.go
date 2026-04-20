package app

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"
)

// GitHubAccountInfo is the subset of GET /user the UI needs. Fields we don't
// populate (like premium request quotas) are intentionally absent because
// GitHub does not expose them on the public API.
type GitHubAccountInfo struct {
	Login         string
	Name          string
	AvatarURL     string
	PlanName      string
	PlanRepos     int32
	PlanSeats     int32
	PlanSpace     int64
	CopilotActive bool
	RawMessage    string
}

// ErrNoPAT is returned by GetGitHubAccountInfo when no PAT has been stored.
// Upstream translates this to FailedPrecondition so the UI prompts the user
// to add one in Settings.
var ErrNoPAT = errors.New("app: no PAT configured; add one in Settings to fetch account info")

// ErrInvalidToken is returned when GitHub responds 401 Unauthorized to a
// call made with the stored PAT. The UI distinguishes this from "token
// present but lacks scopes" so it can prompt the user to replace the
// token rather than adjust scopes.
var ErrInvalidToken = errors.New("app: GitHub rejected the PAT (401); rotate or replace it in Settings")

// ErrInsufficientScopes is returned when GitHub responds 403 Forbidden to
// /user, which in practice means the token is valid but missing scopes
// (or the SSO session expired). The UI surfaces this as a scope check
// reminder rather than a "bad token" state.
var ErrInsufficientScopes = errors.New("app: GitHub PAT lacks required scopes or SSO authorization (403)")

// GetGitHubAccountInfo fetches /user from GitHub REST API using the active
// PAT. The SDK auth state is consulted separately so the copilot_enabled
// flag reflects whether Copilot is reachable.
func (s *Service) GetGitHubAccountInfo(ctx context.Context) (*GitHubAccountInfo, error) {
	if s.secrets == nil {
		return nil, ErrSecretsUnavailable
	}
	tok, err := s.secrets.GetGitHubToken()
	if err != nil {
		return nil, fmt.Errorf("app: read PAT: %w", err)
	}
	if tok == "" {
		return nil, ErrNoPAT
	}
	info, err := fetchGitHubUser(ctx, tok)
	if err != nil {
		return nil, err
	}
	// Consult the SDK auth state for Copilot reachability. A PAT with
	// insufficient scopes may still satisfy /user but fail Copilot calls;
	// we separate the two signals so the UI can explain.
	if auth, authErr := s.runtime.CheckAuth(ctx); authErr == nil {
		info.CopilotActive = auth.Authenticated
		if info.RawMessage == "" {
			info.RawMessage = auth.Message
		}
	}
	return info, nil
}

// fetchGitHubUser hits https://api.github.com/user with the supplied token
// and decodes the response into our flat struct. Kept as a free function so
// tests can exercise the parsing without a Service instance.
func fetchGitHubUser(ctx context.Context, token string) (*GitHubAccountInfo, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, "https://api.github.com/user", nil)
	if err != nil {
		return nil, fmt.Errorf("app: build /user request: %w", err)
	}
	req.Header.Set("Authorization", "Bearer "+token)
	req.Header.Set("Accept", "application/vnd.github+json")
	req.Header.Set("X-GitHub-Api-Version", "2022-11-28")
	req.Header.Set("User-Agent", "FleetKanban")

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("app: GET /user: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(io.LimitReader(resp.Body, 64*1024))
	if err != nil {
		return nil, fmt.Errorf("app: read /user body: %w", err)
	}
	switch resp.StatusCode {
	case http.StatusOK:
		return parseUserResponse(body)
	case http.StatusUnauthorized:
		// 401 → token is outright invalid / revoked / expired. The body
		// is included for operator diagnostics but the sentinel is what
		// callers (and the UI) branch on.
		return nil, fmt.Errorf("%w: %s", ErrInvalidToken, strings.TrimSpace(string(body)))
	case http.StatusForbidden:
		// 403 on /user almost always means scopes are insufficient or a
		// SAML-SSO session needs re-authorizing. Distinguish from 401
		// so the UI can nudge the user toward the right fix.
		return nil, fmt.Errorf("%w: %s", ErrInsufficientScopes, strings.TrimSpace(string(body)))
	default:
		return nil, fmt.Errorf("app: GET /user returned %d: %s",
			resp.StatusCode, strings.TrimSpace(string(body)))
	}
}

// parseUserResponse extracts the flat struct from the REST JSON. The
// upstream schema includes many fields we don't need; we ignore them.
func parseUserResponse(body []byte) (*GitHubAccountInfo, error) {
	var payload struct {
		Login     string `json:"login"`
		Name      string `json:"name"`
		AvatarURL string `json:"avatar_url"`
		Plan      struct {
			Name          string `json:"name"`
			Space         int64  `json:"space"`
			PrivateRepos  int32  `json:"private_repos"`
			Collaborators int32  `json:"collaborators"`
		} `json:"plan"`
	}
	if err := json.Unmarshal(body, &payload); err != nil {
		return nil, fmt.Errorf("app: parse /user JSON: %w", err)
	}
	return &GitHubAccountInfo{
		Login:     payload.Login,
		Name:      payload.Name,
		AvatarURL: payload.AvatarURL,
		PlanName:  payload.Plan.Name,
		PlanRepos: payload.Plan.PrivateRepos,
		PlanSeats: payload.Plan.Collaborators,
		PlanSpace: payload.Plan.Space,
	}, nil
}
