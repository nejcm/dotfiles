#!/bin/bash
# OpenCode Setup Validation Script
# Validates complete OpenCode agent architecture setup
# Usage: bash validate-setup.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0
WARNINGS=0

# Base directory
OPENCODE_DIR="$HOME/.config/opencode"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}OpenCode Setup Validation${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Function to check if file exists
check_file() {
    local file=$1
    local description=$2
    local required=$3

    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $description"
        ((PASSED++))
        return 0
    else
        if [ "$required" = "true" ]; then
            echo -e "${RED}✗${NC} $description (MISSING)"
            ((FAILED++))
        else
            echo -e "${YELLOW}⚠${NC} $description (optional, not found)"
            ((WARNINGS++))
        fi
        return 1
    fi
}

# Function to check directory
check_directory() {
    local dir=$1
    local description=$2

    if [ -d "$dir" ]; then
        echo -e "${GREEN}✓${NC} $description"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} $description (MISSING)"
        ((FAILED++))
        return 1
    fi
}

# Function to validate JSON
validate_json() {
    local file=$1
    local description=$2

    if command -v python3 &> /dev/null; then
        if python3 -c "import json; json.load(open('$file'))" 2>/dev/null; then
            echo -e "${GREEN}✓${NC} $description"
            ((PASSED++))
            return 0
        else
            echo -e "${RED}✗${NC} $description (INVALID JSON)"
            ((FAILED++))
            return 1
        fi
    else
        echo -e "${YELLOW}⚠${NC} $description (cannot validate, python3 not found)"
        ((WARNINGS++))
        return 1
    fi
}

# 1. Check Base Directory Structure
echo -e "${BLUE}1. Checking Base Directory Structure${NC}"
check_directory "$OPENCODE_DIR" "OpenCode config directory"
check_directory "$OPENCODE_DIR/agents" "Agents directory"
check_directory "$OPENCODE_DIR/workflows" "Workflows directory"
check_directory "$OPENCODE_DIR/skills" "Skills directory"
check_directory "$OPENCODE_DIR/specs" "Specs directory"
check_directory "$OPENCODE_DIR/scripts" "Scripts directory"
check_directory "$OPENCODE_DIR/mcp" "MCP directory"
check_directory "$OPENCODE_DIR/config" "Config directory"
echo ""

# 2. Check Main Configuration
echo -e "${BLUE}2. Checking Main Configuration${NC}"
check_file "$OPENCODE_DIR/opencode.json" "Main config file (opencode.json)" "true"
if [ -f "$OPENCODE_DIR/opencode.json" ]; then
    validate_json "$OPENCODE_DIR/opencode.json" "opencode.json is valid JSON"
fi
echo ""

# 3. Check Core Agents
echo -e "${BLUE}3. Checking Core Agents${NC}"
check_directory "$OPENCODE_DIR/agents/core" "Core agents directory"
check_file "$OPENCODE_DIR/agents/core/planner.md" "Planner agent" "true"
check_file "$OPENCODE_DIR/agents/core/builder.md" "Builder agent" "true"
check_file "$OPENCODE_DIR/agents/core/tester.md" "Tester agent" "true"
check_file "$OPENCODE_DIR/agents/core/reviewer.md" "Reviewer agent" "true"
echo ""

# 4. Check Specialized Agents
echo -e "${BLUE}4. Checking Specialized Agents${NC}"
check_directory "$OPENCODE_DIR/agents/specialized" "Specialized agents directory"
check_file "$OPENCODE_DIR/agents/specialized/security.md" "Security agent" "true"
check_file "$OPENCODE_DIR/agents/specialized/migration.md" "Migration agent" "true"
check_file "$OPENCODE_DIR/agents/specialized/performance.md" "Performance agent" "true"
check_file "$OPENCODE_DIR/agents/specialized/refactor.md" "Refactor agent" "true"
check_file "$OPENCODE_DIR/agents/specialized/debug.md" "Debug agent" "true"
echo ""

# 5. Check Workflows
echo -e "${BLUE}5. Checking Workflows${NC}"
check_file "$OPENCODE_DIR/workflows/feature_implementation.md" "Feature implementation workflow" "true"
check_file "$OPENCODE_DIR/workflows/hotfix_workflow.md" "Hotfix workflow" "true"
check_file "$OPENCODE_DIR/workflows/incident_response.md" "Incident response workflow" "true"
check_file "$OPENCODE_DIR/workflows/security_review.md" "Security review workflow" "true"
check_file "$OPENCODE_DIR/workflows/database_migration.md" "Database migration workflow" "true"
check_file "$OPENCODE_DIR/workflows/pr_checklist.md" "PR checklist workflow" "true"
check_file "$OPENCODE_DIR/workflows/release_checklist.md" "Release checklist workflow" "true"
echo ""

