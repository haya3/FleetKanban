# Code Signing (future)

FleetKanban Phase 1 distributes unsigned binaries. Users see Windows
SmartScreen's "Windows protected your PC" dialog on first launch and need to
click *More info → Run anyway*. This is acceptable for the initial small-scale
release and has no effect on update delivery (Velopack's update channel works
the same for signed and unsigned packages).

This doc captures the plan for when signing becomes worthwhile.

## When to sign

Adopt a signing certificate when any of the following become true:

- Distribution size grows to the point where SmartScreen reputation matters
  (new unsigned binaries take weeks to accumulate trust automatically).
- An enterprise user blocks the installer outright due to policy.
- Delta updates start failing because a user's endpoint protection quarantines
  unsigned `.nupkg` payloads.

## Preferred option: Azure Trusted Signing

Microsoft's managed signing service, successor to Azure Code Signing.

- Per-signature billing (~$0.60/signature at 2026-04 pricing). Cheap for a
  few releases a month.
- Individuals eligible after identity verification.
- No hardware token to manage; signing happens against an HSM in Azure.
- Integrates with GitHub Actions via `Azure/trusted-signing-action`.

Integration point: Set `VPK_SIGN_TEMPLATE` in the workflow environment to the
`signtool` invocation the action emits. The Taskfile and CI already forward
`VPK_SIGN_TEMPLATE` to `vpk pack --signTemplate`.

## Fallback: SSL.com OV certificate

- ~$45–60/year (2026-04). Personal OV issuable.
- Hardware token (YubiKey HSM-compliant) required since CA/B Forum rules.
- Suitable if Trusted Signing is unavailable or cost ceiling is tight.

Avoid DigiCert ($400+/year) and EV certificates ($200+/year on top of OV)
unless SmartScreen instant-reputation is specifically required.

## Concrete TODO when signing lands

1. Issue or provision the certificate / Trusted Signing identity.
2. Add a GitHub Actions secret `VPK_SIGN_TEMPLATE` with the exact signing
   command template (e.g. `signtool sign /tr ... /td sha256 /fd sha256 {{file...}}`).
3. Set the same env var in `.github/workflows/release.yml`'s job env.
4. Re-run a release; `Setup.exe`, `*-full.nupkg`, and `*-delta.nupkg` become
   signed automatically.

No source-code changes are needed — the pipeline is already wired to pick up
the signing template when the variable is present.
