//go:build windows

package copilot

import (
	"net/url"
	"strings"
	"testing"
)

// TestDeviceCodeLineRegex pins the exact stdout format of `copilot login`
// that we parse. If GitHub/Copilot ever reword this line, the regex must
// be updated alongside — this test surfaces the change fast instead of
// leaving users with a silent "device code never appeared" UI.
func TestDeviceCodeLineRegex(t *testing.T) {
	cases := []struct {
		name    string
		line    string
		wantURL string
		wantCod string
	}{
		{
			name:    "canonical line from copilot 1.0.21",
			line:    "To authenticate, visit https://github.com/login/device and enter code D8FC-D614.",
			wantURL: "https://github.com/login/device",
			wantCod: "D8FC-D614",
		},
		{
			name:    "extra whitespace and trailing punctuation still matches",
			line:    "To authenticate,   visit   https://github.com/login/device   and  enter  code   AAAA-BBBB   .",
			wantURL: "https://github.com/login/device",
			wantCod: "AAAA-BBBB",
		},
		{
			name:    "GitHub Enterprise host is captured correctly",
			line:    "To authenticate, visit https://ghe.example.com/login/device and enter code ZZZZ-9999.",
			wantURL: "https://ghe.example.com/login/device",
			wantCod: "ZZZZ-9999",
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			m := deviceCodeLineRE.FindStringSubmatch(tc.line)
			if m == nil {
				t.Fatalf("no match for line: %q", tc.line)
			}
			if m[1] != tc.wantURL {
				t.Errorf("URL: got %q, want %q", m[1], tc.wantURL)
			}
			if m[2] != tc.wantCod {
				t.Errorf("code: got %q, want %q", m[2], tc.wantCod)
			}
		})
	}
}

// TestDeviceCodeLineRegex_NonMatching lists lines the CLI may legitimately
// emit but that should NOT be picked up as a device-code line. Catches
// false positives that would otherwise cause the UI to display garbage in
// the dialog.
func TestDeviceCodeLineRegex_NonMatching(t *testing.T) {
	lines := []string{
		"Waiting for authorization...",
		"",
		"Authorization successful! Welcome, octocat.",
		"Error: device code expired",
		// 4-char code, but not XXXX-XXXX format
		"visit https://github.com/login/device and enter code ABCD.",
	}
	for _, line := range lines {
		if m := deviceCodeLineRE.FindStringSubmatch(line); m != nil {
			t.Errorf("false positive on %q: matched %v", line, m)
		}
	}
}

// TestBuildVerificationURI ensures the user_code and skip_account_picker
// params are added without clobbering anything the CLI may have already
// put in the URL, and that the resulting URL is valid.
func TestBuildVerificationURI(t *testing.T) {
	cases := []struct {
		name string
		raw  string
		code string
	}{
		{"plain github.com", "https://github.com/login/device", "ABCD-1234"},
		{"URL already has query params", "https://github.com/login/device?foo=bar", "ABCD-1234"},
		{"GHE hostname", "https://ghe.example.com/login/device", "ZZZZ-9999"},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			got, err := buildVerificationURI(tc.raw, tc.code)
			if err != nil {
				t.Fatalf("buildVerificationURI: %v", err)
			}
			u, err := url.Parse(got)
			if err != nil {
				t.Fatalf("result not a valid URL: %v", err)
			}
			if u.Query().Get("user_code") != tc.code {
				t.Errorf("user_code missing or wrong: got %q", u.Query().Get("user_code"))
			}
			if u.Query().Get("skip_account_picker") != "true" {
				t.Errorf("skip_account_picker missing: got %q", u.Query().Get("skip_account_picker"))
			}
			// Preserve any pre-existing params.
			if strings.Contains(tc.raw, "foo=bar") && u.Query().Get("foo") != "bar" {
				t.Errorf("pre-existing query param foo=bar was lost")
			}
		})
	}
}
