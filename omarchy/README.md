<<<<<<< Updated upstream
# Omarchy

## Fix GPU issues

Modify `KERNEL_CMDLINE[default]` value inside `limine` file in `/etc/default`.

**Add:** `nvidia.NVreg_PreserveVideoMemoryAllocations=1 nvidia.NVreg_TemporaryFilePath=/var/tmp amdgpu.dc=1 amdgpu.ppfeaturemask=0xffffffff amdgpu.gpu_recovery=1 amdgpu.dcdebugmask=0x10`

## Pacman packages

### Backup

```bash
yay -Qqe > yay-list.txt
```

### Restore

```bash
yay -S --needed < yay-list.txt
```

## Configs

Copy all .config folders and files into OS .config folder.

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

#### 1. Copy Files

```bash
# Copy touchpad toggle script
sudo cp scripts/toggle-touchpad /usr/local/bin/
sudo chmod +x /usr/local/bin/toggle-touchpad

# Copy Hyprland bindings (or merge with your existing config)
sudo cp bindings.conf ~/.config/hypr/bindings.conf

# Copy sudoers rule
sudo cp sudoers-touchpad-toggle /etc/sudoers.d/touchpad-toggle
sudo chmod 440 /etc/sudoers.d/touchpad-toggle
```

#### 3. Reload Hyprland

```bash
hyprctl reload
```

### Copy scripts

Copy any scripts into `/etc/local/bin`
=======
# Omarchy

## Fix GPU issues

Modify `KERNEL_CMDLINE[default]` value inside `limine` file in `/etc/default`.

**Add:** `nvidia.NVreg_PreserveVideoMemoryAllocations=1 nvidia.NVreg_TemporaryFilePath=/var/tmp amdgpu.dc=1 amdgpu.ppfeaturemask=0xffffffff amdgpu.gpu_recovery=1 amdgpu.dcdebugmask=0x10`

## Pacman packages

### Backup

```bash
yay -Qqe > yay-list.txt
```

### Restore

```bash
yay -S --needed < yay-list.txt
```

## Configs

Copy all .config folders and files into OS .config folder.

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

#### 1. Copy Files

```bash
# Copy touchpad toggle script
sudo cp scripts/toggle-touchpad /usr/local/bin/
sudo chmod +x /usr/local/bin/toggle-touchpad

# Copy Hyprland bindings (or merge with your existing config)
sudo cp bindings.conf ~/.config/hypr/bindings.conf

# Copy sudoers rule
sudo cp sudoers-touchpad-toggle /etc/sudoers.d/touchpad-toggle
sudo chmod 440 /etc/sudoers.d/touchpad-toggle
```

#### 3. Reload Hyprland

```bash
hyprctl reload
```

### Copy scripts

Copy any scripts into `/etc/local/bin`
>>>>>>> Stashed changes
