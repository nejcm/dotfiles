#!/bin/bash
# OpenCode Health Check Script
# Checks agent availability and system health
# Usage: bash health-check.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Counters
HEALTHY=0
UNHEALTHY=0
DEGRADED=0

OPENCODE_DIR="$HOME/.config/opencode"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}OpenCode Health Check${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 1. Check System Requirements
echo -e "${BLUE}1. System Requirements${NC}"

# Check Node.js
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo -e "${GREEN}✓${NC} Node.js: $NODE_VERSION"
    ((HEALTHY++))
else
    echo -e "${YELLOW}⚠${NC} Node.js: Not found (required for MCP servers)"
    ((DEGRADED++))
fi

# Check npm
if command -v npm &> /dev/null; then
    NPM_VERSION=$(npm --version)
    echo -e "${GREEN}✓${NC} npm: v$NPM_VERSION"
    ((HEALTHY++))
else
    echo -e "${YELLOW}⚠${NC} npm: Not found (required for MCP servers)"
    ((DEGRADED++))
fi

# Check Python (optional)
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    echo -e "${GREEN}✓${NC} Python: $PYTHON_VERSION"
    ((HEALTHY++))
else
    echo -e "${YELLOW}⚠${NC} Python: Not found (optional, for Python projects)"
    ((DEGRADED++))
fi

# Check Git
if command -v git &> /dev/null; then
    GIT_VERSION=$(git --version)
    echo -e "${GREEN}✓${NC} Git: $GIT_VERSION"
    ((HEALTHY++))
else
    echo -e "${RED}✗${NC} Git: Not found (required for git-workflow skill)"
    ((UNHEALTHY++))
fi

# Check disk space
AVAILABLE_SPACE=$(df -h "$HOME" | awk 'NR==2 {print $4}')
echo -e "${GREEN}✓${NC} Disk space available: $AVAILABLE_SPACE"
((HEALTHY++))

echo ""

# 2. Check Configuration
echo -e "${BLUE}2. Configuration Health${NC}"

if [ -f "$OPENCODE_DIR/opencode.json" ]; then
    # Check if valid JSON
    if command -v python3 &> /dev/null; then
        if python3 -c "import json; json.load(open('$OPENCODE_DIR/opencode.json'))" 2>/dev/null; then
            echo -e "${GREEN}✓${NC} opencode.json: Valid JSON"
            ((HEALTHY++))
        else
            echo -e "${RED}✗${NC} opencode.json: Invalid JSON syntax"
            ((UNHEALTHY++))
        fi
    else
        echo -e "${YELLOW}⚠${NC} opencode.json: Cannot validate (Python not available)"
        ((DEGRADED++))
    fi

    # Check file size
    CONFIG_SIZE=$(stat -f%z "$OPENCODE_DIR/opencode.json" 2>/dev/null || stat -c%s "$OPENCODE_DIR/opencode.json" 2>/dev/null)
    if [ -n "$CONFIG_SIZE" ] && [ "$CONFIG_SIZE" -gt 0 ]; then
        echo -e "${GREEN}✓${NC} opencode.json: Size OK (${CONFIG_SIZE} bytes)"
        ((HEALTHY++))
    else
        echo -e "${RED}✗${NC} opencode.json: Empty or cannot read size"
        ((UNHEALTHY++))
    fi

    # Check last modified
    if command -v stat &> /dev/null; then
        LAST_MODIFIED=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$OPENCODE_DIR/opencode.json" 2>/dev/null || \
                        stat -c "%y" "$OPENCODE_DIR/opencode.json" 2>/dev/null | cut -d'.' -f1)
        echo -e "${GREEN}✓${NC} opencode.json: Last modified $LAST_MODIFIED"
        ((HEALTHY++))
    fi
else
    echo -e "${RED}✗${NC} opencode.json: Not found"
    ((UNHEALTHY++))
fi

echo ""

# 3. Check Agents
echo -e "${BLUE}3. Agent Health${NC}"

CORE_AGENTS=("planner" "builder" "tester" "reviewer")
SPECIALIZED_AGENTS=("security" "migration" "performance" "refactor" "debug")

AGENT_COUNT=0
MISSING_AGENTS=0

for agent in "${CORE_AGENTS[@]}"; do
    if [ -f "$OPENCODE_DIR/agents/core/${agent}.md" ]; then
        echo -e "${GREEN}✓${NC} Core agent: $agent"
        ((AGENT_COUNT++))
        ((HEALTHY++))
    else
        echo -e "${RED}✗${NC} Core agent: $agent (MISSING)"
        ((MISSING_AGENTS++))
        ((UNHEALTHY++))
    fi
done

for agent in "${SPECIALIZED_AGENTS[@]}"; do
    if [ -f "$OPENCODE_DIR/agents/specialized/${agent}.md" ]; then
        echo -e "${GREEN}✓${NC} Specialized agent: $agent"
        ((AGENT_COUNT++))
        ((HEALTHY++))
    else
        echo -e "${YELLOW}⚠${NC} Specialized agent: $agent (optional, not found)"
        ((DEGRADED++))
    fi
done

echo ""

# 4. Check MCP Servers
echo -e "${BLUE}4. MCP Server Health${NC}"

# GitHub MCP
if grep -q '"github"' "$OPENCODE_DIR/opencode.json" 2>/dev/null; then
    if grep -q 'GITHUB_PERSONAL_ACCESS_TOKEN' "$OPENCODE_DIR/opencode.json" 2>/dev/null; then
        # Check if token is set (not just "your_token_here")
        if grep -q '"GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_' "$OPENCODE_DIR/opencode.json" 2>/dev/null; then
            echo -e "${GREEN}✓${NC} GitHub MCP: Configured with token"
            ((HEALTHY++))
        else
            echo -e "${YELLOW}⚠${NC} GitHub MCP: Token placeholder detected (needs real token)"
            ((DEGRADED++))
        fi
    else
        echo -e "${YELLOW}⚠${NC} GitHub MCP: Configured but no token found"
        ((DEGRADED++))
    fi

    # Check if GitHub MCP package is available
    if command -v npx &> /dev/null; then
        if npm list -g @modelcontextprotocol/server-github &> /dev/null || \
           npm list @modelcontextprotocol/server-github &> /dev/null; then
            echo -e "${GREEN}✓${NC} GitHub MCP: Package installed"
            ((HEALTHY++))
        else
            echo -e "${YELLOW}⚠${NC} GitHub MCP: Package not installed globally"
            ((DEGRADED++))
        fi
    fi
else
    echo -e "${YELLOW}⚠${NC} GitHub MCP: Not configured"
    ((DEGRADED++))
fi

# Linear MCP
if grep -q '"linear"' "$OPENCODE_DIR/opencode.json" 2>/dev/null; then
    if grep -q 'LINEAR_API_KEY' "$OPENCODE_DIR/opencode.json" 2>/dev/null; then
        if grep -q '"LINEAR_API_KEY": "lin_api_' "$OPENCODE_DIR/opencode.json" 2>/dev/null; then
            echo -e "${GREEN}✓${NC} Linear MCP: Configured with API key"
            ((HEALTHY++))
        else
            echo -e "${YELLOW}⚠${NC} Linear MCP: API key placeholder detected"
            ((DEGRADED++))
        fi
    else
        echo -e "${YELLOW}⚠${NC} Linear MCP: Configured but no API key found"
        ((DEGRADED++))
    fi
else
    echo -e "${YELLOW}⚠${NC} Linear MCP: Not configured"
    ((DEGRADED++))
fi

# Context7 MCP
if grep -q '"context7"' "$OPENCODE_DIR/opencode.json" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Context7 MCP: Configured"
    ((HEALTHY++))
else
    echo -e "${YELLOW}⚠${NC} Context7 MCP: Not configured"
    ((DEGRADED++))
fi

echo ""

# 5. Check Skills
echo -e "${BLUE}5. Skills Health${NC}"

REQUIRED_SKILLS=("run-tests" "spec-validator" "git-workflow" "ci-status")
OPTIONAL_SKILLS=("code-quality" "dependency-check" "coverage-analyzer" "doc-generator")

for skill in "${REQUIRED_SKILLS[@]}"; do
    if [ -f "$OPENCODE_DIR/skills/${skill}/SKILL.md" ]; then
        echo -e "${GREEN}✓${NC} Required skill: $skill"
        ((HEALTHY++))
    else
        echo -e "${RED}✗${NC} Required skill: $skill (MISSING)"
        ((UNHEALTHY++))
    fi
done

for skill in "${OPTIONAL_SKILLS[@]}"; do
    if [ -f "$OPENCODE_DIR/skills/${skill}/SKILL.md" ]; then
        echo -e "${GREEN}✓${NC} Optional skill: $skill"
        ((HEALTHY++))
    else
        echo -e "${YELLOW}⚠${NC} Optional skill: $skill (not found)"
        ((DEGRADED++))
    fi
done

echo ""

# 6. Check Workflows
echo -e "${BLUE}6. Workflow Health${NC}"

CRITICAL_WORKFLOWS=("feature_implementation" "hotfix_workflow" "incident_response")
IMPORTANT_WORKFLOWS=("security_review" "database_migration" "pr_checklist" "release_checklist")

for workflow in "${CRITICAL_WORKFLOWS[@]}"; do
    if [ -f "$OPENCODE_DIR/workflows/${workflow}.md" ]; then
        echo -e "${GREEN}✓${NC} Critical workflow: $workflow"
        ((HEALTHY++))
    else
        echo -e "${RED}✗${NC} Critical workflow: $workflow (MISSING)"
        ((UNHEALTHY++))
    fi
done

for workflow in "${IMPORTANT_WORKFLOWS[@]}"; do
    if [ -f "$OPENCODE_DIR/workflows/${workflow}.md" ]; then
        echo -e "${GREEN}✓${NC} Important workflow: $workflow"
        ((HEALTHY++))
    else
        echo -e "${YELLOW}⚠${NC} Important workflow: $workflow (not found)"
        ((DEGRADED++))
    fi
done

echo ""

# 7. Check Documentation
echo -e "${BLUE}7. Documentation Health${NC}"

CRITICAL_DOCS=("README.md" "ARCHITECTURE.md" "QUICK_START.md")
IMPORTANT_DOCS=("INDEX.md" "TROUBLESHOOTING.md" "GLOSSARY.md" "config/GUARDRAILS_GUIDE.md")

for doc in "${CRITICAL_DOCS[@]}"; do
    if [ -f "$OPENCODE_DIR/$doc" ]; then
        echo -e "${GREEN}✓${NC} Critical doc: $doc"
        ((HEALTHY++))
    else
        echo -e "${RED}✗${NC} Critical doc: $doc (MISSING)"
        ((UNHEALTHY++))
    fi
done

for doc in "${IMPORTANT_DOCS[@]}"; do
    if [ -f "$OPENCODE_DIR/$doc" ]; then
        echo -e "${GREEN}✓${NC} Important doc: $doc"
        ((HEALTHY++))
    else
        echo -e "${YELLOW}⚠${NC} Important doc: $doc (not found)"
        ((DEGRADED++))
    fi
done

echo ""

# 8. Check Guardrails
echo -e "${BLUE}8. Guardrails Health${NC}"

if [ -f "$OPENCODE_DIR/opencode.json" ]; then
    GUARDRAILS=("guardrails" "cost_controls" "audit" "security")

    for guardrail in "${GUARDRAILS[@]}"; do
        if grep -q "\"$guardrail\"" "$OPENCODE_DIR/opencode.json"; then
            echo -e "${GREEN}✓${NC} $guardrail section configured"
            ((HEALTHY++))
        else
            echo -e "${YELLOW}⚠${NC} $guardrail section not found"
            ((DEGRADED++))
        fi
    done
fi

echo ""

# 9. Check Logs Directory
echo -e "${BLUE}9. Logging Health${NC}"

if [ -d "$OPENCODE_DIR/logs" ]; then
    LOG_COUNT=$(find "$OPENCODE_DIR/logs" -type f -name "*.log" 2>/dev/null | wc -l)
    echo -e "${GREEN}✓${NC} Logs directory exists ($LOG_COUNT log files)"
    ((HEALTHY++))

    # Check if logs are recent
    if [ $LOG_COUNT -gt 0 ]; then
        RECENT_LOGS=$(find "$OPENCODE_DIR/logs" -type f -name "*.log" -mtime -1 2>/dev/null | wc -l)
        if [ $RECENT_LOGS -gt 0 ]; then
            echo -e "${GREEN}✓${NC} Recent activity detected ($RECENT_LOGS logs from last 24h)"
            ((HEALTHY++))
        else
            echo -e "${YELLOW}⚠${NC} No recent log activity (no logs in last 24h)"
            ((DEGRADED++))
        fi
    fi
else
    echo -e "${YELLOW}⚠${NC} Logs directory not found (will be created on first use)"
    ((DEGRADED++))
fi

echo ""

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Health Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${GREEN}Healthy:${NC} $HEALTHY checks passed"
echo -e "${YELLOW}Degraded:${NC} $DEGRADED warnings (optional features)"
echo -e "${RED}Unhealthy:${NC} $UNHEALTHY checks failed"
echo ""

TOTAL=$((HEALTHY + DEGRADED + UNHEALTHY))
if [ $TOTAL -gt 0 ]; then
    HEALTH_PERCENTAGE=$((HEALTHY * 100 / TOTAL))

    if [ $HEALTH_PERCENTAGE -ge 90 ]; then
        echo -e "Overall Health: ${GREEN}$HEALTH_PERCENTAGE%${NC} (Excellent)"
        STATUS="HEALTHY"
    elif [ $HEALTH_PERCENTAGE -ge 70 ]; then
        echo -e "Overall Health: ${YELLOW}$HEALTH_PERCENTAGE%${NC} (Good)"
        STATUS="DEGRADED"
    else
        echo -e "Overall Health: ${RED}$HEALTH_PERCENTAGE%${NC} (Needs Attention)"
        STATUS="UNHEALTHY"
    fi
else
    echo -e "Overall Health: ${RED}0%${NC}"
    STATUS="UNHEALTHY"
fi
echo ""

# System Status
echo "System Status: $STATUS"
echo "Agents Available: $AGENT_COUNT / 9"
echo "Critical Issues: $UNHEALTHY"
echo ""

# Recommendations
if [ $UNHEALTHY -gt 0 ]; then
    echo -e "${YELLOW}Recommendations:${NC}"
    echo "1. Fix all unhealthy checks (marked with ✗)"
    echo "2. Run: bash $OPENCODE_DIR/scripts/validate-setup.sh"
    echo "3. Review: $OPENCODE_DIR/TROUBLESHOOTING.md"
    echo ""
    exit 1
elif [ $DEGRADED -gt 5 ]; then
    echo -e "${YELLOW}Recommendations:${NC}"
    echo "1. Consider enabling degraded features (marked with ⚠)"
    echo "2. Set up MCP servers for full functionality"
    echo "3. Review: $OPENCODE_DIR/mcp/SETUP_GUIDE.md"
    echo ""
    exit 0
else
    echo -e "${GREEN}✓ System is healthy!${NC}"
    echo ""
    echo "All critical components are functioning properly."
    echo "You can start using OpenCode agents."
    echo ""
    exit 0
fi
