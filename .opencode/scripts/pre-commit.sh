#!/bin/bash
# OpenCode Pre-Commit Hook
# Runs quality checks before allowing commit
# Install: bash setup-git-hooks.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}OpenCode Pre-Commit Checks${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Track failures
FAILURES=0

# Get list of staged files
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACMR)

if [ -z "$STAGED_FILES" ]; then
    echo -e "${YELLOW}⚠${NC} No files staged for commit"
    exit 0
fi

echo "Staged files:"
echo "$STAGED_FILES" | sed 's/^/  - /'
echo ""

# 1. Check for sensitive files
echo -e "${BLUE}1. Checking for sensitive files...${NC}"

SENSITIVE_PATTERNS=(
    "*.pem"
    "*.key"
    "*secret*"
    "*password*"
    "*.env"
    ".env.*"
    "*credentials*"
    "*token*"
)

SENSITIVE_FOUND=0
for pattern in "${SENSITIVE_PATTERNS[@]}"; do
    if echo "$STAGED_FILES" | grep -qi "$pattern"; then
        echo -e "${RED}✗${NC} Sensitive file pattern detected: $pattern"
        echo "$STAGED_FILES" | grep -i "$pattern" | sed 's/^/    /'
        ((SENSITIVE_FOUND++))
    fi
done

if [ $SENSITIVE_FOUND -gt 0 ]; then
    echo ""
    echo -e "${RED}WARNING: Attempting to commit sensitive files!${NC}"
    echo "These files may contain secrets and should not be committed."
    echo ""
    echo "To proceed anyway (NOT RECOMMENDED):"
    echo "  git commit --no-verify"
    echo ""
    exit 1
fi

echo -e "${GREEN}✓${NC} No sensitive files detected"
echo ""

# 2. Check file sizes
echo -e "${BLUE}2. Checking file sizes...${NC}"

LARGE_FILE_LIMIT=1048576  # 1MB in bytes
LARGE_FILES_FOUND=0

while IFS= read -r file; do
    if [ -f "$file" ]; then
        SIZE=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo 0)
        if [ "$SIZE" -gt "$LARGE_FILE_LIMIT" ]; then
            SIZE_MB=$(echo "scale=2; $SIZE / 1048576" | bc)
            echo -e "${YELLOW}⚠${NC} Large file: $file (${SIZE_MB}MB)"
            ((LARGE_FILES_FOUND++))
        fi
    fi
done <<< "$STAGED_FILES"

if [ $LARGE_FILES_FOUND -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}Warning: Large files detected${NC}"
    echo "Consider using Git LFS for files >1MB"
    echo ""
else
    echo -e "${GREEN}✓${NC} All files within size limit"
    echo ""
fi

# 3. Check for merge conflict markers
echo -e "${BLUE}3. Checking for merge conflicts...${NC}"

CONFLICT_MARKERS_FOUND=0
while IFS= read -r file; do
    if [ -f "$file" ]; then
        if grep -Hn "^<<<<<<< \|^=======$\|^>>>>>>> " "$file"; then
            echo -e "${RED}✗${NC} Merge conflict markers found in: $file"
            ((CONFLICT_MARKERS_FOUND++))
        fi
    fi
done <<< "$STAGED_FILES"

if [ $CONFLICT_MARKERS_FOUND -gt 0 ]; then
    echo ""
    echo -e "${RED}ERROR: Unresolved merge conflicts!${NC}"
    echo "Resolve conflicts before committing."
    exit 1
fi

echo -e "${GREEN}✓${NC} No merge conflicts detected"
echo ""

# 4. Check for debugging statements
echo -e "${BLUE}4. Checking for debugging statements...${NC}"

DEBUG_PATTERNS=(
    "console.log"
    "console.debug"
    "debugger"
    "print("
    "pdb.set_trace"
    "import pdb"
)

DEBUG_FOUND=0
while IFS= read -r file; do
    if [ -f "$file" ]; then
        # Skip test files
        if [[ $file == *".test."* ]] || [[ $file == *"__tests__"* ]] || [[ $file == *"/tests/"* ]]; then
            continue
        fi

        for pattern in "${DEBUG_PATTERNS[@]}"; do
            if grep -Hn "$pattern" "$file" > /dev/null 2>&1; then
                echo -e "${YELLOW}⚠${NC} Debug statement found in $file:"
                grep -Hn "$pattern" "$file" | sed 's/^/    /'
                ((DEBUG_FOUND++))
            fi
        done
    fi
