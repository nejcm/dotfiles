# Omarchy

Use `install.sh` on a fresh Omarchy install after cloning this repo.

## Prerequisites

- `yay` is installed and working
- The repo is cloned locally
- You run the script as your normal user
- `sudo` access is available if you want to install the touchpad sudoers rule

## Run install

From the repo root:

```bash
chmod +x omarchy/install.sh
./omarchy/install.sh
```

## What install does

- Installs packages listed in `omarchy/pkg-list.txt`
- Copies everything under `omarchy/.config/` into the matching paths under `~/.config/`
- Copies `bash/.bashrc` to `~/.bashrc`
- Ensures `export REPO_ROOT="$HOME/Work"` exists in `~/.bashrc` (used by scripts like `bash/gff-all`)
- Copies `ghostty/config` to `~/.config/ghostty/config`
- Copies `starship/starship.toml` to `~/.config/starship.toml`
- Installs `omarchy/scripts/toggle-touchpad` into `~/.local/bin/toggle-touchpad`
- Installs `omarchy/sudoers-touchpad-toggle` into `/etc/sudoers.d/touchpad-toggle` when sudo is available
- Keeps the extra `curl`-based tool installs at the end of the script

## After install

Reload Hyprland:

```bash
hyprctl reload
```

## Fix GPU issues

Modify `KERNEL_CMDLINE[default]` value inside `limine` file in `/etc/default`.

**Add:** `nvidia.NVreg_PreserveVideoMemoryAllocations=1 nvidia.NVreg_TemporaryFilePath=/var/tmp amdgpu.dc=1 amdgpu.ppfeaturemask=0xffffffff amdgpu.gpu_recovery=1 amdgpu.dcdebugmask=0x10`

## Configs

The install script copies the tracked files automatically. If you want to do it manually instead, copy the files from this folder into the matching locations under your home directory, then place:

- `scripts/toggle-touchpad` at `~/.local/bin/toggle-touchpad`
- `sudoers-touchpad-toggle` at `/etc/sudoers.d/touchpad-toggle`

### Dual boot

```bash
sudo limine-entry-tool --scan
```

## Function Keys Setup

This document describes the configuration for function keys (brightness, volume, touchpad toggle) on ASUS laptops running Omarchy.

### Files

- **bindings.conf** - Hyprland key bindings configuration (copy to `~/.config/hypr/bindings.conf`)
- **scripts/toggle-touchpad** - Script to toggle touchpad on/off (copy to `~/.local/bin/toggle-touchpad`)
- **sudoers-touchpad-toggle** - Sudoers rule for passwordless touchpad toggle (copy to `/etc/sudoers.d/touchpad-toggle`)

### Setup Instructions

#### Copy Files

```bash
# Copy touchpad toggle script
mkdir -p ~/.local/bin
cp scripts/toggle-touchpad ~/.local/bin/toggle-touchpad
chmod +x ~/.local/bin/toggle-touchpad

# Copy Hyprland bindings (or merge with your existing config)
mkdir -p ~/.config/hypr
cp .config/hypr/bindings.conf ~/.config/hypr/bindings.conf

# Copy sudoers rule
sudo cp sudoers-touchpad-toggle /etc/sudoers.d/touchpad-toggle
sudo chmod 440 /etc/sudoers.d/touchpad-toggle
```

#### Reload Hyprland

```bash
hyprctl reload
```

## Hyprwhspr setup

```bash
hyprwhspr setup
```

### Scripts

Copy any user scripts into `~/.local/bin`
