# Hotfix Workflow

Emergency patch process for critical production issues that require immediate fixes.

## When to Use Hotfix Workflow

Hotfixes are for **CRITICAL** issues that require immediate production deployment:

✅ **Use hotfix for:**
- Security vulnerabilities (CVE, data exposure)
- Data corruption or loss
- Critical API endpoints down
- Payment processing failures
- Authentication/authorization failures
- Performance degradation affecting all users
- Certificate expiration

❌ **Don't use hotfix for:**
- Minor bugs
- Feature requests
- Non-critical performance issues
- Cosmetic issues
- Issues affecting < 5% of users

**Rule**: If it can wait until the next release, it's not a hotfix.

---

## Severity Classification

### CRITICAL (P0) - Immediate Hotfix Required
- System down or completely unavailable
- Data loss or corruption
- Security breach or vulnerability
- Payment processing failures
- **SLA**: Fix within 1-4 hours

### HIGH (P1) - Urgent Hotfix
- Major feature broken for all users
- Performance degraded > 50%
- Authentication issues
- **SLA**: Fix within 4-24 hours

### MEDIUM (P2) - Can Wait for Next Release
- Feature broken for subset of users
- Workaround available
- Non-critical API degradation
- **SLA**: Fix in next scheduled release

---

## Hotfix Workflow Steps

### Phase 1: Assessment (5-15 minutes)

#### 1. Declare Incident

```bash
# In #incidents channel or equivalent
🚨 CRITICAL INCIDENT: [Brief description]
Severity: P0/P1
Impact: [Users affected, revenue impact]
Started: [Timestamp]
Incident Commander: @your-name
```

#### 2. Quick Assessment

- [ ] Confirm it's truly critical
- [ ] Estimate users/revenue affected
- [ ] Check if rollback is faster than hotfix
- [ ] Identify which component is affected
- [ ] Determine root cause (if obvious)

#### 3. Communication

- [ ] Notify stakeholders (product, support, leadership)
- [ ] Update status page if customer-facing
- [ ] Create war room (Slack channel, Zoom call)

---

### Phase 2: Preparation (10-20 minutes)

#### 1. Create Hotfix Branch

```bash
# Get latest production tag
git fetch --tags

# Find current production version
git tag --sort=-version:refname | head -n 1
# Example output: v1.2.3

# Create hotfix branch from production tag
git checkout -b hotfix/security-patch v1.2.3

# Or for emergency from current production
git checkout -b hotfix/fix-payment-failure $(git describe --tags --abbrev=0)
```

#### 2. Create Minimal Spec

**Keep it ultra-focused** - hotfixes should be surgical

```bash
# Create hotfix spec
@planner Create emergency hotfix spec for [critical issue]

# Spec should include ONLY:
# - Problem statement
# - Minimal fix approach
# - Verification steps
# - Rollback plan
```

**Hotfix Spec Template:**
```markdown
# HOTFIX: [Issue Name]

## Severity: P0/P1

## Problem
[One sentence: What's broken]

## Impact
- Users affected: [number or percentage]
- Revenue impact: [if applicable]
- Duration: [how long has this been happening]

## Root Cause
[If known; skip if not immediately obvious]

## Minimal Fix
[Smallest possible change to resolve issue]

## Files to Change
- [file1.ts] - [specific change]
- [file2.ts] - [specific change]

## Verification
1. [How to verify fix works]
2. [Test this specific scenario]

## Rollback Plan
[How to revert if hotfix makes things worse]

## Post-Fix Actions
- [ ] Create follow-up ticket for permanent fix
- [ ] Update monitoring/alerts
- [ ] Post-mortem scheduled
```

---

### Phase 3: Implementation (20-60 minutes)

#### 1. Implement Fix

```bash
# Use builder agent with STRICT scope
@builder Implement ONLY the hotfix from specs/hotfix-[issue].md

# Builder will:
# - Make minimal changes
# - Update only affected tests
# - Run fast validation
```

