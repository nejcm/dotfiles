# OpenCode Agent Architecture - Glossary

**Comprehensive terminology reference for the OpenCode agent system.**

---

## Table of Contents

- [Core Concepts](#core-concepts)
- [Agents](#agents)
- [Permissions & Security](#permissions--security)
- [Workflows](#workflows)
- [Skills](#skills)
- [MCP (Model Context Protocol)](#mcp-model-context-protocol)
- [Models & AI](#models--ai)
- [Cost & Performance](#cost--performance)
- [Database & Migrations](#database--migrations)
- [Incident Management](#incident-management)
- [Development Terms](#development-terms)

---

## Core Concepts

### Agent
A specialized AI assistant configured with specific permissions, tools, and responsibilities. Each agent is designed for a single purpose (planning, building, testing, etc.).

**Example:** `@planner` agent creates specifications, `@builder` agent implements code.

**See:** `agents/` directory for all agent configurations.

---

### Spec (Specification)
A structured document that describes what needs to be built, including problem statement, constraints, approach, acceptance criteria, and task breakdown.

**Format:** Markdown file with standardized sections.

**Example:** `specs/example-user-profiles.md`

**See:** `specs/template.md` for complete template.

---

### Spec Artifact Pattern
A design pattern where specifications are stored as files (artifacts) rather than conversational memory. This enables persistent, reviewable, version-controlled requirements.

**Benefits:**
- Version control via Git
- Peer review possible
- Reusable across sessions
- Clear source of truth

**See:** `ARCHITECTURE.md` - Design Patterns section

---

### Skill
A reusable tool or capability that agents can invoke to perform specific actions (run tests, validate specs, check CI status, etc.).

**Format:** Markdown file with YAML frontmatter in subdirectory.

**Location:** `skills/[skill-name]/SKILL.md`

**Example:** `skills/run-tests/SKILL.md`

---

### Workflow
A step-by-step process for completing complex tasks (feature implementation, PR creation, incident response, etc.).

**Format:** Comprehensive markdown guide with phases, checklists, and examples.

**Location:** `workflows/[workflow-name].md`

**Example:** `workflows/feature_implementation.md`

---

### Guardrails
Safety controls that prevent agents from performing dangerous operations, exceeding budgets, or violating security policies.

**Categories:**
- **Operational:** Max tool calls, max retries, max files per edit
- **Cost:** Daily budgets, per-session limits
- **Security:** Blocked operations, sensitive paths
- **Deployment:** Production approval requirements

**See:** `config/guardrails.md` for complete reference.

---

### MCP (Model Context Protocol)
A standardized protocol for connecting AI agents to external services (GitHub, Linear, databases, etc.).

**Purpose:** Enables agents to read/write data in external systems.

**Configuration:** `opencode.json` - `mcp` section

**See:** `mcp/README.md` and `mcp/SETUP_GUIDE.md`

---

### Tool Permission
Access control that determines what actions an agent can perform.

**Permission Types:**
- **read:** View files and data
- **write:** Create new files
- **edit:** Modify existing files
- **bash:** Execute shell commands
- **search:** Search codebase

**Configuration:** Per-agent in `opencode.json`

---

### Subagent Mode
An agent that operates as a subprocess with isolated context and specific tools, rather than in the main conversation thread.

**Benefits:**
- Isolated permissions
- Specialized model selection
- Clear separation of concerns

**Configuration:** `mode: subagent` in agent YAML frontmatter

---

## Agents

### Planner Agent
**Purpose:** Creates specifications and breaks down tasks.

**Permissions:** Read-only (read, search)

**Model:** Claude Sonnet-4 (temperature: 0.3)

**Output:** Complete specification file in `specs/` directory

**Command:** `@planner Create spec for [feature]`

---

### Builder Agent
**Purpose:** Implements features based on specifications.

**Permissions:** Write, edit, bash, read

**Model:** Claude Sonnet-4 (temperature: 0.1)

**Guardrail:** Requires specification file (configurable)

**Command:** `@builder Implement specs/[spec-file].md`

---

### Tester Agent
**Purpose:** Executes tests and returns structured results.

**Permissions:** Bash, read

**Model:** Claude Haiku-4 (temperature: 0) - Cost optimized

**Output:** Test results with pass/fail status, coverage metrics

**Command:** `@tester Run comprehensive tests`

---

### Reviewer Agent
**Purpose:** Validates code correctness, security, and spec compliance.

**Permissions:** Read-only (read, search)

**Model:** Claude Sonnet-4 (temperature: 0.2)

**Output:** Review report with issues categorized by severity

**Command:** `@reviewer Review implementation against spec`

---

### Security Agent
**Purpose:** Security review specialist for auth, payments, permissions, secrets.

**Permissions:** Read-only (read, search)

**Model:** Claude Opus-4 (temperature: 0) - Most capable for critical work

**Triggers:** Changes to auth/, payment/, admin/ paths or sensitive files

**Command:** `@security Review [file/feature] for security issues`

---

### Migration Agent
**Purpose:** Database schema changes and migrations.

**Permissions:** Write, bash, read

**Model:** Claude Sonnet-4 (temperature: 0)

**Output:** Migration files with up/down scripts and rollback procedures

**Command:** `@migration Create migration to [description]`

---

### Performance Agent
**Purpose:** Performance optimization specialist.

**Permissions:** Edit, bash, read

**Model:** Claude Sonnet-4 (temperature: 0.2)

**Output:** Performance analysis and optimization recommendations

**Command:** `@performance Analyze and optimize [feature]`

---

### Refactor Agent
**Purpose:** Code restructuring and cleanup.

**Permissions:** Edit, bash, read

**Model:** Claude Haiku-4 (temperature: 0.1) - Cost optimized for routine work

**Output:** Refactored code with explanations

**Command:** `@refactor Improve structure of [file/module]`

---

### Debug Agent
**Purpose:** Root cause analysis and bug diagnosis.

**Permissions:** Bash, read, search

**Model:** Claude Sonnet-4 (temperature: 0.3)

**Output:** Debug report with root cause and fix recommendations

**Command:** `@debug Investigate [error/failure]`

---

## Permissions & Security

### READ Permission
Allows agent to view files and data without modification.

**Operations:**
- Read file contents
- Search codebase
- View configuration
- Access documentation

**Security:** Lowest risk permission level

---

### WRITE Permission
Allows agent to create new files but not modify existing ones.

**Operations:**
- Create new files
- Generate code
- Create directories

**Security:** Medium risk - agent can add files but not change existing code

**Guardrails:**
- Max files per operation
- Restricted paths (e.g., can't write to production configs)

---

### EDIT Permission
Allows agent to modify existing files.

**Operations:**
- Change code
- Update configuration
- Refactor existing files

**Security:** Higher risk - agent can alter existing functionality

**Guardrails:**
- Diff-based editing (show what changes)
- Max files per edit
- Backup before edit

---

### BASH/EXECUTE Permission
Allows agent to run shell commands.

**Operations:**
- Run tests
- Execute build scripts
- Run database migrations
- Execute CLI tools

**Security:** Highest risk - arbitrary command execution

**Guardrails:**
- Blocked operations list
- Approval required for dangerous commands
- Audit logging of all executions

---

### Security-Sensitive Path
File paths that automatically trigger security review when modified.

**Default Paths:**
- `auth/` - Authentication logic
- `payment/` - Payment processing
- `admin/` - Administrative functions
- `security/` - Security controls
- `secrets/` - Secret management

**Configuration:** `opencode.json` - `security.security_sensitive_paths`

---

### Security-Sensitive File
File patterns that trigger security review.

**Default Patterns:**
- `*password*` - Password handling
- `*secret*` - Secret management
- `*token*` - Token generation/validation
- `*key*` - Cryptographic keys
- `*credential*` - Credential storage

**Configuration:** `opencode.json` - `security.security_sensitive_files`

---

### Blocked Operation
Commands or SQL statements that are prohibited by security policy.

**Default Blocked:**
- `DROP DATABASE` - Prevent accidental database deletion
- `TRUNCATE TABLE users` - Prevent mass user deletion
- `DELETE FROM users WHERE 1=1` - Prevent unfiltered deletes

**Configuration:** `opencode.json` - `security.block_sensitive_operations`

---

### Audit Log
Comprehensive log of all agent actions including tool calls, file changes, API calls, and decisions.

**Purpose:** Compliance, debugging, security review

**Retention:** Configurable (default: 90 days)

**Location:** `~/.config/opencode/logs/audit.log`

**Configuration:** `opencode.json` - `audit` section

---

## Workflows

### Feature Implementation Workflow
Complete process for building a new feature from specification to deployment.

**Phases:**
1. Planning (spec creation)
2. Implementation (code writing)
3. Testing (validation)
4. Review (quality check)
5. Deployment (release)

**Duration:** 35-55 minutes typical

**See:** `workflows/feature_implementation.md`

---

### Hotfix Workflow
Emergency process for critical production issues requiring immediate fixes.

**Severity Levels:**
- **P0 (Critical):** Production completely down
- **P1 (High):** Major functionality broken
- **P2 (Medium):** Partial functionality affected
- **P3 (Low):** Minor issue with workaround

**Phases:**
1. Assessment
2. Preparation
3. Implementation
4. Deployment
5. Verification
6. Post-Hotfix

**See:** `workflows/hotfix_workflow.md`

---

### Incident Response Workflow
Process for handling production incidents from detection to post-mortem.

**Roles:**
- **IC (Incident Commander):** Overall coordination
- **Tech Lead:** Technical investigation and resolution
- **Communications:** Stakeholder updates
- **Scribe:** Documentation

**Phases:**
1. Detect
2. Declare
3. Triage
4. Investigate
5. Resolve
6. Communicate
7. Close
8. Learn

**See:** `workflows/incident_response.md`

---

### Security Review Workflow
Process for reviewing code changes for security vulnerabilities.

**When Required:**
- Authentication/authorization changes
- Payment processing
- File uploads
- Cryptography
- Database access
- Admin functionality

**Checklist:** OWASP Top 10 coverage

**See:** `workflows/security_review.md`

---

### Database Migration Workflow
Safe process for schema changes with zero-downtime patterns.

**Risk Levels:**
- **LOW:** Adding nullable columns, adding indexes (online)
- **MEDIUM:** Renaming columns, changing types (compatible)
- **HIGH:** Dropping columns, changing types (incompatible)

**Patterns:**
- **Expand-Migrate-Contract:** Gradual transition
- **Shadow Table:** Parallel old/new tables
- **Online Schema Change:** Use tools like gh-ost, pt-online-schema-change

**See:** `workflows/database_migration.md`

---

### PR Checklist Workflow
Process for creating production-ready pull requests.

**Checklist:**
- [ ] All tests passing
- [ ] Code reviewed
- [ ] Documentation updated
- [ ] No security issues
- [ ] Migrations tested
- [ ] Rollback plan documented

**See:** `workflows/pr_checklist.md`

---

### Release Checklist Workflow
Process for deploying new versions to production.

**Phases:**
1. Pre-release (preparation)
2. Release (deployment)
3. Post-release (verification)

**See:** `workflows/release_checklist.md`

---

## Skills

### run-tests
**Purpose:** Execute test suite and return structured results.

**Input:** Test command (npm test, pytest, etc.)

**Output:** Pass/fail status, coverage metrics, failed test details

**Location:** `skills/run-tests/SKILL.md`

---

### spec-validator
**Purpose:** Validate specification completeness and correctness.

**Checks:**
- All required sections present
- Acceptance criteria clear
- Risks identified
- Task breakdown complete

**Location:** `skills/spec-validator/SKILL.md`

---

### git-workflow
**Purpose:** Git operations (commit, branch, PR creation).

**Operations:**
- Create branches
- Commit with conventional format
- Create pull requests
- Merge strategies

**Location:** `skills/git-workflow/SKILL.md`

---

### ci-status
**Purpose:** Check CI/CD pipeline status.

**Integrations:**
- GitHub Actions
- CircleCI
- Jenkins
- GitLab CI

**Output:** Build status, test results, deployment status

**Location:** `skills/ci-status/SKILL.md`

---

## MCP (Model Context Protocol)

### GitHub MCP
**Purpose:** Read/write GitHub repositories, issues, PRs.

**Requirements:**
- GitHub Personal Access Token
- Scopes: `repo`, `read:org`, `workflow`

**Operations:**
- Create issues/PRs
- Read repository contents
- Update issue status
- List pull requests

**Configuration:** `opencode.json` - `mcp.github`

**See:** `mcp/SETUP_GUIDE.md` - GitHub section

---

### Linear MCP
**Purpose:** Project management integration with Linear.

**Requirements:**
- Linear API Key

**Operations:**
- Create/update issues
- Assign team members
- Update project status
- Track progress

**Configuration:** `opencode.json` - `mcp.linear`

**See:** `mcp/SETUP_GUIDE.md` - Linear section

---

### Context7 MCP
**Purpose:** Semantic search and embeddings for codebase.

**Requirements:** None (works out of the box)

**Operations:**
- Semantic code search
- Find similar code
- Get code context

**Configuration:** `opencode.json` - `mcp.context7`

---

## Models & AI

### Claude Opus-4
**Capabilities:** Most capable model, best reasoning, highest quality.

**Use Cases:**
- Security-critical reviews
- Complex architecture decisions
- High-stakes production issues

**Cost:** Highest (~$15 input / $75 output per 1M tokens)

**Configuration:** `anthropic/claude-opus-4-20250514`

---

### Claude Sonnet-4
**Capabilities:** Balanced model, good reasoning, fast performance.

**Use Cases:**
- Feature implementation
- Code review
- Planning and architecture
- Debugging

**Cost:** Medium (~$3 input / $15 output per 1M tokens)

**Configuration:** `anthropic/claude-sonnet-4-20250514`

---

### Claude Haiku-4
**Capabilities:** Fast model, lower cost, good for routine tasks.

**Use Cases:**
- Test execution
- Code formatting
- Documentation generation
- Routine refactoring

**Cost:** Lowest (~$0.25 input / $1.25 output per 1M tokens)

**Configuration:** `anthropic/claude-haiku-4-20250514`

---

### Temperature
Controls randomness/creativity in model output.

**Values:**
- **0.0:** Deterministic, same output every time
- **0.1-0.3:** Mostly deterministic, slight variation
- **0.5-0.7:** Balanced creativity and consistency
- **0.8-1.0:** High creativity, more variation

**Recommendations:**
- **Implementation:** 0.1 (builder agent)
- **Testing:** 0.0 (tester agent)
- **Planning:** 0.3 (planner agent)
- **Review:** 0.2 (reviewer agent)

---

### Context Window
Maximum amount of text (in tokens) a model can process in a single request.

**Typical Sizes:**
- Claude 3.5 Sonnet: 200K tokens
- Claude 3 Opus: 200K tokens
- Claude 3.5 Haiku: 200K tokens

**Guardrail:** `max_context_tokens` limits to prevent excessive costs

---

### Token
Basic unit of text for AI models. Approximately:
- 1 token ≈ 4 characters
- 1 token ≈ 0.75 words
- 100 tokens ≈ 75 words

**Example:** This sentence is about 8-10 tokens.

---

## Cost & Performance

### Daily Budget
Maximum amount (in USD) that can be spent on AI API calls per day.

**Default:** $100/day

**Configuration:** `opencode.json` - `cost_controls.daily_budget_usd`

**Reset:** Midnight UTC

---

### Per-Session Limit
Maximum amount (in USD) for a single conversation session.

**Default:** $10/session

**Configuration:** `opencode.json` - `cost_controls.per_session_limit_usd`

**Purpose:** Prevent runaway costs from single long-running tasks

---

### Expensive Operation Threshold
Dollar amount that triggers a warning before executing.

**Default:** $5

**Configuration:** `opencode.json` - `cost_controls.expensive_operation_threshold_usd`

**Trigger:** Large context, Opus model, many tool calls

---

### Rate Limit
Maximum number of API calls an agent can make per hour.

**Purpose:** Prevent abuse and control costs

**Configuration:** `opencode.json` - `rate_limits` section

**Example:**
- Planner: 30 calls/hour
- Builder: 20 calls/hour
- Tester: 40 calls/hour

---

### Model Strategy
Intentional selection of models (Opus/Sonnet/Haiku) based on task complexity to optimize cost/performance.

**Strategy:**
- **Security-critical:** Opus-4 (highest capability)
- **Implementation:** Sonnet-4 (balanced)
- **Testing:** Haiku-4 (fast and cheap)

**Savings:** 60-80% compared to using Opus for everything

**See:** `opencode.json` - `model_strategy` section

---

## Database & Migrations

### Zero-Downtime Migration
Database schema change that doesn't require application downtime.

**Key Principle:** Old and new code must work simultaneously during transition.

**See:** `workflows/database_migration.md` - Patterns section

---

### Expand-Migrate-Contract Pattern
Three-phase migration strategy:

1. **Expand:** Add new column (nullable) alongside old column
2. **Migrate:** Dual-write to both columns, backfill data
3. **Contract:** Remove old column once fully migrated

**Duration:** Days to weeks (safe and gradual)

**See:** `workflows/database_migration.md`

---

### Shadow Table
Migration pattern using parallel tables.

**Process:**
1. Create new table with desired schema
2. Dual-write to old and new tables
3. Backfill historical data
4. Switch reads to new table
5. Drop old table

**Use Case:** Major schema redesigns

---

### Online Schema Change
Tool-assisted migrations that don't lock tables.

**Tools:**
- **gh-ost:** GitHub's online schema change tool
- **pt-online-schema-change:** Percona toolkit
- **pgslice:** PostgreSQL partitioning

**Benefit:** No downtime even for large tables

---

### Migration Rollback
Process of reverting a database change.

**Requirements:**
- Down migration script
- Data preservation strategy
- Tested rollback procedure

**Best Practice:** Test rollback before deploying migration

---

## Incident Management

### Incident Severity
Classification of incident impact.

**Levels:**
- **P0 (Critical):** Complete outage, all users affected
- **P1 (High):** Major feature broken, most users affected
- **P2 (Medium):** Partial degradation, some users affected
- **P3 (Low):** Minor issue, few users affected

**See:** `workflows/incident_response.md` - Severity section

---

### IC (Incident Commander)
Person responsible for overall incident coordination.

**Responsibilities:**
- Declare incident
- Assign roles
- Make decisions
- Coordinate response
- Communicate with stakeholders

**Not responsible for:** Actually fixing the issue (that's Tech Lead)

---

### Tech Lead (Incident)
Technical expert responsible for diagnosis and resolution.

**Responsibilities:**
- Investigate root cause
- Implement fixes
- Coordinate technical team
- Advise IC on technical decisions

**Selection:** Senior engineer with domain knowledge

---

### Post-Mortem
Blameless retrospective after incident to learn and improve.

**Sections:**
1. Timeline of events
2. Root cause analysis
3. What went well
4. What went wrong
5. Action items (with owners)

**Timing:** Within 3 business days of incident resolution

**See:** `workflows/incident_response.md` - Post-Mortem section

---

### RCA (Root Cause Analysis)
Deep investigation to identify the fundamental reason an incident occurred.

**Method:** "5 Whys" technique

**Example:**
1. Why did the app crash? → Out of memory
2. Why out of memory? → Memory leak
3. Why memory leak? → Event listeners not cleaned up
4. Why not cleaned up? → Missing cleanup in useEffect
5. Why missing? → Code review didn't catch it

**Root Cause:** Insufficient code review process for React hooks

---

## Development Terms

### Conventional Commits
Standardized commit message format.

**Format:** `<type>(<scope>): <description>`

**Types:**
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation
- `refactor:` Code restructuring
- `test:` Test changes
- `chore:` Maintenance

**Example:** `feat(auth): add OAuth2 login support`

---

### Acceptance Criteria
Specific, testable conditions that must be met for a feature to be considered complete.

**Format:** Given/When/Then

**Example:**
- Given: User is logged in
- When: User clicks "Logout"
- Then: User session is terminated and redirected to login page

---

### Edge Case
Unusual or extreme input that might cause unexpected behavior.

**Examples:**
- Empty array
- Null values
- Very large numbers
- Special characters in strings
- Concurrent requests

**Best Practice:** Identify edge cases in specification phase

---

### Technical Debt
Code or architecture shortcuts that will need to be fixed later.

**Types:**
- **Deliberate:** Conscious decision to move faster now
- **Accidental:** Didn't know better at the time
- **Environmental:** External changes (deprecated API, etc.)

**Management:** Track in issues, allocate time for paydown

---

### Rollback
Reverting a deployment to a previous version.

**Types:**
- **Code rollback:** Deploy previous version
- **Database rollback:** Run down migration
- **Config rollback:** Restore previous configuration

**Best Practice:** Test rollback procedure before deploying

---

### Canary Deployment
Gradual rollout strategy where new version is deployed to small percentage of users first.

**Process:**
1. Deploy to 5% of users
2. Monitor metrics
3. If successful, increase to 25%
4. Monitor again
5. If successful, deploy to 100%

**Benefit:** Limit blast radius of bugs

---

### Blast Radius
Scope of potential damage from a failure or bug.

**Examples:**
- **Small:** Single user affected
- **Medium:** One feature broken
- **Large:** Entire application down

**Risk Mitigation:** Reduce blast radius through canary deployments, feature flags, circuit breakers

---

## Index

For quick navigation to specific topics, see:
- **By Role:** [INDEX.md - By Role](INDEX.md#by-role-who-you-are)
- **By Task:** [INDEX.md - By Task](INDEX.md#by-task-what-you-want-to-do)
- **By Scenario:** [INDEX.md - By Scenario](INDEX.md#by-scenario-whats-happening)

---

**This glossary defines all terms used across OpenCode documentation. Bookmark for quick reference!**

*Last updated: 2026-02-17*
