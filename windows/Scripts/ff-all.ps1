param(
  [string]$Root = "C:\Work",
  [switch]$StopOnError
)

# Validate root
if (-not (Test-Path -LiteralPath $Root)) {
  Write-Error "Root folder not found: $Root"
  exit 1
}

# Get immediate subfolders
$folders = Get-ChildItem -LiteralPath $Root -Directory | Sort-Object Name
if (-not $folders) {
  Write-Warning "No subfolders found under: $Root"
  exit 0
}

foreach ($folder in $folders) {
  # Skip folders that don't have a .git subfolder
  if (-not (Test-Path -LiteralPath (Join-Path $folder.FullName ".git"))) {
    Write-Host "Skipping $($folder.Name) - not a git repository"
    continue
  }

  Push-Location $folder.FullName
  try {
    Write-Host "=== Running in $($PWD) ==="

    # Confirm ff exists
    $ff = Get-Command ff -CommandType Function -ErrorAction SilentlyContinue
    if (-not $ff) {
      Write-Error "Function 'ff' not found after loading `$PROFILE in $($PWD)."
      if ($StopOnError) { exit 9009 } else { continue }
    }

    # Run ff
    ff
    $exit = if ($LASTEXITCODE -ne $null) { $LASTEXITCODE } else { if ($?) { 0 } else { 1 } }

    if ($exit -ne 0) {
      Write-Error "Command failed with exit code $exit in '$($PWD)'."
      if ($StopOnError) { exit $exit }
    }
  }
  finally {
    Pop-Location
    Write-Host
  }
}

# Uncomment this line if you want the window to stay open when double-clicked:
Read-Host "Press Enter to exit"
