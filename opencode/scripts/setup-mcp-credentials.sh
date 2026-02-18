#!/bin/bash
# OpenCode MCP Credentials Setup
# Securely configures GitHub and Linear MCP server credentials
# Usage: bash setup-mcp-credentials.sh [--github-token TOKEN] [--linear-key KEY]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

OPENCODE_DIR="$HOME/.config/opencode"
ENV_FILE="$HOME/.opencode_mcp_env"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}OpenCode MCP Credentials Setup${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Parse arguments
GITHUB_TOKEN=""
LINEAR_KEY=""
NON_INTERACTIVE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --github-token)
            GITHUB_TOKEN="$2"
            NON_INTERACTIVE=true
            shift 2
            ;;
        --linear-key)
            LINEAR_KEY="$2"
            NON_INTERACTIVE=true
            shift 2
            ;;
        --help)
            echo "Usage: bash setup-mcp-credentials.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --github-token TOKEN   GitHub Personal Access Token"
            echo "  --linear-key KEY       Linear API Key"
            echo "  --help                 Show this help"
            echo ""
            echo "Interactive mode (recommended):"
            echo "  bash setup-mcp-credentials.sh"
            echo ""
            echo "Non-interactive mode:"
            echo "  bash setup-mcp-credentials.sh --github-token ghp_xxx --linear-key lin_xxx"
            echo ""
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# ===========================
# GitHub Personal Access Token
# ===========================

if [ -z "$GITHUB_TOKEN" ]; then
    echo -e "${BLUE}1. GitHub Personal Access Token${NC}"
    echo ""
    echo "OpenCode needs a GitHub PAT to access repositories, create issues, and PRs."
    echo ""
    echo "How to create a GitHub PAT:"
    echo "  1. Go to: https://github.com/settings/tokens"
    echo "  2. Click 'Generate new token' → 'Generate new token (classic)'"
    echo "  3. Name: 'OpenCode MCP'"
    echo "  4. Expiration: 90 days (recommended)"
    echo "  5. Scopes (check these boxes):"
    echo "     ☑ repo (Full control of private repositories)"
    echo "     ☑ read:org (Read org and team membership)"
    echo "  6. Click 'Generate token'"
    echo "  7. Copy the token (starts with 'ghp_')"
    echo ""
    echo -n "Enter GitHub PAT (or press Enter to skip): "
    read -s GITHUB_TOKEN
    echo ""
    echo ""
fi

# Validate GitHub token format
if [ -n "$GITHUB_TOKEN" ]; then
    if [[ ! "$GITHUB_TOKEN" =~ ^ghp_[a-zA-Z0-9]{36}$ ]] && [[ ! "$GITHUB_TOKEN" =~ ^github_pat_[a-zA-Z0-9_]{82}$ ]]; then
        echo -e "${YELLOW}⚠ Warning: GitHub token format unexpected${NC}"
        echo "Expected format: ghp_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
        echo "Or: github_pat_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
        echo ""
        echo -n "Continue anyway? (y/n): "
        read -r CONFIRM
        if [ "$CONFIRM" != "y" ]; then
            echo "Aborting."
            exit 1
        fi
    fi

    # Test GitHub connectivity
    echo -e "${BLUE}Testing GitHub connection...${NC}"
    GITHUB_USER=$(curl -s -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user | grep -o '"login": *"[^"]*"' | cut -d'"' -f4)

    if [ -n "$GITHUB_USER" ]; then
        echo -e "${GREEN}✓ GitHub token valid${NC}"
        echo "  Authenticated as: $GITHUB_USER"
        echo ""
    else
        echo -e "${RED}✗ GitHub token invalid or network error${NC}"
        echo ""
        echo "Please check:"
        echo "  1. Token is correct"
        echo "  2. Token has required scopes (repo, read:org)"
        echo "  3. Network connection is working"
        echo ""
        exit 1
    fi
fi

# ===========================
# Linear API Key
# ===========================

if [ -z "$LINEAR_KEY" ]; then
    echo -e "${BLUE}2. Linear API Key${NC}"
    echo ""
    echo "OpenCode needs a Linear API key to read tickets and update issues."
    echo ""
    echo "How to create a Linear API key:"
    echo "  1. Go to: https://linear.app/settings/api"
    echo "  2. Click 'Create new API key'"
    echo "  3. Label: 'OpenCode MCP'"
    echo "  4. Copy the key (starts with 'lin_')"
    echo ""
    echo -n "Enter Linear API Key (or press Enter to skip): "
    read -s LINEAR_KEY
    echo ""
    echo ""
fi

