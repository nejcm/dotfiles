# OpenCode CI/CD Integration Templates

**Ready-to-use CI/CD pipeline template with OpenCode validation and deployment.**

---

## Available Template

### GitHub Actions
**File:** `.github/workflows/opencode-ci.yml`

**Features:**
- OpenCode setup validation
- Code quality checks (ESLint, Prettier, TypeScript)
- Comprehensive testing with coverage
- Security scanning (npm audit, Snyk)
- Automated builds
- Canary deployments
- Cost analysis on PRs

**Setup:**
```bash
cp ci-templates/.github/workflows/opencode-ci.yml .github/workflows/
```

---

## Pipeline Stages

1. **Validate** — OpenCode setup validation, health checks, configuration verification
2. **Lint** — ESLint, Prettier, TypeScript type checking
3. **Test** — Unit tests, integration tests, coverage threshold (80%)
4. **Security** — npm audit, Snyk scanning, dependency vulnerability checks
5. **Build** — Application build, artifact creation
6. **Deploy** — Staging (auto on develop), Production (manual approval on main)

---

## Required Secrets

Add to GitHub: Settings → Secrets and variables → Actions → New repository secret

- `CODECOV_TOKEN` — Codecov integration
- `SNYK_TOKEN` — Snyk security scanning
- `SLACK_WEBHOOK` — Slack notifications (optional)

---

## Pipeline Workflow

**Feature branch:** `Push → Validate → Lint → Test → Security → Build`

**Develop branch:** `Merge → ... → Build → Deploy Staging → Smoke Tests`

**Main branch:** `Merge → ... → Build → [Manual Approval] → Canary Deploy → Monitor → Full Deploy`

---

## Related Documentation

- **OpenCode Scripts:** `../scripts/README.md`
- **Workflows:** `../workflows/`

*Last updated: 2026-02-17*
