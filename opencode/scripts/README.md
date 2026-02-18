# OpenCode Scripts

**Automation and validation scripts for OpenCode agent architecture.**

---

## Overview

This directory contains helper scripts for:
- **Validation**: Verify setup completeness and health
- **Monitoring**: Track costs and system status
- **Git Integration**: Quality checks before commits
- **Maintenance**: Setup and configuration helpers

---

## Available Scripts

### 1. validate-mcp.sh

**Purpose:** Validates MCP (Model Context Protocol) server configuration.

**Usage:**
```bash
bash ~/.config/opencode/scripts/validate-mcp.sh
```

**What It Checks:**
- Node.js and npm availability
- GitHub MCP configuration and token
- Linear MCP configuration and API key
- Context7 MCP setup
- Package installations

**Exit Codes:**
- `0`: All MCP servers configured correctly
- `1`: One or more MCP servers have issues

**When to Run:**
- After initial setup
- After changing MCP configuration
- When MCP servers aren't working
- As part of troubleshooting

**See Also:** `../mcp/SETUP_GUIDE.md`

---

### 2. validate-setup.sh

**Purpose:** Complete validation of OpenCode installation.

**Usage:**
```bash
bash ~/.config/opencode/scripts/validate-setup.sh
```

**What It Checks:**
- Directory structure (agents, workflows, skills, etc.)
- Configuration file (opencode.json) syntax and completeness
- All 9 agents (core + specialized)
- All 7 workflows
- All skills (required + optional)
- Spec templates
- Documentation files
- Guardrails configuration
- MCP servers
- File permissions

**Output:**
```
========================================
Validation Summary
========================================

Passed: 87
Failed: 0
Warnings: 5

Completion: 94%

✓ All critical checks passed!
```

**Exit Codes:**
- `0`: Setup is complete and ready
- `1`: Critical components missing or broken

**When to Run:**
- After initial installation
- After major configuration changes
- Before starting work with OpenCode
- As part of CI/CD validation

---

### 3. health-check.sh

**Purpose:** Real-time health monitoring of OpenCode system.

**Usage:**
```bash
bash ~/.config/opencode/scripts/health-check.sh
```

**What It Checks:**
- **System Requirements**: Node.js, npm, Python, Git, disk space
- **Configuration Health**: Valid JSON, file size, last modified
- **Agent Health**: All 9 agents availability
- **MCP Server Health**: Configuration and authentication
- **Skills Health**: Required and optional skills
- **Workflow Health**: Critical and important workflows
- **Documentation Health**: All documentation files
- **Guardrails Health**: All guardrail sections
- **Logging Health**: Log directory and recent activity

**Output:**
```
========================================
Health Summary
========================================

Healthy: 65 checks passed
Degraded: 8 warnings (optional features)
Unhealthy: 0 checks failed

Overall Health: 89% (Good)

System Status: HEALTHY
Agents Available: 9 / 9
```

**Health Levels:**
- **90-100%**: Excellent (system fully operational)
- **70-89%**: Good (system operational, some optional features missing)
- **Below 70%**: Needs Attention (critical issues present)

**Exit Codes:**
- `0`: System is healthy
- `1`: System has critical issues

**When to Run:**
- Daily monitoring
- Before major operations
- After system updates
- When experiencing issues

---

### 4. cost-analyzer.sh

**Purpose:** Analyze API spending and provide cost insights.

**Usage:**
```bash
# Analyze last 7 days (default)
bash ~/.config/opencode/scripts/cost-analyzer.sh

# Analyze last 30 days
bash ~/.config/opencode/scripts/cost-analyzer.sh --period 30

# Analyze specific agent
bash ~/.config/opencode/scripts/cost-analyzer.sh --agent builder
```

**Options:**
- `--period DAYS`: Analyze last N days (default: 7)
- `--agent NAME`: Analyze specific agent only
- `--help`: Show help message

