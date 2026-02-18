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

# Function to run gff in a git repository
function Invoke-GFFInFolder {
  param([string]$FolderPath)
  
  Push-Location $FolderPath
  try {
    Write-Host "=== Running in $($PWD) ==="

    # Confirm gff exists
    $gff = Get-Command gff -CommandType Function -ErrorAction SilentlyContinue
    if (-not $gff) {
      Write-Error "Function 'gff' not found after loading `$PROFILE in $($PWD)."
      if ($StopOnError) { exit 9009 } else { return }
    }

    # Run gff
    gff
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

foreach ($folder in $folders) {
  $gitPath = Join-Path $folder.FullName ".git"
  
  # Check if this folder is a git repository
  if (Test-Path -LiteralPath $gitPath) {
    # Run gff directly in this folder
    Invoke-GFFInFolder -FolderPath $folder.FullName
  } else {
    # Go one level deeper and check subfolders
    Write-Host "Checking subfolders of $($folder.Name) - not a git repository"
    $subfolders = Get-ChildItem -LiteralPath $folder.FullName -Directory -ErrorAction SilentlyContinue | Sort-Object Name
    
    if ($subfolders) {
      foreach ($subfolder in $subfolders) {
        $subGitPath = Join-Path $subfolder.FullName ".git"
        if (Test-Path -LiteralPath $subGitPath) {
          Invoke-GFFInFolder -FolderPath $subfolder.FullName
        }
      }
    }
  }
}

# Uncomment this line if you want the window to stay open when double-clicked:
Read-Host "Press Enter to exit"
