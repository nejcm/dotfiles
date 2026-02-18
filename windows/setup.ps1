# Windows System Setup Script (PowerShell)
# This script automates the setup of a new Windows installation

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Windows System Setup Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check for admin privileges
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script requires administrator privileges."
    exit 1
}

# Install PowerShell 7 first
Write-Host "Installing PowerShell 7..." -ForegroundColor Yellow
winget install --id Microsoft.PowerShell --source winget --accept-package-agreements --accept-source-agreements

# Setup PowerShell profile
Write-Host "Setting up PowerShell profile..." -ForegroundColor Yellow
$profilePath = $PROFILE.CurrentUserCurrentHost
$profileDir = Split-Path $profilePath -Parent
if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force
}

if (Test-Path "powerShell\Microsoft.PowerShell_profile.ps1") {
    Copy-Item "powerShell\Microsoft.PowerShell_profile.ps1" $profilePath -Force
}

# Install Chocolatey
Write-Host "Installing Chocolatey..." -ForegroundColor Yellow
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install Chocolatey packages from file
Write-Host "Installing Chocolatey packages..." -ForegroundColor Yellow
if (Test-Path "chocolatey\packages.txt") {
    Get-Content "chocolatey\packages.txt" | ForEach-Object {
        if ($_.Trim() -and -not $_.StartsWith("#")) {
            choco install $_.Trim() -y
        }
    }
} else {
    Write-Warning "chocolatey\packages.txt not found. Skipping Chocolatey package installation."
}

# Install remaining tools via Winget
Write-Host "Installing additional tools via winget..." -ForegroundColor Yellow
$wingetPackages = @(
    "Docker.DockerDesktop",
    "GoLang.Go"
)

foreach ($package in $wingetPackages) {
    winget install --id $package --source winget --accept-package-agreements --accept-source-agreements
}

# Install bun
powershell -c "irm bun.sh/install.ps1 | iex"

# Install Node.js tools
Write-Host "Installing Node.js tools..." -ForegroundColor Yellow
Invoke-RestMethod bun.sh/install.ps1 | Invoke-Expression
npm install -g pnpm rimraf @anthropic-ai/claude-code

# Apply registry settings
Write-Host "Applying registry settings..." -ForegroundColor Yellow
if (Test-Path "reg") {
    Get-ChildItem -Path "reg" -Filter "*.reg" | ForEach-Object {
        Write-Host "Applying $($_.Name)..." -ForegroundColor Gray
        reg import $_.FullName
    }
} else {
    Write-Warning "reg folder not found. Skipping registry settings."
}

# Configure Git
Write-Host "Configuring Git..." -ForegroundColor Yellow
git config --global user.name "nejcm"
git config --global merge.tool kdiff3
git config --global credential.helper manager-core


Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "SETUP COMPLETED" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Your Windows development environment has been set up successfully." -ForegroundColor Green
Write-Host "Recommended next steps:" -ForegroundColor Yellow
Write-Host "1. Restart your system" -ForegroundColor White
Write-Host "2. Log in to your applications (GitHub, Docker, etc.)" -ForegroundColor White
Write-Host "3. Configure VSCode/Cursor extensions" -ForegroundColor White
Write-Host "4. Verify all applications work correctly" -ForegroundColor White


