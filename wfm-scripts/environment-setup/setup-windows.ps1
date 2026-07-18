<#
.SYNOPSIS
    All-in-one Windows dev/terminal environment setup.

.DESCRIPTION
    Installs Chocolatey (if missing), then a curated set of dev tools,
    terminal quality-of-life tools, and core infrastructure tooling
    (Docker Desktop, Git, VS Code family, etc.) via Chocolatey.

.NOTES
    Run from an elevated (Administrator) PowerShell prompt:
        powershell -ExecutionPolicy Bypass -File setup-windows.ps1

    Re-runnable: choco upgrade is idempotent, safe to run again later
    to pick up new versions.
#>

[CmdletBinding()]
param(
    [switch]$SkipDockerDesktop,
    [switch]$SkipWSL2
)

$ErrorActionPreference = "Stop"

function Write-Section($title) {
    Write-Host ""
    Write-Host "=== $title ===" -ForegroundColor Cyan
}

function Test-IsAdmin {
    $identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdmin)) {
    Write-Host "This script must be run as Administrator. Relaunch PowerShell with 'Run as administrator'." -ForegroundColor Red
    exit 1
}

Write-Section "Installing Chocolatey"
if (Get-Command choco -ErrorAction SilentlyContinue) {
    Write-Host "Chocolatey already installed, skipping install." -ForegroundColor Yellow
} else {
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}

# Enable global confirmation so choco doesn't prompt for every package
choco feature enable -n allowGlobalConfirmation

Write-Section "Excluding Chocolatey temp folder from Defender (speeds up installs)"
try {
    Add-MpPreference -ExclusionPath "$env:LOCALAPPDATA\Temp\chocolatey\" -ErrorAction SilentlyContinue
} catch {
    Write-Host "Could not add Defender exclusion (non-fatal): $_" -ForegroundColor Yellow
}

Write-Section "Core dev tools"
choco upgrade git python vscode -y

Write-Section "Terminal"
choco upgrade microsoft-windows-terminal -y

if (-not $SkipWSL2) {
    Write-Section "WSL2"
    choco upgrade wsl2 -y
} else {
    Write-Host "Skipping WSL2 (per -SkipWSL2 flag)." -ForegroundColor Yellow
}

if (-not $SkipDockerDesktop) {
    Write-Section "Docker Desktop"
    choco upgrade docker-desktop -y
} else {
    Write-Host "Skipping Docker Desktop (per -SkipDockerDesktop flag)." -ForegroundColor Yellow
}

Write-Section "Networking / remote access"
choco upgrade openssh openvpn -y

Write-Section "Pentest / recon tooling"
choco upgrade netcat nmap wireshark -y

Write-Section "API testing"
choco upgrade postman -y

Write-Section "Utilities"
choco upgrade sysinternals putty 7zip -y

Write-Section "Refreshing environment variables"
$chocoInstallVars = "$env:ChocolateyInstall\bin\RefreshEnv.cmd"
if (Test-Path $chocoInstallVars) {
    cmd /c $chocoInstallVars
} else {
    Write-Host "RefreshEnv.cmd not found — restart your terminal to pick up PATH changes." -ForegroundColor Yellow
}

Write-Section "Done"
Write-Host "Core Windows dev/terminal stack installed." -ForegroundColor Green
Write-Host "A reboot is recommended, especially if WSL2 or Docker Desktop was just installed." -ForegroundColor Yellow
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  - Reboot if prompted"
Write-Host "  - Launch Docker Desktop once manually to finish its setup"
Write-Host "  - If you use WSL2/Ubuntu for terminal work, run setup-linux.sh inside it"
