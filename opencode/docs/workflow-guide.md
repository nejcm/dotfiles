# Workflow Guide

## Overview

OpenCode provides 7 comprehensive workflows for different development scenarios. This guide helps you choose the right workflow, chain workflows together, and understand when to escalate to humans or specialized agents.

---

## Workflow Selection Decision Tree

```
┌─────────────────────────────────────────────────────────────┐
│ What are you trying to accomplish?                          │
└─────────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
        ▼                   ▼                   ▼
┌───────────────┐   ┌───────────────┐   ┌───────────────┐
│ Build/Change  │   │ Deploy/Ship   │   │ Investigate   │
│ Code          │   │ Code          │   │ Issue         │
└───────────────┘   └───────────────┘   └───────────────┘
        │                   │                   │
        │                   │                   │
        ▼                   ▼                   ▼

┌─────────────────────────────────────────────────────────────┐
│ BUILD/CHANGE CODE - What type of change?                    │
└─────────────────────────────────────────────────────────────┘
        │
        ├─► New feature                → feature_implementation.md
        │
        ├─► Bug fix (P2/P3)           → feature_implementation.md (expedited)
        │
        ├─► Database change           → database_migration.md
        │
        ├─► Security-critical         → security_review.md → feature_implementation.md
        │   (auth, payment, admin)
        │
        ├─► Performance optimization  → feature_implementation.md
        │                                + performance-profiler skill
        │
        └─► Code refactoring          → feature_implementation.md
                                         + @refactor agent

┌─────────────────────────────────────────────────────────────┐
│ DEPLOY/SHIP CODE - What's the urgency?                      │
└─────────────────────────────────────────────────────────────┘
        │
        ├─► Normal release            → release_checklist.md
        │
        ├─► Hotfix (P0/P1 bug)       → hotfix_workflow.md
        │
        └─► Production is DOWN        → incident_response.md

┌─────────────────────────────────────────────────────────────┐
│ INVESTIGATE ISSUE - What's happening?                       │
└─────────────────────────────────────────────────────────────┘
        │
        ├─► Production incident       → incident_response.md
        │
        ├─► Bug in staging/dev        → feature_implementation.md (bug fix)
        │
        ├─► Security vulnerability    → security_review.md
        │
        └─► Performance regression    → feature_implementation.md
                                         + performance-profiler skill
```

---

## Workflow Catalog

### 1. Feature Implementation Workflow
**File:** `workflows/feature_implementation.md`

**When to use:**
- Building new features
- Fixing non-critical bugs (P2/P3)
- Code refactoring
- Performance optimizations

**Phases:**
1. **Planning** (@planner) - Create spec with acceptance criteria
2. **Implementation** (@builder) - Write code, tests
3. **Testing** (@tester) - Validate functionality, coverage
4. **Review** (@reviewer) - Code review, quality check
5. **Merge** - PR approval, merge to develop

**Duration:** 1-5 days

**Example:**
```bash
# Start feature workflow
@planner Create spec for user preferences feature

# Implement
@builder Implement based on spec #123

# Test
@tester Run full test suite with coverage

# Review
@reviewer Review PR #456
```

---

### 2. Pull Request Checklist
**File:** `workflows/pr_checklist.md`

**When to use:**
- Before requesting PR review
- Ensuring all quality gates passed
- Pre-merge validation

**Checklist:**
- [ ] Code linted (ESLint, Prettier)
- [ ] Tests written and passing
- [ ] Coverage ≥80%
- [ ] No security vulnerabilities
- [ ] API contracts validated (if applicable)
- [ ] Performance benchmarked (if critical path)
- [ ] Documentation updated

**Duration:** 30 minutes - 2 hours

**Example:**
```bash
# Run PR checklist
@reviewer Validate PR #456 against checklist

# Auto-invokes:
# - code-quality skill (lint, format, type check)
# - run-tests skill (with coverage)
# - dependency-check skill (security audit)
```

---

### 3. Database Migration Workflow
**File:** `workflows/database_migration.md`

**When to use:**
- Adding/modifying database schema
- Data migrations (backfills, transformations)
- Index creation/removal

**Phases:**
1. **Design** (@migration, @planner) - Migration strategy (zero-downtime)
2. **Implementation** (@migration) - Write migration files
3. **Testing** (@tester) - Test on staging, validate rollback
4. **Deployment** (@migration) - 4-phase rollout (add → deploy → backfill → constrain)
5. **Validation** (@tester) - Verify data integrity

**Duration:** 2-5 days (including testing)

