# OpenCode Integration Guide

**Guide for integrating OpenCode with external services and tools.**

---

## Table of Contents

1. [MCP (Model Context Protocol)](#mcp-model-context-protocol)
2. [Version Control (Git/GitHub)](#version-control-gitgithub)
3. [Project Management (Linear/Jira)](#project-management-linearjira)
4. [CI/CD Pipelines](#cicd-pipelines)
5. [Communication (Slack/Teams)](#communication-slackteams)
6. [Monitoring & Observability](#monitoring--observability)
7. [Database Integrations](#database-integrations)
8. [IDE Integrations](#ide-integrations)

---

## MCP (Model Context Protocol)

**Model Context Protocol** enables agents to interact with external services.

### Configured MCP Servers

#### 1. GitHub MCP

**Purpose:** Read/write GitHub repositories, issues, PRs.

**Setup:**
```bash
# See full guide
cat ~/.config/opencode/mcp/SETUP_GUIDE.md
```

**Required:**
- GitHub Personal Access Token
- Scopes: `repo`, `read:org`, `workflow`

**Configuration:**
```json
{
  "mcp": {
    "github": {
      "enabled": true,
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-github"
      ],
      "environment": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_xxxxx"
      }
    }
  }
}
```

**Agent Usage:**
```
@planner Fetch GitHub issues labeled "bug" and create specs

@builder Create PR for feature/user-auth branch

@reviewer Get PR #123 comments and address feedback
```

**Operations:**
- List repositories
- Create/read/update issues
- Create/read pull requests
- List commits
- Read file contents
- Update issue status

---

#### 2. Linear MCP

**Purpose:** Project management integration.

**Setup:**
- Get API key: https://linear.app/settings/api
- Add to `opencode.json`

**Configuration:**
```json
{
  "mcp": {
    "linear": {
      "enabled": true,
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-linear"
      ],
      "environment": {
        "LINEAR_API_KEY": "lin_api_xxxxx"
      }
    }
  }
}
```

**Agent Usage:**
```
@planner Get all Linear issues assigned to me

@builder Mark Linear issue ENG-123 as "In Progress"

@tester Update Linear issue with test results
```

**Operations:**
- List issues
- Create/update issues
- Assign team members
- Update status
- Add comments
- Link to PRs

---

#### 3. Context7 MCP

**Purpose:** Semantic code search using embeddings.

**Setup:** No authentication required!

**Configuration:**
```json
{
  "mcp": {
    "context7": {
      "enabled": true,
      "command": "npx",
      "args": [
        "-y",
        "@upstash/context7-mcp"
      ]
    }
  }
}
```

**Agent Usage:**
```
@planner Find similar authentication code in codebase

@builder Search for API endpoint patterns

@debug Find code that handles payment processing
```

**Operations:**
- Semantic code search
- Find similar code
- Get code context
- Discover patterns

---

### Adding New MCP Servers

#### Slack MCP (Example)

**1. Install Package:**
```bash
npm install -g @modelcontextprotocol/server-slack
```

**2. Get Slack Token:**
- Go to https://api.slack.com/apps
- Create new app
- Add OAuth scopes: `channels:read`, `chat:write`, `users:read`
- Install app to workspace
- Copy Bot User OAuth Token

**3. Add to opencode.json:**
```json
{
  "mcp": {
    "slack": {
      "enabled": true,
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-slack"],
      "environment": {
        "SLACK_BOT_TOKEN": "xoxb-xxxxx",
        "SLACK_TEAM_ID": "T0xxxxx"
      }
    }
  }
}
```

**4. Use in Agents:**
```
@planner Notify #engineering channel about new feature spec

@builder Post deployment update to #releases channel
```

---

## Version Control (Git/GitHub)

### Git Workflow Skill

**Purpose:** Automated Git operations.

**Location:** `skills/git-workflow/SKILL.md`

**Operations:**
- Create branches
- Commit changes
- Create pull requests
- Check status
- View diffs

**Agent Usage:**
```
@builder Use git-workflow to create branch feature/user-auth

@builder Commit changes with message "feat: add OAuth login"

@builder Create PR for current branch
```

---

### GitHub Actions Integration

**Purpose:** Run OpenCode validations in CI/CD.

**Setup:**

**1. Create Workflow** `.github/workflows/opencode.yml`:
```yaml
name: OpenCode Validation

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  validate:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'

      - name: Install OpenCode
        run: |
          # Install OpenCode dependencies
          npm install -g @modelcontextprotocol/server-github

      - name: Validate Setup
        run: bash ~/.config/opencode/scripts/validate-setup.sh

      - name: Health Check
        run: bash ~/.config/opencode/scripts/health-check.sh

      - name: Run Tests
        run: npm test

      - name: Check Coverage
        run: npm run coverage
        env:
          COVERAGE_THRESHOLD: 80
```

**2. Add Status Check:**
```yaml
      - name: Quality Gate
        run: |
          COVERAGE=$(cat coverage/coverage-summary.json | jq '.total.lines.pct')
          if (( $(echo "$COVERAGE < 80" | bc -l) )); then
            echo "Coverage ($COVERAGE%) below threshold"
            exit 1
          fi
```

---

### Pre-Commit Hooks

**Purpose:** Validate before commit.

**Setup:**
```bash
# Install hook
bash ~/.config/opencode/scripts/setup-git-hooks.sh
```

**What It Checks:**
- Sensitive files (passwords, keys)
- File sizes (>1MB warning)
- Merge conflicts
- Debug statements
- Linting (ESLint, Pylint)
- Formatting (Prettier, Black)

**Bypass (Not Recommended):**
```bash
git commit --no-verify
```

---

## Project Management (Linear/Jira)

### Linear Integration

**Configured via MCP** (see above)

**Workflow:**
```
1. @planner Fetch Linear issues for current sprint
2. @planner Create spec from Linear issue ENG-456
3. @builder Implement spec, link to Linear issue
4. @tester Run tests, update Linear issue with results
5. @builder Create PR, link to Linear issue
6. @reviewer Review PR, update Linear issue status
```

**Automation:**
```
When PR merged:
  → Linear issue status: "Done"
  → Linear comment: "Deployed in PR #123"
```

---

### Jira Integration

**Setup (Example - Not Built-In):**

**1. Jira API Token:**
- Go to https://id.atlassian.com/manage/api-tokens
- Create API token
- Save securely

**2. Create Custom MCP (if needed):**
```bash
# If Jira MCP doesn't exist, use REST API
```

**3. Agent Integration:**
```
@planner Fetch Jira tickets from PROJ sprint

@builder Update Jira PROJ-123 status to "In Progress"
```

**Alternative:** Use GitHub-Jira integration
- Link commits: `git commit -m "PROJ-123: Add feature"`
- Auto-transition Jira status based on PR status

---

## CI/CD Pipelines

### GitHub Actions (Detailed)

**Complete Pipeline:**

**.github/workflows/ci.yml:**
```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop, 'feature/**']
  pull_request:
    branches: [main, develop]

env:
  NODE_VERSION: '18'
  COVERAGE_THRESHOLD: 80

jobs:
  lint:
    name: Lint & Format
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: ${{ env.NODE_VERSION }}

      - name: Install Dependencies
        run: npm ci

      - name: Run ESLint
        run: npx eslint src/

      - name: Check Prettier
        run: npx prettier --check src/

  test:
    name: Test & Coverage
    runs-on: ubuntu-latest
    needs: lint
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3

      - name: Install Dependencies
        run: npm ci

      - name: Run Tests
        run: npm test -- --coverage

      - name: Check Coverage
        run: |
          COVERAGE=$(cat coverage/coverage-summary.json | jq '.total.lines.pct')
          if (( $(echo "$COVERAGE < $COVERAGE_THRESHOLD" | bc -l) )); then
            echo "Coverage $COVERAGE% < $COVERAGE_THRESHOLD%"
            exit 1
          fi

      - name: Upload Coverage to Codecov
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage/lcov.info

  security:
    name: Security Scan
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Run npm audit
        run: npm audit --audit-level=moderate

      - name: Run Snyk
        uses: snyk/actions/node@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}

  build:
    name: Build
    runs-on: ubuntu-latest
    needs: [lint, test, security]
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3

      - name: Install Dependencies
        run: npm ci

      - name: Build
        run: npm run build

      - name: Upload Artifacts
        uses: actions/upload-artifact@v3
        with:
          name: build
          path: dist/

  deploy-staging:
    name: Deploy to Staging
    runs-on: ubuntu-latest
    needs: build
    if: github.ref == 'refs/heads/develop'
    environment:
      name: staging
      url: https://staging.example.com
    steps:
      - uses: actions/download-artifact@v3
        with:
          name: build

      - name: Deploy to Staging
        run: |
          # Deploy logic here
          echo "Deploying to staging..."

  deploy-production:
    name: Deploy to Production
    runs-on: ubuntu-latest
    needs: build
    if: github.ref == 'refs/heads/main'
    environment:
      name: production
      url: https://example.com
    steps:
      - uses: actions/download-artifact@v3

      - name: Deploy to Production
        run: |
          # Production deployment
          echo "Deploying to production..."
```

---

### GitLab CI

**.gitlab-ci.yml:**
```yaml
stages:
  - lint
  - test
  - build
  - deploy

variables:
  NODE_VERSION: "18"

lint:
  stage: lint
  image: node:${NODE_VERSION}
  script:
    - npm ci
    - npx eslint src/
    - npx prettier --check src/

test:
  stage: test
  image: node:${NODE_VERSION}
  script:
    - npm ci
    - npm test -- --coverage
  coverage: '/Lines\s*:\s*(\d+\.\d+)%/'
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage/cobertura-coverage.xml

build:
  stage: build
  image: node:${NODE_VERSION}
  script:
    - npm ci
    - npm run build
  artifacts:
    paths:
      - dist/

deploy:staging:
  stage: deploy
  only:
    - develop
  script:
    - echo "Deploy to staging"

deploy:production:
  stage: deploy
  only:
    - main
  when: manual
  script:
    - echo "Deploy to production"
```

---

## Communication (Slack/Teams)

### Slack Integration

**Via MCP** (example above) or **Webhooks**:

**Webhook Integration:**

**1. Create Incoming Webhook:**
- Go to Slack App settings
- Add Incoming Webhooks
- Copy webhook URL

**2. Send Notifications:**
```bash
# From bash script
curl -X POST -H 'Content-type: application/json' \
  --data '{"text":"Deployment completed successfully!"}' \
  YOUR_WEBHOOK_URL
```

**3. Agent Integration:**
```typescript
// Custom skill or in build script
async function notifySlack(message: string) {
  await fetch(process.env.SLACK_WEBHOOK_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ text: message })
  });
}
```

**Use Cases:**
- Deployment notifications
- Build failures
- Security alerts
- Daily summaries

---

### Microsoft Teams

**Similar to Slack:**

**1. Create Incoming Webhook:**
- Teams → Channel → Connectors
- Configure Incoming Webhook
- Copy webhook URL

**2. Send Notifications:**
```bash
curl -X POST -H 'Content-type: application/json' \
  --data '{
    "@type": "MessageCard",
    "@context": "http://schema.org/extensions",
    "text": "Deployment completed!"
  }' \
  YOUR_TEAMS_WEBHOOK_URL
```

---

## Monitoring & Observability

### Logging Integration

**Centralized Logging (Datadog, Splunk, ELK):**

**Forward OpenCode Logs:**
```bash
# Tail audit logs to centralized system
tail -f ~/.config/opencode/logs/audit.log | \
  datadog-agent send-logs
```

**Structured Logging:**
```json
{
  "timestamp": "2024-02-14T10:30:45Z",
  "agent": "builder",
  "action": "file_write",
  "file": "src/auth/login.ts",
  "user": "developer@example.com",
  "session_id": "abc123"
}
```

---

### Metrics & Alerting

**Track Metrics:**
- Agent invocation count
- Average cost per agent
- Error rate
- Response time

**Alert On:**
- Cost threshold exceeded
- High error rate
- Security violations
- Deployment failures

**Example (Datadog):**
```yaml
# metrics.yaml
- type: gauge
  name: opencode.agent.cost
  value: 0.52
  tags:
    - agent:builder
    - model:sonnet

- type: count
  name: opencode.agent.invocations
  value: 1
  tags:
    - agent:planner
```

---

## Database Integrations

### Database MCP (Future)

**Concept:**
```json
{
  "mcp": {
    "database": {
      "enabled": true,
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres"],
      "environment": {
        "DATABASE_URL": "postgresql://user:pass@localhost:5432/db"
      }
    }
  }
}
```

**Agent Usage:**
```
@migration Use database MCP to create migration for adding roles table

@debug Query database to investigate data issue
```

---

### Migration Tools Integration

**Prisma:**
```
@migration Create Prisma migration to add user.roles column

# Generates: prisma/migrations/20240214_add_user_roles.sql
```

**TypeORM:**
```
@migration Generate TypeORM migration for User entity changes
```

**Flyway/Liquibase:**
```
@migration Create Flyway migration V2__add_roles_table.sql
```

---

## IDE Integrations

### VS Code (Future)

**OpenCode Extension** (concept):
- Invoke agents from command palette
- Inline agent suggestions
- View specs in sidebar
- Check cost/budget in status bar

**Manual Integration:**
```json
// .vscode/tasks.json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "OpenCode: Validate Setup",
      "type": "shell",
      "command": "bash ~/.config/opencode/scripts/validate-setup.sh"
    },
    {
      "label": "OpenCode: Health Check",
      "type": "shell",
      "command": "bash ~/.config/opencode/scripts/health-check.sh"
    }
  ]
}
```

---

### JetBrains IDEs (Future)

**Plugin Concept:**
- Agent invocation from context menu
- Spec templates
- Cost tracking
- Git integration

---

## Summary

**Integrated Services:**
- ✅ GitHub (via MCP)
- ✅ Linear (via MCP)
- ✅ Context7 (via MCP)
- ✅ Git (via skill)
- ✅ CI/CD (GitHub Actions, GitLab CI)

**Easily Integrable:**
- 🔄 Slack (webhook or MCP)
- 🔄 Microsoft Teams (webhook)
- 🔄 Jira (REST API)
- 🔄 Databases (future MCP)
- 🔄 Monitoring (log forwarding)

**For More:**
- MCP Setup: `mcp/SETUP_GUIDE.md`
- Scripts: `scripts/README.md`
- Workflows: `workflows/`

---

*Last updated: 2026-02-17*
