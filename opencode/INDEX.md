# OpenCode Agent Architecture - Complete Index

**Navigation guide for all documentation.** Start here to find what you need.

---

## Quick Start (New Users)

1. Start → [QUICK_START.md](QUICK_START.md) - 5-minute introduction
2. Configure → [mcp/SETUP_GUIDE.md](mcp/SETUP_GUIDE.md) - Set up GitHub/Linear tokens
3. Try → Run your first agent command: `@planner Create a spec for a health check endpoint`

---

## By Role

### Developer
1. [QUICK_START.md](QUICK_START.md) - Get started in 5 minutes
2. [workflows/feature_implementation.md](workflows/feature_implementation.md) - How to build features
3. [specs/template.md](specs/template.md) - How to write specs
4. [agents/QUICK_REFERENCE.md](agents/QUICK_REFERENCE.md) - Agent lookup table

### Tech Lead / Architect
1. [ARCHITECTURE.md](ARCHITECTURE.md) - System design & patterns
2. [README.md](README.md) - Complete overview
3. [workflows/](workflows/) - All workflows
4. [config/guardrails.md](config/guardrails.md) - Safety controls & guidelines

### Security Engineer
1. [workflows/security_review.md](workflows/security_review.md) - When/how to review
2. [agents/specialized/security.md](agents/specialized/security.md) - Security agent
3. [workflows/incident_response.md](workflows/incident_response.md) - Incidents

### DevOps / SRE
1. [workflows/incident_response.md](workflows/incident_response.md) - Incident handling
2. [workflows/hotfix_workflow.md](workflows/hotfix_workflow.md) - Emergency process
3. [workflows/database_migration.md](workflows/database_migration.md) - DB changes
4. [workflows/release_checklist.md](workflows/release_checklist.md) - Releases

---

## By Task

| Task | Start Here |
|------|------------|
| Implement a new feature | [workflows/feature_implementation.md](workflows/feature_implementation.md) |
| Create a pull request | [workflows/pr_checklist.md](workflows/pr_checklist.md) |
| Handle production incident | [workflows/incident_response.md](workflows/incident_response.md) |
| Deploy a release | [workflows/release_checklist.md](workflows/release_checklist.md) |
| Review code for security | [workflows/security_review.md](workflows/security_review.md) |
| Migrate database schema | [workflows/database_migration.md](workflows/database_migration.md) |
| Optimize performance | [agents/specialized/performance.md](agents/specialized/performance.md) |
| Refactor code | [agents/specialized/refactor.md](agents/specialized/refactor.md) |
| Debug a failure | [agents/debug.md](agents/debug.md) |
| Set up MCP servers | [mcp/SETUP_GUIDE.md](mcp/SETUP_GUIDE.md) |
| Choose an agent | [agents/QUICK_REFERENCE.md](agents/QUICK_REFERENCE.md) |

---

## Documentation Structure