**Example:**
```bash
# Plan migration
@migration Design zero-downtime migration for adding user_preferences column

# Test on staging
@tester Test migration and rollback on staging database

# Deploy to production
@migration Execute 4-phase deployment:
# Phase 1: Add nullable column
# Phase 2: Deploy code using new column
# Phase 3: Backfill existing rows
# Phase 4: Add NOT NULL constraint
```

**See also:** `examples/database-migration-example.md`

---

### 4. Security Review Workflow
**File:** `workflows/security_review.md`

**When to use:**
- Changes to authentication/authorization
- Payment processing code
- Admin/privileged functionality
- External API integrations
- File uploads, user-generated content

**Phases:**
1. **Threat Modeling** (@security) - Identify attack vectors
2. **Code Review** (@security) - OWASP Top 10 check
3. **Testing** (@tester) - Security test cases
4. **Audit** (@security) - Dependency vulnerabilities
5. **Sign-off** (@security) - Security scorecard

**Duration:** 1-3 days

**Example:**
```bash
# Start security review
@security Review OAuth2 implementation in PR #789

# Security checks:
# - CSRF protection (state parameter)
# - PKCE for public clients
# - Redirect URI validation
# - Token storage (httpOnly cookies)
# - Rate limiting

# Result: Security score 9.5/10 ✅
```

**See also:** `examples/security-review-example.md`

---

### 5. Release Checklist
**File:** `workflows/release_checklist.md`

**When to use:**
- Preparing production deployment
- Version bumps (major, minor, patch)
- Creating release candidates

**Phases:**
1. **Pre-release** - All tests passing, no blockers
2. **Changelog** (@release) - Generate release notes
3. **Version Bump** (@release) - Update package.json, tag
4. **Staging Deploy** - Test on staging
5. **Production Deploy** - Canary → full rollout
6. **Post-deploy** - Smoke tests, monitoring

**Duration:** 1-2 days

**Example:**
```bash
# Prepare release
@release Create release candidate for v2.5.0

# Pre-release checks:
# ✅ All CI/CD jobs passing
# ✅ Code coverage 85% (above 80% threshold)
# ✅ No critical vulnerabilities
# ✅ Performance benchmarks stable

# Generate changelog
@release Generate release notes from commits since v2.4.0

# Deploy
# Staging → Canary (5%) → Monitor (10 min) → Full (100%)
```

---

### 6. Hotfix Workflow
**File:** `workflows/hotfix_workflow.md`

**When to use:**
- Critical bugs in production (P0/P1)
- Security vulnerabilities requiring immediate patch
- Data corruption issues

**Phases:**
1. **Triage** (@debug) - Confirm severity, assess impact
2. **Root Cause** (@debug) - Identify bug, create fix
3. **Testing** (@tester) - Expedited test, rollback plan
4. **Deploy** (@release) - Fast-track to production
5. **Post-mortem** - Document incident, prevent recurrence

**Duration:** 2-8 hours (emergency timeline)

**Example:**
```bash
# Emergency hotfix
@debug Investigate payment processing failure in production

# Root cause: Race condition in concurrent payment handling
# Fix: Add pessimistic locking (SELECT FOR UPDATE)

# Fast-track testing
@tester Run critical path tests on hotfix branch

# Deploy
@release Emergency deploy to production with rollback plan

# Post-mortem
@planner Create post-mortem document, add regression tests
```

**See also:** `examples/bug-fix-example.md`

---

### 7. Incident Response Workflow
**File:** `workflows/incident_response.md`

**When to use:**
- Production outage (service unavailable)
- Security breach detected
- Data loss/corruption
- Performance degradation affecting users

**Phases:**
1. **Detection** - Alert triggered, oncall notified
2. **Assessment** (@debug) - Severity, impact, affected users
3. **Mitigation** (@debug, @release) - Immediate fix, rollback, or failover
4. **Communication** - Status page, stakeholder updates
5. **Resolution** (@builder) - Permanent fix
6. **Post-incident** - RCA, action items, runbook updates

**Duration:** 30 minutes - 24 hours

**Example:**
```bash
# Incident declared: API response time >5s (P0)
# SLA breach: 99.9% uptime at risk

# Immediate mitigation
@performance Identify slow queries causing database contention

# Temporary fix: Add database connection pooling, increase limits
# Deploy emergency patch

# Permanent fix
@performance Optimize slow queries, add indexes

# Post-incident review
# Root cause: N+1 queries on user dashboard
# Action items: Add query monitoring, review all dashboard endpoints
```

---

## Workflow Chaining Patterns

### Pattern 1: Feature → PR → Release (Happy Path)
**Sequence:** `feature_implementation` → `pr_checklist` → `release_checklist`

