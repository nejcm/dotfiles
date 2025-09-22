#!/bin/bash

# Fedora System Setup Script
# This script automates the setup of a new Fedora installation with all specified apps and configurations

# Ensure script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "Please run this script as root or with sudo."
    exit 1
fi

# Update system first
echo "Updating system packages..."
dnf update -y

# Install basic utilities
echo "Installing basic utilities..."
dnf install -y curl wget git gnome-tweaks dconf-editor chrome-gnome-shell

# Setup system preferences
echo "Configuring system preferences..."

# Enable fractional scaling
gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer']"

# Enable dark mode
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita'
gsettings set org.gnome.desktop.interface document-font-name 'Cantarell 11'
gsettings set org.gnome.desktop.interface enable-animations false
gsettings set org.gnome.desktop.interface font-name 'Cantarell 11'

# Install Flatpak apps from flatpak_apps.txt
echo "Installing Flatpak applications..."
while IFS= read -r line; do
    flatpak install -y flathub $line
done < flatpak_apps.txt

# Install GNOME extensions
echo "Installing GNOME extensions..."
EXTENSIONS=(
    "clipboard-history@alexsaveau.dev"   # Clipboard History
    "dash-to-dock@micxgx.gmail.com"      # Dash to Dock
    "tilingshell@ferrarodomenico.com"    # Tiling Shell
)
for EXT in "${EXTENSIONS[@]}"; do
    sudo -u $SUDO_USER gnome-extensions install $EXT
    sudo -u $SUDO_USER gnome-extensions enable $EXT
done

# Install TLP for power management
echo "Installing and configuring TLP..."
dnf install -y tlp tlp-rdw
dnf remove tuned tuned-ppd
systemctl enable tlp.service
systemctl mask systemd-rfkill.service systemd-rfkill.socket

# Configure TLP battery thresholds
echo "Configuring TLP battery thresholds..."
TLP_CONFIG="/etc/tlp.conf"
sed -i 's/^#START_CHARGE_THRESH_BAT0=.*/START_CHARGE_THRESH_BAT0=75/' $TLP_CONFIG
sed -i 's/^#STOP_CHARGE_THRESH_BAT0=.*/STOP_CHARGE_THRESH_BAT0=80/' $TLP_CONFIG
sed -i 's/^#START_CHARGE_THRESH_BAT1=.*/START_CHARGE_THRESH_BAT1=75/' $TLP_CONFIG
sed -i 's/^#STOP_CHARGE_THRESH_BAT1=.*/STOP_CHARGE_THRESH_BAT1=80/' $TLP_CONFIG
systemctl start tlp.service
tlp start
tlp-stat -s

# Install Ghostty terminal
echo "Installing Ghostty terminal..."
dnf copr enable -y pgdev/ghostty
dnf install -y ghostty

# Install Fish shell and Starship prompt
echo "Installing Fish shell and Starship..."
dnf install -y fish
chsh -s /usr/bin/fish
curl -sS https://starship.rs/install.sh | sh -s -- -y

# Copy config files from this repo to config folder
echo "Copying configuration files..."
mkdir -p /home/$SUDO_USER/.config/fish
mkdir -p /home/$SUDO_USER/.config/ghostty
cp ../fish/config.fish /home/$SUDO_USER/.config/fish/config.fish
cp ../starship/starship.toml /home/$SUDO_USER/.config/starship.toml
cp ../ghostty/config /home/$SUDO_USER/.config/ghostty/config
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
echo "Configuring Docker..."
systemctl enable docker
systemctl start docker
usermod -aG docker $SUDO_USER

# Install VSCode
echo "Installing Visual Studio Code..."
rpm --import https://packages.microsoft.com/keys/microsoft.asc
echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | tee /etc/yum.repos.d/vscode.repo > /dev/null
dnf install code

# Install Cursor editor
wget https://downloads.cursor.com/production/b753cece5c67c47cb5637199a5a5de2b7100c18f/linux/x64/rpm/x86_64/cursor-1.6.35.el8.x86_64.rpm -O cursor.rpm
dnf /cursor.rpm

# Move bin directory to home directory
mkdir -p /home/$SUDO_USER/bin
mv bin/* /home/$SUDO_USER/bin/
chown -R $SUDO_USER:$SUDO_USER /home/$SUDO_USER/bin

# Install kdiff3 (already installed via Flatpak)
# Configure git to use kdiff3
echo "Configuring git with kdiff3..."
sudo -u $SUDO_USER git config --global merge.tool kdiff3
sudo -u $SUDO_USER git config --global mergetool.kdiff3.path "/usr/bin/flatpak"
sudo -u $SUDO_USER git config --global mergetool.kdiff3.cmd "flatpak run org.kde.kdiff3 \$LOCAL \$BASE \$REMOTE -o \$MERGED"
sudo -u $SUDO_USER git config --global diff.tool kdiff3
sudo -u $SUDO_USER git config --global difftool.kdiff3.path "/usr/bin/flatpak"
sudo -u $SUDO_USER git config --global difftool.kdiff3.cmd "flatpak run org.kde.kdiff3 \$LOCAL \$REMOTE"

# Configure git credential storage
echo "Configuring git credential storage..."
sudo -u $SUDO_USER git config --global credential.credentialStore secretservice
git config --global user.name "nejcm"


# Configure screenshot shortcut
echo "Configuring screenshot shortcut..."
sudo -u $SUDO_USER gsettings set org.gnome.settings-daemon.plugins.media-keys screenshot '["<Shift><Super>s"]'

# Final system update
echo "Performing final system update..."
dnf update -y

echo ""
echo "Setup complete! Some changes may require a reboot to take effect."
echo "Recommended next steps:"
echo "1. Reboot your system"
echo "2. Log in to your applications (NordVPN, GitHub, etc.)"
echo "3. Configure Cursor extensions through the app"
echo "4. Customize GNOME extensions through gnome-tweaks"
