# alsiraj.ps1 - AlSiraj control center (interactive, right-click friendly).
# Start, then pick a job: bump version / build Windows / build Android /
# build AAB for Google Play / run dev on Windows or Chrome.
# Every job opens in its OWN PowerShell window, so this menu stays available
# while work runs. The menu window stays open until you choose Quit.

$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ProjectRoot
$ErrorActionPreference = 'Continue'
$Flutter = 'C:/flutter/bin/flutter.bat'

function Get-CurrentVersion {
    $text = [System.IO.File]::ReadAllText((Join-Path $ProjectRoot 'pubspec.yaml'))
    $m = [regex]::Match($text, '(?m)^\s*version:\s*([^\s]+)\s*$')
    if ($m.Success) { return $m.Groups[1].Value }
    return '(unknown)'
}

function Run-Script([string[]]$ScriptArgs, [string]$Title) {
    Write-Host ''
    Write-Host "=== $Title ===" -ForegroundColor Cyan
    Write-Host "Opening it in a NEW window (this menu stays available)..." -ForegroundColor Gray
    $ps = @('-NoExit', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $ScriptArgs[0])
    if ($ScriptArgs.Count -gt 1) { $ps += $ScriptArgs[1..($ScriptArgs.Count - 1)] }
    Start-Process powershell.exe -ArgumentList $ps -WorkingDirectory $ProjectRoot -WindowStyle Normal
    Start-Sleep -Milliseconds 800
}

function Run-Dev([string]$Device) {
    Write-Host ''
    Write-Host "=== flutter run -d $Device ===" -ForegroundColor Cyan
    Write-Host "Opening it in a NEW window (this menu stays available)..." -ForegroundColor Gray
    Start-Process powershell.exe -ArgumentList @(
        '-NoExit', '-NoProfile', '-ExecutionPolicy', 'Bypass',
        '-Command', "& '$Flutter' run -d $Device"
    ) -WorkingDirectory $ProjectRoot -WindowStyle Normal
    Start-Sleep -Milliseconds 800
}

while ($true) {
    Clear-Host
    Write-Host '================================================' -ForegroundColor Cyan
    Write-Host '              AlSiraj Control Center' -ForegroundColor Cyan
    Write-Host '================================================' -ForegroundColor Cyan
    Write-Host "  Current version: $(Get-CurrentVersion)" -ForegroundColor White
    Write-Host '  ----------------------------------------------'
    Write-Host '   1. Bump version (patch / minor / major / +N)'
    Write-Host '   2. Build Windows (release) + install'
    Write-Host '   3. Build Android (release, signed) + install on USB'
    Write-Host '   4. Build Android (debug, dev) + install on USB'
    Write-Host '   5. Build Android AAB (Google Play upload)'
    Write-Host '   6. Run app on Windows (dev, hover/hot-reload)'
    Write-Host '   7. Run app on Web/Chrome (dev)'
    Write-Host '   8. Flutter DevTools'
    Write-Host '   9. Google Play Console (browser)'
    Write-Host '   10. Project PowerShell prompt'
    Write-Host '   11. VS Code in project'
    Write-Host '   Q. Quit'
    Write-Host ''
    $sel = Read-Host '   Choose (1-11, Q)'
    Write-Host ''

    switch -Regex ($sel.Trim().ToLowerInvariant()) {
        '^1$' {
            Run-Script @((Join-Path $ProjectRoot 'bump_version.ps1')) 'Bump version'
        }
        '^2$' {
            Run-Script @((Join-Path $ProjectRoot 'build_install.ps1'), '-Windows') 'Build Windows'
        }
        '^3$' {
            Run-Script @((Join-Path $ProjectRoot 'build_install.ps1'), '-AndroidRelease') 'Build Android release'
        }
        '^4$' {
            Run-Script @((Join-Path $ProjectRoot 'build_install.ps1'), '-AndroidDebug') 'Build Android debug'
        }
        '^5$' {
            Run-Script @((Join-Path $ProjectRoot 'build_install.ps1'), '-Aab') 'Build AAB'
        }
        '^6$' {
            Run-Dev 'windows'
        }
        '^7$' {
            Run-Dev 'chrome'
        }
        '^8$' {
            Write-Host '=== Flutter DevTools ===' -ForegroundColor Cyan
            $devtools = "$env:LOCALAPPDATA\Pub\Cache\bin\devtools.bat"
            if (Test-Path $devtools) {
                Write-Host 'Opening in a NEW window...' -ForegroundColor Gray
                Start-Process powershell.exe -ArgumentList @(
                    '-NoExit', '-NoProfile', '-ExecutionPolicy', 'Bypass',
                    '-Command', "& '$devtools'"
                ) -WorkingDirectory $ProjectRoot -WindowStyle Normal
            } else {
                Write-Host 'DevTools is built into the Flutter tool - it connects to a running app.' -ForegroundColor Green
                $dev = Read-Host 'Start the app now? (W = Windows / C = Chrome)'
                if ($dev -match '^c') { Run-Dev 'chrome' } else { Run-Dev 'windows' }
                Write-Host ''
                Write-Host 'In the app window that just opened, press  d  then Enter.' -ForegroundColor Green
            }
            Write-Host ''
            Read-Host '   Press Enter to continue' | Out-Null
        }
        '^9$' {
            Write-Host '=== Google Play Console ===' -ForegroundColor Cyan
            Start-Process 'https://play.google.com/console'
            Start-Sleep -Milliseconds 500
        }
        '^10$' {
            Write-Host '=== Project PowerShell prompt ===' -ForegroundColor Cyan
            Start-Process powershell.exe -ArgumentList @(
                '-NoExit', '-NoProfile', '-ExecutionPolicy', 'Bypass'
            ) -WorkingDirectory $ProjectRoot -WindowStyle Normal
            Start-Sleep -Milliseconds 500
        }
        '^11$' {
            Write-Host '=== VS Code in project ===' -ForegroundColor Cyan
            $code = (Get-Command code.cmd -ErrorAction SilentlyContinue).Source
            if ($code) {
                Start-Process $code -ArgumentList '.' -WorkingDirectory $ProjectRoot
            } elseif (Test-Path "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe") {
                Start-Process "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe" -ArgumentList '.' -WorkingDirectory $ProjectRoot
            } else {
                Write-Host 'VS Code not found on PATH or default location.' -ForegroundColor Yellow
            }
            Start-Sleep -Milliseconds 500
        }
        '^q$' {
            Write-Host 'Bye.' -ForegroundColor Green
            break
        }
        default {
            Write-Host "Invalid choice: $sel" -ForegroundColor Yellow
        }
    }
}