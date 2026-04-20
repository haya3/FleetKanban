# Security Policy

## Supported Versions

FleetKanban is in Phase 1 development, so **only the latest `main` branch is
supported at this time**. After Phase 1 GA (v0.1.0), we plan to support the
current minor and the previous one.

| Version | Supported |
| --- | --- |
| `main` (pre-release) | ✅ |
| Anything else | ❌ |

## Reporting a Vulnerability

**Do not report vulnerabilities in a public GitHub Issue.**

Use one of the non-public channels below. We aim to acknowledge reports within
72 hours.

1. **GitHub Security Advisories** (recommended)
   - Open the [Security tab](../../security/advisories/new), choose
     "Report a vulnerability", and submit the details.
   - Lets us run the entire flow privately: discussion, patch review, and
     CVE issuance.

2. **Email**
   - Prefix the subject with `[FleetKanban SECURITY]` and include:
     - Affected component (sidecar / ui / proto / build, etc.)
     - Reproduction steps
     - Expected impact (RCE / data exfiltration / DoS, etc.)
     - References (relevant PoC / CVE / prior incidents)

## Response Timeline

| Stage | Target |
| --- | --- |
| Initial acknowledgement (receipt) | within 72 hours |
| Initial triage (severity assessment) | within 7 days |
| Fix release | 14–90 days depending on severity |
| Public advisory | promptly after the fix release |

Severity is rated against [CVSS 4.0](https://www.first.org/cvss/v4-0/), and
the timeline is adjusted accordingly. We assume **responsible disclosure** —
please withhold public details until the agreed window has elapsed.

## Out of Scope

The following are not treated as vulnerabilities:

- Local builds being flagged by Windows SmartScreen
  (Phase 1 ships unsigned by design)
- DPAPI decryption by a user who has already obtained local administrator
  privileges (DPAPI is designed to operate within a single user scope)
- Vulnerabilities in the Copilot CLI itself, the GitHub API, or the Windows
  OS itself (please report to the relevant upstream project)

## Safe Defaults

The security design invariants FleetKanban currently upholds:

- **gRPC binds to 127.0.0.1 only and requires token auth**
  (`sidecar/cmd/fleetkanban-sidecar/main.go`)
- **GitHub PAT is encrypted with Windows DPAPI** and scoped to the user
  (`sidecar/internal/app/secrets_dpapi.go`)
- **Copilot sessions cannot write outside the worktree cwd**
  (canonical-path comparison in `ResolvePath` at
  `sidecar/internal/copilot/permission.go`)
- **Goal / ReviewFeedback are sanitized** before being embedded in prompts
  (`sidecar/internal/copilot/prompt.go`)
- **Automatic push / PR / merge are permanently forbidden**
