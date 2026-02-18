# Windows Dotfiles

Scripts and setup for Windows development environment.

## Setup

The main setup script configures a new Windows installation: PowerShell 7, Chocolatey, winget packages, bun, Node tools, registry tweaks, and Git.

### Prerequisites

- Run **PowerShell as Administrator** (right‑click → “Run as administrator”).
- Execute from the **dotfiles repo root** (the folder that contains `windows/`, `chocolatey/`, `powerShell/`, `reg/`, etc.), not from inside `windows/`.

### Run setup

```powershell
cd C:\Work\Personal\dotfiles   # or your dotfiles path
.\windows\setup.ps1
```

If execution policy blocks the script:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### After setup

- Restart the machine.
- Log in to apps (GitHub, Docker, etc.) and configure VSCode/Cursor as needed.

---

## Running `.ps1` scripts globally

To run scripts like `gff-all.ps1` from any directory by name (or by full path), put them in a folder that is on your **PATH**.

### Option 1: PowerShell 7 scripts folder (recommended)

1. Create the folder (if it doesn’t exist):
   ```powershell
   $scriptsDir = "$env:USERPROFILE\Documents\PowerShell\Scripts"
   New-Item -ItemType Directory -Path $scriptsDir -Force
   ```

2. Copy the scripts:
   ```powershell
   Copy-Item "C:\Work\Personal\dotfiles\windows\Scripts\*.ps1" -Destination $scriptsDir -Force
   ```

3. Add that folder to your user PATH (once):
   ```powershell
   [Environment]::SetEnvironmentVariable("Path", $env:Path + ";$scriptsDir", "User")
   ```
   Then open a **new** PowerShell window.

4. Run from anywhere:
   ```powershell
   gff-all.ps1
   # or with options:
   gff-all.ps1 -Root "D:\Projects" -StopOnError
   ```

### Option 2: Custom scripts folder

1. Choose a folder, e.g. `C:\Users\<YourName>\Scripts`.

2. Add it to your user PATH:
   ```powershell
   [Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\Users\<YourName>\Scripts", "User")
   ```

3. Copy the `.ps1` files from `windows\Scripts\` into that folder.

4. Use a new PowerShell window and run:
   ```powershell
   gff-all.ps1
   ```

### Scripts in this repo

| Script       | Description |
|-------------|-------------|
| `setup.ps1` | One-time system setup (run as Admin from dotfiles root). |
| `Scripts\gff-all.ps1` | Runs `gff` (fetch + prune, pull --ff-only) in every git repo under a root (default `C:\Work`). Requires the PowerShell profile that defines `gff` (installed by `setup.ps1`). |

**Note:** `gff-all.ps1` depends on the `gff` function from `powerShell\Microsoft.PowerShell_profile.ps1`. Ensure setup has been run so that profile is installed, or the script will report that `gff` is not found.
