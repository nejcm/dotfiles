#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

if [[ -n "${SUDO_USER:-}" ]]; then
    REAL_USER="$SUDO_USER"
    REAL_HOME="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
else
    REAL_USER="$(id -un)"
    REAL_HOME="$HOME"
fi

RESTORED=()
SKIPPED=()
SUDO_AVAILABLE=false

if command -v sudo >/dev/null 2>&1; then
    if sudo -n true 2>/dev/null; then
        SUDO_AVAILABLE=true
    elif [[ -t 0 ]] && sudo -v; then
        SUDO_AVAILABLE=true
    fi
fi

record_restore() {
    RESTORED+=("$1")
}

record_skip() {
    SKIPPED+=("$1")
}

install_user_file() {
    local src="$1"
    local dest="$2"
    local mode="$3"

    if [[ ! -f "$src" ]]; then
        record_skip "$src (missing)"
        return
    fi

    if [[ -n "${SUDO_USER:-}" ]]; then
        sudo -u "$REAL_USER" install -Dm"$mode" "$src" "$dest"
    else
        install -Dm"$mode" "$src" "$dest"
    fi

    record_restore "$dest"
}

install_system_file() {
    local src="$1"
    local dest="$2"
    local mode="$3"

    if [[ ! -f "$src" ]]; then
        record_skip "$src (missing)"
        return
    fi

    if [[ "$SUDO_AVAILABLE" != true ]]; then
        record_skip "$dest (sudo unavailable)"
        return
    fi

    sudo install -Dm"$mode" "$src" "$dest"
    record_restore "$dest"
}

install_packages() {
    local pkg_file="$SCRIPT_DIR/pkg-list.txt"
    local -a packages=()

    if [[ ! -f "$pkg_file" ]]; then
        record_skip "pkg-list.txt (missing)"
        return
    fi

    if ! command -v yay >/dev/null 2>&1; then
        record_skip "package install (yay not installed)"
        return
    fi

    mapfile -t packages < <(
        awk '
            {
                for (i = 1; i <= NF; i++) {
                    if ($i ~ /^#/) {
                        break
                    }
                    print $i
                }
            }
        ' "$pkg_file"
    )

    if (( ${#packages[@]} == 0 )); then
        record_skip "package install (pkg-list.txt is empty)"
        return
    fi

    echo "Installing packages from $pkg_file"
    if [[ -n "${SUDO_USER:-}" ]]; then
        sudo -u "$REAL_USER" yay -S --needed "${packages[@]}"
    else
        yay -S --needed "${packages[@]}"
    fi

    record_restore "packages from pkg-list.txt"
}

install_omarchy_config_tree() {
    local config_root="$SCRIPT_DIR/.config"
    local src

    if [[ ! -d "$config_root" ]]; then
        record_skip "$config_root (missing)"
        return
    fi

    while IFS= read -r -d '' src; do
        local rel_path="${src#"$config_root/"}"
        install_user_file "$src" "$REAL_HOME/.config/$rel_path" 644
    done < <(find "$config_root" -type f -print0)
}

echo "Installing Omarchy setup for $REAL_USER"

install_packages
install_omarchy_config_tree

install_user_file "$REPO_DIR/bash/.bashrc" "$REAL_HOME/.bashrc" 644
install_user_file "$REPO_DIR/ghostty/config" "$REAL_HOME/.config/ghostty/config" 644
install_user_file "$REPO_DIR/starship/starship.toml" "$REAL_HOME/.config/starship.toml" 644
install_user_file "$SCRIPT_DIR/scripts/toggle-touchpad" "$REAL_HOME/.local/bin/toggle-touchpad" 755

install_system_file "$SCRIPT_DIR/sudoers-touchpad-toggle" "/etc/sudoers.d/touchpad-toggle" 440
if [[ "$SUDO_AVAILABLE" == true && -f "$SCRIPT_DIR/sudoers-touchpad-toggle" ]]; then
    sudo visudo -cf /etc/sudoers.d/touchpad-toggle >/dev/null
fi

git config --global user.name "nejcm"
git config --global user.email "1865210+nejcm@users.noreply.github.com"

# Install encore
curl -fsSL https://encore.dev/install.sh | bash

# Install bun
curl -fsSL https://bun.sh/install | bash

# Install pnpm
curl -fsSL https://get.pnpm.io/install.sh | sh -

# Install opencode
curl -fsSL https://opencode.ai/install | bash

# Install claude code
curl -fsSL https://claude.ai/install.sh | bash

# Install openai codex
bun add -g @openai/codex

echo
echo "Installed:"
for item in "${RESTORED[@]}"; do
    echo "  - $item"
done

if (( ${#SKIPPED[@]} > 0 )); then
    echo
    echo "Skipped:"
    for item in "${SKIPPED[@]}"; do
        echo "  - $item"
    done
fi

echo
echo "Next steps:"
echo "  - hyprctl reload"
echo "  - sudo limine-entry-tool --scan"