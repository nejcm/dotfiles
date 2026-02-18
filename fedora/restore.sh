#!/bin/bash

# Fedora System Restore and Setup Script
# This script restores from backup if available and performs system setup

# Title and initial check
echo "========================================"
echo "Fedora System Restore and Setup Script"
echo "========================================"
echo "This script will restore your backup (if available) and setup the system"
echo ""

# Check if script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "Please run this script as root or with sudo."
    exit 1
fi

# Get current working and backup directories
CURRENT_DIR="$(pwd)"
BACKUP_DIR="$CURRENT_DIR/backup"

# Function to restore directories from backup
restore_directory() {
    local src="$1"
    local dest="$2"
    local desc="$3"
    
    if [ -d "$src" ]; then
        echo "Restoring $desc..."
        if [ -d "$dest" ]; then
            mv "$dest" "$dest.old" 2>/dev/null || echo "  Warning: Could not backup existing $dest"
        fi
        cp -r "$src" "$dest" 2>/dev/null || echo "  Warning: Could not restore $desc"
        chown -R $SUDO_USER:$SUDO_USER "$dest" 2>/dev/null
    else
        echo "  Skipping $desc (not found in backup)"
    fi
}

# Function to restore files from backup
restore_file() {
    local src="$1"
    local dest="$2"
    local desc="$3"
    
    if [ -f "$src" ]; then
        echo "Restoring $desc..."
        if [ -f "$dest" ]; then
            mv "$dest" "$dest.old" 2>/dev/null || echo "  Warning: Could not backup existing $dest"
        fi
        cp "$src" "$dest" 2>/dev/null || echo "  Warning: Could not restore $desc"
        chown $SUDO_USER:$SUDO_USER "$dest" 2>/dev/null
    else
        echo "  Skipping $desc (not found in backup)"
    fi
}

# RESTORE SECTION
if [ -d "$BACKUP_DIR" ]; then
    echo ""
    echo "Starting restore from: $BACKUP_DIR"
    echo ""

    # Confirmation prompt for restore
    read -p "This will overwrite existing files in the home directory. Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Restore cancelled."
        exit 1
    fi

    # Restore personal data
    restore_directory "$BACKUP_DIR/Documents" "/home/$SUDO_USER/Documents" "Documents"
    restore_directory "$BACKUP_DIR/Pictures" "/home/$SUDO_USER/Pictures" "Pictures"
    restore_directory "$BACKUP_DIR/Videos" "/home/$SUDO_USER/Videos" "Videos"
    restore_directory "$BACKUP_DIR/Music" "/home/$SUDO_USER/Music" "Music"
    restore_directory "$BACKUP_DIR/Downloads" "/home/$SUDO_USER/Downloads" "Downloads"
    restore_directory "$BACKUP_DIR/Desktop" "/home/$SUDO_USER/Desktop" "Desktop"
    restore_directory "$BACKUP_DIR/Templates" "/home/$SUDO_USER/Templates" "Templates"

    # Restore configuration files
    restore_directory "$BACKUP_DIR/.config" "/home/$SUDO_USER/.config" "configuration files"
    restore_file "$BACKUP_DIR/.bashrc" "/home/$SUDO_USER/.bashrc" "bashrc"
    restore_file "$BACKUP_DIR/.bash_profile" "/home/$SUDO_USER/.bash_profile" "bash_profile"
    restore_file "$BACKUP_DIR/.gitconfig" "/home/$SUDO_USER/.gitconfig" "git configuration"

    # Restore additional settings and tools
    restore_directory "$BACKUP_DIR/.gnupg" "/home/$SUDO_USER/.gnupg" "GPG keys"
    restore_directory "$BACKUP_DIR/.pki" "/home/$SUDO_USER/.pki" "PKI certificates"
    restore_directory "$BACKUP_DIR/.npm" "/home/$SUDO_USER/.npm" "NPM configuration"
    restore_directory "$BACKUP_DIR/.yarn" "/home/$SUDO_USER/.yarn" "Yarn configuration"
    restore_directory "$BACKUP_DIR/.nv" "/home/$SUDO_USER/.nv" "Node version manager"
    restore_directory "$BACKUP_DIR/.cursor" "/home/$SUDO_USER/.cursor" "Cursor editor settings"
    restore_directory "$BACKUP_DIR/.var" "/home/$SUDO_USER/.var" "local application data"

    # Restore important system files
    if [ -f "$BACKUP_DIR/hosts" ]; then
        echo "Restoring /etc/hosts..."
        cp "$BACKUP_DIR/hosts" /etc/hosts 2>/dev/null || echo "  Warning: Could not restore /etc/hosts"
    else
        echo "  Skipping /etc/hosts (not found in backup)"
    fi

    # Restore GNOME Desktop settings
    if [ -f "$BACKUP_DIR/dconf_settings.txt" ]; then
        echo "Restoring GNOME Desktop settings..."
        sudo -u $SUDO_USER dconf load / < "$BACKUP_DIR/dconf_settings.txt" 2>/dev/null || echo "  Warning: Could not restore dconf settings"
    else
        echo "  Skipping GNOME Desktop settings (not found in backup)"
    fi

    # Set proper permissions for restored files
    echo "Setting proper permissions..."
    chmod 700 "/home/$SUDO_USER/.gnupg" 2>/dev/null || echo "  Warning: Could not set permissions for .gnupg"
    chmod 600 "/home/$SUDO_USER/.gnupg/gpg.conf" 2>/dev/null
    chmod 600 "/home/$SUDO_USER/.gitconfig" 2>/dev/null
    chmod 644 "/home/$SUDO_USER/.bashrc" 2>/dev/null
    chmod 644 "/home/$SUDO_USER/.bash_profile" 2>/dev/null
    echo "Restore process completed!"
