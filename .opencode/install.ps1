# OpenCode dotfiles install script (Windows)
# Copies this opencode tree into $env:USERPROFILE\.config\opencode

$ErrorActionPreference = "Stop"

$OpenCodeConfig = if ($env:OPENCODE_CONFIG) { $env:OPENCODE_CONFIG } else { Join-Path $env:USERPROFILE ".config\opencode" }
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "OpenCode install (Windows)"
Write-Host "  Source: $ScriptDir"
Write-Host "  Target: $OpenCodeConfig"
Write-Host ""

if (Test-Path $OpenCodeConfig) {
    if (Test-Path (Join-Path $OpenCodeConfig "opencode.json")) {
        $Backup = "${OpenCodeConfig}.opencode-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Write-Host "Existing config found. Backing up to: $Backup"
        Copy-Item -Path $OpenCodeConfig -Destination $Backup -Recurse -Force
    }
}

New-Item -ItemType Directory -Path $OpenCodeConfig -Force | Out-Null

# Copy contents, excluding install scripts
$Exclude = @("install.sh", "install.ps1")
Get-ChildItem -Path $ScriptDir -Exclude $Exclude | ForEach-Object {
    $Dest = Join-Path $OpenCodeConfig $_.Name
    if ($_.PSIsContainer) {
        Copy-Item -Path $_.FullName -Destination $Dest -Recurse -Force
    } else {
        Copy-Item -Path $_.FullName -Destination $Dest -Force
    }
}

Write-Host ""
Write-Host "Done. OpenCode config is at: $OpenCodeConfig"
Write-Host "  - Edit: $OpenCodeConfig\opencode.json"
Write-Host "  - Scripts: $OpenCodeConfig\scripts\"
Write-Host "  - Validate (if you have bash): bash $OpenCodeConfig/scripts/validate-setup.sh"
