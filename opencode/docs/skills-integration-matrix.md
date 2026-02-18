# Skills Integration Matrix

## Overview

This matrix shows how OpenCode's 11 specialized skills integrate with agents, support different languages, and work within CI/CD pipelines. Use this guide to understand which skills to invoke for specific tasks and how they complement each other.

---

## Skill-Agent Compatibility Matrix

| Skill | Primary Agents | Secondary Agents | Use Case | Invoke When |
|-------|----------------|------------------|----------|-------------|
| **code-quality** | @builder, @reviewer | @planner, @refactor | Linting, formatting, type checking | Before commits, during PR review |
| **run-tests** | @tester | @builder, @reviewer | Unit, integration, e2e testing | After code changes, before merge |
| **coverage-analyzer** | @tester, @reviewer | @builder | Code coverage tracking (80% threshold) | After test runs, in CI/CD |
| **dependency-check** | @builder, @security | @reviewer | Security audits, license compliance | Daily, on PRs, pre-deployment |
| **performance-profiler** | @performance | @builder, @refactor | CPU/memory profiling, benchmarking | On PRs, before releases |
| **mutation-tester** | @tester | @reviewer | Test quality validation (mutation score) | Weekly, on critical modules |
| **api-validator** | @builder, @reviewer | @tester, @security | OpenAPI/GraphQL spec validation | After API changes, pre-release |
| **db-migrator** | @migration | @builder, @reviewer | Database schema migrations | Before deployment, with rollback plan |
| **release-notes** | @release | @documentation | Changelog generation from commits | Before releases, version bumps |
| **security-scanner** | @security | @builder, @reviewer | OWASP checks, secret detection | On every PR, pre-deployment |
| **ai-code-review** | @reviewer | @security, @performance | AI-powered code analysis | Final PR review, complex changes |

---

## Language & Framework Support

| Skill | JavaScript/TypeScript | Python | Go | Rust | Other |
|-------|----------------------|--------|-----|------|-------|
| **code-quality** | ✅ ESLint, Prettier, TSC | ✅ Pylint, Black, Mypy | ✅ golangci-lint | ✅ Clippy, rustfmt | ⚠️ Generic linters |
| **run-tests** | ✅ Jest, Mocha, Vitest | ✅ pytest, unittest | ✅ Go testing | ✅ Cargo test | ✅ Language-agnostic |
| **coverage-analyzer** | ✅ NYC, Istanbul, c8 | ✅ Coverage.py | ✅ go test -cover | ✅ Tarpaulin | ⚠️ Manual config |
| **dependency-check** | ✅ npm audit, Snyk | ✅ Safety, pip-audit | ✅ Nancy, govulncheck | ✅ Cargo audit | ✅ Generic SBOM |
| **performance-profiler** | ✅ Clinic.js, 0x | ✅ cProfile, py-spy | ✅ pprof | ✅ perf, flamegraph | ⚠️ Manual tools |
| **mutation-tester** | ✅ Stryker | ✅ Mutmut, Cosmic Ray | ❌ Limited support | ❌ Limited support | ❌ Experimental |
| **api-validator** | ✅ Dredd, Postman | ✅ Dredd, Schemathesis | ✅ Dredd, Prism | ✅ Dredd | ✅ OpenAPI standard |
| **db-migrator** | ✅ Knex, Sequelize, Prisma | ✅ Alembic, Django | ✅ golang-migrate | ✅ Diesel | ⚠️ Framework-specific |
| **release-notes** | ✅ All | ✅ All | ✅ All | ✅ All | ✅ Git-based |
| **security-scanner** | ✅ Snyk, npm audit | ✅ Bandit, Safety | ✅ gosec | ✅ cargo-audit | ✅ Language-agnostic |
| **ai-code-review** | ✅ All | ✅ All | ✅ All | ✅ All | ✅ Language-agnostic |

**Legend:**
- ✅ Full support with recommended tools
- ⚠️ Partial support, may require configuration
- ❌ Limited/experimental support

---

## CI/CD Platform Integration