**What It Shows:**
1. **Overall Cost Summary**
   - Total spend
   - Total API calls
   - Average per call
   - Daily average
   - Budget usage percentage

2. **Cost by Agent**
   - Each agent's total cost
   - Number of calls
   - Average cost per call
   - Percentage of total

3. **Cost by Model**
   - Haiku/Sonnet/Opus breakdown
   - Cost per model
   - Call distribution

4. **Optimization Recommendations**
   - Expensive agents identified
   - Model strategy suggestions
   - Budget warnings

5. **Cost Projections**
   - Monthly projection
   - Yearly projection

6. **Savings Opportunities**
   - Potential savings from optimization
   - Recommended model distribution

**Example Output:**
```
========================================
OpenCode Cost Analysis
========================================

Period: Last 7 days

1. Overall Cost Summary

Total Spend:       $201.92
Total API Calls:   741
Average per Call:  $0.2726
Daily Average:     $28.85

Daily Budget: $100
Budget Usage: 28.9% (Healthy)

2. Cost Breakdown by Agent

Agent           Calls       Cost    Avg/Call  % Total
--------------- ---------- ---------- ------------ --------
builder         98         $67.82     $0.6920     33.6%
security        12         $34.22     $2.8517     16.9%
planner         145        $23.45     $0.1617     11.6%
```

**Exit Codes:**
- `0`: Cost analysis complete

**When to Run:**
- Weekly cost review
- Monthly budget planning
- When approaching budget limits
- Before scaling up usage

**Requirements:**
- Audit logging must be enabled
- `opencode.json` must have `audit.enabled: true`

**See Also:** `../config/guardrails.md` (Cost Controls section)

---

### 5. pre-commit.sh

**Purpose:** Git pre-commit hook for code quality checks.

**Installation:**
```bash
# From your Git repository
bash ~/.config/opencode/scripts/setup-git-hooks.sh
```

**Manual Usage:**
```bash
# Test without committing
bash ~/.config/opencode/scripts/pre-commit.sh
```

**What It Checks:**
1. **Sensitive Files**
   - Detects passwords, keys, secrets, .env files
   - Blocks commit if found
   - Prevents credential leaks

2. **File Sizes**
   - Warns on files >1MB
   - Suggests Git LFS for large files

3. **Merge Conflicts**
   - Detects `<<<<<<<`, `=======`, `>>>>>>>` markers
   - Blocks commit until resolved

4. **Debug Statements**
   - Finds `console.log`, `debugger`, `print()`, etc.
   - Warns but allows commit with confirmation

5. **Linting**
   - Runs ESLint for JavaScript/TypeScript
   - Runs Pylint for Python
   - Blocks commit on errors

6. **Formatting**
   - Checks Prettier for JavaScript/TypeScript
   - Checks Black for Python
   - Offers auto-fix option

**Example Output:**
```
========================================
OpenCode Pre-Commit Checks
========================================

Staged files:
  - src/auth/login.ts
  - src/api/users.ts

1. Checking for sensitive files...
✓ No sensitive files detected

2. Checking file sizes...
✓ All files within size limit

3. Checking for merge conflicts...
✓ No merge conflicts detected

4. Checking for debugging statements...
⚠ Debug statement found in src/api/users.ts:
    23:    console.log('User data:', user);

Warning: Debug statements detected
Consider removing debug code before committing.

Continue anyway? (y/N): n

5. Running linters...
Running ESLint...
✓ ESLint passed

========================================
Pre-Commit Summary
========================================

✗ 1 check(s) failed

Fix the issues above before committing.
```

**Bypass Hook (Not Recommended):**
```bash
git commit --no-verify
```

**Exit Codes:**
- `0`: All checks passed, commit allowed
- `1`: Checks failed, commit blocked

**When to Use:**
- Automatically runs on every `git commit`
- Can be tested manually before committing

**See Also:** `setup-git-hooks.sh`

---

### 6. setup-git-hooks.sh

**Purpose:** Install pre-commit hook into current Git repository.

