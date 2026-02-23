# Production-Grade Agent Architecture for OpenCode

A comprehensive, production-ready agent system for software development teams, implementing modern agent research patterns with practical engineering guardrails.

## Philosophy

**Agents are microservices for AI.** Each agent has a single responsibility, clear contracts, limited permissions, and observable behavior.

## Quick Start

### 1. Installation

This agent architecture is already set up in your OpenCode global configuration:

```
~/.config/opencode/
├── agents/           # Agent prompt definitions
├── skills/           # Tool/skill definitions
├── workflows/        # Development workflows
├── specs/            # Specification templates
├── config/           # Configuration files
└── opencode.json     # Main configuration
```

### 2. Basic Usage

#### Plan a Feature

```
@planner Create a spec for user authentication system
```

#### Implement a Feature

```
@builder Implement the feature from specs/2026-02-13-auth-system.md
```

#### Run Tests

```
@tester Run comprehensive tests for the authentication feature
```

#### Review Code

```
@reviewer Review the authentication implementation
```

### 3. Complete Workflow

**Full Pipeline: Spec → Execute → Verify → Ship**

```
User: "Add user profile editing functionality"
  ↓
@planner → Creates specification in specs/
  ↓ (human reviews & approves)
@builder → Implements according to spec
  ↓
@tester → Runs comprehensive test suite
  ↓
@reviewer → Validates correctness & quality
  ↓ (triggers security review if needed)
@security → Reviews security implications
  ↓
Create PR → CI/CD → Deploy
```

## Core Agents

### 🎯 Planner (Read-only)

**Purpose**: Decompose tasks and create specification artifacts

**Responsibilities**:

- Research existing code
- Identify patterns
- Create detailed specs
- Define acceptance criteria
- Identify risks

**Permissions**: Read-only (no file writes, no execution)

**Usage**:

```
@planner Plan implementation for real-time notifications
```

**Output**: `specs/YYYY-MM-DD-feature-name.md`

---

### 🔨 Builder (Write + Execute)

**Purpose**: Implement features strictly against specifications

**Responsibilities**:

- Write code following specs
- Update tests
- Run fast validation
- Apply diff-based edits

**Permissions**: File write (diff-only), execute (scoped)

**Usage**:

```
@builder Implement specs/2026-02-13-notifications.md
```

**Output**: Code changes + test updates

**Guardrails**:

- Max 2 auto-fix attempts
- Max 5 files per edit
- Must pass lint/typecheck/unit tests

---

### ✅ Tester (Execute-only)

**Purpose**: Run tests and return structured results

**Responsibilities**:

- Execute test suites
- Generate coverage reports
- Identify failure patterns
- Return machine-readable results

**Permissions**: Execute tests only (no source edits)

**Usage**:

```
@tester Run full test suite with coverage
```

**Output**: JSON test results + coverage metrics

---

### 👀 Reviewer (Read-only)

**Purpose**: Validate correctness, security, and spec compliance

**Responsibilities**:

- Check spec compliance
- Review code quality
- Identify security issues
- Assess performance
- Verify edge cases

**Permissions**: Read-only (no edits)

**Usage**:

```
@reviewer Review the notification system implementation
```

**Output**: Approve / Request Changes / Block

---

## Specialized Agents

### 🔒 Security Agent

**Trigger**: Authentication, payments, file uploads, secrets, crypto

**Purpose**: Deep security analysis

- OWASP Top 10 vulnerabilities
- Authentication/authorization flaws
- Input validation issues
- Cryptographic weaknesses

**Model**: Opus-4 (maximum capability)

**Usage**:

```
@security Review payment processing implementation
```

---

### 🗃️ Migration Agent

**Trigger**: Database schema changes

**Purpose**: Safe database migrations

- Generate migrations
- Test rollbacks
- Assess data loss risks
- Dry-run validation

**Guardrails**: NEVER applies production migrations automatically

**Usage**:

```
@migration Create migration for user_profiles table
```

---

### ⚡ Performance Agent

**Trigger**: Performance bottlenecks identified

**Purpose**: Optimize code and queries

- Database optimization
- Algorithm improvements
- Caching strategies
- Bundle size reduction

**Usage**:

```
@performance Optimize the order listing endpoint
```

---

### ♻️ Refactor Agent

**Trigger**: Code quality improvements needed

**Purpose**: Improve maintainability without changing behavior

- Extract functions
- Remove duplication
- Simplify complexity
- Modernize patterns

**Guardrails**: Must not change functionality

**Usage**:

```
@refactor Improve the authentication service code
```

---

### 🐛 Debug Agent

**Trigger**: After 2 failed auto-fix attempts

**Purpose**: Root cause analysis

- Stack trace interpretation
- Reproduce failures
- Identify patterns
- Recommend fixes

