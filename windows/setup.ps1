# Windows System Setup Script (PowerShell)
# This script automates the setup of a new Windows installation

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Windows System Setup Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$chocoPackagesFile = Join-Path $repoRoot "windows\choco.txt"
$wingetPackagesFile = Join-Path $repoRoot "windows\winget.txt"
$nodePackagesFile = Join-Path $repoRoot "node\packages.txt"
$profileSourceFile = Join-Path $repoRoot "powerShell\Profile.ps1"
$regPath = Join-Path $repoRoot "windows\reg"

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

if (Test-Path $profileSourceFile) {
    Copy-Item $profileSourceFile $profilePath -Force
}

Write-Host "Configuring custom scripts folder..." -ForegroundColor Yellow
$scriptsDir = Join-Path $env:USERPROFILE "Scripts"
if (-not (Test-Path $scriptsDir)) {
    New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null
}

$currentUserPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($null -eq $currentUserPath -or -not ($currentUserPath.Split(';') -contains $scriptsDir)) {
    if ($null -eq $currentUserPath) {
        $newUserPath = $scriptsDir
    } else {
        $newUserPath = "$currentUserPath;$scriptsDir"
    }
    [Environment]::SetEnvironmentVariable("Path", $newUserPath, "User")
}

$scriptsSource = Join-Path $repoRoot "windows\Scripts"
if (Test-Path $scriptsSource) {
    Copy-Item (Join-Path $scriptsSource "*.ps1") -Destination $scriptsDir -Force -ErrorAction SilentlyContinue
} else {
    Write-Warning "windows\Scripts folder not found. Skipping custom scripts deployment."
}

# Install Chocolatey
Write-Host "Installing Chocolatey..." -ForegroundColor Yellow
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install Chocolatey packages from file
Write-Host "Installing Chocolatey packages..." -ForegroundColor Yellow
if (Test-Path $chocoPackagesFile) {
    Get-Content $chocoPackagesFile |
    Where-Object { $_ -and $_.Trim() -notmatch '^\s*#' } |
    ForEach-Object {
        $pkg = $_.Trim()
        choco install $pkg -y
    }
} else {
    Write-Warning "windows\choco.txt not found. Skipping Chocolatey package installation."
}

# Install tools via Winget from file
Write-Host "Installing tools via winget..." -ForegroundColor Yellow
if (Test-Path $wingetPackagesFile) {
    Get-Content $wingetPackagesFile |
    Where-Object { $_ -and $_.Trim() -notmatch '^\s*#' } |
    ForEach-Object {
        $package = $_.Trim()
        winget install --id $package --source winget --accept-package-agreements --accept-source-agreements
    }
} else {
    Write-Warning "windows\winget.txt not found. Skipping winget package installation."
}

# Install Node.js tools
Write-Host "Installing Node.js tools..." -ForegroundColor Yellow
powershell -c "irm bun.sh/install.ps1 | iex"
if (Test-Path $nodePackagesFile) {
    Get-Content $nodePackagesFile |
    Where-Object { $_ -and $_.Trim() -notmatch '^\s*#' } |
    ForEach-Object {
        $pkg = $_.Trim()
        bun add -g $pkg
    }
} else {
    Write-Warning "bun\install.txt not found. Skipping global bun package installation."
}

# Apply registry settings
Write-Host "Applying registry settings..." -ForegroundColor Yellow
if (Test-Path $regPath) {
    Get-ChildItem -Path $regPath -Filter "*.reg" | ForEach-Object {
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


