# build-from-source.ps1 — self-bootstrapping build entry point for FleetKanban.
#
# Installs the full toolchain (Go / Flutter / VS Build Tools / .NET SDK /
# PowerShell 7 / Task / buf / Velopack) via winget + go install + dotnet tool,
# then delegates the actual build to Taskfile.yml so there is no duplicated
# build logic. Idempotent — re-running only installs what is missing.
#
# Intended audience: developers who clone the repo before a tagged release
# exists. Runs under Windows PowerShell 5.1 or PowerShell 7+.
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-from-source.ps1
#   pwsh       -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-from-source.ps1 -Mode Dev
#
# Parameters:
#   -Mode Dev|Release|MSIX   Build target (default: Release → Velopack Setup.exe)
#   -SkipPrereqs             Skip winget / go install / dotnet tool checks
#   -InstallPrereqsOnly      Install toolchain and exit without building

[CmdletBinding()]
param(
    [ValidateSet('Dev','Release','MSIX')]
    [string]$Mode = 'Release',

    [switch]$SkipPrereqs,
    [switch]$InstallPrereqsOnly
)

$ErrorActionPreference = 'Stop'

$scriptsDir = $PSScriptRoot
$repoRoot   = Split-Path -Parent $scriptsDir

function Write-Section($msg) { Write-Host "`n=== $msg ===" -ForegroundColor Cyan }
function Write-Step($msg)    { Write-Host "  - $msg" -ForegroundColor Gray }
function Write-Ok($msg)      { Write-Host "  [ok] $msg" -ForegroundColor Green }
function Write-SkipMsg($msg) { Write-Host "  [skip] $msg" -ForegroundColor DarkGray }

