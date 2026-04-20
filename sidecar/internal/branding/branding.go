//go:build windows

// Package branding centralises user-visible product names, identifiers, and
// file/directory naming. To rebrand the product, edit the constants in this
// file and regenerate bindings; no other Go source change is required.
package branding

const (
	// AppName is the user-facing product name shown in window titles, Toast
	// group headers, and user data directory names.
	AppName = "FleetKanban"

	// AUMID is the Windows AppUserModelID used by the Shell to group Start
	// Menu entries, taskbar icons and Toast notifications.
	AUMID = "com.fleetkanban.desktop"

	// DataDirName is the leaf directory under %APPDATA% (or %LOCALAPPDATA%
	// on UNC-redirected profiles) that holds the SQLite DB and worktrees.
	DataDirName = "FleetKanban"

	// DBFileName is the SQLite database file name, located inside DataDirName.
	DBFileName = "fleetkanban.db"

	// BinaryName is the produced executable name (without .exe). Keep this
	// in sync with Taskfile.yml's APP_NAME variable.
	BinaryName = "fleetkanban"

	// BranchPrefix prefixes every git branch created for a task worktree.
	// Changing this breaks compatibility with existing worktrees.
	BranchPrefix = "fleetkanban/"

	// Tagline is the short product description shown in window chrome and
	// About dialogs.
	Tagline = "Autonomous multi-agent task runner"

	// ProtocolVersion is a monotonic integer bumped whenever the gRPC
	// contract changes in a way that would break clients built against
	// an older sidecar (new RPC, new service, removed field, etc).
	//
	// The UI embeds an "expected protocol version" constant (see
	// ui/lib/app/version.dart) and compares at connect time. A mismatch
	// — typical after a rebuild when an old sidecar instance is still
	// running — triggers the UI to kill that process and spawn the
	// fresh binary, avoiding "UNIMPLEMENTED: unknown service ..."
	// errors that users could otherwise only fix by hand.
	//
	// Bump this whenever a proto change lands. Never decrement.
	ProtocolVersion = 25
)

// AppVersion is the user-facing release version (semver, no leading "v").
// Kept as a var rather than const so release builds can override it via
//
//	go build -ldflags "-X github.com/<...>/branding.AppVersion=1.2.3"
//
// without editing source. Must match ui/pubspec.yaml version and
// ui/lib/app/version.dart appVersion.
var AppVersion = "0.1.0"