# 6. Check Skills
echo -e "${BLUE}6. Checking Skills${NC}"
check_file "$OPENCODE_DIR/skills/run-tests/SKILL.md" "run-tests skill" "true"
check_file "$OPENCODE_DIR/skills/spec-validator/SKILL.md" "spec-validator skill" "true"
check_file "$OPENCODE_DIR/skills/git-workflow/SKILL.md" "git-workflow skill" "true"
check_file "$OPENCODE_DIR/skills/ci-status/SKILL.md" "ci-status skill" "true"
check_file "$OPENCODE_DIR/skills/code-quality/SKILL.md" "code-quality skill" "false"
check_file "$OPENCODE_DIR/skills/dependency-check/SKILL.md" "dependency-check skill" "false"
check_file "$OPENCODE_DIR/skills/coverage-analyzer/SKILL.md" "coverage-analyzer skill" "false"
check_file "$OPENCODE_DIR/skills/doc-generator/SKILL.md" "doc-generator skill" "false"
echo ""

# 7. Check Spec Templates
echo -e "${BLUE}7. Checking Spec Templates${NC}"
check_file "$OPENCODE_DIR/specs/template.md" "Spec template" "true"
check_file "$OPENCODE_DIR/specs/example-user-profiles.md" "Example spec" "false"
echo ""

# 8. Check MCP Configuration
echo -e "${BLUE}8. Checking MCP Configuration${NC}"
check_file "$OPENCODE_DIR/mcp/README.md" "MCP README" "true"
check_file "$OPENCODE_DIR/mcp/SETUP_GUIDE.md" "MCP setup guide" "true"
echo ""

# 9. Check Scripts
echo -e "${BLUE}9. Checking Scripts${NC}"
check_file "$OPENCODE_DIR/scripts/validate-mcp.sh" "MCP validation script" "true"
check_file "$OPENCODE_DIR/scripts/validate-setup.sh" "Setup validation script (this file)" "true"
check_file "$OPENCODE_DIR/scripts/health-check.sh" "Health check script" "false"
check_file "$OPENCODE_DIR/scripts/cost-analyzer.sh" "Cost analyzer script" "false"
check_file "$OPENCODE_DIR/scripts/pre-commit.sh" "Pre-commit hook script" "false"
check_file "$OPENCODE_DIR/scripts/setup-git-hooks.sh" "Git hooks setup script" "false"
echo ""

# 10. Check Documentation
echo -e "${BLUE}10. Checking Documentation${NC}"
check_file "$OPENCODE_DIR/README.md" "Main README" "true"
check_file "$OPENCODE_DIR/ARCHITECTURE.md" "Architecture documentation" "true"
check_file "$OPENCODE_DIR/QUICK_START.md" "Quick start guide" "true"
check_file "$OPENCODE_DIR/INDEX.md" "Navigation index" "true"
check_file "$OPENCODE_DIR/TROUBLESHOOTING.md" "Troubleshooting guide" "true"
check_file "$OPENCODE_DIR/GLOSSARY.md" "Glossary" "true"
check_file "$OPENCODE_DIR/SETUP_COMPLETE.md" "Setup completion guide" "true"
check_file "$OPENCODE_DIR/IMPLEMENTATION_STATUS.md" "Implementation status" "false"
check_file "$OPENCODE_DIR/FINAL_STATUS.md" "Final status report" "false"
check_file "$OPENCODE_DIR/config/GUARDRAILS_GUIDE.md" "Guardrails guide" "true"
echo ""

# 11. Check Guardrails Configuration
echo -e "${BLUE}11. Checking Guardrails in opencode.json${NC}"
if [ -f "$OPENCODE_DIR/opencode.json" ]; then
    if grep -q '"guardrails"' "$OPENCODE_DIR/opencode.json"; then
        echo -e "${GREEN}✓${NC} Guardrails section present"
        ((PASSED++))
    else
        echo -e "${RED}✗${NC} Guardrails section missing"
        ((FAILED++))
    fi

    if grep -q '"cost_controls"' "$OPENCODE_DIR/opencode.json"; then
        echo -e "${GREEN}✓${NC} Cost controls section present"
        ((PASSED++))
    else
        echo -e "${RED}✗${NC} Cost controls section missing"
        ((FAILED++))
    fi

    if grep -q '"audit"' "$OPENCODE_DIR/opencode.json"; then
        echo -e "${GREEN}✓${NC} Audit logging section present"
        ((PASSED++))
    else
        echo -e "${RED}✗${NC} Audit logging section missing"
        ((FAILED++))
    fi

    if grep -q '"deployment"' "$OPENCODE_DIR/opencode.json"; then
        echo -e "${GREEN}✓${NC} Deployment protections section present"
        ((PASSED++))
    else
        echo -e "${YELLOW}⚠${NC} Deployment protections section missing (optional)"
        ((WARNINGS++))
    fi

    if grep -q '"rate_limits"' "$OPENCODE_DIR/opencode.json"; then
        echo -e "${GREEN}✓${NC} Rate limits section present"
        ((PASSED++))
    else
        echo -e "${YELLOW}⚠${NC} Rate limits section missing (optional)"
        ((WARNINGS++))
    fi

    if grep -q '"security"' "$OPENCODE_DIR/opencode.json"; then
        echo -e "${GREEN}✓${NC} Security policies section present"
        ((PASSED++))
    else
        echo -e "${RED}✗${NC} Security policies section missing"
        ((FAILED++))
    fi