**Hotfix Rules:**
- ✅ Fix ONE thing only
- ✅ Minimal code changes
- ✅ No refactoring
- ✅ No "while we're here" improvements
- ❌ No feature additions
- ❌ No dependency updates (unless that's the fix)
- ❌ No formatting/linting changes

#### 2. Test Locally

```bash
# Run ONLY tests related to the fix
npm run test:unit -- [affected-test-file]

# Quick smoke test
npm run test:smoke

# If web app, test manually in local environment
```

#### 3. Code Review (Fast Track)

```bash
# Create hotfix PR
git add .
git commit -m "hotfix: [brief description]

Fixes [issue link]
Severity: P0/P1

Changes:
- [specific change 1]
- [specific change 2]

Tested:
- [test 1]
- [test 2]

Rollback: git revert [commit-sha]"

git push origin hotfix/[issue-name]

# Create PR
gh pr create \
  --title "HOTFIX: [issue name]" \
  --label "hotfix,priority:critical" \
  --base main \
  --body "[Link to incident] - Emergency fix for [issue]"
```

**Fast-Track Review:**
- Tech lead review ONLY (skip normal reviewers)
- Focus on: Does this fix the issue? Will it break anything?
- Review time limit: 10 minutes max
- Security review if touching auth/payments/secrets

---

### Phase 4: Deployment (15-30 minutes)

#### 1. Deploy to Staging First

```bash
# Even for hotfixes, test in staging
npm run deploy:staging

# Quick smoke test in staging
curl https://staging.yourapp.com/health
# Test the specific fix
```

**Staging Verification (5 min max):**
- [ ] Application starts
- [ ] Health check passes
- [ ] Fixed functionality works
- [ ] No errors in logs

#### 2. Deploy to Production

```bash
# Create release tag
git tag -a v1.2.4-hotfix.1 -m "Hotfix: [issue]"
git push origin v1.2.4-hotfix.1

# Deploy (use your deployment method)
npm run deploy:production

# Or gradual rollout if available
npm run deploy:production --canary=10  # 10% traffic
# Monitor for 5 minutes
npm run deploy:production --percentage=100  # Full rollout
```

#### 3. Monitor Closely

**First 15 minutes (actively watch):**
- [ ] Error rate < 0.1%
- [ ] Response time normal
- [ ] No new errors in logs
- [ ] Specific issue is resolved
- [ ] CPU/memory usage normal

**First hour (periodic checks):**
- Check every 10 minutes
- Monitor dashboard
- Watch for secondary issues

---

### Phase 5: Verification & Communication (15 minutes)

#### 1. Verify Fix

```bash
# Test the exact scenario that was broken
# Example: If login was broken
curl -X POST https://api.yourapp.com/login \
  -d '{"email":"test@example.com","password":"test"}'

# Should return 200, not 500
```

- [ ] Original issue is resolved
- [ ] No regression in related features
- [ ] Metrics returned to normal
- [ ] No new errors introduced

#### 2. Update Stakeholders

```bash
# In #incidents channel
✅ HOTFIX DEPLOYED: [issue]
Version: v1.2.4-hotfix.1
Deployed: [timestamp]
Verification: [passed/monitoring]
Next: Post-mortem scheduled for [date/time]
```

#### 3. Update Status Page

- Mark incident as resolved
- Add timeline of events
- Thank users for patience

---

### Phase 6: Post-Hotfix Actions (Within 24 hours)

#### 1. Back-Merge to Main

```bash
# Merge hotfix back to main branch
git checkout main
git pull origin main
git merge hotfix/[issue-name]
git push origin main

# Delete hotfix branch
git branch -d hotfix/[issue-name]
git push origin --delete hotfix/[issue-name]
```

#### 2. Create Follow-Up Tickets

- [ ] **Root cause analysis** - Why did this happen?
- [ ] **Permanent fix** - Is the hotfix temporary?
- [ ] **Testing gap** - Why didn't tests catch this?
- [ ] **Monitoring improvement** - How to detect earlier?
- [ ] **Process improvement** - How to prevent?

#### 3. Schedule Post-Mortem

**Post-Mortem Meeting (within 48 hours):**
- Timeline of events
- Root cause analysis
- What went well
- What could be improved
- Action items

**Post-Mortem Template:**
```markdown
# Post-Mortem: [Issue Name]

## Summary
- Incident start: [time]
- Detection: [how we found out]
- Resolution: [time]
- Total duration: [duration]
- Users affected: [number]

## Timeline
- [time] - Issue began
- [time] - Alert fired / reported
- [time] - Incident declared
- [time] - Root cause identified
- [time] - Hotfix deployed
- [time] - Verified fixed

## Root Cause
[Technical explanation]

## Resolution
[What we did to fix it]

## What Went Well
- Fast detection (or not)
- Clear communication
- Quick deployment

## What Could Be Improved
- Earlier detection needed
- Better monitoring
- Testing gaps

## Action Items
- [ ] Add monitoring for [metric]
- [ ] Add test for [scenario]
- [ ] Update runbook
- [ ] Improve [process]
```

---

## Hotfix Checklist

### Pre-Deployment
- [ ] Severity correctly assessed (P0/P1)
- [ ] Incident declared in #incidents
- [ ] Stakeholders notified
- [ ] Hotfix branch created from production tag
- [ ] Minimal spec created
- [ ] Fix implemented (minimal changes only)
- [ ] Tests pass
- [ ] Code reviewed (fast-track)
- [ ] Deployed to staging
- [ ] Staging verification passed

### Deployment
- [ ] Production deployment initiated
- [ ] Deployment successful
- [ ] Health checks passing
- [ ] No new errors in logs
- [ ] Original issue resolved

### Post-Deployment
- [ ] Monitoring for 1 hour
- [ ] Stakeholders updated
- [ ] Status page updated
- [ ] Hotfix back-merged to main
- [ ] Follow-up tickets created
- [ ] Post-mortem scheduled
- [ ] Runbooks updated

---

## Common Hotfix Scenarios

### Scenario 1: Security Vulnerability

```bash
# 1. Assess severity
@security Review the vulnerability report

# 2. Create emergency patch
git checkout -b hotfix/security-cve-2024-xxxxx v1.2.3

# 3. Minimal fix
@builder Apply security patch from spec

# 4. Fast deployment
# Deploy immediately after review
```

**Timeline**: 1-4 hours

---

### Scenario 2: Database Corruption

```bash
# 1. STOP writes immediately
# Consider read-only mode

# 2. Assess data loss
@debug Analyze extent of data corruption

# 3. Restore from backup if needed
# OR apply data fix script

# 4. Deploy application fix to prevent recurrence
```

**Timeline**: 2-6 hours

---

### Scenario 3: API Endpoint Down

```bash
# 1. Identify failing endpoint
# Check logs, monitoring

# 2. Quick fix or rollback?
# If recent deploy caused it → rollback faster

# 3. If hotfix needed
@builder Fix the specific endpoint issue

# 4. Deploy with canary rollout
# 10% → monitor → 100%
```

**Timeline**: 1-2 hours

---

### Scenario 4: Performance Degradation

```bash
# 1. Identify bottleneck
@performance Profile the slow component

# 2. Quick optimization
# Add caching, index, or rate limiting

# 3. Deploy with monitoring
# Watch CPU, memory, response times

# 4. Longer-term optimization in follow-up
```

**Timeline**: 2-4 hours

---

### Scenario 5: Payment Processing Failure

```bash
# 1. CRITICAL - affects revenue
# Highest priority

# 2. Identify issue
# Stripe/PayPal integration? Database? Logic?

# 3. Fix with extreme care
@security Review any payment code changes

# 4. Test thoroughly in staging
# Process test transactions

# 5. Deploy with 100% verification
```

**Timeline**: 1-3 hours

---

## Rollback Procedure

If the hotfix makes things worse:

```bash
# 1. Immediate rollback
git revert [hotfix-commit-sha]
git push origin main

# OR revert to previous tag
git checkout v1.2.3
npm run deploy:production

# 2. Notify team
"Hotfix rolled back - investigating alternative fix"

# 3. Reassess approach
# Maybe the fix wasn't minimal enough
# Maybe root cause was misunderstood
```

---

## Hotfix vs. Regular Release

| Aspect | Hotfix | Regular Release |
|--------|--------|-----------------|
| Scope | ONE critical issue | Multiple features/fixes |
| Timeline | Hours | Days/weeks |
| Testing | Minimal (affected area) | Comprehensive |
| Review | Fast-track (1 reviewer) | Full team review |
| Branch | From production tag | From main |
| Documentation | Minimal spec | Full spec |
| Deployment | Immediate | Scheduled |
| Risk | High (speed > safety) | Low (safety > speed) |

---

## Best Practices

### ✅ DO

1. Keep changes minimal
2. Test the exact failing scenario
3. Deploy to staging first (even if brief)
4. Monitor closely for 1 hour post-deploy
5. Create follow-up tickets
6. Schedule post-mortem
7. Back-merge to main immediately

### ❌ DON'T

1. Bundle multiple fixes
2. Refactor code
3. Update dependencies (unless that's the fix)
4. Skip code review
5. Deploy without staging test
6. Skip post-mortem
7. Leave hotfix branch unmerged

---

##Emergency Contacts

- **On-Call Engineer**: [contact]
- **Tech Lead**: [contact]
- **DevOps/Infrastructure**: [contact]
- **Security Team**: [contact]
- **Product Manager**: [contact]

---

## Tools & Resources

- **Monitoring**: [your monitoring tool]
- **Logs**: [your logging tool]
- **Status Page**: [your status page]
- **Incident Channel**: #incidents
- **Runbooks**: [location]

**Remember**: Hotfixes are for emergencies only. Speed is important, but don't skip critical safety checks like code review and staging deployment.
