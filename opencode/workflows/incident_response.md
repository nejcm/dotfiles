# Incident Response Workflow

Systematic process for handling production incidents and outages.

## What is an Incident?

An **incident** is any event that degrades or interrupts service quality:

- System outage or degradation
- Security breach or vulnerability
- Data loss or corruption
- Performance degradation
- Third-party service failures affecting users

**Key Difference from Hotfix:**
- **Hotfix**: The code fix itself
- **Incident Response**: The overall process of detecting, communicating, resolving, and learning from issues

---

## Incident Severity Levels

### P0 - CRITICAL
**Impact**: Complete service outage or severe degradation

**Examples**:
- Entire application down
- Database unavailable
- Payment processing completely broken
- Major security breach
- Data loss affecting multiple users

**Response**: Immediate
**SLA**: Resolve within 1-4 hours
**Escalation**: Page on-call immediately

---

### P1 - HIGH
**Impact**: Major feature broken, significant user impact

**Examples**:
- Critical API endpoint down
- Auth system degraded
- Performance degraded >50%
- Partial data corruption

**Response**: Urgent
**SLA**: Resolve within 4-24 hours
**Escalation**: Notify on-call within 15 minutes

---

### P2 - MEDIUM
**Impact**: Non-critical feature broken, workaround available

**Examples**:
- Secondary feature broken
- Performance degraded 10-50%
- Minor data inconsistency
- Single endpoint slow

**Response**: Schedule fix
**SLA**: Resolve within 1-3 days
**Escalation**: Standard process

---

### P3 - LOW
**Impact**: Minimal user impact, cosmetic issues

**Examples**:
- UI glitch
- Minor performance issue
- Non-critical log errors

**Response**: Next sprint
**SLA**: Resolve within 1-2 weeks
**Escalation**: None

---

## Incident Response Phases

### Phase 1: DETECT (0-5 minutes)

#### How Incidents are Detected

**Automated Monitoring**:
- Alert fires from monitoring system
- Health check fails
- Error rate spike
- Performance degradation

**User Reports**:
- Support tickets
- Social media mentions
- Direct customer complaints

**Team Discovery**:
- Engineer notices unusual behavior
- Failed deployment

#### Immediate Actions

```bash
# 1. Acknowledge the incident
# Click "acknowledge" in PagerDuty/monitoring tool

# 2. Quick assessment
# - What's broken?
# - How many users affected?
# - Is it getting worse?

# 3. Declare incident if severity ≥ P1
```

---

### Phase 2: DECLARE (5-10 minutes)

#### Incident Declaration

**Create Incident Channel**:
```bash
# In Slack (or your communication tool)
/incident create

# Or manually create channel:
#incident-2024-02-13-payment-failure
```

**Post Incident Declaration**:
```markdown
🚨 INCIDENT DECLARED

**Severity**: P0 / P1 / P2
**Title**: [Brief description]
**Started**: [HH:MM timezone]
**Affected**: [Users/features/services]
**Impact**: [Customer-facing description]

**Incident Commander**: @your-name
**Tech Lead**: @tech-lead
**Comms Lead**: @comms-person

**Status Page**: [Updated / Updating / Not needed]
**War Room**: [Zoom link if applicable]

**Next Update**: [Time]
```

#### Role Assignments

**Incident Commander (IC)**:
- Overall coordination
- Decision making authority
- Communication hub
- Runs the war room

**Tech Lead**:
- Technical investigation
- Assigns debugging tasks
- Reviews proposed fixes

**Communications Lead**:
- Updates status page
- Notifies stakeholders
- Manages customer communications

**Scribe**:
- Documents timeline
- Records decisions
- Takes notes for post-mortem

---

### Phase 3: TRIAGE (10-30 minutes)

#### Gather Information

```bash
# Check recent deployments
git log --oneline --since="2 hours ago"

# Check recent changes
gh pr list --state merged --limit 10

# Review error logs
# [your logging command]

# Check monitoring dashboards
# [your monitoring tool]
```