| Skill | GitHub Actions | GitLab CI | CircleCI | Status | Config File |
|-------|----------------|-----------|----------|--------|-------------|
| **code-quality** | ✅ Integrated | ✅ Integrated | ✅ Integrated | Production | `eslint.config.js` |
| **run-tests** | ✅ Integrated | ✅ Integrated | ✅ Integrated | Production | `jest.config.js` |
| **coverage-analyzer** | ✅ Integrated | ✅ Integrated | ✅ Integrated | Production | `.nycrc.json` |
| **dependency-check** | ✅ Integrated | ✅ Integrated | ✅ Integrated | Production | `audit-config.json` |
| **performance-profiler** | ✅ Integrated | ✅ Integrated | ✅ Integrated | ⭐ New in v3 | `clinic.config.js` |
| **mutation-tester** | ✅ Integrated | ✅ Integrated | ✅ Integrated | ⭐ New in v3 | `stryker.config.json` |
| **api-validator** | ⚠️ Manual setup | ⚠️ Manual setup | ⚠️ Manual setup | Manual | `dredd.yml` |
| **db-migrator** | ⚠️ Deploy stage | ⚠️ Deploy stage | ⚠️ Deploy stage | Manual | Framework-specific |
| **release-notes** | ✅ Release workflow | ✅ Release workflow | ✅ Release workflow | Production | N/A |
| **security-scanner** | ✅ Integrated | ✅ Integrated | ✅ Integrated | Production | N/A |
| **ai-code-review** | ⚠️ Manual trigger | ⚠️ Manual trigger | ⚠️ Manual trigger | Manual | N/A |

**Status Legend:**
- ✅ Integrated: Automatically runs in CI/CD pipelines
- ⚠️ Manual: Requires explicit configuration or trigger
- ⭐ New: Recently added advanced feature

---

## Skill Workflows & Pipelines

### 1. Code Quality Pipeline
**Sequence:** code-quality → run-tests → coverage-analyzer → mutation-tester

**When to use:** Every PR, before merge

**Agents involved:** @builder → @tester → @reviewer

**Expected outcome:**
- ✅ No linting errors (ESLint, Prettier, TSC pass)
- ✅ All tests pass
- ✅ Coverage ≥80%
- ✅ Mutation score ≥70%

**Example:**
```bash
# 1. Code quality checks
npx eslint src/ --fix
npx prettier --write src/
npx tsc --noEmit

# 2. Run tests with coverage
npm test -- --coverage

# 3. Check coverage threshold
# Automatically enforced by jest.config.js (80%)

# 4. Mutation testing (optional, resource-intensive)
npx stryker run
```

---

### 2. Security Pipeline
**Sequence:** dependency-check → security-scanner → (api-validator for APIs)

**When to use:** Daily scans, every PR, pre-deployment

**Agents involved:** @security → @reviewer

**Expected outcome:**
- ✅ No critical/high vulnerabilities
- ✅ All licenses compliant
- ✅ No secrets in code
- ✅ API contracts secure (if applicable)

**Example:**
```bash
# 1. Dependency audit
npm audit --audit-level=moderate
npx audit-ci --moderate

# 2. Security scanning
npx eslint src/ --plugin security
# Manual: Snyk, CodeQL, Semgrep

# 3. API validation (if API project)
npx dredd openapi.yaml http://localhost:3000
```

---

### 3. Performance Pipeline
**Sequence:** performance-profiler → code-quality → run-tests

**When to use:** On PRs affecting critical paths, before releases

**Agents involved:** @performance → @refactor → @tester

**Expected outcome:**
- ✅ No performance regression (within 10% of baseline)
- ✅ No memory leaks
- ✅ Optimized code meets quality standards

**Example:**
```bash
# 1. Baseline benchmark
npx autocannon -c 100 -d 30 http://localhost:3000 > baseline.txt

# 2. CPU profiling
npx clinic doctor -- node server.js

# 3. Flamegraph generation
npx clinic flame -- node server.js

# 4. Compare results
# Check for: wide bars (hotspots), heavy I/O, event loop delays
```

---

### 4. Release Pipeline
**Sequence:** (all quality checks) → db-migrator → release-notes → deploy

**When to use:** Before every production deployment

**Agents involved:** @planner → @builder → @tester → @security → @migration → @release

**Expected outcome:**
- ✅ All quality gates passed
- ✅ Database migrations tested (with rollback)
- ✅ Changelog generated
- ✅ Version bumped

