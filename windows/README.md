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

The setup script also creates a user environment variable `REPO_ROOT` (default: `C:\Work`) used by helper scripts such as `gff-all.ps1`.

If execution policy blocks the script:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

# Chocolatey

List all choco packages

```bash
choco list --idonly >> choco.txt
```

List all node packages

```bash
bun list -g --depth=0 >> packages.txt
```

# Other tools and apps

bunx playwright install --with-deps

<https://github.com/imputnet/helium-windows/releases>
<https://cursor.com/download>
<https://claude.com/download>
<https://opencode.ai/download>
<https://account.termius.com/>
<https://tailscale.com/download>
<https://letsvpn.world/>

## Running `.ps1` scripts globally

To run scripts like `gff-all.ps1` from any directory by name (or by full path), put them in a folder that is on your **PATH**.

For quick navigation, use `cpr` from your PowerShell profile:

```powershell
cpr           # go to REPO_ROOT (or WORK_ROOT / C:\Work fallback)
cpr spendwise # go to REPO_ROOT\spendwise
```
