# build_install.ps1 - build/install AlSiraj (Windows and/or Android).
# Usage:
#   .\build_install.ps1                 : Windows build+install AND Android release APK+install
#   .\build_install.ps1 -Windows        : only Windows build + Inno installer + install
#   .\build_install.ps1 -AndroidRelease : only build signed release APK + USB install
#   .\build_install.ps1 -AndroidDebug   : only build debug APK + USB install
#   .\build_install.ps1 -Aab            : only build release AAB for Google Play
#   -NoLaunch   : install but do not launch the app at the end
#   -SkipAndroid: (legacy) same as -Windows

param(
    [switch]$NoLaunch,
    [switch]$SkipAndroid,
    [switch]$Windows,
    [switch]$AndroidRelease,
    [switch]$AndroidDebug,
    [switch]$Aab
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ProjectRoot

# ---- Which targets to run? ---------------------------------------------------
$hasMode = $Windows -or $AndroidRelease -or $AndroidDebug -or $Aab
if ($hasMode) {
    $doWindows        = $Windows
    $doAndroid        = $AndroidRelease -or $AndroidDebug
} else {
    $doWindows        = $true
    $doAndroid        = -not $SkipAndroid
}
$doAndroidRelease = if ($AndroidDebug) { $false } elseif ($hasMode) { $AndroidRelease } else { $doAndroid }
$doAndroidDebug   = $AndroidDebug
$doAab            = $Aab

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

# Runs a native tool so NEITHER its stdout nor its stderr can poison the
# session. Proven rules on this machine (PS 5.1, flutter + JDK print to
# stderr constantly):
# - uncaptured stdout inside a captured call pollutes the return value
#   (re-emit via Write-Host, which never enters the pipeline);
# - ANY redirected/merged native stderr (2>file, 2>&1) materializes into
#   error records that detonate at a later innocent statement under
#   $ErrorActionPreference = 'Stop' — even when the tool succeeded.
# So: stdout streams via Write-Host, stderr goes to a temp log shown only
# on failure. The exit code stays the only failure signal.
function Invoke-NativeCode([string]$Exe, [string[]]$ToolArgs) {
    $prevPref = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $errLog = Join-Path ([System.IO.Path]::GetTempPath()) 'alsiraj_native_err.log'
        if (Test-Path $errLog) { Remove-Item $errLog -Force }
        & $Exe @ToolArgs 2>$errLog | ForEach-Object { Write-Host "$_" }
        $code = $LASTEXITCODE
        if ($code -ne 0 -and (Test-Path $errLog)) {
            Get-Content $errLog | ForEach-Object { Log "ERR: $_" }
        }
        Remove-Item $errLog -Force -ErrorAction SilentlyContinue
        return $code
    } finally {
        $ErrorActionPreference = $prevPref
    }
}

function Invoke-Native([string]$Exe, [string[]]$ToolArgs, [string]$What) {
    $code = Invoke-NativeCode $Exe $ToolArgs
    if ($code -ne 0) { throw "$What failed (exit $code, see $LogFile)" }
}

# ---- Must run as administrator for the Windows install step ----
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)) {
    if ($doWindows) {
        Write-Host 'Requesting administrator rights...' -ForegroundColor Yellow
        $args = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`"")
        foreach ($flag in @('NoLaunch', 'Windows', 'AndroidRelease', 'AndroidDebug', 'Aab')) {
            if ((Get-Variable $flag -ValueOnly)) { $args += "-$flag" }
        }
        Start-Process powershell.exe -ArgumentList $args -Verb RunAs -Wait
        exit $LASTEXITCODE
    } else {
        Write-Host 'Running Android-only steps (no admin needed).'
    }
}

Log '=== AlSiraj build + install ==='

# 1) Stop the running app so install/upgrade is not blocked.
# .NET API instead of Get-Process: it returns an empty array (never an
# error record), keeping $Error clean for stream-merging callers.
$proc = [System.Diagnostics.Process]::GetProcessesByName('AlSiraj')
if ($proc -and $proc.Count -gt 0) {
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

if ($doWindows) {

# 3) Build the Windows release
Log 'Building Windows release (flutter build windows --release)...'
Invoke-Native $Flutter @('build', 'windows', '--release') 'Flutter Windows build'

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
    Invoke-NativeCode $uninstaller @('/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART') | Out-Null
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

}

# 8) Android: build the slim release APK and install it on a USB-connected device
function Find-Adb {
    $sdk = $env:ANDROID_HOME
    if (-not $sdk) { $sdk = "$env:LOCALAPPDATA\Android\Sdk" }
    $adb = Join-Path $sdk 'platform-tools\adb.exe'
    if (-not (Test-Path $adb)) { $adb = (Get-Command adb -ErrorAction SilentlyContinue).Source }
    return $adb
}

if ($doAndroidRelease -or $doAndroidDebug) {
    # The APK always builds; only the USB install needs a device (without
    # one the APK stays ready for manual transfer, e.g. via WhatsApp).
    if ($doAndroidRelease) {
        Log 'Building release APK (arm64 + arm)...'
        Invoke-Native $Flutter @('build', 'apk', '--release', '--target-platform', 'android-arm64,android-arm') 'Flutter APK build'
        $apk = Join-Path $ProjectRoot 'build\app\outputs\flutter-apk\app-release.apk'
    } else {
        Log 'Building debug APK (arm64 + arm)...'
        Invoke-Native $Flutter @('build', 'apk', '--debug', '--target-platform', 'android-arm64,android-arm') 'Flutter APK build'
        $apk = Join-Path $ProjectRoot 'build\app\outputs\flutter-apk\app-debug.apk'
    }
    if (-not (Test-Path $apk)) { throw "APK not produced: $apk" }
    Log "APK built: $apk"
    $adb = Find-Adb
    if (-not $adb) {
        Log 'Android SDK (adb) not found — skipping USB install.'
    } else {
        $devices = & $adb devices | Where-Object { $_ -match '^\S+\s+device$' }
        if (-not $devices) {
            Log 'No Android device connected (adb devices) — skipping USB install.'
        } else {
            foreach ($line in $devices) {
                $serial = ($line -split '\s+')[0]
                Log "Installing APK on $serial..."
                $code = Invoke-NativeCode $adb @('-s', $serial, 'install', '-r', $apk)
                if ($code -ne 0) {
                    Log "Install failed (exit $code). Retrying after uninstall (signature mismatch after key rotation)..."
                    Invoke-NativeCode $adb @('-s', $serial, 'uninstall', 'com.siraj.alsiraj') | Out-Null
                    Invoke-Native $adb @('-s', $serial, 'install', '-r', $apk) "adb install on $serial"
                }
            }
            Log 'APK installed on device(s).'
        }
    }
}

if ($doAab) {
    Log 'Building release App Bundle (arm64 + arm)...'
    Invoke-Native $Flutter @('build', 'appbundle', '--release', '--target-platform', 'android-arm64,android-arm') 'Flutter AAB build'
    $aab = $ProjectRoot + '\build\app\outputs\bundle\release\app-release.aab'
    if (-not [System.IO.File]::Exists($aab)) { throw "AAB not produced: $aab" }
    Log "AAB ready: $aab (upload to Google Play Console)"
}

if (-not ($doWindows -or $doAndroidRelease -or $doAndroidDebug -or $doAab)) {
    Log 'Nothing to do — pass at least one target (-Windows / -AndroidRelease / -AndroidDebug / -Aab).'
}

Log 'Done.'