**Example:**
```bash
# 1. Run full quality pipeline
npm run lint && npm test && npm run build

# 2. Database migration (if needed)
npx knex migrate:latest --env=staging
# Test rollback: npx knex migrate:rollback

# 3. Generate release notes
npx conventional-changelog -p angular -i CHANGELOG.md -s

# 4. Deploy
# Staging → Production (with canary)
```

---

## Skill Combinations & Advanced Workflows

### Scenario 1: New Feature Implementation
**Skills:** code-quality + run-tests + api-validator (if API feature)

**Workflow:**
1. @planner: Create spec with acceptance criteria
2. @builder: Implement feature, invoke `code-quality` skill
3. @tester: Write tests, invoke `run-tests` and `coverage-analyzer`
4. @reviewer: Invoke `ai-code-review` for final check

---

### Scenario 2: Performance Optimization
**Skills:** performance-profiler + mutation-tester + coverage-analyzer

**Workflow:**
1. @performance: Invoke `performance-profiler`, identify bottlenecks
2. @refactor: Optimize code (e.g., add indexes, cache, parallelize)
3. @tester: Invoke `mutation-tester` to ensure test quality maintained
4. @performance: Re-profile, compare results (expect 20-50% improvement)

---

### Scenario 3: Security Audit
**Skills:** dependency-check + security-scanner + api-validator

**Workflow:**
1. @security: Invoke `dependency-check`, fix vulnerabilities
2. @security: Invoke `security-scanner`, check for OWASP issues
3. @security: Invoke `api-validator`, verify OAuth2/CORS configs
4. @reviewer: Final review, create security report

---

### Scenario 4: Database Migration
**Skills:** db-migrator + run-tests + performance-profiler

**Workflow:**
1. @migration: Design migration, invoke `db-migrator`
2. @tester: Test migration on staging, invoke `run-tests`
3. @performance: Benchmark migration duration, invoke `performance-profiler`
4. @migration: Execute zero-downtime deployment (4-phase rollout)

---

### Scenario 5: Release Preparation
**Skills:** ALL (comprehensive quality gate)

**Workflow:**
1. @release: Invoke `code-quality` (final lint check)
2. @release: Invoke `run-tests` + `coverage-analyzer` (ensure 80%+)
3. @release: Invoke `dependency-check` (no vulnerabilities)
4. @release: Invoke `security-scanner` (OWASP compliance)
5. @release: Invoke `performance-profiler` (regression check)
6. @release: Invoke `mutation-tester` (test quality validation)
7. @release: Invoke `release-notes` (generate changelog)
8. @release: Deploy to staging → canary → production

---

## Configuration Files Quick Reference

All skills have production-ready configuration templates in `skills/*/config/`:

| Skill | Config File | Key Settings | Location |
|-------|-------------|--------------|----------|
| code-quality | `eslint.config.js` | Max complexity: 15, security rules | `skills/code-quality/config/` |
| code-quality | `prettier.config.js` | Single quotes, 2 spaces, 100 line width | `skills/code-quality/config/` |
| code-quality | `tsconfig.json` | Strict mode, ES2022, path mappings | `skills/code-quality/config/` |
| coverage-analyzer | `jest.config.js` | 80% threshold, ts-jest, reporters | `skills/coverage-analyzer/config/` |
| coverage-analyzer | `.nycrc.json` | 80% threshold, NYC reporters | `skills/coverage-analyzer/config/` |
| dependency-check | `audit-config.json` | Moderate threshold, allowlist, blocklist | `skills/dependency-check/config/` |
| mutation-tester | `stryker.config.json` | 70% threshold, Jest runner, reporters | `skills/mutation-tester/config/` |

**Usage:**
```bash
# Copy template to your project
cp ~/.config/opencode/skills/code-quality/config/eslint.config.js .

# Customize as needed
# Templates include inline comments explaining all options
```

---

## Performance Considerations

### Resource Usage by Skill

