# Release Workflow

This workflow guides the process of creating and deploying a production release.

## Pre-Release Checklist

### 1. Code Freeze
- [ ] All planned features merged
- [ ] All critical bugs fixed
- [ ] No open P0/P1 issues
- [ ] Feature flags configured
- [ ] Release branch created

### 2. Testing
- [ ] All unit tests passing
- [ ] All integration tests passing
- [ ] All e2e tests passing
- [ ] Smoke tests on staging
- [ ] Performance tests completed
- [ ] Security scan clean
- [ ] Load testing (if applicable)

### 3. Documentation
- [ ] CHANGELOG.md updated
- [ ] API documentation updated
- [ ] README updated (if needed)
- [ ] Migration guides written (if breaking changes)
- [ ] Release notes drafted

### 4. Dependencies
- [ ] Dependencies updated (security patches)
- [ ] Audit clean (`npm audit`)
- [ ] License compliance verified
- [ ] No deprecated packages

### 5. Infrastructure
- [ ] Database migrations tested
- [ ] Rollback plan documented
- [ ] Monitoring alerts configured
- [ ] Feature flags ready
- [ ] Canary deployment config (if applicable)

## Release Process

### Step 1: Create Release Branch

```bash
# Create release branch from main
git checkout main
git pull origin main
git checkout -b release/v1.2.0

# Update version number
npm version 1.2.0

# Push release branch
git push origin release/v1.2.0
```

### Step 2: Run Final Tests

```bash
# Full test suite
npm run test:all

# Build and verify
npm run build

# Security audit
npm audit
npm run test:security

# Performance benchmarks
npm run benchmark
```

### Step 3: Update Release Assets

**CHANGELOG.md:**
```markdown
# Changelog

## [1.2.0] - 2026-02-13

### Added
- User profile editing functionality
- Advanced search filters
- Email notification preferences

### Changed
- Improved API response times by 40%
- Updated authentication flow

### Fixed
- Fixed race condition in order processing
- Resolved memory leak in background jobs

### Security
- Updated dependencies with security patches
- Implemented rate limiting on auth endpoints

### Breaking Changes
None

### Migration Notes
- No migrations required
- Backwards compatible with 1.1.x
```

**Release Notes:**
```markdown
# Release v1.2.0

## Highlights
🎉 User profile editing
⚡ 40% faster API responses
🔒 Enhanced security measures

## What's New
- Users can now edit their profiles...
- Advanced search with new filters...

## Improvements
- Significant performance optimizations
- Better error messages

## Bug Fixes
- Fixed order processing race condition
- Resolved memory leak

## Security Updates
- Updated to latest dependencies
- New rate limiting on authentication

## Upgrade Guide
This release is fully backwards compatible with 1.1.x

## Thank You
Thanks to @contributor1, @contributor2 for their contributions!
```

### Step 4: Create Release PR

```bash
gh pr create \
  --base main \
  --head release/v1.2.0 \
  --title "Release v1.2.0" \
  --body "$(cat <<'EOF'
## Release v1.2.0

### Pre-Release Checklist
- [x] All features merged
- [x] All tests passing
- [x] Security audit clean
- [x] Documentation updated
- [x] CHANGELOG updated
- [x] Staging deployment successful

### Changes
See CHANGELOG.md for detailed changes.

### Migration Required
No

### Rollback Plan
Documented in docs/runbooks/rollback.md

### Deployment Plan
1. Deploy to canary (5% traffic)
2. Monitor for 30 minutes
3. Deploy to 50% traffic
4. Monitor for 1 hour
5. Full deployment

### Approvals Required
- [ ] Tech Lead
- [ ] Product Manager
- [ ] Security Team (if security changes)

### Post-Deployment
- [ ] Smoke tests in production
- [ ] Monitor error rates
- [ ] Check performance metrics
- [ ] Verify feature flags
EOF
)"
```

### Step 5: Deploy to Staging

```bash
# Deploy to staging environment
npm run deploy:staging

# Wait for deployment
gh run watch

# Run smoke tests
npm run test:smoke -- --env=staging
```

**Staging Validation:**
- [ ] Application starts successfully
- [ ] Health checks passing
- [ ] Critical user flows working
- [ ] Database migrations applied
- [ ] No errors in logs

### Step 6: Get Approvals

**Required Approvals:**
1. **Tech Lead**: Code review, architecture
2. **Product Manager**: Features match requirements
3. **Security**: (if security-sensitive changes)
4. **DBA**: (if database migrations)

### Step 7: Tag Release