**Triage Questions**:
- [ ] What changed recently? (deploy, config, traffic spike)
- [ ] What's the error rate? (baseline vs. current)
- [ ] Which services/endpoints are affected?
- [ ] Are there any obvious patterns? (geography, user type, etc.)
- [ ] Can we isolate the issue? (specific feature, component)

#### Immediate Mitigation

**Quick Fixes (if obvious)**:
```bash
# Rollback recent deployment
git revert [commit-sha]
npm run deploy:production

# Disable problematic feature flag
# [feature flag command]

# Scale up resources
# [scaling command]

# Switch to backup service
# [failover command]
```

**Decision Tree**:
```
Is the cause obvious?
├─ YES → Apply quick fix → Monitor
└─ NO → Continue investigation

Is rollback safe and fast?
├─ YES → Rollback → Verify → Investigate offline
└─ NO → Continue troubleshooting
```

---

### Phase 4: INVESTIGATE (Variable Duration)

#### Systematic Investigation

**1. Check Recent Changes**
```bash
# What deployed in last 24 hours?
@debug Analyze recent changes that might cause [issue]

# Any configuration changes?
# Any database migrations?
# Any infrastructure changes?
```

**2. Review Logs**
```bash
# Error logs
@debug Analyze error patterns in logs from past 2 hours

# Application logs
# Look for stack traces, unusual patterns

# Infrastructure logs
# Check system resources, network issues
```

**3. Monitor Metrics**
```bash
# Key metrics to check:
# - Error rate (vs. baseline)
# - Response time (p50, p95, p99)
# - Traffic volume (unusual spike?)
# - Resource usage (CPU, memory, disk)
# - Database performance (queries, connections)
# - External API latency (third-party issues?)
```

**4. Reproduce**
```bash
# Try to reproduce the issue
# Use actual user data if possible
# Document exact steps

# If reproducible:
@debug Create minimal reproduction case
```

**5. Hypothesis Testing**
```markdown
# Document hypotheses

## Hypothesis 1: Database connection pool exhausted
- Evidence: Connection timeout errors
- Test: Check pool size and active connections
- Result: [Pass/Fail]

## Hypothesis 2: Memory leak in new feature
- Evidence: Memory usage climbing steadily
- Test: Disable feature flag
- Result: [Pass/Fail]
```

#### Parallel Investigation

If multiple possible causes:
```bash
# Split team to investigate in parallel

@debug-person1 Investigate database angle
@debug-person2 Investigate recent code changes
@debug-person3 Investigate infrastructure/network
```

---

### Phase 5: RESOLVE (Variable Duration)

#### Implement Fix

**Option 1: Rollback**
```bash
# Fastest if recent deploy caused issue
git revert [bad-commit]
git push origin main
npm run deploy:production

# Verify fix worked
# Monitor for 15-30 minutes
```

**Option 2: Hotfix**
```bash
# If rollback not possible/desirable
# Follow hotfix workflow
# See: workflows/hotfix_workflow.md

@planner Create emergency spec for [issue]
@builder Implement minimal fix
# ... hotfix process
```

**Option 3: Configuration Change**
```bash
# If config-related
# Update environment variables
# Adjust feature flags
# Scale resources

# No code deployment needed
```

**Option 4: External Service Issue**
```bash
# If third-party service is down
# Implement fallback/graceful degradation
# OR wait for service restoration
# Keep customers informed
```

#### Verification

After fix is deployed:

- [ ] **Immediate** (5 min): Error rate decreased?
- [ ] **Short-term** (15 min): Metrics returned to normal?
- [ ] **Medium-term** (30 min): No secondary issues?
- [ ] **Long-term** (1 hour): System stable?

**Verification Checklist**:
```bash
# 1. Check error rate
# Should be < baseline

# 2. Check response time
# Should be back to normal p95

# 3. Spot check functionality
# Test the specific feature that was broken

# 4. Monitor alerts
# No new alerts firing

# 5. Check user reports
# Complaints stopped?
```