**Timeline:** 1-2 weeks

**Flow:**
```
Day 1-3:  Feature implementation (@planner, @builder, @tester)
Day 4:    PR checklist validation (@reviewer)
Day 5:    PR merged to develop
Day 6-7:  Staging testing
Day 8:    Release preparation (@release)
Day 9:    Production deployment (canary → full)
Day 10:   Post-deploy monitoring
```

**Agents involved:** @planner → @builder → @tester → @reviewer → @release

**Artifacts:**
- Spec: `specs/user-preferences-feature.md`
- Tests: `src/**/*.test.ts`
- Changelog: `CHANGELOG.md` (updated)
- Release notes: `releases/v2.5.0.md`

---

### Pattern 2: Security Feature (High Security Requirements)
**Sequence:** `security_review` → `feature_implementation` → `security_review` → `pr_checklist` → `release`

**Timeline:** 2-3 weeks (extended for security rigor)

**Flow:**
```
Week 1:   Threat modeling, security design review (@security, @planner)
Week 2:   Implementation with security tests (@builder, @tester)
Week 2:   Final security audit (@security)
Week 3:   PR review, staging, release (@reviewer, @release)
```

**Example:** OAuth2 implementation, payment processing, admin panel

**Critical checks:**
- OWASP Top 10 compliance
- Penetration testing (automated + manual)
- Security scorecard ≥9/10

---

### Pattern 3: Database Change (Zero-Downtime Required)
**Sequence:** `database_migration` → `feature_implementation` → `pr_checklist` → `release`

**Timeline:** 1-2 weeks (longer for large datasets)

**Flow:**
```
Day 1-2:  Migration design (@migration, @planner)
Day 3:    Write migration files, test rollback (@migration)
Day 4-5:  Implement application code (@builder)
Day 6:    Test on staging with production-scale data (@tester)
Day 7-8:  Release preparation
Day 9:    4-phase production deployment (@migration, @release)
```

**Example:** Adding user_preferences JSONB column to 2.4M user table

**Phases:**
1. Add nullable column (instant)
2. Deploy code reading/writing new column (5 min)
3. Backfill existing rows in batches (14 min for 2.4M rows)
4. Add NOT NULL constraint (instant)

**See also:** `examples/database-migration-example.md`

---

### Pattern 4: Incident → Hotfix → Release (Emergency Path)
**Sequence:** `incident_response` → `hotfix_workflow` → `release_checklist` (expedited)

**Timeline:** 2-24 hours (emergency mode)

**Flow:**
```
Hour 1:   Incident detected, severity assessed (@debug)
Hour 2-4: Mitigation (rollback or emergency patch) (@release)
Hour 5-6: Root cause analysis (@debug)
Hour 7-8: Permanent fix implementation (@builder)
Hour 9:   Expedited testing (@tester)
Hour 10:  Production deployment (@release)
Hour 11+: Post-incident review, runbook updates
```

**Example:** Payment processing race condition causing duplicate charges

**Critical decisions:**
- Rollback vs forward fix?
- Communication strategy (internal, customer-facing)
- Escalation criteria (when to involve humans)

**See also:** `examples/bug-fix-example.md`

---

### Pattern 5: Performance Investigation → Optimization → Release
**Sequence:** `feature_implementation` (optimization) + `performance-profiler` skill

**Timeline:** 3-7 days

**Flow:**
```
Day 1:    Performance profiling, identify bottlenecks (@performance)
Day 2-3:  Optimization (indexing, caching, query rewriting) (@builder, @refactor)
Day 4:    Re-profile, validate improvement (@performance)
Day 5:    Testing with production-scale data (@tester)
Day 6-7:  Release (@release)
```

**Example:** User dashboard optimization (2847ms → 79ms, 36x faster)

**Techniques:**
- Database indexing (B-tree, GIN for JSONB)
- Eliminate N+1 queries (JOIN instead of multiple SELECTs)
- Parallel execution (Promise.all() for independent queries)
- Redis caching (user preferences, rarely-changing data)

**See also:** `examples/performance-optimization-example.md`

---

## When to Escalate to Humans

### Critical Escalation Scenarios

**Immediate Human Escalation (P0):**
- Production outage >15 minutes
- Security breach detected (unauthorized access, data leak)
- Data corruption affecting >100 users
- Financial impact >$10,000
- Legal/compliance violation

**Timely Human Escalation (P1, within 4 hours):**
- Architecture decisions (choosing databases, frameworks)
- Breaking API changes requiring migration guide
- Deployment failures requiring rollback
- Critical bug with no obvious fix
- Technical debt >40% of codebase

