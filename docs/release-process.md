# Release Process

FleetKanban currently ships as a **source-only GitHub Release**. No prebuilt
binaries are distributed until a code-signing certificate is in place (see
`docs/signing-future.md`). Users build from source via
`scripts/build-from-source.ps1`; the in-app 1-click updater continues to work
through the self-built install feed (`update-feed.txt` → local
`build/release/`).

The CI workflow at `.github/workflows/release.yml` only generates release
notes and publishes a GitHub Release with the auto-attached source archives.
Tag creation and version bumps are manual per the project branching policy.

## One-time setup

- `git-cliff` installed locally if you want to preview release notes:
  ```
  cargo install git-cliff
  ```
- Git identity set to **haya3** in this repo (never commit with another account):
  ```
  git config user.name  "haya3"
  git config user.email "<haya3 email>"
  ```
- (Optional) `vpk` and the Flutter/Go toolchains for local `task release:pack`
  rehearsals; these are what `scripts/build-from-source.ps1` also drives.

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
   proto change justifies a bump. When proto does change, bump
   `ProtocolVersion` in `branding.go` and `expectedSidecarProtocolVersion` in
   `version.dart` in lockstep — otherwise the UI's evict/respawn loop will
   surface HTTP/2 GOAWAY noise.

3. **Update `CHANGELOG.md`** by hand (move items from `## [Unreleased]` into
   a new `## [x.y.z]` section with today's date). Preview with:
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
   - Runs `git-cliff --latest --tag vX.Y.Z` → `RELEASE_NOTES.md`
   - Creates the GitHub Release with those notes
   - GitHub auto-attaches `Source code (zip)` and `Source code (tar.gz)` —
     these are the only release artefacts. No installers, no nupkg.

6. **Verify**:
   - Check the rendered release notes at the Release page match `CHANGELOG.md`
   - On a clean Windows 11 machine, run
     `git clone --branch vX.Y.Z https://github.com/haya3/FleetKanban` then
     `scripts/build-from-source.ps1` and confirm the About dialog shows
     `appVersion == X.Y.Z` and sidecar `AppVersion == X.Y.Z`
   - In an existing self-built install, open **Settings → "Pull & rebuild
     from source"** and confirm the in-app *Update available* InfoBar fires
     after the rebuild completes (driven by `update-feed.txt`, not the
     GitHub Release)

## Why source-only?

- **No code-signing certificate yet** — publishing unsigned installers means
  every first-run triggers SmartScreen *"Windows protected your PC"*, which
  is a poor onboarding story. See `docs/signing-future.md` for the
  reactivation plan (Azure Trusted Signing / SSL.com OV) and the concrete
  TODO list for reintroducing binary Releases.
- **Updater is not affected** — `velopack_updater.dart` checks
  `update-feed.txt` first and only falls back to GitHub Releases when
  absent. Self-built installs never consult GitHub for updates, so
  source-only Releases do not break the 1-click update flow.
- **Tag + notes still valuable** — a tag anchors a reproducible checkpoint
  (`git checkout vX.Y.Z && scripts/build-from-source.ps1`) and the
  generated release notes document what changed, even without binaries.

## Rehearsing locally

`git cliff --latest --tag vX.Y.Z-rc.1` renders the release-notes block that
CI will publish, so you can review wording before tagging.

`task release:pack` still exists and drops a Velopack bundle into
`repo/build/release/` — useful for exercising the in-app updater flow
locally (via a self-built install feed), but those artefacts are **not**
uploaded by the release workflow.

## Rolling back

To pull a broken release without deleting the tag (deleting a published tag
is destructive and breaks anyone who already fetched it):

1. Cut a new patch release (e.g. `vX.Y.Z+1`) with the fix or revert.
2. Mark the broken Release as a pre-release in the GitHub UI to hide it from
   the "latest" feed.
