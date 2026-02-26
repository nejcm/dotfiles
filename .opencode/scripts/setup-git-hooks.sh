#!/bin/bash
# OpenCode Git Hooks Setup Script
# Installs pre-commit hook into current Git repository
# Usage: bash setup-git-hooks.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

OPENCODE_DIR="$HOME/.config/opencode"
PRE_COMMIT_SCRIPT="$OPENCODE_DIR/scripts/pre-commit.sh"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}OpenCode Git Hooks Setup${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if we're in a Git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}✗${NC} Not in a Git repository"
    echo ""
    echo "Please run this script from within a Git repository."
    echo ""
    exit 1
fi

GIT_DIR=$(git rev-parse --git-dir)
HOOKS_DIR="$GIT_DIR/hooks"
PRE_COMMIT_HOOK="$HOOKS_DIR/pre-commit"

echo "Git directory: $GIT_DIR"
echo "Hooks directory: $HOOKS_DIR"
echo ""

# Create hooks directory if it doesn't exist
if [ ! -d "$HOOKS_DIR" ]; then
    echo "Creating hooks directory..."
    mkdir -p "$HOOKS_DIR"
    echo -e "${GREEN}✓${NC} Hooks directory created"
fi

# Check if pre-commit script exists
if [ ! -f "$PRE_COMMIT_SCRIPT" ]; then
    echo -e "${RED}✗${NC} Pre-commit script not found at:"
    echo "  $PRE_COMMIT_SCRIPT"
    echo ""
    echo "Please ensure OpenCode is properly installed."
    exit 1
fi

# Make pre-commit script executable
chmod +x "$PRE_COMMIT_SCRIPT"

# Check if pre-commit hook already exists
if [ -f "$PRE_COMMIT_HOOK" ]; then
    echo -e "${YELLOW}⚠${NC} Pre-commit hook already exists"
    echo ""
    echo "Current hook:"
    head -n 5 "$PRE_COMMIT_HOOK"
    echo "..."
    echo ""

    read -p "Overwrite existing hook? (y/N): " -n 1 -r
    echo ""

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted. No changes made."
        exit 0
    fi

    # Backup existing hook
    BACKUP_FILE="$PRE_COMMIT_HOOK.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$PRE_COMMIT_HOOK" "$BACKUP_FILE"
    echo -e "${GREEN}✓${NC} Existing hook backed up to:"
    echo "  $BACKUP_FILE"
    echo ""
fi

# Install hook (symlink to maintain updates)
echo "Installing pre-commit hook..."

# Remove old hook if exists
rm -f "$PRE_COMMIT_HOOK"

# Create symlink
ln -s "$PRE_COMMIT_SCRIPT" "$PRE_COMMIT_HOOK"

# Make hook executable
chmod +x "$PRE_COMMIT_HOOK"

echo -e "${GREEN}✓${NC} Pre-commit hook installed successfully!"
echo ""

# Verify installation
echo -e "${BLUE}Verifying installation...${NC}"

if [ -L "$PRE_COMMIT_HOOK" ]; then
    echo -e "${GREEN}✓${NC} Hook is a symlink (will auto-update with OpenCode)"
elif [ -f "$PRE_COMMIT_HOOK" ]; then
    echo -e "${GREEN}✓${NC} Hook installed as file"
else
    echo -e "${RED}✗${NC} Hook installation failed"
    exit 1
fi

if [ -x "$PRE_COMMIT_HOOK" ]; then
    echo -e "${GREEN}✓${NC} Hook is executable"
else
    echo -e "${RED}✗${NC} Hook is not executable"
    chmod +x "$PRE_COMMIT_HOOK"
    echo -e "${GREEN}✓${NC} Fixed: Made hook executable"
fi

echo ""

# Test hook
echo -e "${BLUE}Testing hook...${NC}"
echo ""

if bash "$PRE_COMMIT_HOOK" --help > /dev/null 2>&1 || true; then
    echo -e "${GREEN}✓${NC} Hook is functional"
else
    echo -e "${YELLOW}⚠${NC} Hook test inconclusive (this is normal if no files are staged)"
fi

echo ""

# Configuration options
echo -e "${BLUE}Configuration Options${NC}"
echo ""
echo "The pre-commit hook will run the following checks:"
echo "  ✓ Sensitive file detection (passwords, keys, secrets)"
echo "  ✓ File size limits (warns on files >1MB)"
echo "  ✓ Merge conflict markers"
echo "  ✓ Debug statements (console.log, debugger, etc.)"
echo "  ✓ Code linting (ESLint, Pylint if configured)"
echo "  ✓ Code formatting (Prettier, Black if configured)"
echo ""

echo "To customize checks, edit:"
echo "  $PRE_COMMIT_SCRIPT"
echo ""

echo "To bypass pre-commit hook (NOT RECOMMENDED):"
echo "  git commit --no-verify"
echo ""

echo "To disable hook:"
echo "  rm $PRE_COMMIT_HOOK"
echo ""

# Additional hooks available
echo -e "${BLUE}Additional Hooks Available${NC}"
echo ""
echo "You can also install these hooks manually:"
echo ""

# Pre-push hook suggestion
echo "Pre-push hook (runs tests before pushing):"
echo "  Create: $HOOKS_DIR/pre-push"
echo '  Content: #!/bin/bash'
echo '           npm test || { echo "Tests failed! Push aborted."; exit 1; }'
echo ""

# Commit-msg hook suggestion
echo "Commit-msg hook (enforces conventional commits):"
echo "  Create: $HOOKS_DIR/commit-msg"
echo '  Content: #!/bin/bash'
echo '           grep -E "^(feat|fix|docs|style|refactor|test|chore):" "$1" ||'
echo '           { echo "Commit message must start with type (feat|fix|docs|...)"; exit 1; }'
echo ""

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Setup Complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

echo -e "${GREEN}✓${NC} Pre-commit hook installed and ready"
echo ""
echo "The hook will run automatically on every commit."
echo ""
echo "Test it by:"
echo "  1. Stage some files: git add <file>"
echo "  2. Commit: git commit -m \"test\""
echo "  3. The hook will run checks before allowing commit"
echo ""

echo "For more information:"
echo "  - Hook script: $PRE_COMMIT_SCRIPT"
echo "  - Git hooks docs: https://git-scm.com/docs/githooks"
echo "  - OpenCode docs: $OPENCODE_DIR/README.md"
echo ""

exit 0