---

### Phase 6: COMMUNICATE (Throughout)

#### Internal Communication

**Regular Updates** (every 15-30 minutes):
```markdown
📊 UPDATE [HH:MM]

**Status**: Investigating / Identified / Fixing / Resolved
**Progress**: [What we've learned/done]
**Next Steps**: [What's happening next]
**ETA**: [Best estimate or "Unknown"]
```

**Example Updates**:
```markdown
📊 UPDATE 14:45
Status: Investigating
Progress: Identified database connection issues. High connection count.
Next Steps: Reviewing recent queries. Checking for connection leaks.
ETA: Unknown

---

📊 UPDATE 15:00
Status: Identified
Progress: Found N+1 query in user profile endpoint causing connection exhaustion.
Next Steps: Implementing fix. ETA 20 minutes.
ETA: 15:20

---

📊 UPDATE 15:25
Status: Resolved
Progress: Fix deployed. Connection count normalized. Error rate back to baseline.
Next Steps: Monitoring for 30 minutes, then close incident.
ETA: Close at 16:00
```

#### External Communication (Customer-Facing)

**Status Page Updates**:

**Initial Notice**:
```
🔴 Investigating - Payment Processing Issues
February 13, 2024 at 14:30 PST

We are currently investigating reports of payment processing failures.
Our team is actively working on this issue. We will provide updates
every 30 minutes.
```

**Progress Update**:
```
🟡 Identified - Payment Processing Issues
February 13, 2024 at 15:00 PST

We have identified the root cause and are implementing a fix.
We expect service to be restored by 15:30 PST.
```

**Resolution**:
```
🟢 Resolved - Payment Processing Issues
February 13, 2024 at 15:35 PST

This incident has been resolved. Payment processing is now operating
normally. We apologize for any inconvenience.
```

**Best Practices**:
- Be transparent but don't over-share technical details
- Give realistic ETAs or say "investigating"
- Apologize for impact
- Explain what happened (briefly)
- Describe preventive measures (in post-mortem)

---

### Phase 7: CLOSE (After Resolution)

#### Incident Closure Checklist

- [ ] **System Stable**: No issues for 1+ hours
- [ ] **Root Cause Identified**: We know what happened
- [ ] **Fix Verified**: Solution working as expected
- [ ] **Monitoring Confirmed**: Alerts back to green
- [ ] **Stakeholders Notified**: Everyone informed of resolution
- [ ] **Status Page Updated**: Marked as resolved
- [ ] **Post-Mortem Scheduled**: Meeting on calendar

#### Close Incident

```markdown
✅ INCIDENT CLOSED

**Duration**: [total time]
**Resolution**: [brief description]
**Users Affected**: [number/percentage]
**Revenue Impact**: [if applicable]

**Timeline**:
- 14:30 - Incident detected
- 14:35 - Incident declared
- 14:45 - Root cause identified
- 15:20 - Fix deployed
- 15:30 - Verified resolved
- 16:00 - Monitoring complete, incident closed

**Next Steps**:
- Post-mortem: [date/time]
- Follow-up tickets: [links]
- Action items: [immediate actions]

Thanks to @person1, @person2, @person3 for quick response!
```

---

### Phase 8: LEARN (Within 48 hours)

#### Post-Mortem Meeting

**Required Attendees**:
- Incident Commander
- Technical responders
- Product/stakeholder representatives

**Agenda** (60 minutes):
1. **Timeline Review** (10 min)
   - What happened when
   - Key decision points

2. **Root Cause Analysis** (15 min)
   - Technical cause
   - Contributing factors
   - Why it wasn't caught earlier

3. **What Went Well** (10 min)
   - Fast detection
   - Good communication
   - Effective troubleshooting

4. **What Could Improve** (15 min)
   - Detection could be faster
   - Testing gaps
   - Process improvements

5. **Action Items** (10 min)
   - Specific, assignable tasks
   - With owners and deadlines

