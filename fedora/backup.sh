#!/bin/bash

# Needs sudo privileges to run
if sudo -v &>/dev/null; then
  echo "User has sudo privileges."
else
  echo "User does NOT have sudo privileges."
  exit 1
fi

# Get the current working directory
CURRENT_DIR="$(pwd)"
BACKUP_DIR="$CURRENT_DIR/backup"

# Create backup directory in current location
mkdir -p "$BACKUP_DIR"

echo "Starting backup process..."
echo "Backup location: $BACKUP_DIR"
echo ""

# Back up personal data
echo "Backing up personal data..."
cp -r ~/Documents "$BACKUP_DIR/" 2>/dev/null || echo "  Warning: Could not backup ~/Documents"
cp -r ~/Pictures "$BACKUP_DIR/" 2>/dev/null || echo "  Warning: Could not backup ~/Pictures"
cp -r ~/Videos "$BACKUP_DIR/" 2>/dev/null || echo "  Warning: Could not backup ~/Videos"
cp -r ~/Music "$BACKUP_DIR/" 2>/dev/null || echo "  Warning: Could not backup ~/Music"
cp -r ~/Downloads "$BACKUP_DIR/" 2>/dev/null || echo "  Warning: Could not backup ~/Downloads"
cp -r ~/Desktop "$BACKUP_DIR/" 2>/dev/null || echo "  Warning: Could not backup ~/Desktop"
cp -r ~/Templates "$BACKUP_DIR/" 2>/dev/null || echo "  Warning: Could not backup ~/Templates"
cp -r ~/Work "$BACKUP_DIR/" 2>/dev/null || echo "  Warning: Could not backup ~/Work"

# Back up configuration files and settings
echo "Backing up configuration files..."
cp -r ~/.config "$BACKUP_DIR/" 2>/dev/null || echo "  Warning: Could not backup ~/.config"
cp ~/.bashrc "$BACKUP_DIR/" 2>/dev/null || echo "  Warning: Could not backup ~/.bashrc"
cp ~/.bash_profile "$BACKUP_DIR/" 2>/dev/null || echo "  Warning: Could not backup ~/.bash_profile"
cp ~/.gitconfig "$BACKUP_DIR/" 2>/dev/null || echo "  Warning: Could not backup ~/.gitconfig"

# Back up VSCode settings
echo "Backing up VSCode settings..."
cp -r ~/.vscode "$BACKUP_DIR/" 2>/dev/null || echo "  Warning: Could not backup ~/.vscode"

# Back up GPG keys
echo "Backing up GPG keys..."
cp -r ~/.gnupg "$BACKUP_DIR/" 2>/dev/null || echo "  Warning: Could not backup ~/.gnupg"

# Back up PKI certificates
echo "Backing up PKI certificates..."
cp -r ~/.pki "$BACKUP_DIR/" 2>/dev/null || echo "  Warning: Could not backup ~/.pki"

# Back up development tools
echo "Backing up development tools..."
cp -r ~/.npm "$BACKUP_DIR/" 2>/dev/null || echo "  Warning: Could not backup ~/.npm"
cp -r ~/.yarn "$BACKUP_DIR/" 2>/dev/null || echo "  Warning: Could not backup ~/.yarn"
cp -r ~/.nv "$BACKUP_DIR/" 2>/dev/null || echo "  Warning: Could not backup ~/.nv"
cp -r ~/.cursor "$BACKUP_DIR/" 2>/dev/null || echo "  Warning: Could not backup ~/.cursor"
cp -r ~/.var "$BACKUP_DIR/" 2>/dev/null || echo "  Warning: Could not backup ~/.var"

# Back up Go workspace
echo "Backing up Go workspace..."
cp -r ~/go "$BACKUP_DIR/" 2>/dev/null || echo "  Warning: Could not backup ~/go"

# Back up special files
#echo "Backing up special files..."
#cp ~/gnome-settings.txt "$BACKUP_DIR/" 2>/dev/null || echo "  Warning: Could not backup ~/gnome-settings.txt"

# Generate package lists
echo "Generating package lists..."
#rpm -qa > "$BACKUP_DIR/installed_packages.txt" 2>/dev/null || echo "  Warning: Could not generate RPM package list"
flatpak list --columns=application --app > "$BACKUP_DIR/flatpak_apps.txt" 2>/dev/null || echo "  Warning: Could not generate Flatpak app list"
dnf repolist > "$BACKUP_DIR/repositories.txt" 2>/dev/null || echo "  Warning: Could not generate repository list"

# Back up enabled services
#echo "Backing up service configurations..."
#systemctl --user list-unit-files --state=enabled > "$BACKUP_DIR/user_services.txt" 2>/dev/null || echo "  Warning: Could not backup user services"
#systemctl list-unit-files --state=enabled > "$BACKUP_DIR/system_services.txt" 2>/dev/null || echo "  Warning: Could not backup system services"

# Back up development environment
echo "Backing up development environment..."
npm list -g --depth=0 > "$BACKUP_DIR/npm_global_packages.txt" 2>/dev/null || echo "  Warning: Could not generate NPM global packages list"
pip list > "$BACKUP_DIR/pip_packages.txt" 2>/dev/null || echo "  Warning: Could not generate pip packages list"
docker images > "$BACKUP_DIR/docker_images.txt" 2>/dev/null || echo "  Warning: Could not generate Docker images list"

# Back up GNOME Desktop settings
echo "Backing up GNOME Desktop settings..."
dconf dump / > "$BACKUP_DIR/dconf_settings.txt" 2>/dev/null || echo "  Warning: Could not backup dconf settings"
gnome-extensions list > "$BACKUP_DIR/gnome_extensions.txt" 2>/dev/null || echo "  Warning: Could not generate GNOME extensions list"

# Important system files (if customized)
echo "Backing up important system files..."
sudo cp /etc/hosts "$BACKUP_DIR/" 2>/dev/null || echo "  Warning: Could not backup /etc/hosts"

# Notify user of completion
echo ""
echo "Backup completed successfully!"
echo "All files are located in: $BACKUP_DIR"
echo "You can run this script from any location and it will create a backup folder in the current directory."