```bash
# After PR approved and merged
git checkout main
git pull origin main

# Create annotated tag
git tag -a v1.2.0 -m "Release version 1.2.0

- User profile editing
- Performance improvements
- Security updates

See CHANGELOG.md for full details."

# Push tag
git push origin v1.2.0
```

### Step 8: Deploy to Production

**Gradual Rollout Strategy:**

```bash
# 1. Canary Deployment (5% traffic)
npm run deploy:canary

# Monitor for 30 minutes
# Check: error rates, response times, resource usage
```

**Monitoring Checklist:**
- [ ] Error rate < 0.1%
- [ ] Response time p95 < 500ms
- [ ] CPU usage < 70%
- [ ] Memory usage stable
- [ ] No unusual logs

```bash
# 2. If canary healthy: 50% traffic
npm run deploy:production -- --percentage=50

# Monitor for 1 hour
```

```bash
# 3. If still healthy: Full deployment
npm run deploy:production -- --percentage=100
```

### Step 9: Post-Deployment Validation

**Immediate Checks (0-15 min):**
- [ ] Application responding
- [ ] Health endpoints green
- [ ] No 5xx errors
- [ ] Critical flows working
- [ ] Database responsive

**Short-term Monitoring (1-24 hours):**
- [ ] Error rates normal
- [ ] Performance metrics good
- [ ] No memory leaks
- [ ] Resource usage acceptable
- [ ] User metrics stable

**Smoke Tests:**
```bash
npm run test:smoke -- --env=production
```

### Step 10: Communicate Release

**Internal Communication:**
```
Subject: ✅ v1.2.0 Deployed to Production

The v1.2.0 release has been successfully deployed to production.

Key Changes:
- User profile editing now live
- 40% performance improvement on API calls
- Security enhancements

Monitoring:
- All metrics healthy
- No errors detected

Rollback:
Available if needed: npm run rollback:v1.1.9

Questions? #engineering-releases
```

**External Communication:**
- [ ] Release notes published
- [ ] Status page updated
- [ ] Customers notified (if needed)
- [ ] Social media announcement (if major)

## Rollback Procedure

If issues detected:

### Quick Rollback
```bash
# Rollback to previous version
npm run rollback:v1.1.9

# Verify rollback successful
npm run test:smoke -- --env=production

# Communicate
# Post in #incidents: "Rolling back v1.2.0 due to [issue]"
```

### Rollback Checklist
- [ ] Traffic redirected to previous version
- [ ] Database migrations rolled back (if needed)
- [ ] Feature flags disabled
- [ ] Monitoring confirms stability
- [ ] Team notified
- [ ] Incident post-mortem scheduled

## Common Issues

### Database Migration Fails
```
Problem: Migration fails during deployment
Solution:
1. Pause deployment
2. Investigate migration error
3. Fix migration or rollback
4. Test fix on staging
5. Resume deployment
```

### Performance Degradation
```
Problem: Response times increased after deployment
Solution:
1. Check metrics (CPU, memory, database)
2. Review recent code changes
3. Enable feature flags to disable new features
4. Rollback if critical
5. Investigate and fix offline
```

### Increased Error Rate
```
Problem: Error rate above threshold
Solution:
1. Check error logs for patterns
2. Identify affected endpoints
3. Disable via feature flags if possible
4. Rollback if widespread
5. Debug in staging environment
```

## Release Cadence

### Regular Releases
- **Weekly**: Minor releases, bug fixes
- **Monthly**: Feature releases
- **Quarterly**: Major versions

### Hotfix Releases
For critical bugs or security issues:

```bash
# Create hotfix branch from production
git checkout v1.2.0
git checkout -b hotfix/security-patch

# Fix and test
# ... make changes ...
npm test

# Version bump (patch)
npm version patch # v1.2.1

# Deploy directly
npm run deploy:production

# Merge back to main
git checkout main
git merge hotfix/security-patch
```

## Metrics to Track

### Deployment Metrics
- Deployment frequency
- Lead time (code to production)
- Change failure rate
- Mean time to recovery (MTTR)

### Release Quality
- Bugs found post-release
- Rollback frequency
- Customer complaints
- Performance regressions

## Automation

### GitHub Actions Release Workflow
```yaml
# .github/workflows/release.yml
name: Release
on:
  push:
    tags:
      - 'v*'
jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - run: npm ci
      - run: npm test
      - run: npm run build
      - uses: actions/create-release@v1
        with:
          tag_name: ${{ github.ref }}
          release_name: Release ${{ github.ref }}
          body_path: CHANGELOG.md
```

This workflow ensures safe, reliable production releases with minimal downtime and maximum confidence.
