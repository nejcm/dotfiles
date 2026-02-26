#!/usr/bin/env bash
# OpenCode dotfiles install script (Linux)
# Copies this opencode tree into ~/.config/opencode

set -e

OPENCODE_CONFIG="${OPENCODE_CONFIG:-$HOME/.opencode}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "OpenCode install (Linux)"
echo "  Source: $SCRIPT_DIR"
echo "  Target: $OPENCODE_CONFIG"
echo ""

if [ -d "$OPENCODE_CONFIG" ] && [ -f "$OPENCODE_CONFIG/opencode.json" ]; then
  BACKUP="$OPENCODE_CONFIG.opencode-backup-$(date +%Y%m%d-%H%M%S)"
  echo "Existing config found. Backing up to: $BACKUP"
  cp -a "$OPENCODE_CONFIG" "$BACKUP"
fi

mkdir -p "$OPENCODE_CONFIG"

# Copy contents
for item in "$SCRIPT_DIR"/*; do
  [ -e "$item" ] || continue
  case "$(basename "$item")" in
    install.sh|install.ps1) continue ;;
  esac
  cp -a "$item" "$OPENCODE_CONFIG/"
done

# Make scripts executable
if [ -d "$OPENCODE_CONFIG/scripts" ]; then
  chmod +x "$OPENCODE_CONFIG/scripts/"*.sh 2>/dev/null || true
fi

echo ""
echo "Done. OpenCode config is at: $OPENCODE_CONFIG"
echo "  - Edit: $OPENCODE_CONFIG/opencode.json"
echo "  - Scripts: $OPENCODE_CONFIG/scripts/"
echo "  - Validate: bash $OPENCODE_CONFIG/scripts/validate-setup.sh"
echo ""
echo "Running setup command in: $OPENCODE_CONFIG"
(
  cd "$OPENCODE_CONFIG"
  npx get-shit-done-cc@latest
)