else
    echo "No backup directory found at $BACKUP_DIR. Proceeding with setup only."
fi

# SETUP SECTION

echo ""
echo "Starting system setup..."
echo ""
echo "Updating system packages..."
dnf update -y

# Install basic utilities
echo "Installing basic utilities..."
dnf install -y curl wget git gnome-tweaks dconf-editor chrome-gnome-shell

# Setup system preferences
sudo -u $SUDO_USER gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer']"
sudo -u $SUDO_USER gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
sudo -u $SUDO_USER gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita'
sudo -u $SUDO_USER gsettings set org.gnome.desktop.interface document-font-name 'Cantarell 11'
sudo -u $SUDO_USER gsettings set org.gnome.desktop.interface enable-animations false
sudo -u $SUDO_USER gsettings set org.gnome.desktop.interface font-name 'Cantarell 11'

# Install Flatpak apps
echo "Installing Flatpak applications..."
FLATPAK_LIST="flatpak_apps.txt"
if [ -f "$FLATPAK_LIST" ]; then
    while IFS= read -r line; do
        flatpak install -y flathub $line
    done < "$FLATPAK_LIST"
else
    echo "  Warning: No Flatpak apps list found"
fi

# Install GNOME extensions from backup
if [ -f "$BACKUP_DIR/gnome_extensions.txt" ]; then
    echo "Installing GNOME extensions from backup..."
    while IFS= read -r line; do
        if [ ! -z "$line" ]; then
            sudo -u $SUDO_USER gnome-extensions install "$line" 2>/dev/null || echo "  Warning: Could not install extension $line"
            sudo -u $SUDO_USER gnome-extensions enable "$line" 2>/dev/null || echo "  Warning: Could not enable extension $line"
        fi
    done < "$BACKUP_DIR/gnome_extensions.txt"
else
    echo "  Warning: No GNOME extensions list found in backup"
fi

# Install Fish shell and Starship prompt
echo "Installing Fish shell and Starship..."
dnf install -y fish
sudo -u $SUDO_USER chsh -s /usr/bin/fish
curl -sS https://starship.rs/install.sh | sh -s -- -y

# Install Ghostty terminal
echo "Installing Ghostty terminal..."
dnf copr enable -y pgdev/ghostty
dnf install -y ghostty

