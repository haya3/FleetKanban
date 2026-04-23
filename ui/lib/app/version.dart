// Expected sidecar protocol version. Must equal
// sidecar/internal/branding.ProtocolVersion — keep the two in sync when a
// proto change lands. SidecarSupervisor compares this against
// SystemService.GetVersion immediately after connect, and kills/respawns
// the process when it doesn't match (typically after a rebuild where an
// old sidecar is still running from the prior launch).
//
// Bumping this constant without rebuilding the sidecar will cause the UI
// to kill whatever process it finds and spawn the binary at
// `build/bin/fleetkanban-sidecar.exe`. Make sure that binary is the new
// build before bumping.
const int expectedSidecarProtocolVersion = 35;

/// User-facing release version (semver, no leading "v"). Must match
/// `pubspec.yaml` `version` and `sidecar/internal/branding.AppVersion`.
/// Shown in the About dialog and sent to the updater for comparison
/// against the latest GitHub Release.
const String appVersion = '0.1.0';