**Usage**:

```
@debug Analyze test failures in auth.spec.ts
```

---

## Key Workflows

### Feature Implementation

See [workflows/feature_implementation.md](workflows/feature_implementation.md)

```
1. @planner → Create spec
2. Human approval
3. @builder → Implement
4. @tester → Validate
5. @reviewer → Approve
6. Create PR → Merge → Deploy
```

### Pull Request

See [workflows/pr_checklist.md](workflows/pr_checklist.md)

Comprehensive checklist for creating high-quality pull requests.

### Release

See [workflows/release_checklist.md](workflows/release_checklist.md)

Complete release process with rollback procedures and monitoring.

---

## Skills

Skills are deterministic capability wrappers that agents can use.

### run-tests

Execute test suites and return structured results

```json
{
  "status": "passed",
  "coverage": 87,
  "failures": []
}
```

### spec-validator

Validate implementation against spec acceptance criteria

### git-workflow

Manage Git operations (branch, commit, PR)

### ci-status

Check CI/CD pipeline status and build results

---

## Specifications

All features start with a spec artifact in `specs/`.

### Spec Template

`specs/template.md` - Complete specification template

### Example Spec

`specs/example-user-profiles.md` - Reference implementation

### Spec Format

```markdown
# Feature Name

## Problem

What needs to be solved

## Constraints

Technical & business limits

## Proposed Approach

How to implement

## Acceptance Criteria

- [ ] Testable requirement 1
- [ ] Testable requirement 2

## Risks

What could go wrong

## Task Breakdown

Step-by-step implementation
```

**Why Specs?**

- Audit trail
- Reproducibility
- Team visibility
- Debuggable failures
- Decouples planning from execution

---

## Configuration

### Agent Configuration

`opencode.json` - Main configuration file

**Key Settings**:

```json
{
  "agent": {
    "planner": {
      "mode": "subagent",
      "model": "anthropic/claude-sonnet-4-20250514",
      "tools": { "write": false, "read": true }
    }
  },
  "guardrails": {
    "max_tool_calls_per_session": 100,
    "max_retries": 2,
    "require_spec_for_builder": true
  }
}
```

### Model Strategy (Cost Optimization)

**Planning & Architecture**: Sonnet-4 / Opus-4

- Complex reasoning required
- High-impact decisions

**Implementation**: Sonnet-4

- Precision needed
- Context-heavy

**Testing**: Haiku-4

- Fast execution
- Structured output

**Security**: Opus-4

- Maximum capability
- Critical analysis

**Refactoring / Docs**: Haiku-4

- Routine operations
- Lower complexity

**Cost savings**: 60-80% compared to using one model for everything

---

## MCP Servers

Model Context Protocol servers provide external tool access.

### GitHub MCP

Repository operations, issues, PRs

```json
"github": {
  "type": "local",
  "command": ["npx", "-y", "@modelcontextprotocol/server-github"],
  "environment": {
    "GITHUB_PERSONAL_ACCESS_TOKEN": "your_token_here"
  }
}
```

### Linear MCP

Issue tracking, project management

```json
"linear": {
  "type": "local",
  "command": ["npx", "-y", "@linear/mcp"],
  "environment": {
    "LINEAR_API_KEY": "your_api_key_here"
  }
}
```

### Context7 MCP

Up-to-date documentation access

```json
"context7": {
  "type": "local",
  "command": ["npx", "-y", "@upstash/context7-mcp"]
}
```

---

## Guardrails & Safety

### Permission Tiers

**READ**: Search, inspect, analyze
**WRITE**: Modify files, create artifacts
**EXECUTE**: Shell, migrations, deployments

**Rule**: Never give all three to one agent

### Diff-Based Editing

Prevents catastrophic rewrites

```
apply_patch(file, diff)  # ✅ Safe
rewrite_file(file, content)  # ❌ Dangerous
```

### Planning Gate

```
plan → approve → execute  # Always
plan → execute  # Never
```

### Budget Limits

- Max tool calls per session
- Token ceilings
- Runtime caps
- Max retry attempts (2)

---

## Best Practices

### ✅ DO

- Always start with a spec
- Use appropriate agent for each task
- Trust but verify critical changes
- Monitor agent outputs
- Iterate with fast feedback
- Document learnings
- Use cost-optimized models

### ❌ DON'T

- Skip planning phase
- Mix multiple concerns in one spec
- Give excessive permissions
- Allow infinite retry loops
- Bypass code review
- Ignore security triggers
- Use one model for everything

---

## Troubleshooting

### Agent Not Working

1. Check `opencode.json` configuration
2. Verify agent mode (primary/subagent/all)
3. Check tool permissions
4. Review model availability

### Tests Failing

