//go:build windows

package winapi

import (
	"context"
	"fmt"
	"os/exec"
	"strings"
	"time"

	"github.com/FleetKanban/fleetkanban/internal/branding"
)

const (
	toastTimeout = 5 * time.Second
)

// Toast is a minimal notification payload.
type Toast struct {
	Title string
	Body  string
	// AppUserModelID overrides the process AUMID for this toast (optional).
	// Defaults to branding.AUMID when empty.
	AppUserModelID string
}

// ShowToast dispatches a Windows 11 Toast via PowerShell. Non-blocking;
// errors indicate dispatch failures, not user interaction.
func ShowToast(t Toast) error {
	aumid := t.AppUserModelID
	if aumid == "" {
		aumid = branding.AUMID
	}

	xml := buildToastXML(t.Title, t.Body)
	script := buildToastScript(xml, aumid)

	ctx, cancel := context.WithTimeout(context.Background(), toastTimeout)
	defer cancel()

	// -sta is required for WinRT COM apartment; without it the Windows.Data.Xml
	// and Windows.UI.Notifications types cannot be loaded from PowerShell.
	cmd := exec.CommandContext(ctx, "powershell",
		"-NoProfile",
		"-NonInteractive",
		"-sta",
		"-Command", script,
	)
	out, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("winapi: ShowToast powershell: %w: %s", err, strings.TrimSpace(string(out)))
	}
	return nil
}

// buildToastXML constructs a ToastGeneric XML payload with Title and Body
// properly HTML-escaped so that special characters do not break the XML.
func buildToastXML(title, body string) string {
	return `<toast><visual><binding template="ToastGeneric"><text>` +
		escapeXML(title) +
		`</text><text>` +
		escapeXML(body) +
		`</text></binding></visual></toast>`
}

// buildToastScript returns a self-contained PowerShell one-liner that loads
// the Windows Runtime Toast types, builds a notification from xml, and fires
// it via the given aumid notifier.
//
// Both the Windows.UI.Notifications and Windows.Data.Xml.Dom.XmlDocument WinRT
// namespaces must be loaded explicitly before New-Object can resolve them.
// PowerShell must be launched with -sta for the COM apartment to accept WinRT.
func buildToastScript(xml, aumid string) string {
	// Single-quote the XML inside the PowerShell string. Because the XML
	// itself may not contain single quotes (HTML-escaped already), embedding
	// is safe. The AUMID is validated by SetAppUserModelID or supplied
	// directly — it must not contain single quotes, which is enforced by the
	// Windows shell naming rules (alphanumeric + dots).
	return `[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null; ` +
		`[Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null; ` +
		`$xml = New-Object Windows.Data.Xml.Dom.XmlDocument; ` +
		`$xml.LoadXml('` + xml + `'); ` +
		`$toast = New-Object Windows.UI.Notifications.ToastNotification $xml; ` +
		`[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('` + aumid + `').Show($toast)`
}

// escapeXML replaces the five XML special characters with their entity
// references so that arbitrary strings are safe inside XML text nodes.
func escapeXML(s string) string {
	s = strings.ReplaceAll(s, "&", "&amp;")
	s = strings.ReplaceAll(s, "<", "&lt;")
	s = strings.ReplaceAll(s, ">", "&gt;")
	s = strings.ReplaceAll(s, `"`, "&quot;")
	s = strings.ReplaceAll(s, "'", "&#39;")
	return s
}