| Skill | CPU | Memory | Duration | Best Run |
|-------|-----|--------|----------|----------|
| code-quality | Low | Low | 5-30s | Every commit |
| run-tests | Medium | Medium | 30s-5min | Every commit |
| coverage-analyzer | Medium | Medium | 1-5min | Every PR |
| dependency-check | Low | Low | 10-60s | Daily, PRs |
| performance-profiler | High | High | 5-15min | Weekly, PRs |
| mutation-tester | Very High | High | 10-60min | Weekly, critical modules |
| api-validator | Low | Low | 1-5min | API changes |
| db-migrator | Medium | Medium | Varies | Deployments only |
| release-notes | Low | Low | <10s | Releases only |
| security-scanner | Medium | Medium | 2-10min | Daily, PRs |
| ai-code-review | Low | Low | 1-5min | Final review |

**Optimization Tips:**
- Run `mutation-tester` on changed files only (not full codebase)
- Cache `node_modules` in CI/CD (saves 1-2 min per run)
- Run `performance-profiler` on PRs only, not every commit
- Use parallel test execution (`jest --maxWorkers=4`)

---

## Troubleshooting Guide

### Common Integration Issues

**Issue:** "Skill not found" error
- **Cause:** Skill path not in OpenCode config
- **Fix:** Check `~/.config/opencode/opencode.json` includes skill directory

**Issue:** Coverage below threshold but tests pass
- **Cause:** Missing test cases for edge cases
- **Fix:** Invoke `mutation-tester` to find weak tests, add missing cases

**Issue:** Performance profiler shows no hotspots
- **Cause:** Need longer benchmark duration or higher concurrency
- **Fix:** Increase autocannon duration (`-d 60`) and connections (`-c 200`)

**Issue:** API validator fails with 404 errors
- **Cause:** Server not started or wrong port
- **Fix:** Start server in background before running Dredd (`npm start &`)

**Issue:** Mutation testing times out
- **Cause:** Too many mutants, slow tests
- **Fix:** Reduce scope (`mutate: ["src/critical/**/*.ts"]`), increase timeout

**Issue:** Dependency check fails on allowlisted vulnerability
- **Cause:** Allowlist not configured in `audit-config.json`
- **Fix:** Add advisory ID to `allowlist.advisories[]` with justification

---

## Version History

**v3.0** (Current)
- ✅ Added `performance-profiler` to CI/CD pipelines (GitHub Actions, GitLab CI, CircleCI)
- ✅ Added `mutation-tester` to CI/CD pipelines
- ✅ Expanded skill documentation (performance-profiler: 692 lines, api-validator: 737 lines)
- ✅ Created 7 production-ready configuration templates

**v2.0**
- Added 4 advanced skills (performance-profiler, mutation-tester, api-validator, ai-code-review)
- Integrated security-scanner with OWASP checks

**v1.0**
- Initial release with 7 essential skills
- GitHub Actions CI/CD template

---

## Related Documentation

- **[Workflow Guide](./workflow-guide.md)** - Decision tree for selecting workflows
- **[Agent Integration Points](./agent-integration-points.md)** - How agents communicate
- **[CI/CD Templates](../ci-templates/)** - Platform-specific configurations
- **[Skills Documentation](../skills/)** - Detailed skill usage guides

---

## Quick Start Examples

### Example 1: Full Quality Check Before PR
```bash
# Run complete quality pipeline
@tester

# Skills invoked automatically:
# 1. code-quality (lint, format, type check)
# 2. run-tests (with coverage)
# 3. coverage-analyzer (enforce 80%)

# Optional: Add mutation testing
@tester Use mutation-tester skill on src/services/payment.ts
```

### Example 2: Performance Regression Check
```bash
# Before optimization
@performance Use performance-profiler skill, benchmark dashboard endpoint

# After optimization
@performance Re-run performance-profiler, compare with baseline

# Expected output:
# Baseline: 2847ms
# Current: 79ms
# Improvement: 36x faster ✅
```

### Example 3: Security Audit
```bash
# Comprehensive security check
@security Run complete security audit

# Skills invoked:
# 1. dependency-check (npm audit, Snyk)
# 2. security-scanner (OWASP, secret detection)
# 3. api-validator (OAuth2, CORS validation)

# Review report: reports/security-audit.md
```

---

## Support & Feedback

For issues or feature requests:
- GitHub: https://github.com/anthropics/claude-code/issues
- Documentation: `~/.config/opencode/docs/`
- Skills Directory: `~/.config/opencode/skills/`

Last updated: 2026-02-16
