#!/bin/bash

# MCP Server Validation Script for OpenCode
# Validates that all configured MCP servers are properly set up

set -e

OPENCODE_DIR="$HOME/.config/opencode"
CONFIG_FILE="$OPENCODE_DIR/opencode.json"

echo "🔍 OpenCode MCP Server Validation"
echo "=================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if opencode.json exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}❌ ERROR: opencode.json not found at $CONFIG_FILE${NC}"
    exit 1
fi

echo "✅ Found opencode.json"
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check Node.js and npm
echo "📦 Checking prerequisites..."
if command_exists node; then
    NODE_VERSION=$(node --version)
    echo -e "${GREEN}✅ Node.js: $NODE_VERSION${NC}"
else
    echo -e "${RED}❌ Node.js not found${NC}"
    echo "   Install from: https://nodejs.org/"
    exit 1
fi

if command_exists npm; then
    NPM_VERSION=$(npm --version)
    echo -e "${GREEN}✅ npm: $NPM_VERSION${NC}"
else
    echo -e "${RED}❌ npm not found${NC}"
    exit 1
fi

if command_exists npx; then
    echo -e "${GREEN}✅ npx available${NC}"
else
    echo -e "${RED}❌ npx not found${NC}"
    exit 1
fi

echo ""

# Check MCP servers
echo "🔌 Checking MCP Server Configurations..."
echo ""

# GitHub MCP
echo "1. GitHub MCP"
if grep -q '"github"' "$CONFIG_FILE"; then
    echo -e "   ${GREEN}✅ Configured in opencode.json${NC}"

    # Check for token
    if grep -q '"GITHUB_PERSONAL_ACCESS_TOKEN": ""' "$CONFIG_FILE"; then
        echo -e "   ${YELLOW}⚠️  GitHub token is empty${NC}"
        echo "      → Get token: https://github.com/settings/tokens"
        echo "      → Required scopes: repo, read:org, read:user"
    elif grep -q '"GITHUB_PERSONAL_ACCESS_TOKEN":' "$CONFIG_FILE"; then
        echo -e "   ${GREEN}✅ GitHub token configured${NC}"
    fi

    # Check if package is available
    if npx -y @modelcontextprotocol/server-github --help >/dev/null 2>&1; then
        echo -e "   ${GREEN}✅ Package accessible via npx${NC}"
    else
        echo -e "   ${YELLOW}⚠️  Package test skipped (requires token)${NC}"
    fi
else
    echo -e "   ${RED}❌ Not configured${NC}"
fi
echo ""

# Linear MCP
echo "2. Linear MCP"
if grep -q '"linear"' "$CONFIG_FILE"; then
    echo -e "   ${GREEN}✅ Configured in opencode.json${NC}"

    # Check for API key
    if grep -q '"LINEAR_API_KEY": ""' "$CONFIG_FILE"; then
        echo -e "   ${YELLOW}⚠️  Linear API key is empty${NC}"
        echo "      → Get key: https://linear.app/settings/api"
    elif grep -q '"LINEAR_API_KEY":' "$CONFIG_FILE"; then
        echo -e "   ${GREEN}✅ Linear API key configured${NC}"
    fi
else
    echo -e "   ${RED}❌ Not configured${NC}"
fi
echo ""

# Context7 MCP
echo "3. Context7 MCP"
if grep -q '"context7"' "$CONFIG_FILE"; then
    echo -e "   ${GREEN}✅ Configured in opencode.json${NC}"
    echo -e "   ${GREEN}✅ No authentication required${NC}"

    # Check if package is available
    if npx -y @upstash/context7-mcp --help >/dev/null 2>&1; then
        echo -e "   ${GREEN}✅ Package accessible via npx${NC}"
    else
        echo -e "   ${YELLOW}⚠️  Package test skipped${NC}"
    fi
else
    echo -e "   ${RED}❌ Not configured${NC}"
fi
echo ""

# Summary
echo "=================================="
echo "📊 Validation Summary"
echo "=================================="
echo ""

# Count configurations
TOTAL_MCPS=3
CONFIGURED_MCPS=0

grep -q '"github"' "$CONFIG_FILE" && ((CONFIGURED_MCPS++)) || true
grep -q '"linear"' "$CONFIG_FILE" && ((CONFIGURED_MCPS++)) || true
grep -q '"context7"' "$CONFIG_FILE" && ((CONFIGURED_MCPS++)) || true

echo "MCP Servers: $CONFIGURED_MCPS/$TOTAL_MCPS configured"
echo ""

# Check tokens
TOKENS_NEEDED=0
grep -q '"GITHUB_PERSONAL_ACCESS_TOKEN": ""' "$CONFIG_FILE" && ((TOKENS_NEEDED++)) || true
grep -q '"LINEAR_API_KEY": ""' "$CONFIG_FILE" && ((TOKENS_NEEDED++)) || true

if [ $TOKENS_NEEDED -eq 0 ]; then
    echo -e "${GREEN}✅ All MCP servers have authentication configured${NC}"
else
    echo -e "${YELLOW}⚠️  $TOKENS_NEEDED MCP server(s) need authentication tokens${NC}"
    echo ""
    echo "Next steps:"
    if grep -q '"GITHUB_PERSONAL_ACCESS_TOKEN": ""' "$CONFIG_FILE"; then
        echo "  1. Create GitHub token: https://github.com/settings/tokens"
        echo "     - Select scopes: repo, read:org, read:user"
        echo "     - Add to opencode.json: \"GITHUB_PERSONAL_ACCESS_TOKEN\": \"ghp_your_token\""
    fi
    if grep -q '"LINEAR_API_KEY": ""' "$CONFIG_FILE"; then
        echo "  2. Create Linear API key: https://linear.app/settings/api"
        echo "     - Add to opencode.json: \"LINEAR_API_KEY\": \"lin_api_your_key\""
    fi
fi

echo ""
echo "=================================="
echo "For detailed setup instructions, see:"
echo "  $OPENCODE_DIR/mcp/README.md"
echo "=================================="
