# instalation_dev_env_windows.ps1 - one-shot dev environment setup for AlSiraj (Windows).
# Installs: Git, Python 3.12, Flutter SDK (stable, C:\flutter), Android SDK
# pieces (via Android Studio + cmdline-tools), Inno Setup 6. Then runs
# flutter pub get + sync_resources.py so the project builds.
# Usage:
#   Right-click -> Run with PowerShell (interactive, prompts before each step)
#   .\instalation_dev_env_windows.ps1 -Yes                : non-interactive, install all missing
#   .\instalation_dev_env_windows.ps1 -FlutterOnly -Yes   : only Flutter SDK
#   .\instalation_dev_env_windows.ps1 -PythonOnly -Yes    : only Python
#   .\instalation_dev_env_windows.ps1 -NoAndroid -Yes      : skip Android/Inno steps
# Flags are opt-in filters; with no filter flags everything missing is offered.

param(
    [switch]$Yes,
    [switch]$FlutterOnly,
    [switch]$PythonOnly,
    [switch]$NoAndroid,
    [switch]$NoMenu
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ProjectRoot

$FlutterDir = 'C:\flutter'
$FlutterBat = 'C:\flutter\bin\flutter.bat'
$DartBat = 'C:\flutter\bin\dart.bat'

function Test-Cmd([string]$Name) {
    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Confirm-Step([string]$Message) {
    if ($Yes) { return $true }
    $ans = Read-Host "$Message [Y/n]"
    $ans = $ans.Trim().ToLowerInvariant()
    return ($ans -eq '' -or $ans -eq 'y' -or $ans -eq 'yes')
}

function Install-Winget([string]$Id, [string]$Label) {
    Write-Host "Installing $Label ($Id) via winget..." -ForegroundColor Cyan
    winget install --exact --id $Id --source winget --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) { throw "winget install failed for $Id (exit $LASTEXITCODE)" }
}

function Refresh-PathEnv {
    $machine = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user = [System.Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = "$machine;$user"
}

function Add-UserPathOnce([string]$Dir) {
    $user = [System.Environment]::GetEnvironmentVariable('Path', 'User')
    if ($user -notlike "*$Dir*") {
        [System.Environment]::SetEnvironmentVariable(
            'Path', ($user.TrimEnd(';') + ";$Dir"), 'User')
        Write-Host "Added $Dir to User PATH." -ForegroundColor Green
    }
    Refresh-PathEnv
}

# ---- 0) Preconditions -------------------------------------------------------
if (-not (Test-Cmd 'winget')) {
    throw 'winget not found. Install "App Installer" from the Microsoft Store, then re-run.'
}
$hasFilter = $FlutterOnly -or $PythonOnly
$doFlutter = if ($hasFilter) { $FlutterOnly } else { $true }
$doPython = if ($hasFilter) { $PythonOnly } else { $true }
$doAndroid = -not $NoAndroid -and -not $hasFilter

# ---- 1) Git (needed to clone Flutter) ----------------------------------------
if ($doFlutter -and -not (Test-Cmd 'git')) {
    if (Confirm-Step 'Git is missing. Install Git.Git?') {
        Install-Winget 'Git.Git' 'Git'
        Refresh-PathEnv
    }
}

# ---- 2) Python 3.12 (needed by sync_resources.py) -----------------------------
if ($doPython) {
    $py = Get-Command python -ErrorAction SilentlyContinue
    $pyOk = $false
    if ($py) {
        try {
            $v = & python --version 2>&1 | Out-String
            Write-Host "Found: $v" -ForegroundColor Gray
            if ($v -match 'Python 3\.') { $pyOk = $true }
        } catch { $pyOk = $false }
    }
    if (-not $pyOk) {
        if (Confirm-Step 'Python 3 is missing. Install Python.Python.3.12?') {
            Install-Winget 'Python.Python.3.12' 'Python 3.12'
            Refresh-PathEnv
        }
    } else {
        Write-Host 'Python OK, skipping install.' -ForegroundColor Green
    }
}

# ---- 3) Flutter SDK (stable -> C:\flutter) ------------------------------------
if ($doFlutter) {
    if (Test-Path $FlutterBat) {
        Write-Host "Flutter OK at $FlutterBat, skipping clone." -ForegroundColor Green
    } else {
        if ((Test-Path $FlutterDir) -and -not (Test-Path $FlutterBat)) {
            throw "Found partial/broken SDK at $FlutterDir (flutter.bat missing). Delete it manually and re-run."
        }
        if (Confirm-Step "Clone Flutter stable into $FlutterDir? (needs admin, ~1.5GB)") {
            if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
                    [Security.Principal.WindowsBuiltInRole]::Administrator)) {
                Write-Host 'Re-launching as administrator for the Flutter clone...' -ForegroundColor Yellow
                $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`"")
                if ($Yes) { $argList += '-Yes' }
                if ($NoMenu) { $argList += '-NoMenu' }
                if ($FlutterOnly) { $argList += '-FlutterOnly' }
                if ($PythonOnly) { $argList += '-PythonOnly' }
                if ($NoAndroid) { $argList += '-NoAndroid' }
                Start-Process powershell.exe -ArgumentList $argList -Verb RunAs -Wait
                exit $LASTEXITCODE
            }
            if (-not (Test-Cmd 'git')) { throw 'Git is required to clone Flutter but was not found.' }
            git clone https://github.com/flutter/flutter.git -b stable $FlutterDir
            if ($LASTEXITCODE -ne 0) { throw "Flutter clone failed (exit $LASTEXITCODE)" }
        }
    }
    if (Test-Path $FlutterBat) {
        Write-Host 'Running flutter --version (first run warms up the SDK)...' -ForegroundColor Cyan
        Add-UserPathOnce 'C:\flutter\bin'
        & $FlutterBat --version
        Write-Host 'Running flutter precache (windows + android artifacts)...' -ForegroundColor Cyan
        & $FlutterBat precache --windows --android
    }
}

# ---- 4) Android SDK + Inno Setup (skipped with -NoAndroid) ---------------------
if ($doAndroid) {
    $sdk = $env:ANDROID_HOME
    if ([string]::IsNullOrWhiteSpace($sdk)) { $sdk = "$env:LOCALAPPDATA\Android\Sdk" }
    $adb = Join-Path $sdk 'platform-tools\adb.exe'
    if (Test-Path $adb) {
        Write-Host "Android SDK OK at $sdk, skipping install." -ForegroundColor Green
    } else {
        if (Confirm-Step 'Android SDK not found. Install Android Studio (includes SDK + adb)?') {
            Install-Winget 'Google.AndroidStudio' 'Android Studio'
            Write-Host 'Open Android Studio once and finish the SDK wizard, then re-run this script.' -ForegroundColor Yellow
        }
    }
    $iscc = "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe"
    $isccAlt = "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe"
    if ((Test-Path $iscc) -or (Test-Path $isccAlt)) {
        Write-Host 'Inno Setup 6 OK, skipping install.' -ForegroundColor Green
    } else {
        if (Confirm-Step 'Inno Setup 6 is missing. Install it (Windows installer builds)?') {
            Install-Winget 'JRSoftware.InnoSetup' 'Inno Setup 6'
        }
    }
}

# ---- 5) Project dependencies ---------------------------------------------------
function Invoke-PubGet {
    if (-not (Test-Path $FlutterBat)) {
        Write-Host 'Flutter not installed, skipping flutter pub get.' -ForegroundColor Yellow
        return
    }
    & $FlutterBat pub get
    if ($LASTEXITCODE -ne 0) { throw "flutter pub get failed (exit $LASTEXITCODE)" }
}

function Invoke-SyncResources {
    $syncScriptPath = Join-Path $ProjectRoot 'sync_resources.py'
    if (-not (Test-Cmd 'python')) {
        Write-Host 'Skipping sync_resources.py (python not found).' -ForegroundColor Yellow
        return
    }
    if (-not (Test-Path $syncScriptPath)) {
        Write-Host 'Skipping sync_resources.py (script not found).' -ForegroundColor Yellow
        return
    }
    python $syncScriptPath
    if ($LASTEXITCODE -ne 0) { throw "sync_resources.py failed (exit $LASTEXITCODE)" }
}

if (Test-Path $FlutterBat) {
    if (Confirm-Step 'Run flutter pub get in quran-app?') {
        Invoke-PubGet
    }
} else {
    Write-Host 'Flutter not installed, skipping flutter pub get.' -ForegroundColor Yellow
}

$syncPy = Join-Path $ProjectRoot 'sync_resources.py'
if ((Test-Cmd 'python') -and (Test-Path $syncPy)) {
    if (Confirm-Step 'Run python sync_resources.py (copy pages + build indexes)?') {
        Invoke-SyncResources
    }
} else {
    Write-Host 'Skipping sync_resources.py (need python + sync_resources.py).' -ForegroundColor Yellow
}

# ---- 6) Status checks + stay-open summary menu ----------------------------------
function Get-EnvStatus {
    $rows = @()
    $gitCmd = Get-Command git -ErrorAction SilentlyContinue
    $gitDetail = 'not found'
    if ($gitCmd) {
        try { $gitDetail = (((& git --version 2>$null | Out-String).Trim()) -split "`r?`n")[0] } catch { $gitDetail = $gitCmd.Source }
    }
    $rows += [pscustomobject]@{ Name = 'Git'; Ok = ($gitCmd -ne $null); Detail = $gitDetail }

    $pyCmd = Get-Command python -ErrorAction SilentlyContinue
    $pyOk = $false
    $pyDetail = 'not found'
    if ($pyCmd) {
        try {
            $rawPy = ((& python --version 2>&1 | Out-String).Trim())
            if ($LASTEXITCODE -ne 0) {
                $pyDetail = 'not found'
            } else {
                $pyDetail = ($rawPy -split "`r?`n")[0]
                if ($pyDetail -match 'Python 3\.') { $pyOk = $true }
            }
        } catch { $pyDetail = 'not found' }
    }
    $rows += [pscustomobject]@{ Name = 'Python 3'; Ok = $pyOk; Detail = $pyDetail }

    $flutterOk = Test-Path $FlutterBat
    $rows += [pscustomobject]@{ Name = 'Flutter SDK'; Ok = $flutterOk; Detail = $(if ($flutterOk) { $FlutterBat } else { 'not found (expected C:\flutter)' }) }
    $rows += [pscustomobject]@{ Name = 'Dart'; Ok = (Test-Path $DartBat); Detail = $(if (Test-Path $DartBat) { $DartBat } else { 'comes with Flutter' }) }

    $sdkDir = $env:ANDROID_HOME
    if ([string]::IsNullOrWhiteSpace($sdkDir)) { $sdkDir = "$env:LOCALAPPDATA\Android\Sdk" }
    $adbPath = Join-Path $sdkDir 'platform-tools\adb.exe'
    $rows += [pscustomobject]@{ Name = 'Android SDK'; Ok = (Test-Path $adbPath); Detail = $(if (Test-Path $adbPath) { $sdkDir } else { 'not found' }) }

    $isccPath = "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe"
    $isccAltPath = "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe"
    $isccFound = ''
    if (Test-Path $isccPath) { $isccFound = $isccPath } elseif (Test-Path $isccAltPath) { $isccFound = $isccAltPath }
    $rows += [pscustomobject]@{ Name = 'Inno Setup 6'; Ok = ($isccFound -ne ''); Detail = $(if ($isccFound -ne '') { $isccFound } else { 'not found' }) }

    $pubCfg = Join-Path $ProjectRoot '.dart_tool\package_config.json'
    $rows += [pscustomobject]@{ Name = 'Pub deps'; Ok = (Test-Path $pubCfg); Detail = $(if (Test-Path $pubCfg) { 'ready' } else { 'run flutter pub get' }) }

    $imgDir = Join-Path $ProjectRoot 'assets\images'
    $jsonDir = Join-Path $ProjectRoot 'assets\json'
    $imgCount = 0
    $jsonCount = 0
    try { $imgCount = (Get-ChildItem $imgDir -Filter *.png -ErrorAction SilentlyContinue | Measure-Object).Count } catch { $imgCount = 0 }
    try { $jsonCount = (Get-ChildItem $jsonDir -Filter *.json -ErrorAction SilentlyContinue | Measure-Object).Count } catch { $jsonCount = 0 }
    $idxOk = (Test-Path (Join-Path $ProjectRoot 'assets\surah_index.json')) -and (Test-Path (Join-Path $ProjectRoot 'assets\search_index.json'))
    $rows += [pscustomobject]@{ Name = 'App assets'; Ok = ($idxOk -and ($imgCount -gt 0)); Detail = "images $imgCount, json $jsonCount" }

    return $rows
}

function Show-Summary {
    Write-Host '================================================' -ForegroundColor Cyan
    Write-Host '        Dev environment - summary' -ForegroundColor Cyan
    Write-Host '================================================' -ForegroundColor Cyan
    $statusRows = Get-EnvStatus
    foreach ($row in $statusRows) {
        if ($row.Ok) {
            Write-Host ('  [OK]      ' + $row.Name + ' - ' + $row.Detail) -ForegroundColor Green
        } else {
            Write-Host ('  [MISSING] ' + $row.Name + ' - ' + $row.Detail) -ForegroundColor Red
        }
    }
    $missing = @($statusRows | Where-Object { -not $_.Ok }).Count
    Write-Host '  ----------------------------------------------'
    if ($missing -eq 0) {
        Write-Host '  Everything is ready. Happy coding.' -ForegroundColor Green
    } else {
        Write-Host "  $missing item(s) still missing - pick 1 to install them." -ForegroundColor Yellow
    }
    Write-Host '  If Flutter was just installed, restart the terminal so PATH picks up C:\flutter\bin.'
}

if ($NoMenu) {
    Show-Summary
    Write-Host 'DONE.'
    exit 0
}

while ($true) {
    Clear-Host
    Show-Summary
    Write-Host ''
    Write-Host '  1. Install all missing now (no prompts)'
    Write-Host '  2. flutter doctor'
    Write-Host '  3. flutter pub get'
    Write-Host '  4. python sync_resources.py'
    Write-Host '  5. Open AlSiraj control center'
    Write-Host '  R. Refresh status'
    Write-Host '  Q. Quit'
    Write-Host ''
    $choice = (Read-Host '  Choose').Trim().ToLowerInvariant()
    Write-Host ''

    switch -Regex ($choice) {
        '^1$' {
            $forwardArgs = @('-Yes', '-NoMenu')
            if ($FlutterOnly) { $forwardArgs += '-FlutterOnly' }
            if ($PythonOnly) { $forwardArgs += '-PythonOnly' }
            if ($NoAndroid) { $forwardArgs += '-NoAndroid' }
            & $PSCommandPath @forwardArgs
            Read-Host 'Press Enter to continue' | Out-Null
        }
        '^2$' {
            if (Test-Path $FlutterBat) { & $FlutterBat doctor } else { Write-Host 'Flutter not installed.' -ForegroundColor Yellow }
            Read-Host 'Press Enter to continue' | Out-Null
        }
        '^3$' {
            Invoke-PubGet
            Read-Host 'Press Enter to continue' | Out-Null
        }
        '^4$' {
            Invoke-SyncResources
            Read-Host 'Press Enter to continue' | Out-Null
        }
        '^5$' {
            $alsirajPath = Join-Path $ProjectRoot 'alsiraj.ps1'
            if (Test-Path $alsirajPath) {
                Start-Process powershell.exe -ArgumentList @('-NoExit', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$alsirajPath`"") -WorkingDirectory $ProjectRoot
            } else {
                Write-Host 'alsiraj.ps1 not found.' -ForegroundColor Yellow
                Read-Host 'Press Enter to continue' | Out-Null
            }
        }
        '^r$' { }
        '^q$' { return }
        default {
            Write-Host 'Unknown choice.' -ForegroundColor Yellow
            Start-Sleep -Seconds 1
        }
    }
}