```
opencode/
├── Getting Started
│   ├── QUICK_START.md                      # 5-minute introduction
│   └── INDEX.md                            # This file
│
├── Core Documentation
│   ├── README.md                           # Complete system overview
│   ├── ARCHITECTURE.md                     # Technical design
│   ├── GLOSSARY.md                         # Terminology reference
│   ├── TROUBLESHOOTING.md                  # Problem solving
│   ├── PATTERNS.md                         # Best practices
│   └── INTEGRATION.md                      # Integration guide
│
├── Agents
│   ├── QUICK_REFERENCE.md                  # Agent lookup table
│   ├── debug.md                            # Debug agent (primary mode)
│   ├── plan.md                             # Plan mode system prompt
│   ├── writer.md                           # Blog writer agent
│   ├── core/
│   │   ├── planner.md                      # Planning agent (read-only)
│   │   ├── builder.md                      # Implementation agent
│   │   ├── tester.md                       # Test execution
│   │   └── reviewer.md                     # Code review
│   └── specialized/
│       ├── security.md                     # Security review
│       ├── migration.md                    # Database migrations
│       ├── performance.md                  # Performance optimization
│       ├── refactor.md                     # Code refactoring
│       ├── release.md                      # Release management
│       ├── documentation.md                # Documentation
│       ├── analytics.md                    # Codebase analytics
│       ├── tooling-engineer.md             # Build tooling & DX
│       ├── git-workflow-manager.md         # Git workflow
│       ├── dependency-manager.md           # Dependency management
│       ├── devops-engineer.md              # CI/CD & infrastructure
│       └── mcp-developer.md               # MCP development
│
├── Workflows
│   ├── feature_implementation.md           # Complete feature workflow
│   ├── pr_checklist.md                     # Pull request process
│   ├── release_checklist.md                # Release process
│   ├── hotfix_workflow.md                  # Emergency patches
│   ├── incident_response.md                # Production incidents
│   ├── security_review.md                  # Security review process
│   └── database_migration.md               # Database changes
│
├── Specifications
│   ├── template.md                         # Full spec template
│   └── example-user-profiles.md            # Complete example
│
├── Skills
│   └── [14 skill directories]             # See skills/ for full list
│
├── MCP Servers
│   ├── README.md                           # MCP overview
│   └── SETUP_GUIDE.md                      # Step-by-step setup
│
├── CI Templates
│   ├── README.md                           # CI template docs
│   └── .github/workflows/opencode-ci.yml   # GitHub Actions template
│
├── Configuration
│   ├── opencode.json                       # Main configuration
│   ├── opencode-notes.md                   # Config extraction notes
│   └── config/guardrails.md                # Operational guidelines
│
├── Scripts
│   └── README.md                           # Script documentation
│
└── Examples
    └── [5 example files]                   # Usage examples
```

---

## Quick Reference Tables

### Core Agents

| Agent | Command | Purpose | Permissions |
|-------|---------|---------|-------------|
| **planner** | `@planner` | Create specifications | Read-only |
| **builder** | `@builder` | Implement features | Write + Execute |
| **tester** | `@tester` | Run tests | Execute-only |
| **reviewer** | `@reviewer` | Code review | Read-only |

### Specialized Agents

| Agent | Command | Purpose | Permissions |
|-------|---------|---------|-------------|
| **security** | `@security` | Auth, payments, uploads | Read-only |
| **migration** | `@migration` | Database changes | Write + Execute |
| **performance** | `@performance` | Slow endpoints | Edit + Execute |
| **refactor** | `@refactor` | Code cleanup | Edit + Execute |
| **debug** | `@debug` | Failures, bugs | Execute + Search |
| **release** | `@release` | Versioning, releases | Write + Execute |
| **documentation** | `@documentation` | Doc generation | Write + Execute |
| **analytics** | `@analytics` | Codebase metrics | Execute + Search |
| **tooling-engineer** | `@tooling-engineer` | Build tooling, DX | Write + Execute |
| **git-workflow-manager** | `@git-workflow-manager` | Git workflow | Write + Execute |
| **dependency-manager** | `@dependency-manager` | Dependency management | Write + Execute |
| **devops-engineer** | `@devops-engineer` | CI/CD, infrastructure | Write + Execute |
| **mcp-developer** | `@mcp-developer` | MCP development | Write + Execute |

---

## Emergency Quick Links

- **Production is down:** [Incident Response](workflows/incident_response.md)
- **Need emergency fix:** [Hotfix Workflow](workflows/hotfix_workflow.md)
- **Security breach:** [Security Review](workflows/security_review.md) + [Incident Response](workflows/incident_response.md)
- **Agent not working:** [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

## Getting Help

1. Check this INDEX for navigation
2. Try [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
3. Review [GLOSSARY.md](GLOSSARY.md) for terms
4. Read relevant workflow in [workflows/](workflows/)

---

*Last updated: 2026-02-17*