else
    echo -e "${RED}✗${NC} Cannot check guardrails (opencode.json missing)"
    ((FAILED+=6))
fi
echo ""

# 12. Check MCP Servers
echo -e "${BLUE}12. Checking MCP Server Configuration${NC}"
if [ -f "$OPENCODE_DIR/opencode.json" ]; then
    if grep -q '"github"' "$OPENCODE_DIR/opencode.json"; then
        echo -e "${GREEN}✓${NC} GitHub MCP configured"
        ((PASSED++))
    else
        echo -e "${YELLOW}⚠${NC} GitHub MCP not configured (optional)"
        ((WARNINGS++))
    fi

    if grep -q '"linear"' "$OPENCODE_DIR/opencode.json"; then
        echo -e "${GREEN}✓${NC} Linear MCP configured"
        ((PASSED++))
    else
        echo -e "${YELLOW}⚠${NC} Linear MCP not configured (optional)"
        ((WARNINGS++))
    fi

    if grep -q '"context7"' "$OPENCODE_DIR/opencode.json"; then
        echo -e "${GREEN}✓${NC} Context7 MCP configured"
        ((PASSED++))
    else
        echo -e "${YELLOW}⚠${NC} Context7 MCP not configured (optional)"
        ((WARNINGS++))
    fi
fi
echo ""

# 13. Check Agent Definitions in Config
echo -e "${BLUE}13. Checking Agent Definitions in opencode.json${NC}"
if [ -f "$OPENCODE_DIR/opencode.json" ]; then
    AGENTS=("planner" "builder" "tester" "reviewer" "security" "migration" "performance" "refactor" "debug")

    for agent in "${AGENTS[@]}"; do
        if grep -q "\"$agent\"" "$OPENCODE_DIR/opencode.json"; then
            echo -e "${GREEN}✓${NC} $agent agent defined in config"
            ((PASSED++))
        else
            echo -e "${RED}✗${NC} $agent agent missing from config"
            ((FAILED++))
        fi
    done
else
    echo -e "${RED}✗${NC} Cannot check agents (opencode.json missing)"
    ((FAILED+=9))
fi
echo ""

# 14. Check Permissions
echo -e "${BLUE}14. Checking File Permissions${NC}"
if [ -r "$OPENCODE_DIR/opencode.json" ]; then
    echo -e "${GREEN}✓${NC} opencode.json is readable"
    ((PASSED++))
else
    echo -e "${RED}✗${NC} opencode.json is not readable"
    ((FAILED++))
fi

if [ -x "$OPENCODE_DIR/scripts/validate-mcp.sh" ]; then
    echo -e "${GREEN}✓${NC} validate-mcp.sh is executable"
    ((PASSED++))
else
    echo -e "${YELLOW}⚠${NC} validate-mcp.sh is not executable (run: chmod +x)"
    ((WARNINGS++))
fi

if [ -x "$OPENCODE_DIR/scripts/validate-setup.sh" ]; then
    echo -e "${GREEN}✓${NC} validate-setup.sh is executable"
    ((PASSED++))
else
    echo -e "${YELLOW}⚠${NC} validate-setup.sh is not executable (run: chmod +x)"
    ((WARNINGS++))
fi
echo ""

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Validation Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${GREEN}Passed:${NC} $PASSED"
echo -e "${RED}Failed:${NC} $FAILED"
echo -e "${YELLOW}Warnings:${NC} $WARNINGS"
echo ""

TOTAL=$((PASSED + FAILED))
if [ $TOTAL -gt 0 ]; then
    PERCENTAGE=$((PASSED * 100 / TOTAL))
    echo -e "Completion: ${GREEN}$PERCENTAGE%${NC}"
else
    echo -e "Completion: ${RED}0%${NC}"
fi
echo ""

# Recommendations
if [ $FAILED -gt 0 ]; then
    echo -e "${YELLOW}Recommendations:${NC}"
    echo "1. Fix all failed checks (marked with ✗)"
    echo "2. Review warnings (marked with ⚠)"
    echo "3. Re-run this script to verify fixes"
    echo ""
    echo "For help, see:"
    echo "  - $OPENCODE_DIR/TROUBLESHOOTING.md"
    echo "  - $OPENCODE_DIR/SETUP_COMPLETE.md"
    echo ""
    exit 1
else
    echo -e "${GREEN}✓ All critical checks passed!${NC}"
    echo ""
    if [ $WARNINGS -gt 0 ]; then
        echo -e "${YELLOW}Note: $WARNINGS optional items not found.${NC}"
        echo "These are not required but may enhance functionality."
        echo ""
    fi
    echo "Your OpenCode setup is ready to use!"
    echo ""
    echo "Next steps:"
    echo "  - Run MCP validation: bash $OPENCODE_DIR/scripts/validate-mcp.sh"
    echo "  - Review documentation: $OPENCODE_DIR/INDEX.md"
    echo "  - Start using agents: @planner, @builder, @tester, etc."
    echo ""
    exit 0
fi
