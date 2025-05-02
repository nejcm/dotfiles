# Run script

```base
# make executable
chmod +x fedora_setup.sh
# run
sudo ./setup.sh
```

# Instructions

### Setup system preferences

- Background, dark theme, ...
- Screenshot shortcut: Settings > Customize Shortcuts > Screenshots

### Install flatpak apps

### Install other apps

### Set system default apps (browser, ...)

### Power management

[TLP](https://www.reddit.com/r/linux/comments/9z8w0t/tlp_and_tuned_conflict/)

```bash
sudo dnf install tlp tlp-rdw
sudo dnf remove tuned tuned-ppd
sudo systemctl enable tlp.service
sudo systemctl mask systemd-rfkill.service systemd-rfkill.socket
sudo systemctl start tlp.service
sudo tlp start
tlp-stat -s
```

** Config **

# /etc/tlp.conf

START_CHARGE_THRESH_BAT0=75
STOP_CHARGE_THRESH_BAT0=80
START_CHARGE_THRESH_BAT1=75
STOP_CHARGE_THRESH_BAT1=80

### Ghostty

```bash
sudo dnf copr enable pgdev/ghostty
sudo dnf install ghostty
```

### Fish

```bash
sudo dnf install fish
```

### Starship

```bash
curl -sS https://starship.rs/install.sh | sh
```

### Ulauncher

```bash
sudo dnf install ulauncher
```

### Go

```bash
sudo dnf install golang
```

### Docker

```bash
sudo dnf install docker-cli containerd
sudo dnf install docker-compose
```

### Git

```bash
sudo dnf install git
```

```bash
# Setup default merge tool (kdiff3)
git config --global merge.tool kdiff3
git config --global mergetool.kdiff3.path "/usr/bin/flatpak"
git config --global mergetool.kdiff3.cmd "flatpak run org.kde.kdiff3 \$LOCAL \$BASE \$REMOTE -o \$MERGED"
git config --global diff.tool kdiff3
git config --global difftool.kdiff3.path "/usr/bin/flatpak"
git config --global difftool.kdiff3.cmd "flatpak run org.kde.kdiff3 \$LOCAL \$REMOTE"
# Setup git auth
git config --global credential.credentialStore secretservice
```

### SourceGit

- Install from Github

### Nordvpn

Follow instructions on website

### Cursor

Download from website.  
[Instructions](https://dev.to/mhbaando/how-to-install-cursor-the-ai-editor-on-linux-41dm)

```bash
chmod +x cursor.AppImage
```

Install all extensions.

### GNOME Extensions

- Clipboard History
- Dash to Dock
- Tilling Shell
