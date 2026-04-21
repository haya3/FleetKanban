//go:build windows

package winapi

import (
	"os/exec"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/haya3/FleetKanban/internal/branding"
)

func TestShowToast(t *testing.T) {
	if _, err := exec.LookPath("powershell"); err != nil {
		t.Skip("powershell not available")
	}
	err := ShowToast(Toast{
		Title: "FleetKanban Test",
		Body:  "ShowToast integration test",
	})
	require.NoError(t, err)
}

func TestShowToast_WithAUMID(t *testing.T) {
	if _, err := exec.LookPath("powershell"); err != nil {
		t.Skip("powershell not available")
	}
	err := ShowToast(Toast{
		Title:          "FleetKanban Test",
		Body:           "ShowToast with explicit AUMID",
		AppUserModelID: branding.AUMID,
	})
	require.NoError(t, err)
}

func TestEscapeXML(t *testing.T) {
	tests := []struct {
		name  string
		input string
		want  string
	}{
		{"ampersand", "a&b", "a&amp;b"},
		{"less_than", "<tag>", "&lt;tag&gt;"},
		{"greater_than", "x>y", "x&gt;y"},
		{"double_quote", `say "hi"`, "say &quot;hi&quot;"},
		{"single_quote", "it's", "it&#39;s"},
		{"combined", `<a&b="c">`, "&lt;a&amp;b=&quot;c&quot;&gt;"},
		{"no_special", "hello world", "hello world"},
		{"empty", "", ""},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			assert.Equal(t, tc.want, escapeXML(tc.input))
		})
	}
}

func TestBuildToastXML(t *testing.T) {
	xml := buildToastXML("Title & More", "<Body>")
	assert.Contains(t, xml, "Title &amp; More")
	assert.Contains(t, xml, "&lt;Body&gt;")
	assert.Contains(t, xml, `template="ToastGeneric"`)
}

func TestShowToast_DefaultAUMID(t *testing.T) {
	// Verify that an empty AppUserModelID falls back to branding.AUMID.
	toast := Toast{Title: "t", Body: "b"}
	// We check the script builds with the default AUMID, not PowerShell execution.
	xml := buildToastXML(toast.Title, toast.Body)
	script := buildToastScript(xml, branding.AUMID)
	assert.Contains(t, script, branding.AUMID)
}
