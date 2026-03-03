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

# Chocolatey

List all packages

```bash
choco list --idonly >> choco.txt
```

# Other tools and apps

https://github.com/imputnet/helium-windows/releases
https://cursor.com/download
https://claude.com/download
https://opencode.ai/download
https://account.termius.com/
https://tailscale.com/download
https://letsvpn.world/

## Running `.ps1` scripts globally

To run scripts like `gff-all.ps1` from any directory by name (or by full path), put them in a folder that is on your **PATH**.