done <<< "$STAGED_FILES"

if [ $DEBUG_FOUND -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}Warning: Debug statements detected${NC}"
    echo "Consider removing debug code before committing."
    echo ""
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    echo -e "${GREEN}✓${NC} No debug statements found"
    echo ""
fi

# 5. Run linting (if available)
echo -e "${BLUE}5. Running linters...${NC}"

# Check for JavaScript/TypeScript files
JS_FILES=$(echo "$STAGED_FILES" | grep -E '\.(js|jsx|ts|tsx)$' || true)
if [ -n "$JS_FILES" ] && command -v npx &> /dev/null; then
    if [ -f "package.json" ] && grep -q "eslint" "package.json"; then
        echo "Running ESLint..."
        if ! npx eslint $JS_FILES; then
            echo -e "${RED}✗${NC} ESLint failed"
            ((FAILURES++))
        else
            echo -e "${GREEN}✓${NC} ESLint passed"
        fi
    else
        echo -e "${YELLOW}⚠${NC} ESLint not configured (skipping)"
    fi
else
    echo -e "${YELLOW}⚠${NC} No JavaScript/TypeScript files or npm not available"
fi

# Check for Python files
PY_FILES=$(echo "$STAGED_FILES" | grep -E '\.py$' || true)
if [ -n "$PY_FILES" ] && command -v pylint &> /dev/null; then
    echo "Running Pylint..."
    if ! pylint $PY_FILES; then
        echo -e "${RED}✗${NC} Pylint failed"
        ((FAILURES++))
    else
        echo -e "${GREEN}✓${NC} Pylint passed"
    fi
else
    if [ -n "$PY_FILES" ]; then
        echo -e "${YELLOW}⚠${NC} Pylint not installed (skipping)"
    fi
fi

echo ""

# 6. Run formatting check (if available)
echo -e "${BLUE}6. Checking code formatting...${NC}"

if [ -n "$JS_FILES" ] && command -v npx &> /dev/null; then
    if [ -f "package.json" ] && grep -q "prettier" "package.json"; then
        echo "Running Prettier check..."
        if ! npx prettier --check $JS_FILES 2>/dev/null; then
            echo -e "${YELLOW}⚠${NC} Prettier formatting issues detected"
            echo "Run: npx prettier --write <files>"
            echo ""
            read -p "Auto-fix formatting? (y/N): " -n 1 -r
            echo ""
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                npx prettier --write $JS_FILES
                git add $JS_FILES
                echo -e "${GREEN}✓${NC} Formatting fixed and staged"
            fi
        else
            echo -e "${GREEN}✓${NC} Prettier check passed"
        fi
    fi
fi

if [ -n "$PY_FILES" ] && command -v black &> /dev/null; then
    echo "Running Black check..."
    if ! black --check $PY_FILES 2>/dev/null; then
        echo -e "${YELLOW}⚠${NC} Black formatting issues detected"
        echo ""
        read -p "Auto-fix formatting? (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            black $PY_FILES
            git add $PY_FILES
            echo -e "${GREEN}✓${NC} Formatting fixed and staged"
        fi
    else
        echo -e "${GREEN}✓${NC} Black check passed"
    fi
fi

echo ""

# 7. Run tests on changed files (optional, can be slow)
# Uncomment if you want tests to run on every commit
# echo -e "${BLUE}7. Running tests...${NC}"
# if command -v npm &> /dev/null && [ -f "package.json" ]; then
#     if ! npm test; then
#         echo -e "${RED}✗${NC} Tests failed"
#         ((FAILURES++))
#     else
#         echo -e "${GREEN}✓${NC} Tests passed"
#     fi
# fi
# echo ""

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Pre-Commit Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

if [ $FAILURES -gt 0 ]; then
    echo -e "${RED}✗${NC} $FAILURES check(s) failed"
    echo ""
    echo "Fix the issues above before committing."
    echo ""
    echo "To bypass checks (NOT RECOMMENDED):"
    echo "  git commit --no-verify"
    echo ""
    exit 1
else
    echo -e "${GREEN}✓${NC} All checks passed!"
    echo ""
    echo "Proceeding with commit..."
    echo ""
    exit 0
fi