**Usage:**
```bash
# From your Git repository root
bash ~/.config/opencode/scripts/setup-git-hooks.sh
```

**What It Does:**
1. Checks if you're in a Git repository
2. Creates `.git/hooks/` directory if needed
3. Backs up existing pre-commit hook (if any)
4. Installs `pre-commit.sh` as symlink
5. Makes hook executable
6. Verifies installation
7. Tests hook

**Example Output:**
```
========================================
OpenCode Git Hooks Setup
========================================

Git directory: .git
Hooks directory: .git/hooks

Installing pre-commit hook...
✓ Pre-commit hook installed successfully!

Verifying installation...
✓ Hook is a symlink (will auto-update with OpenCode)
✓ Hook is executable

Testing hook...
✓ Hook is functional

========================================
Setup Complete!
========================================

✓ Pre-commit hook installed and ready

The hook will run automatically on every commit.

Test it by:
  1. Stage some files: git add <file>
  2. Commit: git commit -m "test"
  3. The hook will run checks before allowing commit
```

**Benefits of Symlink:**
- Hook auto-updates when OpenCode updates
- No need to reinstall after changes
- Consistent across repositories

**Exit Codes:**
- `0`: Hook installed successfully
- `1`: Installation failed

**When to Run:**
- Once per Git repository
- After cloning a new repository
- After removing/modifying hooks

**Additional Hooks Suggested:**

**Pre-push hook:**
```bash
# .git/hooks/pre-push
#!/bin/bash
npm test || { echo "Tests failed! Push aborted."; exit 1; }
```

**Commit-msg hook (conventional commits):**
```bash
# .git/hooks/commit-msg
#!/bin/bash
grep -E "^(feat|fix|docs|style|refactor|test|chore):" "$1" ||
  { echo "Commit message must start with type (feat|fix|...)"; exit 1; }
```

---

## Usage Patterns

### Daily Development

```bash
# Morning: Check system health
bash ~/.config/opencode/scripts/health-check.sh

# Work with OpenCode agents
@planner, @builder, @tester...

# Pre-commit checks run automatically
git commit -m "feat: add new feature"
```

### Weekly Maintenance

```bash
# Monday: Review costs
bash ~/.config/opencode/scripts/cost-analyzer.sh --period 7

# Validate setup
bash ~/.config/opencode/scripts/validate-setup.sh

# Check MCP servers
bash ~/.config/opencode/scripts/validate-mcp.sh
```

### Troubleshooting

```bash
# 1. Check overall health
bash ~/.config/opencode/scripts/health-check.sh

# 2. Validate complete setup
bash ~/.config/opencode/scripts/validate-setup.sh

# 3. Check specific MCP servers
bash ~/.config/opencode/scripts/validate-mcp.sh

# 4. Review logs and costs
bash ~/.config/opencode/scripts/cost-analyzer.sh
```

### New Repository Setup

```bash
# Clone repository
git clone <repository>
cd <repository>

# Install pre-commit hook
bash ~/.config/opencode/scripts/setup-git-hooks.sh

# Verify setup
bash ~/.config/opencode/scripts/validate-setup.sh
```

---

## Script Dependencies

### System Requirements

**All Scripts:**
- Bash 4.0+
- Unix-like environment (Linux, macOS, WSL on Windows)

**validate-mcp.sh:**
- Node.js (for MCP servers)
- npm (for package installation)

**validate-setup.sh:**
- Python 3 (optional, for JSON validation)

**health-check.sh:**
- Python 3 (optional, for JSON validation)
- Standard Unix tools (stat, df, grep)

**cost-analyzer.sh:**
- bc (calculator)
- Audit logs enabled in opencode.json

**pre-commit.sh:**
- Git
- ESLint/Prettier (optional, for JavaScript linting)
- Pylint/Black (optional, for Python linting)

**setup-git-hooks.sh:**
- Git

### Installation Check