**Advisory Human Escalation (P2, within 1 day):**
- Feature ambiguity (unclear requirements)
- Performance optimization requiring trade-offs
- Refactoring affecting public APIs
- Security vulnerability CVSS 4-7 (moderate)
- Coverage dropping below 70% (warning threshold)

---

## Agent-to-Agent Escalation

### Common Escalation Paths

**@builder → @security:**
- Implementing auth/payment/admin features
- External API integrations
- File uploads, user-generated content

**@tester → @builder:**
- Tests failing after code changes
- Coverage below 80% threshold
- Flaky tests requiring code fixes

**@performance → @refactor:**
- Performance issues require code restructuring
- Complexity hotspots (cyclomatic >15)
- Memory leaks requiring architectural changes

**@debug → @security:**
- Bug reveals security vulnerability
- Race conditions in auth/payment logic
- Input validation failures

**@migration → @tester:**
- Need tests before schema changes
- Rollback testing required
- Data integrity validation

**@reviewer → @builder:**
- Code quality issues (complexity, duplication)
- Missing tests or documentation
- Performance concerns in critical paths

**@release → @security:**
- Vulnerabilities detected in release candidate
- Dependency audit failures
- Emergency security hotfix needed

---

## Workflow Best Practices

### 1. Always Start with Specs
**Why:** Specs prevent scope creep, align expectations, enable parallel work

**How:**
```bash
# Start every feature with planning
@planner Create spec for [feature name]

# Spec includes:
# - User story (As a..., I want..., So that...)
# - Acceptance criteria (Given/When/Then)
# - Technical approach (high-level design)
# - Success metrics (performance, coverage, security)
```

---

### 2. Test Early, Test Often
**Why:** Catch bugs early (10x cheaper to fix in dev vs production)

**How:**
```bash
# Write tests alongside implementation
@builder Implement feature X
@tester Write tests for feature X

# Not this (testing as afterthought):
@builder Implement features A, B, C
@tester Write tests for A, B, C  # ❌ Too late!
```

---

### 3. Use Incremental Deployments
**Why:** Limit blast radius, enable fast rollback

**How:**
```bash
# Canary deployment pattern
# 1. Deploy to 5% of users
# 2. Monitor for 10 minutes (error rate, latency, business metrics)
# 3. If healthy, deploy to 100%
# 4. If issues, rollback immediately

# Zero-downtime database migrations
# 1. Make schema changes backward-compatible
# 2. Deploy code in phases (add → backfill → constrain)
# 3. Test rollback at every phase
```

---

### 4. Automate Quality Gates
**Why:** Prevent human error, enforce standards

**CI/CD Quality Gates:**
- [ ] Linting (ESLint, Prettier)
- [ ] Type checking (TypeScript)
- [ ] Unit tests passing
- [ ] Coverage ≥80%
- [ ] Security audit (no critical/high vulnerabilities)
- [ ] Performance benchmarks (no regression >10%)
- [ ] API contracts valid (OpenAPI validation)

**Example:**
```yaml
# GitHub Actions enforces gates automatically
# PR cannot merge if any gate fails
- Linting ✅
- Tests ✅
- Coverage (85%) ✅
- Security ✅
- Performance (2% improvement) ✅
```

---

### 5. Document Decisions
**Why:** Onboard new team members, prevent repeat mistakes

**What to document:**
- Architecture Decision Records (ADRs)
- Post-mortems (after incidents)
- Migration runbooks
- Performance optimization learnings
- Security review findings

**Example ADR:**
```markdown
# ADR-007: Use PostgreSQL JSONB for User Preferences

## Status: Accepted

## Context
Need to store flexible user preferences without schema migrations.

## Decision
Use PostgreSQL JSONB column with GIN index.

## Consequences
+ Flexible schema (no migrations for new preferences)
+ Fast queries with GIN indexing
- Harder to enforce validation (app-level only)
- Cannot use foreign keys on nested fields

## Alternatives Considered
1. Separate preferences table (rejected: too many joins)
2. MongoDB (rejected: want single database)
```

---

## Workflow Selection Examples

### Example 1: "Add user preferences feature"
**Selected Workflow:** Feature Implementation

**Reasoning:**
- New feature (not a bug or hotfix)
- Not touching auth/payment (no security review needed)
- Standard complexity

**Flow:**
1. @planner → Create spec
2. @builder → Implement
3. @tester → Test, coverage
4. @reviewer → PR review
5. Merge to develop

**Duration:** 3-5 days

---