**Post-Mortem Document Template**:
```markdown
# Post-Mortem: [Incident Title]

## Metadata
- **Date**: 2024-02-13
- **Severity**: P0
- **Duration**: 2 hours 30 minutes
- **Incident Commander**: @name
- **Attendees**: [@name1, @name2, @name3]

## Summary
[2-3 sentence summary of what happened]

## Timeline
| Time  | Event |
|-------|-------|
| 14:30 | First alert: High error rate |
| 14:33 | On-call paged |
| 14:35 | Incident declared (P0) |
| 14:45 | Root cause identified: N+1 query |
| 15:00 | Fix developed and reviewed |
| 15:20 | Fix deployed to production |
| 15:30 | Metrics returned to normal |
| 16:00 | Incident closed |

## Impact
- **Users Affected**: ~10,000 (15% of active users)
- **Duration**: 2.5 hours
- **Revenue Impact**: Estimated $X lost transactions
- **Customer Complaints**: 47 support tickets

## Root Cause
[Detailed technical explanation]

The new user profile feature introduced an N+1 query problem. For each
user request, the system was making 1 query to fetch the user plus N
additional queries to fetch related data, exhausting the database
connection pool.

**Why wasn't this caught?**
- Test database had minimal data (N was small)
- Load testing skipped this endpoint
- Code review didn't catch the pattern

## Resolution
[What we did to fix it]

Optimized query to use JOIN instead of sequential queries. Reduced
database calls from O(n) to O(1).

## Detection
[How we found out]

Automated alert: Database connection pool >90% full
User reports started arriving shortly after

**Detection Timeline**:
- Incident started: 14:25 (estimate)
- First alert: 14:30
- Incident declared: 14:35

**Mean Time to Detect (MTTD)**: 5 minutes ✅

## What Went Well
- ✅ Fast detection via automated monitoring
- ✅ Clear incident declaration and role assignment
- ✅ Quick root cause identification (15 min)
- ✅ Good communication with stakeholders
- ✅ Effective hotfix process

## What Could Improve
- ⚠️ Load testing didn't cover this endpoint
- ⚠️ Code review could be more thorough for query patterns
- ⚠️ Database monitoring could be more granular

## Action Items
- [ ] (@owner, Due: YYYY-MM-DD) Add load test for profile endpoint
- [ ] (@owner, Due: YYYY-MM-DD) Create code review checklist for query optimization
- [ ] (@owner, Due: YYYY-MM-DD) Implement query performance monitoring
- [ ] (@owner, Due: YYYY-MM-DD) Add database connection pool alerts at 75%
- [ ] (@owner, Due: YYYY-MM-DD) Update runbook with this scenario

## Supporting Documents
- Incident Channel: #incident-2024-02-13-profile-slowdown
- Hotfix PR: #1234
- Monitoring Dashboard: [link]
- Status Page Updates: [link]
```

---

## Incident Response Roles

### Incident Commander (IC)
**Responsibilities**:
- Declare incident and assign severity
- Assign roles (tech lead, comms, scribe)
- Make final decisions on actions
- Coordinate war room
- Decide when to escalate
- Close incident when resolved

**Skills**: Leadership, decision-making, communication

---

### Tech Lead
**Responsibilities**:
- Lead technical investigation
- Assign debugging tasks
- Review proposed fixes
- Approve deployment

**Skills**: Deep technical knowledge, debugging

---

### Communications Lead
**Responsibilities**:
- Update status page
- Notify stakeholders (internal/external)
- Draft customer communications
- Monitor support channels

**Skills**: Clear communication, stakeholder management

---

### Scribe
**Responsibilities**:
- Document timeline
- Record decisions made
- Capture action items
- Take notes for post-mortem

**Skills**: Attention to detail, fast typing

---

## Common Incident Types

### 1. Database Issues
**Symptoms**: Timeouts, slow queries, connection errors
**Investigation**:
```bash
# Check connections
@debug Analyze database connection pool status

# Check slow queries
# Review slow query log

# Check locks
# Look for deadlocks or long-running transactions
```

