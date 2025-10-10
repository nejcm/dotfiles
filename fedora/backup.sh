#!/bin/bash

# Determine the real user (not root when using sudo)
if [[ -n "$SUDO_USER" ]]; then
    REAL_USER="$SUDO_USER"
    REAL_HOME="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
else
    REAL_USER="$(whoami)"
    REAL_HOME="$HOME"
fi

echo "Backing up data for user: $REAL_USER"
echo "User home directory: $REAL_HOME"

# Check sudo privileges if needed for system files
if sudo -v &>/dev/null; then
  echo "User has sudo privileges."
else
  echo "User does NOT have sudo privileges."
  echo "Some system files may not be backed up."
fi

# Get the current working directory
CURRENT_DIR="$(pwd)"
BACKUP_DIR="$CURRENT_DIR/backup"

# Create backup directory in current location with proper permissions
mkdir -p "$BACKUP_DIR"
if [[ -n "$SUDO_USER" ]]; then
    chown "$SUDO_USER:$(id -gn "$SUDO_USER")" "$BACKUP_DIR"
fi

echo "Starting backup process..."
echo "Backup location: $BACKUP_DIR"
echo ""

# Back up personal data
echo "Backing up personal data..."
backup_directory() {
    local src="$1"
    local desc="$2"
    if [[ -d "$src" && -r "$src" ]]; then
        cp -r "$src" "$BACKUP_DIR/" 2>/dev/null && echo "  ✓ Backed up $desc" || echo "  Warning: Could not backup $desc"
    else
        echo "  Info: $desc not found or not readable, skipping"
    fi
}

backup_directory "$REAL_HOME/Documents" "Documents"
backup_directory "$REAL_HOME/Pictures" "Pictures"
backup_directory "$REAL_HOME/Videos" "Videos"
backup_directory "$REAL_HOME/Music" "Music"
backup_directory "$REAL_HOME/Downloads" "Downloads"
backup_directory "$REAL_HOME/Desktop" "Desktop"
backup_directory "$REAL_HOME/Templates" "Templates"
backup_directory "$REAL_HOME/Work" "Work"

# Back up configuration files and settings
echo "Backing up configuration files..."
backup_file() {
    local src="$1"
    local desc="$2"
    if [[ -e "$src" && -r "$src" ]]; then
        cp -r "$src" "$BACKUP_DIR/" 2>/dev/null && echo "  ✓ Backed up $desc" || echo "  Warning: Could not backup $desc"
    else
        echo "  Info: $desc not found, skipping"
    fi
}

backup_file "$REAL_HOME/.config" "config directory"
backup_file "$REAL_HOME/.bashrc" "bashrc"
backup_file "$REAL_HOME/.bash_profile" "bash_profile"
backup_file "$REAL_HOME/.gitconfig" "gitconfig"

# Back up VSCode settings
echo "Backing up VSCode settings..."
backup_directory "$REAL_HOME/.vscode" "VSCode settings"

# Back up GPG keys
echo "Backing up GPG keys..."
backup_directory "$REAL_HOME/.gnupg" "GPG keys"

# Back up PKI certificates
echo "Backing up PKI certificates..."
backup_directory "$REAL_HOME/.pki" "PKI certificates"

# Back up development tools
echo "Backing up development tools..."
backup_directory "$REAL_HOME/.nv" "nv config"
backup_directory "$REAL_HOME/.cursor" "Cursor settings"

# Back up special files
#echo "Backing up special files..."
#cp ~/gnome-settings.txt "$BACKUP_DIR/" 2>/dev/null || echo "  Warning: Could not backup ~/gnome-settings.txt"

# Generate package lists
echo "Generating package lists..."
run_as_user() {
    local cmd="$1"
    local output_file="$2"
    local desc="$3"
    
    if [[ -n "$SUDO_USER" ]]; then
        sudo -u "$SUDO_USER" bash -c "$cmd" > "$output_file" 2>/dev/null && echo "  ✓ Generated $desc" || echo "  Warning: Could not generate $desc"
    else
        eval "$cmd" > "$output_file" 2>/dev/null && echo "  ✓ Generated $desc" || echo "  Warning: Could not generate $desc"
    fi
}

# RPM package list (system-wide, needs to run as current user or root)
if command -v rpm &>/dev/null; then
    rpm -qa > "$BACKUP_DIR/installed_packages.txt" 2>/dev/null && echo "  ✓ Generated RPM package list" || echo "  Warning: Could not generate RPM package list"
