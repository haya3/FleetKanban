# Release Process

FleetKanban ships as a Velopack-packaged Windows desktop app, distributed via
GitHub Releases on a public repository. This doc is the checklist for cutting
a release — the CI workflow at `.github/workflows/release.yml` automates the
build and upload, but tag creation and version bumps are manual per the
project branching policy.

## One-time setup

- `vpk` CLI (Velopack) installed locally for the `task release:pack` rehearsal:
  ```
  dotnet tool install -g vpk
  ```
- `git-cliff` installed if you want to preview release notes locally:
  ```
  cargo install git-cliff
  ```
- Git identity set to **haya3** in this repo (never commit with another account):
  ```
  git config user.name  "haya3"
  git config user.email "<haya3 email>"
  ```

## Cutting a release

1. **Pick the new version** (SemVer, no leading `v` in source, e.g. `0.1.1`).
   `ProtocolVersion` is independent — only bump it when the gRPC contract
   actually changed.

2. **Bump four places in lockstep**:
   | File | Field |
   |------|-------|
   | `repo/ui/pubspec.yaml` | `version:` (keep `+1` build-number if unchanged) |
   | `repo/ui/pubspec.yaml` | `msix_config.msix_version` (4-part, e.g. `0.1.1.0`) |
   | `repo/sidecar/internal/branding/branding.go` | `var AppVersion = "..."` |
   | `repo/ui/lib/app/version.dart` | `const String appVersion = '...'` |

   Leave `expectedSidecarProtocolVersion` / `ProtocolVersion` alone unless a
   proto change justifies a bump.

3. **Update `CHANGELOG.md`** by hand (move items from `## [Unreleased]` into
   a new `## [x.y.z]` section). Preview with:
   ```
   git cliff --latest --tag vX.Y.Z
   ```

4. **Commit and tag**:
   ```
   git add -A
   git commit -m "chore(release): vX.Y.Z"
   git tag vX.Y.Z
   ```
   Do **not** push automatically — push the branch and tag deliberately:
   ```
   git push origin main
   git push origin vX.Y.Z
   ```

5. **CI runs** on the tag push (`.github/workflows/release.yml`):
   - Builds `fleetkanban-sidecar.exe` with `-X ...AppVersion=X.Y.Z` injected
   - Runs `flutter build windows --release`
   - Copies the sidecar next to the Release runner
   - Runs `vpk pack` → produces the following in `build/release/`:
     - `com.fleetkanban.FleetKanban-win-Setup.exe` — the installer users download
     - `com.fleetkanban.FleetKanban-<ver>-full.nupkg` — full package (what the in-app updater pulls)
     - `com.fleetkanban.FleetKanban-win-Portable.zip` — portable fallback, optional
     - `RELEASES`, `releases.win.json`, `assets.win.json` — feed metadata
   - Uploads all artefacts to the GitHub Release for the tag

6. **Verify on a clean Windows 11 machine** (not the dev box):
   - Download `com.fleetkanban.FleetKanban-win-Setup.exe` from the Release page
   - SmartScreen: *More info → Run anyway* (unsigned first-run warning is expected; see `docs/signing-future.md`)
   - Confirm the About dialog shows the new `appVersion` and sidecar `AppVersion`
   - Re-run an earlier installed version (if you have one) and confirm the
     in-app "Update available" InfoBar appears, then click Update

## Rehearsing locally

`task release:pack` runs the whole build + package chain and drops artefacts
into `repo/build/release/`. The updater pulls updates from GitHub Releases
(not a local folder), so a full end-to-end rehearsal requires at least two
real Releases on the repo — cut `v0.1.0-rc.1` and `v0.1.0-rc.2` (or similar
pre-release tags) and check that an installed `rc.1` picks up `rc.2` via the
in-app InfoBar.

For a smoke test without pushing tags, run `Setup.exe` on a clean VM to
confirm the installer shape, Start Menu entry, and first-run behaviour.

## Rolling back

To pull a broken release without deleting the tag (deleting a published tag
is destructive and breaks anyone who already updated):

1. Cut a new patch release (e.g. `vX.Y.Z+1`) with the fix or revert.
2. Mark the broken Release as a pre-release in the GitHub UI to hide it from
   "latest" feed consumers.