# Copy configuration files
echo "Copying configuration files..."
mkdir -p /home/$SUDO_USER/.config/fish
mkdir -p /home/$SUDO_USER/.config/ghostty


if [ -f "../fish/config.fish" ]; then
    cp ../fish/config.fish /home/$SUDO_USER/.config/fish/config.fish
fi
if [ -f "../starship/starship.toml" ]; then
    cp ../starship/starship.toml /home/$SUDO_USER/.config/starship.toml
fi
if [ -f "../ghostty/config" ]; then
    cp ../ghostty/config /home/$SUDO_USER/.config/ghostty/config
fi

# Install Warp terminal
echo "Installing Warp terminal..."
rpm --import https://releases.warp.dev/linux/keys/warp.asc
sh -c 'echo -e "[warpdotdev]\nname=warpdotdev\nbaseurl=https://releases.warp.dev/linux/rpm/stable\nenabled=1\ngpgcheck=1\ngpgkey=https://releases.warp.dev/linux/keys/warp.asc" > /etc/yum.repos.d/warpdotdev.repo'
dnf install warp-terminal


chown -R $SUDO_USER:$SUDO_USER /home/$SUDO_USER/.config/fish
chown -R $SUDO_USER:$SUDO_USER /home/$SUDO_USER/.config/starship.toml
chown -R $SUDO_USER:$SUDO_USER /home/$SUDO_USER/.config/ghostty

# Install Ulauncher
echo "Installing Ulauncher..."
dnf install -y ulauncher

# Install development tools
echo "Installing development tools..."
dnf install -y golang docker-cli containerd docker-compose

# Enable and start Docker
systemctl enable docker
systemctl start docker
usermod -aG docker $SUDO_USER

# Install VSCode
rpm --import https://packages.microsoft.com/keys/microsoft.asc
echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | tee /etc/yum.repos.d/vscode.repo > /dev/null
dnf install -y code

# Install Cursor editor
wget https://downloads.cursor.com/production/b753cece5c67c47cb5637199a5a5de2b7100c18f/linux/x64/rpm/x86_64/cursor-1.6.35.el8.x86_64.rpm -O cursor.rpm
dnf /cursor.rpm

# Configure git with kdiff3
sudo -u $SUDO_USER git config --global merge.tool kdiff3
sudo -u $SUDO_USER git config --global mergetool.kdiff3.path "/usr/bin/flatpak"
sudo -u $SUDO_USER git config --global mergetool.kdiff3.cmd "flatpak run org.kde.kdiff3 \$LOCAL \$BASE \$REMOTE -o \$MERGED"
sudo -u $SUDO_USER git config --global diff.tool kdiff3
sudo -u $SUDO_USER git config --global difftool.kdiff3.path "/usr/bin/flatpak"
sudo -u $SUDO_USER git config --global difftool.kdiff3.cmd "flatpak run org.kde.kdiff3 \$LOCAL \$REMOTE"

# Configure git credential storage
sudo -u $SUDO_USER git config --global credential.credentialStore secretservice

# Install Source git
wget https://github.com/sourcegit-scm/sourcegit/releases/download/v2025.26/sourcegit-2025.26-1.x86_64.rpm -O sourcegit.rpm
dnf install -y ./sourcegit.rpm
rm -f sourcegit.rpm

# Configure screenshot shortcut
sudo -u $SUDO_USER gsettings set org.gnome.settings-daemon.plugins.media-keys screenshot '["<Shift><Super>s"]'

# Final system update
dnf update -y

# Completion message
echo ""
echo "========================================"
echo "PROCESS COMPLETED"
echo "========================================"
echo ""
echo "Your system has been successfully restored (if backup was available) and setup."
echo "Recommended next steps:"
echo "1. Reboot your system"
echo "2. Log in to your applications (GitHub, VSCode, Cursor, etc.)"
echo "3. Configure Cursor extensions through the app"
echo "4. Customize GNOME extensions through gnome-tweaks"
echo "5. Verify that all applications work correctly"
echo "6. Remove backup files from home directory if restoration was successful"