fi

# Flatpak apps (user-specific)
if command -v flatpak &>/dev/null; then
    run_as_user "flatpak list --columns=application --app" "$BACKUP_DIR/flatpak_apps.txt" "Flatpak app list"
fi

# DNF repositories (system-wide)
if command -v dnf &>/dev/null; then
    dnf repolist > "$BACKUP_DIR/repositories.txt" 2>/dev/null && echo "  ✓ Generated repository list" || echo "  Warning: Could not generate repository list"
fi

# Back up enabled services
#echo "Backing up service configurations..."
#systemctl --user list-unit-files --state=enabled > "$BACKUP_DIR/user_services.txt" 2>/dev/null || echo "  Warning: Could not backup user services"
#systemctl list-unit-files --state=enabled > "$BACKUP_DIR/system_services.txt" 2>/dev/null || echo "  Warning: Could not backup system services"

# Back up development environment
echo "Backing up development environment..."

# NPM global packages (user-specific)
if command -v npm &>/dev/null; then
    run_as_user "npm list -g --depth=0" "$BACKUP_DIR/npm_global_packages.txt" "NPM global packages list"
fi

# Python pip packages (user-specific)
if command -v pip &>/dev/null; then
    run_as_user "pip list" "$BACKUP_DIR/pip_packages.txt" "pip packages list"
fi

# Docker images (system-wide, but user might not have access)
if command -v docker &>/dev/null; then
    if [[ -n "$SUDO_USER" ]]; then
        sudo -u "$SUDO_USER" docker images > "$BACKUP_DIR/docker_images.txt" 2>/dev/null && echo "  ✓ Generated Docker images list" || echo "  Warning: Could not generate Docker images list (user may not have docker access)"
    else
        docker images > "$BACKUP_DIR/docker_images.txt" 2>/dev/null && echo "  ✓ Generated Docker images list" || echo "  Warning: Could not generate Docker images list"
    fi
fi

# Back up GNOME Desktop settings
echo "Backing up GNOME Desktop settings..."

# dconf settings (user-specific, needs user session)
if command -v dconf &>/dev/null; then
    if [[ -n "$SUDO_USER" ]]; then
        sudo -u "$SUDO_USER" DISPLAY=":0" dconf dump / > "$BACKUP_DIR/dconf_settings.txt" 2>/dev/null && echo "  ✓ Backed up dconf settings" || echo "  Warning: Could not backup dconf settings (may need active session)"
    else
        dconf dump / > "$BACKUP_DIR/dconf_settings.txt" 2>/dev/null && echo "  ✓ Backed up dconf settings" || echo "  Warning: Could not backup dconf settings"
    fi
fi

# GNOME extensions (user-specific, needs user session)
if command -v gnome-extensions &>/dev/null; then
    if [[ -n "$SUDO_USER" ]]; then
        sudo -u "$SUDO_USER" DISPLAY=":0" gnome-extensions list > "$BACKUP_DIR/gnome_extensions.txt" 2>/dev/null && echo "  ✓ Generated GNOME extensions list" || echo "  Warning: Could not generate GNOME extensions list (may need active session)"
    else
        gnome-extensions list > "$BACKUP_DIR/gnome_extensions.txt" 2>/dev/null && echo "  ✓ Generated GNOME extensions list" || echo "  Warning: Could not generate GNOME extensions list"
    fi
fi

# Important system files (if customized)
echo "Backing up important system files..."
if sudo -v &>/dev/null; then
    sudo cp /etc/hosts "$BACKUP_DIR/" 2>/dev/null && echo "  ✓ Backed up /etc/hosts" || echo "  Warning: Could not backup /etc/hosts"
else
    echo "  Info: Skipping system files backup (no sudo privileges)"
fi

# Fix ownership of all backed up files
if [[ -n "$SUDO_USER" ]]; then
    echo "Fixing file ownership..."
    chown -R "$SUDO_USER:$(id -gn "$SUDO_USER")" "$BACKUP_DIR"
    echo "  ✓ Fixed ownership for user $SUDO_USER"
fi

# Notify user of completion
echo ""
echo "Backup completed successfully!"
echo "All files are located in: $BACKUP_DIR"
echo "You can run this script from any location and it will create a backup folder in the current directory."

