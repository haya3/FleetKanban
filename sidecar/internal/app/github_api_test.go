//go:build windows

package app

import (
	"context"
	"errors"
	"io"
	"net/http"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// fetchGitHubUser builds its own http.Client, so the tests swap the
// package default transport with a RoundTripper stub. This keeps the
// production code free of test-only seams while still letting us
// exercise the 200 / 401 / 403 branches directly.
type roundTripFunc func(*http.Request) *http.Response

func (f roundTripFunc) RoundTrip(r *http.Request) (*http.Response, error) { return f(r), nil }

func withTransport(t *testing.T, rt http.RoundTripper) {
	t.Helper()
	orig := http.DefaultTransport
	http.DefaultTransport = rt
	t.Cleanup(func() { http.DefaultTransport = orig })
}

func stubResponse(status int, body string) *http.Response {
	return &http.Response{
		StatusCode: status,
		Body:       io.NopCloser(strings.NewReader(body)),
		Header:     make(http.Header),
		Request:    &http.Request{},
		Proto:      "HTTP/1.1",
		ProtoMajor: 1,
		ProtoMinor: 1,
	}
}

func TestFetchGitHubUser_401ReturnsErrInvalidToken(t *testing.T) {
	withTransport(t, roundTripFunc(func(r *http.Request) *http.Response {
		return stubResponse(http.StatusUnauthorized, `{"message":"Bad credentials"}`)
	}))

	_, err := fetchGitHubUser(context.Background(), "abc")
	assert.ErrorIs(t, err, ErrInvalidToken)
	assert.NotErrorIs(t, err, ErrInsufficientScopes)
}

func TestFetchGitHubUser_403ReturnsErrInsufficientScopes(t *testing.T) {
	withTransport(t, roundTripFunc(func(r *http.Request) *http.Response {
		return stubResponse(http.StatusForbidden,
			`{"message":"Resource not accessible by personal access token"}`)
	}))

	_, err := fetchGitHubUser(context.Background(), "ghp_xxx")
	assert.ErrorIs(t, err, ErrInsufficientScopes)
	assert.NotErrorIs(t, err, ErrInvalidToken)
}

func TestFetchGitHubUser_200Succeeds(t *testing.T) {
	withTransport(t, roundTripFunc(func(r *http.Request) *http.Response {
		return stubResponse(http.StatusOK,
			`{"login":"octocat","name":"Mona","avatar_url":"https://x/y.png","plan":{"name":"pro","space":999}}`)
	}))

	info, err := fetchGitHubUser(context.Background(), "ghp_xxx")
	require.NoError(t, err)
	assert.Equal(t, "octocat", info.Login)
	assert.Equal(t, "Mona", info.Name)
	assert.Equal(t, "pro", info.PlanName)
	assert.EqualValues(t, 999, info.PlanSpace)
}

// Unexpected status codes must keep surfacing the raw status so
// operators can diagnose, without tripping the new sentinel checks.
func TestFetchGitHubUser_UnexpectedStatusFallsThrough(t *testing.T) {
	withTransport(t, roundTripFunc(func(r *http.Request) *http.Response {
		return stubResponse(http.StatusInternalServerError, `boom`)
	}))

	_, err := fetchGitHubUser(context.Background(), "ghp_xxx")
	require.Error(t, err)
	assert.NotErrorIs(t, err, ErrInvalidToken)
	assert.NotErrorIs(t, err, ErrInsufficientScopes)
	assert.Contains(t, err.Error(), "500")
}

func TestSentinelsAreDistinct(t *testing.T) {
	assert.False(t, errors.Is(ErrNoPAT, ErrInvalidToken))
	assert.False(t, errors.Is(ErrNoPAT, ErrInsufficientScopes))
	assert.False(t, errors.Is(ErrInvalidToken, ErrInsufficientScopes))
}
