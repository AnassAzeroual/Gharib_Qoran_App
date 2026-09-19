# build_install.ps1 — build AlSiraj (Windows) + create Inno Setup installer + reinstall
#               Also: build the release APK and install it on a USB-connected Android device.
# Usage:  powershell -ExecutionPolicy Bypass -File .\build_install.ps1
#   -NoLaunch   : install but do not launch the app at the end
#   -SkipAndroid: skip the Android APK build + device install
# Rebuilds with Flutter, compiles the installer with Inno Setup,
# silently uninstalls the old copy and installs the new one.

param(
    [switch]$NoLaunch,
    [switch]$SkipAndroid
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ProjectRoot

$Flutter   = 'C:/flutter/bin/flutter.bat'
$ISCC      = "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe"
$IssScript = Join-Path $ProjectRoot 'installer\AlSiraj.iss'
$SetupExe  = Join-Path $ProjectRoot 'installer\AlSiraj-Setup.exe'
$LogFile   = Join-Path $ProjectRoot 'installer\build_install.log'

function Log([string]$Message) {
    $line = "{0}  {1}" -f (Get-Date -Format 'HH:mm:ss'), $Message
    Write-Host $line
    Add-Content -LiteralPath $LogFile -Value $line
}

if (Test-Path $LogFile) { Remove-Item $LogFile -Force }

# ---- Must run as administrator (install/uninstall into Program Files) ----
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host 'Requesting administrator rights...' -ForegroundColor Yellow
    $args = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`"")
    if ($NoLaunch) { $args += '-NoLaunch' }
    if ($SkipAndroid) { $args += '-SkipAndroid' }
    Start-Process powershell.exe -ArgumentList $args -Verb RunAs -Wait
    exit $LASTEXITCODE
}

Log '=== AlSiraj build + install ==='

# 1) Stop the running app so install/upgrade is not blocked
$proc = Get-Process -Name AlSiraj -ErrorAction SilentlyContinue
if ($proc) {
    Log "Stopping running AlSiraj ($($proc.Count) process(es))..."
    $proc | Stop-Process -Force
    Start-Sleep -Seconds 2
}

# 2) Sync resources (page images/JSON) so the build bundles the latest assets
$SyncScript = Join-Path $ProjectRoot 'sync_resources.py'
$python = (Get-Command python -ErrorAction SilentlyContinue).Source
if ($python -and (Test-Path $SyncScript)) {
    Log 'Syncing resources (python sync_resources.py)...'
    & $python $SyncScript
    if ($LASTEXITCODE -ne 0) { throw 'sync_resources.py failed' }
} else {
    Log 'sync_resources.py or python not found — skipping resource sync.'
}

# 3) Build the Windows release
Log 'Building Windows release (flutter build windows --release)...'
& $Flutter build windows --release
if ($LASTEXITCODE -ne 0) { throw 'Flutter build failed' }

# 4) Compile the Inno Setup installer
Log 'Compiling installer with Inno Setup...'
if (-not (Test-Path $ISCC)) { throw "Inno Setup not found at: $ISCC" }
& $ISCC $IssScript | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Inno Setup compile failed' }
if (-not (Test-Path $SetupExe)) { throw "Installer not produced: $SetupExe" }
Log "Installer ready: $SetupExe"

# 5) Find and silently remove the old installation
function Get-AlSirajUninstaller {
    $roots = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    foreach ($root in $roots) {
        $items = Get-ItemProperty $root -ErrorAction SilentlyContinue
        foreach ($item in $items) {
            if ($item.UninstallString -and ($item.UninstallString -match 'AlSiraj' -or $item.DisplayName -match 'السراج|AlSiraj')) {
                return (($item.UninstallString -replace '^"([^"]+)".*$', '$1').Trim())
            }
        }
    }
    return $null
}

$uninstaller = Get-AlSirajUninstaller
if ($uninstaller -and (Test-Path $uninstaller)) {
    Log "Uninstalling old version ($uninstaller)..."
    & $uninstaller /VERYSILENT /SUPPRESSMSGBOXES /NORESTART
    Start-Sleep -Seconds 3
} else {
    Log 'No previous installation found — skipping uninstall.'
}

# 6) Install the new version silently
Log 'Installing new version...'
$p = Start-Process -FilePath $SetupExe -ArgumentList '/VERYSILENT','/SUPPRESSMSGBOXES','/NORESTART' -Wait -PassThru
if ($p.ExitCode -ne 0) { throw "Installer failed with exit code $($p.ExitCode)" }

# 7) Verify
$installed = @(
    "$env:ProgramFiles\AlSiraj\AlSiraj.exe",
    "${env:ProgramFiles(x86)}\AlSiraj\AlSiraj.exe",
    "$env:LOCALAPPDATA\Programs\AlSiraj\AlSiraj.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $installed) { throw 'Install completed but AlSiraj.exe was not found' }
Log "Installed OK: $installed"

if ($NoLaunch) { Log 'Done (install only).' } else {
    Log 'Launching AlSiraj...'
    Start-Process $installed
    Log 'Done.'
}

# 8) Android: build the slim release APK and install it on a USB-connected device
function Find-Adb {
    $sdk = $env:ANDROID_HOME
    if (-not $sdk) { $sdk = "$env:LOCALAPPDATA\Android\Sdk" }
    $adb = Join-Path $sdk 'platform-tools\adb.exe'
    if (-not (Test-Path $adb)) { $adb = (Get-Command adb -ErrorAction SilentlyContinue).Source }
    return $adb
}

if (-not $SkipAndroid) {
    $adb = Find-Adb
    if (-not $adb) {
        Log 'Android SDK (adb) not found — skipping APK install.'
    } else {
        $devices = & $adb devices | Where-Object { $_ -match '^\S+\s+device$' }
        if (-not $devices) {
            Log 'No Android device connected (adb devices) — skipping APK install.'
        } else {
            Log 'Building release APK (arm64 + arm)...'
            & $Flutter build apk --release --target-platform android-arm64,android-arm
            if ($LASTEXITCODE -ne 0) { throw 'Flutter APK build failed' }
            $apk = Join-Path $ProjectRoot 'build\app\outputs\flutter-apk\app-release.apk'
            if (-not (Test-Path $apk)) { throw "APK not produced: $apk" }
            foreach ($line in $devices) {
                $serial = ($line -split '\s+')[0]
                Log "Installing APK on $serial..."
                & $adb -s $serial install -r $apk
                if ($LASTEXITCODE -ne 0) {
                    Log "Install failed (exit $LASTEXITCODE). Retrying after uninstall (signature mismatch after key rotation)..."
                    & $adb -s $serial uninstall com.siraj.alsiraj | Out-Null
                    & $adb -s $serial install -r $apk
                    if ($LASTEXITCODE -ne 0) { throw "adb install failed on $serial" }
                }
            }
            Log 'APK installed on device(s).'
        }
    }
}