1. Check logs from @tester
2. Reproduce locally
3. Send failure slice to @builder
4. If still failing: invoke @debug

### Security Concerns

Always trigger @security for:

- Authentication/authorization
- Payment processing
- File uploads
- Cryptographic operations
- Personal data handling
- Webhook endpoints

### Performance Issues

1. Profile first (measure, don't guess)
2. Invoke @performance with metrics
3. Focus on bottlenecks (80/20 rule)
4. Monitor after optimization

---

## Examples

### Example 1: Simple Feature

```
User: "Add email validation to registration"
@planner → Creates spec (2 min)
@builder → Implements + tests (5 min)
@tester → Validates (1 min)
@reviewer → Approves (2 min)
Total: ~10 minutes
```

### Example 2: Complex Feature

```
User: "Add real-time notifications with WebSocket"
@planner → Research + spec (10 min)
  ↓ (human reviews architecture decisions)
@builder → Implement (30 min)
@tester → Full test suite (5 min)
@reviewer → Code review (10 min)
@security → Security review (10 min)
  ↓ (triggers due to WebSocket)
Total: ~65 minutes
```

### Example 3: Bug Fix

```
User: "Login fails intermittently"
@debug → Root cause analysis (5 min)
  → Identifies race condition
@builder → Fix with proper await (2 min)
@tester → Verify fix (2 min)
@reviewer → Quick review (2 min)
Total: ~11 minutes
```

---

## Architecture

See [ARCHITECTURE.md](ARCHITECTURE.md) for complete system design, agent interaction patterns, and implementation roadmap.

---

## Metrics

Track these to measure agent system effectiveness:

### Speed

- Time from request to implementation
- Planning time
- Review time
- Total cycle time

### Quality

- Test coverage percentage
- Security vulnerabilities found
- Code review approval rate
- Rollback rate

### Cost

- API costs per feature
- Model usage distribution
- Token efficiency

### Reliability

- First-time success rate
- Auto-fix success rate
- Human intervention rate
- Agent accuracy

---

## Support

### Documentation

- [Complete Workflows](workflows/)
- [Agent Prompts](agents/)
- [Skill Definitions](skills/)
- [Spec Templates](specs/)

### Getting Help

- Review example specs and workflows
- Check troubleshooting section
- Consult [ARCHITECTURE.md](ARCHITECTURE.md)
- Adjust agent prompts based on patterns

---

## Roadmap

### Week 1-2 (Foundation)

- ✅ Core agents (Planner, Builder, Tester, Reviewer)
- ✅ Spec artifact system
- ✅ Basic workflows

### Week 3 (Specialization)

- ✅ Security agent
- ✅ Migration agent
- ✅ Performance agent
- ✅ Debug agent

### Week 4 (Optimization)

- ✅ MCP server integration
- ✅ Model strategy
- ✅ Complete documentation

### Future

- Team collaboration features
- Metrics dashboard
- Agent performance analytics
- Custom agent templates
- Integration with more tools

---

## Credits

Based on production-grade agent architecture principles:

- Microservice-style agents
- Separation of concerns
- Least privilege
- Observable behavior
- Deterministic outputs

Built for OpenCode, adaptable to any AI coding environment.

---

## License

This agent architecture is provided as-is for use with OpenCode.

---

**Remember**: Reliability beats flash. Build for control first, autonomy second.

---

## Useful Links

### Skills

- [anthropics/skills](https://github.com/anthropics/skills) - Public repository for Agent Skills
- [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills) - Vercel's official collection of agent skills
- [skills-directory](https://www.skillsdirectory.com/) - Skills directory
- [agent-skills](https://github.com/vercel-labs/agent-skills) - Vercel agent skills

### Subagents

- [VoltAgent/awesome-claude-code-subagents](https://github.com/VoltAgent/awesome-claude-code-subagents) - 100+ specialized Claude Code subagents
- [gsd-build/get-shit-done](https://github.com/gsd-build/get-shit-done) - Meta-prompting and spec-driven development system

### Plugins

- [kdcokenny/opencode-worktree](https://github.com/kdcokenny/opencode-worktree) - Zero-friction git worktrees for OpenCode

### MCPs

- [mcp-directory](https://cursor.directory/mcp) - MCP cursor directory
- [upstash/context7](https://github.com/upstash/context7) - Context7 MCP Server for up-to-date code docs
- [firecrawl/firecrawl](https://github.com/firecrawl/firecrawl) - Turn websites into LLM-ready data

### Prompts

- [f/prompts.chat](https://github.com/f/prompts.chat) - Awesome ChatGPT Prompts
- [x1xhlol/system-prompts-and-models-of-ai-tools](https://github.com/x1xhlol/system-prompts-and-models-of-ai-tools) - System prompts of AI tools