```bash
# Check Bash version
bash --version

# Check Node.js
node --version

# Check Python
python3 --version

# Check bc (calculator)
bc --version

# Check Git
git --version
```

---

## Permissions

All scripts should be executable:

```bash
# Make all scripts executable
chmod +x ~/.config/opencode/scripts/*.sh

# Verify
ls -la ~/.config/opencode/scripts/
```

If permissions are incorrect, `validate-setup.sh` will warn you.

---

## Customization

### Modify Scripts

All scripts are located in:
```
~/.config/opencode/scripts/
```

You can modify them to suit your needs:

1. **cost-analyzer.sh**: Adjust budget thresholds, add custom reports
2. **pre-commit.sh**: Add/remove checks, change file patterns
3. **health-check.sh**: Add custom health checks, change thresholds
4. **validate-setup.sh**: Add custom validation rules

### Configuration

Many script behaviors are controlled by `opencode.json`:

```json
{
  "guardrails": {
    "max_tool_calls_per_session": 100,
    "max_files_per_edit": 5
  },
  "cost_controls": {
    "enabled": true,
    "daily_budget_usd": 100,
    "per_session_limit_usd": 10
  },
  "audit": {
    "enabled": true,
    "log_directory": "~/.config/opencode/logs"
  }
}
```

See: `../config/guardrails.md` for all settings.

---

## CI/CD Integration

### GitHub Actions

```yaml
name: OpenCode Validation

on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Validate OpenCode Setup
        run: bash ~/.config/opencode/scripts/validate-setup.sh

      - name: Health Check
        run: bash ~/.config/opencode/scripts/health-check.sh

      - name: Cost Analysis
        run: bash ~/.config/opencode/scripts/cost-analyzer.sh --period 7
```

### GitLab CI

```yaml
opencode-validation:
  script:
    - bash ~/.config/opencode/scripts/validate-setup.sh
    - bash ~/.config/opencode/scripts/health-check.sh
    - bash ~/.config/opencode/scripts/cost-analyzer.sh
```

---

## Troubleshooting

### Script Not Found

**Problem:** `bash: script.sh: No such file or directory`

**Solution:**
```bash
# Check if scripts exist
ls -la ~/.config/opencode/scripts/

# Re-run setup if missing
```

### Permission Denied

**Problem:** `bash: permission denied: script.sh`

**Solution:**
```bash
# Make executable
chmod +x ~/.config/opencode/scripts/*.sh
```

### Invalid JSON Error

**Problem:** `validate-setup.sh: Invalid JSON syntax`

**Solution:**
```bash
# Validate JSON manually
python3 -m json.tool ~/.config/opencode/opencode.json

# Fix syntax errors
# Common issues: trailing commas, missing quotes
```

### MCP Validation Fails

**Problem:** `validate-mcp.sh: Authentication failed`

**Solution:**
1. Check token is correct in `opencode.json`
2. Verify token has correct scopes
3. See: `../mcp/SETUP_GUIDE.md`

### Cost Analyzer No Data

**Problem:** `cost-analyzer.sh: No audit log found`

**Solution:**
1. Enable audit logging in `opencode.json`:
   ```json
   {
     "audit": {
       "enabled": true,
       "log_all_tool_calls": true
     }
   }
   ```
2. Use OpenCode agents to generate data
3. Re-run cost analyzer

---

## Getting Help

**For script-specific issues:**
- Run script with `--help` flag (if supported)
- Check script comments at top of file

**For general issues:**
- See: `../TROUBLESHOOTING.md`
- See: `../INDEX.md`

**For MCP issues:**
- See: `../mcp/SETUP_GUIDE.md`

**For cost issues:**
- See: `../config/guardrails.md`

---

## Version History

- **1.0.0** (2024-02-14): Initial scripts
  - validate-mcp.sh
  - validate-setup.sh
  - health-check.sh
  - cost-analyzer.sh
  - pre-commit.sh
  - setup-git-hooks.sh

---

*For complete OpenCode documentation, see [main README](../README.md)*