### Example 2: "Fix payment processing bug causing duplicate charges"
**Selected Workflow:** Hotfix Workflow (if in production) OR Feature Implementation (if caught in staging)

**Reasoning:**
- Critical bug affecting payments (P0 if production)
- Requires security review (payment logic)
- Needs expedited testing

**Flow:**
1. @debug → Root cause analysis (race condition)
2. @builder → Implement fix (pessimistic locking)
3. @security → Review fix (validate security)
4. @tester → Expedited testing
5. @release → Emergency deployment

**Duration:** 4-8 hours (emergency mode)

**See also:** `examples/bug-fix-example.md`

---

### Example 3: "Database is slow, users complaining"
**Selected Workflow:** Incident Response → Performance Optimization

**Reasoning:**
- Active production issue (P0/P1)
- Requires investigation before fix
- May need database migration (indexes)

**Flow:**
1. @debug → Identify slow queries
2. @performance → Profile database, find N+1 queries
3. @builder → Optimize queries, add indexes
4. @migration → Deploy index creation (if large table)
5. @tester → Validate performance improvement
6. @release → Deploy optimizations

**Duration:** 1-3 days

**See also:** `examples/performance-optimization-example.md`

---

### Example 4: "Add OAuth2 login"
**Selected Workflow:** Security Review → Feature Implementation → Security Review

**Reasoning:**
- Security-critical feature (authentication)
- Requires threat modeling upfront
- Needs thorough security testing

**Flow:**
1. @security → Threat modeling, security design
2. @planner → Create spec with security requirements
3. @builder → Implement OAuth2 with PKCE, CSRF protection
4. @tester → Security test cases
5. @security → Final security audit
6. @reviewer → Code review
7. Release with extra monitoring

**Duration:** 2-3 weeks (security rigor)

**See also:** `examples/security-review-example.md`

---

## Workflow Antipatterns (What NOT to Do)

### ❌ Antipattern 1: "Cowboy Coding"
**Problem:** Writing code without specs or tests

**Symptoms:**
- "I'll write tests later" (never happens)
- Unclear acceptance criteria
- Scope creep, feature bloat

**Fix:** Always start with `@planner Create spec`, then `@builder Implement based on spec`

---

### ❌ Antipattern 2: "Merge and Pray"
**Problem:** Skipping PR review or quality gates

**Symptoms:**
- Merging without approval
- Bypassing CI/CD checks
- "It works on my machine"

**Fix:** Use `pr_checklist.md`, enforce branch protection

---

### ❌ Antipattern 3: "Production Debugging"
**Problem:** Deploying untested code to investigate issues

**Symptoms:**
- "Let's add logging and redeploy"
- Multiple deployments in short period
- No rollback plan

**Fix:** Debug on staging/dev, use `incident_response.md` for production issues

---

### ❌ Antipattern 4: "Big Bang Migration"
**Problem:** Deploying database schema changes without rollback plan

**Symptoms:**
- Downtime during migration
- Data loss on rollback
- No testing on production-scale data

**Fix:** Use `database_migration.md`, zero-downtime 4-phase rollout

---

### ❌ Antipattern 5: "Ignoring Technical Debt"
**Problem:** Never refactoring, accumulating complexity

**Symptoms:**
- Cyclomatic complexity >20
- Test coverage <60%
- Performance degrading over time

**Fix:** Allocate 20% time to refactoring, use `@refactor` agent

---

## Related Documentation

- **[Skills Integration Matrix](./skills-integration-matrix.md)** - Which skills to use with which workflows
- **[Agent Integration Points](./agent-integration-points.md)** - How agents communicate
- **[Workflows Directory](../workflows/)** - Detailed workflow templates
- **[Examples Directory](../examples/)** - Real-world workflow examples

---

## Quick Reference Card

| Scenario | Workflow | Duration | Agents |
|----------|----------|----------|--------|
| New feature | Feature Implementation | 1-5 days | @planner, @builder, @tester, @reviewer |
| Bug fix (staging) | Feature Implementation | 1-2 days | @debug, @builder, @tester |
| Critical bug (prod) | Hotfix Workflow | 2-8 hours | @debug, @builder, @tester, @release |
| Production down | Incident Response | 0.5-24 hours | @debug, @performance, @release |
| Database change | Database Migration | 2-5 days | @migration, @tester, @release |
| Security feature | Security Review → Feature | 2-3 weeks | @security, @planner, @builder, @tester |
| Release | Release Checklist | 1-2 days | @release, @tester |
| Before merge | PR Checklist | 0.5-2 hours | @reviewer |

---

**Last updated:** 2026-02-16
**Version:** 3.0 (includes advanced skills integration)