**Common Causes**:
- Connection pool exhaustion
- Slow queries (missing index)
- Deadlocks
- Database overload

---

### 2. API/Service Failures
**Symptoms**: 5xx errors, timeouts, unavailable endpoints
**Investigation**:
```bash
# Check service health
curl https://api.yourapp.com/health

# Check logs
@debug Analyze API error logs from past hour

# Check dependencies
# Are external services down?
```

**Common Causes**:
- Code bug in recent deploy
- External API degradation
- Rate limiting
- Resource exhaustion

---

### 3. Performance Degradation
**Symptoms**: Slow response times, timeouts
**Investigation**:
```bash
# Profile application
@performance Identify performance bottleneck

# Check resources
# CPU, memory, disk I/O

# Check network
# Latency to dependencies
```

**Common Causes**:
- Inefficient code
- Resource constraints
- Traffic spike
- Database slow queries

---

### 4. Security Incidents
**Symptoms**: Unauthorized access, data breach, unusual activity
**Investigation**:
```bash
# IMMEDIATE: Contain the breach
# Disable compromised accounts
# Block malicious IPs

# Investigate
@security Analyze security logs for breach

# Notify
# Security team, legal, affected users
```

**Common Causes**:
- Compromised credentials
- Vulnerability exploit
- Social engineering
- Misconfigured permissions

---

## Incident Communication Templates

### Internal Alert
```
🚨 P1 INCIDENT: Payment Processing Down

Detection: 14:30 PST
Severity: P1 (High)
Impact: Payment endpoint returning 500 errors
Users Affected: All users attempting payments

Incident Commander: @alice
Tech Lead: @bob
Comms: @charlie

War Room: https://zoom.us/j/incident
Channel: #incident-2024-02-13-payments

Status: Investigating
ETA: Unknown
```

### Customer Email (After Resolution)
```
Subject: Service Restoration - Payment Processing

Dear Valued Customer,

We're writing to inform you that between 2:30 PM and 5:00 PM PST today,
our payment processing system experienced technical difficulties. This has
been fully resolved as of 5:00 PM PST.

What happened:
A configuration issue caused payment processing delays and failures.

What we did:
Our engineering team identified and fixed the issue within 2.5 hours.

What we're doing to prevent this:
We're implementing additional monitoring and testing to catch similar
issues before they affect service.

We sincerely apologize for any inconvenience this may have caused.

If you experienced failed transactions, please contact support@yourapp.com
and we'll assist you.

Thank you for your patience and understanding.

[Your Team]
```

---

## Tools & Resources

### Monitoring & Alerting
- **Application Monitoring**: [Your APM tool]
- **Infrastructure Monitoring**: [Your infrastructure tool]
- **Log Aggregation**: [Your logging tool]
- **Alerting**: [PagerDuty/OpsGenie]

### Communication
- **Incident Channel**: #incidents
- **Status Page**: [Your status page]
- **War Room**: [Zoom/Google Meet]

### Documentation
- **Runbooks**: [Location]
- **Architecture Docs**: [Location]
- **Post-Mortems**: [Location]

---

## Incident Response Training

**Regular Training**:
- Monthly incident drills (GameDay)
- Quarterly on-call rotation
- Annual security incident simulation

**Resources**:
- [Company incident response handbook]
- [On-call rotation schedule]
- [Escalation procedures]

---

## Best Practices

### ✅ DO
1. Declare incidents early (better safe than sorry)
2. Assign clear roles immediately
3. Communicate frequently (even if no update)
4. Document everything in real-time
5. Focus on resolution first, blame later
6. Always do post-mortems
7. Track action items to completion

### ❌ DON'T
1. Work in isolation (communicate!)
2. Skip status page updates
3. Blame individuals
4. Rush deployments without testing
5. Skip post-mortem
6. Ignore smaller incidents (they teach lessons)
7. Let action items languish

---

**Remember**: Incidents are learning opportunities. A blameless culture and thorough post-mortems make systems more reliable over time.