# Re-read PATH from registry so tools installed earlier in this run are
# discoverable without requiring the user to reopen their shell.
function Update-PathFromRegistry {
    $machine = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user    = [System.Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = (@($machine, $user) | Where-Object { $_ }) -join ';'
}

function Test-Command($name) {
    return [bool](Get-Command $name -ErrorAction SilentlyContinue)
}

function Test-IsWindows11 {
    return [System.Environment]::OSVersion.Version.Build -ge 22000
}

# winget list --id <id> --exact exits 0 only when the package is installed.
function Test-WingetInstalled($id) {
    $null = winget list --id $id --exact --accept-source-agreements 2>$null
    return $LASTEXITCODE -eq 0
}

function Install-WingetPackage {
    param(
        [Parameter(Mandatory)] [string]$Id,
        [string]$Label = $Id,
        [string[]]$ExtraArgs = @()
    )
    if (Test-WingetInstalled $Id) {
        Write-SkipMsg "$Label already installed"
        return
    }
    Write-Step "Installing $Label via winget ..."
    $wingetArgs = @(
        'install','--id', $Id, '--exact',
        '--accept-package-agreements', '--accept-source-agreements',
        '--silent'
    ) + $ExtraArgs
    & winget @wingetArgs
    if ($LASTEXITCODE -ne 0) {
        Write-Error "winget install failed for $Label (exit $LASTEXITCODE)"
    }
    Write-Ok "$Label installed"
}

function Ensure-GoInstall {
    param(
        [Parameter(Mandatory)] [string]$Name,
        [Parameter(Mandatory)] [string]$Package
    )
    if (Test-Command $Name) {
        Write-SkipMsg "$Name already installed"
        return
    }
    Write-Step "go install $Package"
    & go install $Package
    if ($LASTEXITCODE -ne 0) { Write-Error "go install $Package failed" }
    Write-Ok "$Name installed"
}

# -------- pre-flight --------

if (-not (Test-IsWindows11)) {
    Write-Error "FleetKanban requires Windows 11 64-bit (build 22000+). Detected build $([System.Environment]::OSVersion.Version.Build)."
}

if (-not (Test-Command 'winget')) {
    Write-Error "winget not found. Install 'App Installer' from the Microsoft Store, then re-run this script."
}

# -------- prerequisites --------

function Install-Prerequisites {
    Write-Section "Installing prerequisites (winget)"

    # Git / Go / pwsh7 / .NET SDK are straightforward.
    Install-WingetPackage -Id 'Git.Git'              -Label 'Git for Windows'
    Install-WingetPackage -Id 'GoLang.Go'            -Label 'Go'
    Install-WingetPackage -Id 'Microsoft.PowerShell' -Label 'PowerShell 7'
    Install-WingetPackage -Id 'Microsoft.DotNet.SDK.9' -Label '.NET SDK 9'

    # VS 2022 Build Tools — C++ Desktop workload required for Flutter Windows
    # builds. Uses --override because winget's native args don't cover VS
    # workload selection. Admin elevation is handled by winget's UAC prompt.
    Install-WingetPackage -Id 'Microsoft.VisualStudio.2022.BuildTools' `
        -Label 'VS 2022 Build Tools (C++ Desktop workload)' `
        -ExtraArgs @('--override',
            '--wait --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended --quiet --norestart')

    # Flutter: winget's Flutter.Flutter lags upstream but is good enough for
    # a fresh bootstrap. If flutter is already on PATH (e.g. manual ZIP
    # install per flutter.dev), respect it.
    if (Test-Command 'flutter') {
        Write-SkipMsg "flutter already on PATH"
    } else {
        Install-WingetPackage -Id 'Flutter.Flutter' -Label 'Flutter SDK'
    }

    Update-PathFromRegistry

    # ---- Go-based tools ----
    Write-Section "Installing Go-based tooling"
    if (-not (Test-Command 'go')) {
        Write-Error "go not on PATH after install. Open a new shell and re-run, or add Go's bin directory to PATH."
    }

    # go install drops binaries into $GOBIN (or $GOPATH/bin), which winget's
    # Go package does NOT add to PATH. Prepend it for the remainder of this
    # session so subsequent tool lookups succeed.
    $goBinDir = & go env GOBIN
    if ([string]::IsNullOrWhiteSpace($goBinDir)) {
        $goBinDir = Join-Path (& go env GOPATH) 'bin'
    }
    if ($goBinDir -and ($env:Path -notlike "*$goBinDir*")) {
        $env:Path = "$goBinDir;$env:Path"
    }

    Ensure-GoInstall -Name 'task' -Package 'github.com/go-task/task/v3/cmd/task@latest'

    if (-not (Test-Command 'task')) {
        Write-Error "task not on PATH after go install. Add $goBinDir to PATH and re-run."
    }

    # Delegate proto toolchain (protoc-gen-go / -grpc / buf / protoc_plugin)
    # install to Taskfile so there is one source of truth.
    Push-Location $repoRoot
    try {
        Write-Step "task proto:tools"
        & task proto:tools
        if ($LASTEXITCODE -ne 0) { Write-Error "task proto:tools failed" }
        Write-Ok "Proto toolchain installed"
    } finally {
        Pop-Location
    }

    # ---- Velopack (vpk) via dotnet tool ----
    Write-Section "Installing Velopack CLI (vpk)"
    if (-not (Test-Command 'dotnet')) {
        Write-Error "dotnet not on PATH after .NET SDK install. Open a new shell and re-run."
    }
    if (Test-Command 'vpk') {
        Write-SkipMsg "vpk already installed"
    } else {
        Write-Step "dotnet tool install -g vpk"
        & dotnet tool install -g vpk
        if ($LASTEXITCODE -ne 0) { Write-Error "dotnet tool install vpk failed" }
        Update-PathFromRegistry
        Write-Ok "vpk installed"
    }

    # ---- Flutter: enable Windows desktop + pub get ----
    Write-Section "Configuring Flutter"
    & flutter config --enable-windows-desktop | Out-Null

    # msix is only needed for the MSIX fallback build, but activating it here
    # keeps the bootstrap self-contained (activation is a no-op if present).
    Write-Step "dart pub global activate msix"
    & dart pub global activate msix | Out-Null

    Push-Location (Join-Path $repoRoot 'ui')
    try {
        Write-Step "flutter pub get"
        & flutter pub get
        if ($LASTEXITCODE -ne 0) { Write-Error "flutter pub get failed" }
    } finally {
        Pop-Location
    }
    Write-Ok "Flutter configured"
}

if ($SkipPrereqs) {
    Write-Section "Skipping prerequisite install (-SkipPrereqs)"
    Update-PathFromRegistry
} else {
    Install-Prerequisites
}

if ($InstallPrereqsOnly) {
    Write-Section "Prerequisites installed. Exiting (-InstallPrereqsOnly)."
    exit 0
}

# -------- build --------

# Point the installed app's in-app updater at our local build/release/
# directory so re-running this script produces updates the installed
# FleetKanban sees in the Update InfoBar. VelopackUpdater reads
# `<installRoot>/current/update-feed.txt` and polls this URI's RELEASES
# file instead of GitHub. Writing it to env here causes release:pack in
# Taskfile.yml to drop the marker into the Release runner dir.
if ($Mode -eq 'Release') {
    $releaseDir = Join-Path $repoRoot 'build\release'
    New-Item -ItemType Directory -Force -Path $releaseDir | Out-Null
    # [Uri]::new handles percent-encoding for paths containing spaces or
    # non-ASCII characters (e.g. a Japanese user name in %USERPROFILE%).
    $env:FEED_URL = ([Uri]::new($releaseDir + [IO.Path]::DirectorySeparatorChar)).AbsoluteUri
    Write-Step "Local update feed: $env:FEED_URL"
}

Write-Section "Building FleetKanban ($Mode)"
Push-Location $repoRoot
try {
    switch ($Mode) {
        'Dev'     { & task flutter:run }
        'Release' { & task release:pack }
        'MSIX'    { & task build:msix }
    }
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Build failed (task exit $LASTEXITCODE)"
    }
} finally {
    Pop-Location
}

if ($Mode -eq 'Release') {
    $releaseDir = Join-Path $repoRoot 'build\release'
    Write-Section "Release artifacts"
    Write-Host "  Output directory: $releaseDir" -ForegroundColor Green
    if (Test-Path -LiteralPath $releaseDir) {
        Get-ChildItem -LiteralPath $releaseDir -File |
            Sort-Object Name |
            Select-Object Name, @{Name='Size(MB)';Expression={[math]::Round($_.Length/1MB,2)}} |
            Format-Table -AutoSize | Out-String | Write-Host
    }
    Write-Host "First install  : run build\release\com.fleetkanban.FleetKanban-win-Setup.exe" -ForegroundColor Gray
    Write-Host "Later updates  : git pull; pwsh .\scripts\build-from-source.ps1 -SkipPrereqs" -ForegroundColor Gray
    Write-Host "                 → installed app picks up the new release via the in-app Update InfoBar" -ForegroundColor Gray
}

Write-Host "`nDone." -ForegroundColor Green
