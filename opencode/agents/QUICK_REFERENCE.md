# OpenCode Agents - Quick Reference

**Fast lookup guide for all OpenCode agents.** For full details, see each agent's `.md` file.

---

## Agent Lookup Table

### Core Agents

| Agent | Purpose | Model | Temp | Permissions | Details |
|-------|---------|-------|------|-------------|---------|
| **@planner** | Create specs, decompose tasks | Sonnet-4 | 0.3 | read, search | [planner.md](core/planner.md) |
| **@builder** | Implement features from specs | Sonnet-4 | 0.1 | write, edit, bash, read | [builder.md](core/builder.md) |
| **@tester** | Run tests, check coverage | Haiku-4 | 0 | bash, read | [tester.md](core/tester.md) |
| **@reviewer** | Code review, spec compliance | Sonnet-4 | 0.2 | read, search | [reviewer.md](core/reviewer.md) |

### Specialized Agents

| Agent | Purpose | Model | Temp | Permissions | Details |
|-------|---------|-------|------|-------------|---------|
| **@security** | Security review (auth, payments, crypto) | Opus-4 | 0 | read, search | [security.md](specialized/security.md) |
| **@migration** | Database schema changes | Sonnet-4 | 0 | write, edit, bash, read | [migration.md](specialized/migration.md) |
| **@performance** | Performance optimization | Sonnet-4 | 0.2 | write, edit, bash, read | [performance.md](specialized/performance.md) |
| **@refactor** | Code restructuring, cleanup | Haiku-4 | 0.1 | write, edit, bash, read | [refactor.md](specialized/refactor.md) |
| **@debug** | Root cause analysis, bug diagnosis | Sonnet-4 | 0.3 | bash, read, search | [debug.md](../agents/debug.md) |
| **@release** | Versioning, changelogs, releases | Sonnet-4 | 0.2 | write, edit, bash, read, search | [release.md](specialized/release.md) |
| **@documentation** | Doc generation and maintenance | Haiku-4 | 0.2 | write, edit, bash, read, search | [documentation.md](specialized/documentation.md) |
| **@analytics** | Codebase metrics and analysis | Sonnet-4 | 0.3 | bash, read, search | [analytics.md](specialized/analytics.md) |
| **@tooling-engineer** | Build tooling, DX, CLI commands | Sonnet-4 | 0.2 | write, edit, bash, read, search | [tooling-engineer.md](specialized/tooling-engineer.md) |
| **@git-workflow-manager** | Git branching, PR workflow | Haiku-4 | 0.1 | write, edit, bash, read, search | [git-workflow-manager.md](specialized/git-workflow-manager.md) |
| **@dependency-manager** | Dependency audit, updates, vulns | Haiku-4 | 0.1 | write, edit, bash, read, search | [dependency-manager.md](specialized/dependency-manager.md) |
| **@devops-engineer** | CI/CD, deployment, infra | Sonnet-4 | 0.2 | write, edit, bash, read, search | [devops-engineer.md](specialized/devops-engineer.md) |
| **@mcp-developer** | MCP server dev, protocol integration | Sonnet-4 | 0.2 | write, edit, bash, read, search | [mcp-developer.md](specialized/mcp-developer.md) |

**Cost tiers:** Haiku ($) < Sonnet ($$) < Opus ($$$)

---

## Quick Decision Tree

```
Starting work:
  New feature?        → @planner first, then @builder
  Bug?                → @debug to investigate, then @builder to fix
  Slow code?          → @performance to analyze
  Messy code?         → @refactor to clean up
  DB schema change?   → @migration

After implementation:
  Run tests           → @tester
  Tests failing?      → @debug
  Touches auth/payment? → @security
  Ready for merge?    → @reviewer
```

---

## Common Workflows

**Standard feature:** `@planner → @builder → @tester → @reviewer`

**Security-sensitive:** `@planner → @security (review spec) → @builder → @tester → @security → @reviewer`

**Bug fix:** `@debug → @builder → @tester → @reviewer`

**Database change:** `@planner → @migration → @tester → @reviewer`

**Performance:** `@performance → @tester → @reviewer`

**Emergency (P0):** `@debug → @builder → @tester → DEPLOY`

---

## Pro Tips

1. **Always start with @planner** for non-trivial work — clear specs save rework
2. **Use the right agent** — don't ask @builder to debug or @debug to implement
3. **Always @security for auth/payment** — even if it seems minor
4. **Always @tester after changes** — catch regressions early
5. **Chain agents** don't try to make one agent do everything

## Common Mistakes

- Skipping @planner → unclear requirements → rework
- Skipping @security for auth changes → vulnerabilities missed
- Using @builder for debugging → wrong tool for the job
- Skipping @tester → bugs found in production

---

*For complete agent documentation, see individual files in `agents/core/` and `agents/specialized/`.*

*Last updated: 2026-02-17*
