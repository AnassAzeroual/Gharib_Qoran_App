# watch_windows.ps1 - run the app on Windows with auto hot-reload on save.
# Starts `flutter run -d windows` and watches lib/**/*.dart; every save sends
# `r` (hot reload) to the Flutter tool through its stdin, so you never kill
# and restart the server by hand. Brand-new assets or plugins still need a
# manual restart (type R + Enter here).
# Usage: right-click -> Run with PowerShell, or .\watch_windows.ps1
# Stop: type Q + Enter (sends `q` so flutter shuts down cleanly).

param(
    [string]$Device = 'windows'
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ProjectRoot

if ($Device -ne 'windows' -and $Device -ne 'chrome') {
    throw "Unknown device '$Device' (use windows or chrome)"
}
$DevLabel = if ($Device -eq 'chrome') { 'Chrome' } else { 'Windows' }

$Flutter = 'C:/flutter/bin/flutter.bat'
$LibDir = Join-Path $ProjectRoot 'lib'
if (-not (Test-Path $LibDir)) { throw "lib/ not found under $ProjectRoot" }

Write-Host "=== Watch $DevLabel (auto hot-reload) ===" -ForegroundColor Cyan
Write-Host "Starting: flutter run -d $Device ..." -ForegroundColor Gray

$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = 'cmd.exe'
$psi.Arguments = '/c ""' + $Flutter + '" run -d ' + $Device + '"'
$psi.WorkingDirectory = $ProjectRoot
$psi.UseShellExecute = $false
$psi.RedirectStandardInput = $true
$proc = [System.Diagnostics.Process]::Start($psi)
if ($proc -eq $null) { throw 'Could not start flutter run' }

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $LibDir
$watcher.Filter = '*.dart'
$watcher.IncludeSubdirectories = $true
$watcher.NotifyFilter = [System.IO.NotifyFilters]::LastWrite -bor [System.IO.NotifyFilters]::FileName -bor [System.IO.NotifyFilters]::CreationTime
$subs = @()
foreach ($evt in @('Changed', 'Created', 'Renamed', 'Deleted')) {
    $subs += Register-ObjectEvent -InputObject $watcher -EventName $evt -MessageData $proc -Action {
        $watched = $Event.MessageData
        if ($watched -ne $null -and -not $watched.HasExited) {
            Start-Sleep -Milliseconds 700
            if (-not $watched.HasExited) {
                try {
                    $watched.StandardInput.WriteLine('r')
                    $stamp = Get-Date -Format 'HH:mm:ss'
                    Write-Host "[$stamp watch] $($EventArgs.Name) -> hot reload (r)" -ForegroundColor DarkGray
                } catch {}
            }
        }
    }
}
$watcher.EnableRaisingEvents = $true

Write-Host ''
Write-Host 'Watching lib/**/*.dart - save a file to hot-reload.' -ForegroundColor Green
Write-Host 'Type R + Enter for hot RESTART, Q + Enter to quit cleanly.' -ForegroundColor Gray
Write-Host ''
try {
    while (-not $proc.HasExited) {
        $line = Read-Host 'watch'
        if ($line -match '^(?i)q(uit)?$') { break }
        if ($line -match '^(?i)r(estart)?$') {
            try { $proc.StandardInput.WriteLine('R') } catch {}
        }
    }
} finally {
    try {
        if (-not $proc.HasExited) { $proc.StandardInput.WriteLine('q') }
    } catch {}
    Start-Sleep -Milliseconds 500
    if (-not $proc.HasExited) {
        try { $proc.Kill() } catch {}
    }
    foreach ($s in $subs) {
        Unregister-Event -SubscriptionId $s.Id -ErrorAction SilentlyContinue
    }
    $watcher.Dispose()
}
Write-Host 'Watcher stopped.' -ForegroundColor Green
