# bump_version.ps1 - bump the AlSiraj app version in all 3 places at once.
# Usage:   powershell -ExecutionPolicy Bypass -File .\bump_version.ps1 -Patch
#          powershell -ExecutionPolicy Bypass -File .\bump_version.ps1 -Minor
#          powershell -ExecutionPolicy Bypass -File .\bump_version.ps1 -Major
#   -Patch / -Minor / -Major : which semantic part to increment (pick exactly one)
#   -Build                   : also increment the Android build number (+N)
#   (no flags)               : interactive mode - answers prompts one by one,
#                              perfect for right-click > "Run with PowerShell".
# Updates: pubspec.yaml `version:`, lib/version.dart kAppVersion,
#          installer/AlSiraj.iss MyAppVersion. Verifies all three agree first.

param(
    [switch]$Patch,
    [switch]$Minor,
    [switch]$Major,
    [switch]$Build
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

function Read-Text([string]$Path) { [System.IO.File]::ReadAllText($Path) }
function Write-Text([string]$Path, [string]$Content) {
    $utf8 = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $utf8)
}

# ---- Read current version from the source of truth: pubspec.yaml -------------
$PubspecPath = Join-Path $ProjectRoot 'pubspec.yaml'
$DartPath    = Join-Path $ProjectRoot 'lib\version.dart'
$IssPath     = Join-Path $ProjectRoot 'installer\AlSiraj.iss'

$pubspecText = Read-Text $PubspecPath
$m = [regex]::Match($pubspecText, '(?m)^\s*version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)\s*$')
if (-not $m.Success) { throw "Could not parse version in $PubspecPath" }

$verMajor = [int]$m.Groups[1].Value
$verMinor = [int]$m.Groups[2].Value
$verPatch = [int]$m.Groups[3].Value
$vers     = "$verMajor.$verMinor.$verPatch"

# ---- Safety: the other two places must match pubspec -------------------------
if (-not ((Read-Text $DartPath) -match "kAppVersion = '$([regex]::Escape($vers))'")) {
    throw "lib/version.dart does not match version $vers - fix drift before bumping"
}
if (-not ((Read-Text $IssPath) -match ('#define\s+MyAppVersion\s+"' + [regex]::Escape($vers) + '"'))) {
    throw "installer/AlSiraj.iss does not match version $vers - fix drift before bumping"
}

$oldBuild = [int]$m.Groups[4].Value

# ---- Which bump? ------------------------------------------------------------
$bumps = 0
if ($Patch) { $bumps++ }
if ($Minor) { $bumps++ }
if ($Major) { $bumps++ }
if ($bumps -gt 1) { throw 'Pass only ONE of: -Patch, -Minor, -Major' }

$applyPatch = $Patch
$applyMinor = $Minor
$applyMajor = $Major
$interactive = $bumps -eq 0

if ($interactive) {
    Write-Host ''
    Write-Host "Current version: $vers+$oldBuild" -ForegroundColor Cyan
    Write-Host ''
    $choice = Read-Host 'Bump type? [P]atch, [M]inor, Ma[j]or (Enter = Patch)'
    switch -Regex ($choice.Trim().ToLowerInvariant()) {
        '^m'    { $applyMinor = $true }
        '^j'    { $applyMajor = $true }
        default { $applyPatch = $true }
    }
    $tickBuild = Read-Host 'Also tick Android build number (+N)? [y/N]'
    if ($tickBuild -match '^y') { $Build = $true }
    Write-Host ''
}

# ---- Compute new version -----------------------------------------------------
if ($applyMajor) { $verMajor++; $verMinor = 0; $verPatch = 0 }
elseif ($applyMinor) { $verMinor++; $verPatch = 0 }
else { $verPatch++ }

$newVer = "$verMajor.$verMinor.$verPatch"

$newBuild = $oldBuild
if ($Build) { $newBuild++ }

Write-Host "Bumping:  $vers+$oldBuild  ->  $newVer+$newBuild"

# ---- Apply -------------------------------------------------------------------
$oldLine = "version: $vers+$oldBuild"
$newLine = "version: $newVer+$newBuild"
if (-not $pubspecText.Contains($oldLine)) { throw "pubspec.yaml: expected '$oldLine' not found" }
Write-Text $PubspecPath ($pubspecText.Replace($oldLine, $newLine))

$dartText = Read-Text $DartPath
$oldConst = "kAppVersion = '$vers'"
$newConst = "kAppVersion = '$newVer'"
if (-not $dartText.Contains($oldConst)) { throw "lib/version.dart: expected '$oldConst' not found" }
Write-Text $DartPath ($dartText.Replace($oldConst, $newConst))

$issText = Read-Text $IssPath
$oldIss = "#define MyAppVersion `"$vers`""
$newIss = "#define MyAppVersion `"$newVer`""
if (-not $issText.Contains($oldIss)) { throw "AlSiraj.iss: expected '$oldIss' not found" }
Write-Text $IssPath ($issText.Replace($oldIss, $newIss))

Write-Host "Updated:"
Write-Host "  $PubspecPath     -> version: $newVer+$newBuild"
Write-Host "  $DartPath -> kAppVersion = '$newVer'"
Write-Host "  $IssPath -> MyAppVersion $newVer"
if (-not $Build) {
    Write-Host "Note: Android build number kept at +$oldBuild. Use -Build to tick it (required for every Google Play upload)."
}
Write-Host "Next: rebuild + reinstall with build_install.ps1"

if ($interactive) {
    Write-Host ''
    Read-Host 'Press Enter to close' | Out-Null
}