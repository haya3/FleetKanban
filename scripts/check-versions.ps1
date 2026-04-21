# check-versions.ps1 — gate builds on ProtocolVersion / AppVersion sync.
#
# A ProtocolVersion mismatch causes SidecarSupervisor to kill the running
# sidecar on every connect (see ui/lib/app/version.dart); an AppVersion
# mismatch misreports the build in the About dialog and in error reports.
# Both are easy to forget when landing a proto change, so we guard every
# build entry point (build:sidecar / flutter:build) on this script.
#
# Sources of truth:
#   - sidecar/internal/branding/branding.go — ProtocolVersion, AppVersion
#   - ui/lib/app/version.dart               — expectedSidecarProtocolVersion, appVersion
#   - ui/pubspec.yaml                       — version: <appVersion>[+build]
#
# Exits non-zero on mismatch with a diff showing what needs to change.

$ErrorActionPreference = 'Stop'

$repoRoot   = Split-Path -Parent $PSScriptRoot
$branding   = Join-Path $repoRoot 'sidecar\internal\branding\branding.go'
$versionDart= Join-Path $repoRoot 'ui\lib\app\version.dart'
$pubspec    = Join-Path $repoRoot 'ui\pubspec.yaml'

function Require-File($path) {
    if (-not (Test-Path -LiteralPath $path)) {
        Write-Error "check-versions.ps1: missing $path"
    }
}
Require-File $branding
Require-File $versionDart
Require-File $pubspec

function Extract-Match($path, $pattern, $label) {
    $content = Get-Content -LiteralPath $path -Raw
    $m = [regex]::Match($content, $pattern)
    if (-not $m.Success) {
        Write-Error "check-versions.ps1: failed to locate $label in $path"
    }
    return $m.Groups[1].Value
}

$sidecarProto = Extract-Match $branding    'ProtocolVersion\s*=\s*(\d+)'                   'ProtocolVersion (branding.go)'
$sidecarApp   = Extract-Match $branding    'AppVersion\s*=\s*"([^"]+)"'                    'AppVersion (branding.go)'
$uiProto      = Extract-Match $versionDart 'expectedSidecarProtocolVersion\s*=\s*(\d+)'    'expectedSidecarProtocolVersion (version.dart)'
$uiApp        = Extract-Match $versionDart "appVersion\s*=\s*'([^']+)'"                    'appVersion (version.dart)'
$pubApp       = Extract-Match $pubspec     '(?m)^version:\s*([^\s+]+)'                     'version: (pubspec.yaml)'

$fail = $false

if ($sidecarProto -ne $uiProto) {
    Write-Host "ProtocolVersion mismatch:" -ForegroundColor Red
    Write-Host "  sidecar/internal/branding/branding.go: $sidecarProto"
    Write-Host "  ui/lib/app/version.dart              : $uiProto"
    $fail = $true
}

if ($sidecarApp -ne $uiApp -or $uiApp -ne $pubApp) {
    Write-Host "AppVersion mismatch:" -ForegroundColor Red
    Write-Host "  sidecar/internal/branding/branding.go: $sidecarApp"
    Write-Host "  ui/lib/app/version.dart              : $uiApp"
    Write-Host "  ui/pubspec.yaml                      : $pubApp"
    $fail = $true
}

if ($fail) {
    Write-Host ""
    Write-Host "Bump all three in the same commit when landing a proto change or a release." -ForegroundColor Yellow
    exit 1
}

Write-Host "Versions in sync: protocol=$sidecarProto, app=$sidecarApp"