# Validate Linear key format
if [ -n "$LINEAR_KEY" ]; then
    if [[ ! "$LINEAR_KEY" =~ ^lin_[a-zA-Z0-9]{40}$ ]]; then
        echo -e "${YELLOW}⚠ Warning: Linear key format unexpected${NC}"
        echo "Expected format: lin_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
        echo ""
        echo -n "Continue anyway? (y/n): "
        read -r CONFIRM
        if [ "$CONFIRM" != "y" ]; then
            echo "Aborting."
            exit 1
        fi
    fi

    # Test Linear connectivity
    echo -e "${BLUE}Testing Linear connection...${NC}"
    LINEAR_ORG=$(curl -s -H "Authorization: $LINEAR_KEY" \
                       -H "Content-Type: application/json" \
                       -d '{"query":"{ viewer { id name } }"}' \
                       https://api.linear.app/graphql | grep -o '"name": *"[^"]*"' | head -1 | cut -d'"' -f4)

    if [ -n "$LINEAR_ORG" ]; then
        echo -e "${GREEN}✓ Linear key valid${NC}"
        echo "  Organization: $LINEAR_ORG"
        echo ""
    else
        echo -e "${YELLOW}⚠ Linear key validation inconclusive${NC}"
        echo "  Could not verify key, but will proceed"
        echo ""
    fi
fi

# ===========================
# Save Credentials
# ===========================

if [ -z "$GITHUB_TOKEN" ] && [ -z "$LINEAR_KEY" ]; then
    echo -e "${YELLOW}⚠ No credentials provided${NC}"
    echo "Exiting without changes."
    exit 0
fi

echo -e "${BLUE}3. Save Credentials${NC}"
echo ""
echo "Credentials will be saved to: $ENV_FILE"
echo "This file will have 600 permissions (owner read/write only)"
echo ""

# Create/update .opencode_mcp_env file
cat > "$ENV_FILE" <<EOF
# OpenCode MCP Credentials
# This file contains sensitive API keys - DO NOT commit to git
# Permissions: 600 (owner read/write only)
# Created: $(date -u +"%Y-%m-%d %H:%M:%S UTC")

EOF

if [ -n "$GITHUB_TOKEN" ]; then
    echo "export GITHUB_PAT=\"$GITHUB_TOKEN\"" >> "$ENV_FILE"
fi

if [ -n "$LINEAR_KEY" ]; then
    echo "export LINEAR_API_KEY=\"$LINEAR_KEY\"" >> "$ENV_FILE"
fi

# Secure permissions
chmod 600 "$ENV_FILE"

echo -e "${GREEN}✓ Credentials saved${NC}"
echo ""

# ===========================
# Update Shell RC Files
# ===========================

echo -e "${BLUE}4. Shell Integration${NC}"
echo ""
echo "To load these credentials automatically, add to your shell rc file:"
echo ""
echo -e "${YELLOW}Add this line to ~/.bashrc or ~/.zshrc:${NC}"
echo "  source $ENV_FILE"
echo ""

# Offer to add automatically
if [ "$NON_INTERACTIVE" = false ]; then
    echo -n "Add to ~/.bashrc automatically? (y/n): "
    read -r ADD_TO_RC

    if [ "$ADD_TO_RC" = "y" ]; then
        if [ -f "$HOME/.bashrc" ]; then
            if ! grep -q "source $ENV_FILE" "$HOME/.bashrc"; then
                echo "" >> "$HOME/.bashrc"
                echo "# OpenCode MCP credentials" >> "$HOME/.bashrc"
                echo "source $ENV_FILE" >> "$HOME/.bashrc"
                echo -e "${GREEN}✓ Added to ~/.bashrc${NC}"
                echo ""
            else
                echo -e "${YELLOW}Already in ~/.bashrc${NC}"
                echo ""
            fi
        else
            echo -e "${YELLOW}~/.bashrc not found${NC}"
            echo ""
        fi
    fi
fi

# ===========================
# Verify Environment
# ===========================

echo -e "${BLUE}5. Verification${NC}"
echo ""

# Source the file to test
source "$ENV_FILE"

if [ -n "$GITHUB_PAT" ]; then
    echo -e "${GREEN}✓ GITHUB_PAT environment variable set${NC}"
else
    echo -e "${RED}✗ GITHUB_PAT not set${NC}"
fi

if [ -n "$LINEAR_API_KEY" ]; then
    echo -e "${GREEN}✓ LINEAR_API_KEY environment variable set${NC}"
else
    echo -e "${RED}✗ LINEAR_API_KEY not set${NC}"
fi

echo ""

# ===========================
# Security Reminders
# ===========================

echo -e "${BLUE}6. Security Reminders${NC}"
echo ""
echo -e "${YELLOW}⚠ IMPORTANT SECURITY NOTES:${NC}"
echo ""
echo "1. ${YELLOW}NEVER commit $ENV_FILE to git${NC}"
echo "   Add to .gitignore: echo '.opencode_mcp_env' >> ~/.gitignore"
echo ""
echo "2. ${YELLOW}Rotate tokens every 90 days${NC}"
echo "   Set calendar reminder to regenerate tokens quarterly"
echo ""
echo "3. ${YELLOW}Revoke tokens if compromised${NC}"
echo "   GitHub: https://github.com/settings/tokens"
echo "   Linear: https://linear.app/settings/api"
echo ""
echo "4. ${YELLOW}Use token scopes sparingly${NC}"
echo "   Only grant minimum permissions needed"
echo ""
echo "5. ${YELLOW}Backup credentials securely${NC}"
echo "   Store in password manager (1Password, LastPass, etc.)"
echo ""

# ===========================
# Next Steps
# ===========================

echo -e "${BLUE}7. Next Steps${NC}"
echo ""
echo "1. ${GREEN}Source credentials${NC} in current shell:"
echo "   source $ENV_FILE"
echo ""
echo "2. ${GREEN}Validate MCP servers${NC}:"
echo "   bash $OPENCODE_DIR/scripts/validate-mcp.sh"
echo ""
echo "3. ${GREEN}Test GitHub MCP${NC}:"
echo "   npx @modelcontextprotocol/server-github"
echo ""
echo "4. ${GREEN}Test Linear MCP${NC}:"
echo "   npx @linear/mcp"
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

exit 0
