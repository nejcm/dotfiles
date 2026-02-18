# Agent Integration Points

## Overview

OpenCode's 12 AI agents (4 core + 8 specialized) collaborate through well-defined integration points. This guide documents communication patterns, artifact sharing, handoff protocols, and escalation criteria to ensure smooth multi-agent workflows.

---

## Agent Roster

### Core Agents (Always Available)

| Agent | Role | Primary Responsibility | Model |
|-------|------|------------------------|-------|
| **@planner** | Architect | Spec creation, system design | Sonnet 4.5 |
| **@builder** | Implementation | Code writing, refactoring | Sonnet 4.5 |
| **@tester** | Quality Assurance | Testing, coverage validation | Haiku 4.5 (cost-optimized) |
| **@reviewer** | Quality Control | Code review, final approval | Sonnet 4.5 |

### Specialized Agents (Invoke on Demand)

| Agent | Role | Primary Responsibility | Model |
|-------|------|------------------------|-------|
| **@debug** | Troubleshooter | Bug investigation, root cause analysis | Sonnet 4.5 |
| **@migration** | Database Expert | Schema changes, zero-downtime deployments | Sonnet 4.5 |
| **@performance** | Optimization | Profiling, benchmarking, optimization | Sonnet 4.5 |
| **@refactor** | Code Cleanup | Technical debt reduction, architecture | Sonnet 4.5 |
| **@security** | Security Expert | Threat modeling, OWASP compliance | Opus 4.6 (highest capability) |
| **@release** | Release Manager | Deployment, changelog, versioning | Sonnet 4.5 |
| **@analytics** | Metrics Analyst | Code metrics, technical debt tracking | Haiku 4.5 (cost-optimized) |
| **@documentation** | Technical Writer | API docs, guides, ADRs | Haiku 4.5 (cost-optimized) |

---

## Communication Patterns

### Pattern 1: Sequential Handoff (Linear Workflow)
**Flow:** Agent A completes work → Creates artifact → Agent B reads artifact → Continues work

**Example:** Feature Implementation
```
@planner (Spec creation)
    ↓ [specs/feature-123.md]
@builder (Implementation)
    ↓ [src/**, tests/**]
@tester (Validation)
    ↓ [reports/test-results.md]
@reviewer (Final approval)
    ↓ [APPROVED]
Merge to develop
```

**Artifacts:**
- Spec: `specs/user-preferences-feature.md`
- Code: `src/services/preferences.ts`, `src/api/routes/preferences.ts`
- Tests: `src/services/preferences.test.ts`
- Test Report: `reports/test-results-2026-02-15.md`
- Review: PR comments, approval

**Communication:**
- @planner mentions spec location in handoff message
- @builder references spec ID in commits
- @tester reads spec for acceptance criteria
- @reviewer validates against spec requirements

---

### Pattern 2: Parallel Review (Concurrent Validation)
**Flow:** Agent A completes work → Multiple agents review simultaneously → Results merged

**Example:** Security-Critical Feature
```
@builder (Implementation complete)
    ├─► @tester (Functional testing)     │   ↓ [reports/test-results.md]
    │
    └─► @security (Security audit)
        ↓ [reports/security-review.md]

@reviewer (Merge results, final decision)
```

**Artifacts:**
- Code: `src/auth/oauth2.ts`
- Test Report: `reports/test-results-oauth2.md`
- Security Report: `reports/security-review-oauth2.md` (Security score: 9.5/10)

**Communication:**
- @builder notifies both @tester and @security simultaneously
- @tester focuses on functional correctness
- @security focuses on OWASP compliance
- @reviewer reads both reports, makes final decision

**Benefits:**
- Faster review cycle (parallel vs sequential)
- Specialized expertise (security AND testing)
- Higher quality (multiple perspectives)

---

### Pattern 3: Feedback Loop (Iterative Refinement)
**Flow:** Agent A creates work → Agent B reviews → Finds issues → Agent A fixes → Repeat until approved

**Example:** Code Review Iterations
```
@builder (Initial implementation)
    ↓ [PR #456]
@reviewer (Review, find issues)
    ↓ [Request changes]
@builder (Address feedback)
    ↓ [Updated PR #456]
@reviewer (Re-review)
    ↓ [APPROVED]
```

**Communication:**
- @reviewer provides specific, actionable feedback
- @builder addresses each comment with commit references
- @reviewer validates fixes, approves when satisfied

**Iteration Example:**
```
Iteration 1:
@reviewer: "Missing error handling in payment processing"
@builder: Added try/catch, commit abc123

Iteration 2:
@reviewer: "Test coverage only 65%, need 80%"
@builder: Added edge case tests, now 82%, commit def456

Iteration 3:
@reviewer: "LGTM! ✅ Approved"
```

---

### Pattern 4: Escalation Chain (Progressive Expertise)
**Flow:** Agent A encounters issue → Escalates to Agent B (specialist) → Agent B resolves → Returns to Agent A

**Example:** Performance Bottleneck
```
@builder (Implementing feature, notices slow query)
    ↓ [Escalate to @performance]
@performance (Profile, identify N+1 queries)
    ↓ [Optimization recommendations]
@builder (Implement optimizations)
    ↓ [Re-test performance]
@performance (Validate improvement: 36x faster ✅)
    ↓ [Sign-off]
@builder (Continue implementation)
```

**Escalation Triggers:**
- Response time >200ms for critical endpoint
- Memory usage >500MB for single request
- Database queries >10 per request (N+1 suspected)

**Communication:**
- @builder provides context (endpoint, observed behavior)
- @performance uses profiling tools (Clinic.js, flamegraphs)
- @performance returns actionable recommendations
- @builder implements, @performance validates

---

### Pattern 5: Consensus Decision (Multi-Agent Agreement)
**Flow:** Complex decision → Multiple agents provide input → Team discusses → Consensus reached

**Example:** Architecture Decision
```
User: "Should we use PostgreSQL JSONB or separate table for user preferences?"

@planner (Design perspective)
    ↓ "JSONB: Flexible schema, fewer joins"

@performance (Performance perspective)
    ↓ "JSONB with GIN index: Fast queries, <10ms"

@migration (Operational perspective)
    ↓ "JSONB: Easier migrations, no schema changes"

@security (Security perspective)
    ↓ "JSONB: Validate app-level, no foreign keys"

Consensus: Use PostgreSQL JSONB ✅
```

**Communication:**
- Each agent provides expertise from their domain
- Trade-offs discussed (flexibility vs validation)
- Decision documented in ADR (Architecture Decision Record)

---

## Artifact Sharing Protocol

### Artifact Types & Ownership

| Artifact Type | Creator | Primary Consumers | Secondary Consumers | Location |
|---------------|---------|-------------------|---------------------|----------|
| **Spec** | @planner | @builder, @reviewer | @tester, @security | `specs/*.md` |
| **Code** | @builder | @tester, @reviewer | @refactor, @performance | `src/**` |
| **Tests** | @tester, @builder | @reviewer | @security | `src/**/*.test.ts` |
| **Test Report** | @tester | @reviewer, @builder | @planner | `reports/test-*.md` |
| **Security Report** | @security | @reviewer, @builder | @planner | `reports/security-*.md` |
| **Performance Profile** | @performance | @refactor, @builder | @reviewer | `reports/perf-*.md`, `.clinic/` |
| **Migration Files** | @migration | @release, @tester | @builder | `migrations/*.sql` |
| **Changelog** | @release | @documentation | @planner | `CHANGELOG.md` |
| **ADR** | @planner | All agents | @documentation | `docs/adr/*.md` |
| **Post-Mortem** | @debug, @release | All agents | @planner | `docs/postmortems/*.md` |

---

### Artifact Format Standards

#### 1. Spec Format (`specs/*.md`)
```markdown
# [Feature Name] - Spec #[ID]

**Status:** Draft | In Progress | Implemented | Deployed
**Priority:** P0 | P1 | P2 | P3
**Assigned:** @builder
**Reviewers:** @security, @reviewer

## User Story
As a [user type], I want [feature], so that [benefit].

## Acceptance Criteria
- [ ] Given [context], when [action], then [outcome]
- [ ] [Additional criteria...]

## Technical Approach
- Database: PostgreSQL JSONB column for preferences
- API: GET/PUT /api/users/:id/preferences
- Validation: Joi schema (client + server)

## Success Metrics
- Coverage: ≥80%
- Performance: <100ms response time
- Security: OAuth2 protected endpoint

## Dependencies
- Spec #101 (User authentication)

## References
- ADR-007: Use PostgreSQL JSONB
- API Spec: `docs/api/openapi.yaml`
```

**@planner** creates, **@builder** implements, **@reviewer** validates

---

#### 2. Test Report Format (`reports/test-*.md`)
```markdown
# Test Report - [Feature/Module] - [Date]

**Test Suite:** User Preferences API
**Coverage:** 85% (✅ Above 80% threshold)
**Duration:** 2.3s
**Status:** ✅ PASSED

## Summary
- Total: 47 tests
- Passed: 47 ✅
- Failed: 0
- Skipped: 0

## Coverage Breakdown
| Category | Lines | Statements | Branches | Functions |
|----------|-------|------------|----------|-----------|
| Total    | 85%   | 87%        | 82%      | 90%       |
| services/preferences.ts | 92% | 94% | 88% | 100% |
| api/routes/preferences.ts | 78% | 80% | 75% | 80% |

## Test Cases
### ✅ PASSED (47)
- GET /api/users/:id/preferences - Returns user preferences
- PUT /api/users/:id/preferences - Updates preferences
- PUT /api/users/:id/preferences - Validates schema
- PUT /api/users/:id/preferences - Rejects invalid data
- [...]

## Edge Cases Tested
- [ ] Empty preferences (null)
- [x] Invalid JSON schema
- [x] Large preferences (>1MB)
- [x] Concurrent updates (race condition)

## Performance
- GET: 12ms avg (baseline: 15ms) ✅ 20% faster
- PUT: 34ms avg (baseline: 40ms) ✅ 15% faster

## Recommendations
- Add test for preferences with 1000+ fields (stress test)
- Consider adding mutation testing for validation logic
```

**@tester** creates, **@reviewer** validates, **@builder** addresses failures

---

#### 3. Security Report Format (`reports/security-*.md`)
```markdown
# Security Review - [Feature] - [Date]

**Feature:** OAuth2 Authentication
**Reviewer:** @security
**Security Score:** 9.5/10 ✅ APPROVED

## Executive Summary
OAuth2 implementation follows best practices with PKCE, CSRF protection, and secure token storage. One minor improvement recommended (rate limiting).

## OWASP Top 10 Check
- [x] A01: Broken Access Control - ✅ OAuth2 + RBAC
- [x] A02: Cryptographic Failures - ✅ Tokens in httpOnly cookies
- [x] A03: Injection - ✅ Parameterized queries
- [x] A04: Insecure Design - ✅ Threat model reviewed
- [x] A05: Security Misconfiguration - ✅ Security headers
- [x] A06: Vulnerable Components - ✅ No critical CVEs
- [x] A07: Authentication Failures - ✅ PKCE, state parameter
- [x] A08: Software Integrity - ✅ Dependency signatures
- [x] A09: Logging Failures - ✅ Audit logs enabled
- [x] A10: SSRF - ✅ Redirect URI validated

## Strengths
1. **PKCE for public clients** - Prevents authorization code interception
2. **CSRF protection (state parameter)** - Validates redirect flow
3. **Secure token storage** - httpOnly cookies, not localStorage
4. **Redirect URI validation** - Whitelist prevents open redirects

## Vulnerabilities Found
None (critical/high)

## Recommendations (Medium Priority)
1. Add rate limiting (30 req/hour per user)
   - Prevents brute force attacks
   - Implementation: Redis + express-rate-limit

2. Token rotation on refresh (future enhancement)
   - Currently: Refresh tokens valid 30 days
   - Suggested: Rotate on use, shorter TTL (7 days)

## Security Score Breakdown
| Category | Score | Weight | Notes |
|----------|-------|--------|-------|
| Authentication | 10/10 | 30% | OAuth2 with PKCE ✅ |
| Authorization | 9/10 | 20% | RBAC (missing rate limit) |
| Data Protection | 10/10 | 25% | Encryption, httpOnly cookies |
| Input Validation | 10/10 | 15% | Joi schema validation |
| Logging & Monitoring | 9/10 | 10% | Audit logs (missing alerts) |
| **Total** | **9.5/10** | **100%** | ✅ **APPROVED** |

## Sign-Off
Security review approved. Recommendations are non-blocking, can be addressed post-launch.

**Reviewer:** @security
**Date:** 2026-02-15
**Status:** ✅ APPROVED FOR PRODUCTION
```

**@security** creates, **@reviewer** and **@builder** read, **@release** verifies before deployment

---

## Agent Handoff Protocols

### Handoff Checklist

When an agent completes work and hands off to another agent, they must:

1. **Create artifact** (spec, code, report)
2. **Notify next agent** (mention in message)
3. **Provide context** (what was done, what's next)
4. **Reference artifacts** (file paths, PR numbers)
5. **Highlight blockers** (if any)

**Example Handoff:**
```
@planner → @builder:
"Spec created for user preferences feature (specs/user-prefs-123.md).

Key points:
- Use PostgreSQL JSONB column (per ADR-007)
- Implement GET/PUT endpoints
- Joi validation on client + server
- Target: 80% coverage, <100ms response time

No blockers. @builder, please implement."
```

---

### Handoff Failures (What NOT to Do)

❌ **Bad Handoff:**
```
@planner: "Done. @builder implement it."
```

**Problems:**
- No artifact reference
- No context
- Unclear requirements
- @builder has to search for spec

✅ **Good Handoff:**
```
@planner: "Spec #123 complete (specs/user-prefs-123.md).
Implements user preferences JSONB storage per ADR-007.
Acceptance criteria: 5 user stories, all testable.
@builder, ready for implementation."
```

**Benefits:**
- Clear artifact location
- Context provided (JSONB, ADR-007)
- Acceptance criteria mentioned
- Explicit handoff to @builder

---

## Escalation Criteria

### When to Escalate to Human

**Immediate Escalation (P0):**
- Production outage >15 minutes
- Security breach (unauthorized access, data leak)
- Data corruption affecting >100 users
- Financial impact >$10,000
- Legal/compliance violation

**Timely Escalation (P1, within 4 hours):**
- Architecture decisions (database choice, framework selection)
- Breaking API changes requiring migration guide
- Deployment failures requiring rollback
- Critical bug with no obvious fix
- Technical debt >40% of codebase

**Advisory Escalation (P2, within 1 day):**
- Feature ambiguity (unclear requirements)
- Performance optimization requiring trade-offs
- Refactoring affecting public APIs
- Security vulnerability CVSS 4-7 (moderate)
- Coverage dropping below 70% (warning threshold)

---

### Agent-to-Agent Escalation Matrix

| Source Agent | Escalates To | Trigger Scenario | Expected Response |
|--------------|--------------|------------------|-------------------|
| **@builder** | @security | Implementing auth/payment/admin | Security review, threat model |
| **@builder** | @performance | Slow query (>200ms) | Profiling, optimization recommendations |
| **@builder** | @refactor | Code complexity >15 | Refactoring suggestions |
| **@tester** | @builder | Tests failing | Bug fix |
| **@tester** | @refactor | Coverage <70% (warning) | Improve testability |
| **@performance** | @security | Performance issue reveals vulnerability | Security audit |
| **@performance** | @refactor | Need architectural changes | Restructure code |
| **@debug** | @security | Bug in auth/payment logic | Security review |
| **@debug** | @builder | Root cause identified | Implement fix |
| **@migration** | @tester | Need rollback testing | Test migration + rollback |
| **@migration** | @security | Schema change affects sensitive data | Security review |
| **@reviewer** | @builder | Code quality issues | Address feedback |
| **@reviewer** | @security | Suspicious code patterns | Security audit |
| **@release** | @security | Vulnerability in release candidate | Emergency security review |
| **@release** | @migration | Deployment requires schema changes | Migration coordination |
| **@analytics** | @refactor | Technical debt >40% | Refactoring roadmap |
| **@analytics** | @performance | Performance degradation trend | Investigation |
| **@documentation** | @planner | Missing architectural docs | Create ADR/design doc |

---

## Integration Examples

### Example 1: Feature Implementation (Sequential Handoff)

**Scenario:** Add user preferences feature

**Flow:**
```
User: "Add user preferences feature"
    ↓
@planner: Create spec (specs/user-prefs-123.md)
    ├─ User stories (5)
    ├─ Acceptance criteria (Given/When/Then)
    ├─ Technical approach (JSONB, API endpoints)
    └─ Success metrics (coverage, performance, security)
    ↓
@builder: Implement feature
    ├─ Database migration (add preferences JSONB column)
    ├─ API endpoints (GET/PUT /api/users/:id/preferences)
    ├─ Joi validation (client + server)
    └─ Tests (unit, integration, e2e)
    ↓
@tester: Validate implementation
    ├─ Run test suite (47 tests, all passing)
    ├─ Check coverage (85%, above 80% threshold)
    ├─ Performance test (GET: 12ms, PUT: 34ms)
    └─ Create report (reports/test-results-user-prefs.md)
    ↓
@reviewer: Final review
    ├─ Code quality (ESLint, Prettier, TSC passing)
    ├─ Validate against spec (all 5 user stories met)
    ├─ Read test report (85% coverage ✅)
    └─ APPROVED ✅
    ↓
Merge to develop
```

**Artifacts Created:**
1. `specs/user-prefs-123.md` (by @planner)
2. `src/services/preferences.ts` (by @builder)
3. `src/api/routes/preferences.ts` (by @builder)
4. `src/services/preferences.test.ts` (by @builder)
5. `migrations/20260215_add_user_preferences.sql` (by @builder)
6. `reports/test-results-user-prefs.md` (by @tester)

**Duration:** 3-5 days

---

### Example 2: Security-Critical Feature (Parallel Review)

**Scenario:** Add OAuth2 authentication

**Flow:**
```
User: "Add OAuth2 login"
    ↓
@security: Threat modeling (before implementation)
    ├─ Identify attack vectors (CSRF, authorization code interception)
    ├─ Design security controls (PKCE, state parameter, redirect validation)
    └─ Create security requirements doc
    ↓
@planner: Create spec with security requirements
    ├─ OAuth2 flow (authorization code with PKCE)
    ├─ Token storage (httpOnly cookies, not localStorage)
    ├─ Endpoints (/auth/login, /auth/callback, /auth/refresh)
    └─ Security score target: ≥9/10
    ↓
@builder: Implement OAuth2
    ├─ Authorization code flow with PKCE
    ├─ State parameter for CSRF protection
    ├─ Redirect URI validation (whitelist)
    ├─ Token storage (httpOnly, Secure, SameSite cookies)
    └─ Tests (unit, integration, security test cases)
    ↓
    ┌─────────────┴─────────────┐
    │                           │
    ▼                           ▼
@tester                     @security
├─ Functional tests         ├─ OWASP Top 10 check
├─ OAuth2 flow validation   ├─ PKCE verification
├─ Error handling           ├─ CSRF protection check
├─ Coverage: 88%            ├─ Token security audit
└─ Report                   └─ Security score: 9.5/10
    │                           │
    └─────────────┬─────────────┘
                  ▼
@reviewer: Merge results, final decision
    ├─ Read test report (88% coverage ✅)
    ├─ Read security report (9.5/10 ✅)
    ├─ Validate code quality
    └─ APPROVED ✅
    ↓
Release with extra monitoring
```

**Artifacts Created:**
1. `docs/security/oauth2-threat-model.md` (by @security)
2. `specs/oauth2-implementation.md` (by @planner)
3. `src/auth/oauth2.ts` (by @builder)
4. `src/auth/oauth2.test.ts` (by @builder)
5. `reports/test-results-oauth2.md` (by @tester)
6. `reports/security-review-oauth2.md` (by @security)

**Duration:** 2-3 weeks (security rigor)

**See also:** `examples/security-review-example.md`

---

### Example 3: Performance Optimization (Escalation Chain)

**Scenario:** User dashboard is slow (2847ms)

**Flow:**
```
@builder: Implementing dashboard feature
    ├─ Initial implementation complete
    └─ Performance test: 2847ms ❌ (target: <200ms)
    ↓
@builder → @performance: "Dashboard endpoint slow (2847ms), need optimization"
    ↓
@performance: Profile and analyze
    ├─ CPU profiling (Clinic.js Doctor)
    ├─ Flamegraph analysis (Clinic.js Flame)
    ├─ Identify bottlenecks:
    │   1. N+1 queries (50 SELECTs instead of 1 JOIN)
    │   2. No database indexes on user_id
    │   3. Sequential queries (should be parallel)
    └─ Recommendations:
        1. Add database indexes
        2. Replace N+1 with JOIN
        3. Use Promise.all() for independent queries
        4. Add Redis caching for user preferences
    ↓
@performance → @builder: "Optimization recommendations ready (reports/perf-dashboard.md)"
    ↓
@builder: Implement optimizations
    ├─ Add B-tree index on users.id, preferences.user_id
    ├─ Rewrite queries (JOIN instead of N+1)
    ├─ Parallelize independent queries (Promise.all)
    ├─ Add Redis caching (TTL: 5 min)
    └─ Re-test performance
    ↓
@performance: Validate improvement
    ├─ Before: 2847ms
    ├─ After: 79ms
    └─ Improvement: 36x faster ✅
    ↓
@builder: Continue implementation (optimization complete)
```

**Artifacts Created:**
1. `reports/perf-dashboard-baseline.md` (by @performance)
2. `.clinic/doctor/dashboard-profile.html` (by @performance)
3. `.clinic/flame/dashboard-flamegraph.html` (by @performance)
4. `reports/perf-dashboard-optimized.md` (by @performance)
5. `migrations/20260215_add_dashboard_indexes.sql` (by @builder)
6. `src/services/dashboard-cache.ts` (by @builder)

**Duration:** 3-5 days

**See also:** `examples/performance-optimization-example.md`

---

### Example 4: Incident Response (Multi-Agent Coordination)

**Scenario:** Production API response time >5s (P0 incident)

**Flow:**
```
Alert: API response time >5s (SLA breach imminent)
    ↓
@debug: Investigate
    ├─ Check logs: "Database connection pool exhausted"
    ├─ Check metrics: 500 concurrent connections (limit: 100)
    └─ Root cause: Connection leak in recent deployment
    ↓
@debug → @release: "Need immediate rollback to previous version"
    ↓
@release: Emergency rollback
    ├─ Rollback deployment (5 min downtime)
    ├─ Verify: API response time back to 150ms ✅
    └─ Incident mitigated
    ↓
@debug: Analyze root cause
    ├─ Recent change: Added connection pooling
    ├─ Bug: Connections not released in error handler
    └─ Fix: Add try/finally to ensure connection.release()
    ↓
@builder: Implement permanent fix
    ├─ Add try/finally in all database functions
    ├─ Add connection leak detection (alerts)
    └─ Add tests for error paths
    ↓
@tester: Test fix
    ├─ Simulate errors (network failure, timeout)
    ├─ Verify connections released
    └─ Load test: 1000 concurrent requests ✅
    ↓
@security: Review fix (database access = security concern)
    ├─ Validate error handling
    ├─ Check for SQL injection (parameterized queries ✅)
    └─ APPROVED ✅
    ↓
@release: Deploy fix to production
    ├─ Canary deployment (5% of traffic)
    ├─ Monitor for 30 min (no errors ✅)
    └─ Full deployment (100%)
    ↓
@planner: Post-mortem
    ├─ Timeline (detection → mitigation → resolution)
    ├─ Root cause (connection leak in error handler)
    ├─ Action items:
    │   1. Add connection leak monitoring ✅
    │   2. Review all error handlers for resource leaks
    │   3. Add pre-deployment load testing
    └─ Document in docs/postmortems/2026-02-15-connection-leak.md
```

**Agents Involved:** @debug, @release, @builder, @tester, @security, @planner (6 agents)

**Artifacts Created:**
1. `reports/incident-2026-02-15.md` (by @debug)
2. `src/db/connection-pool.ts` (fix by @builder)
3. `reports/test-results-connection-leak-fix.md` (by @tester)
4. `reports/security-review-db-access.md` (by @security)
5. `docs/postmortems/2026-02-15-connection-leak.md` (by @planner)

**Duration:** 4 hours (incident detected → resolution)

---

## Best Practices

### 1. Always Create Artifacts
**Why:** Enables async collaboration, knowledge preservation

**Do:**
- Create spec before implementation (@planner)
- Write tests alongside code (@builder, @tester)
- Document security reviews (@security)
- Generate test reports (@tester)
- Create post-mortems after incidents (@planner)

**Don't:**
- Handoff work without documentation
- Skip test reports ("tests passing" is not enough)
- Forget to update specs after implementation changes

---

### 2. Use Explicit Handoffs
**Why:** Clear ownership, no ambiguity

**Do:**
```
@planner: "Spec complete (specs/feature-123.md). @builder, please implement."
@builder: "Implementation complete (PR #456). @tester, please validate."
@tester: "Tests passing, 85% coverage (reports/test-results.md). @reviewer, please approve."
```

**Don't:**
```
@planner: "Done."  # ❌ No artifact, no handoff
@builder: "Implemented."  # ❌ No reference, no next agent
```

---

### 3. Validate Against Artifacts
**Why:** Ensure requirements met, prevent drift

**Do:**
- @builder reads spec before implementing
- @tester checks acceptance criteria from spec
- @reviewer validates code against spec requirements

**Don't:**
- Implement without reading spec
- Test without acceptance criteria
- Review without understanding requirements

---

### 4. Escalate Early
**Why:** Specialists save time, prevent rework

**Do:**
- @builder → @security (when touching auth/payment)
- @builder → @performance (when query >200ms)
- @tester → @refactor (when coverage <70%)

**Don't:**
- Try to solve specialized problems alone
- Wait until production to discover issues

---

### 5. Document Decisions
**Why:** Onboard new team members, prevent repeat mistakes

**Do:**
- Create ADRs for architecture decisions
- Write post-mortems after incidents
- Update runbooks after migrations

**Don't:**
- Make decisions in Slack/email (undocumented)
- Forget context after 6 months

---

## Troubleshooting Agent Integration

### Issue: "Handoff failed, next agent confused"
**Symptoms:**
- Next agent asks for clarification
- Work stalled, waiting for context

**Causes:**
- Incomplete artifact (missing sections)
- No artifact reference in handoff message
- Unclear acceptance criteria

**Fix:**
- Use artifact templates (spec, test report, security review)
- Include file paths in handoff messages
- Reference specific requirements/criteria

---

### Issue: "Duplicate work, agents overlapping"
**Symptoms:**
- Two agents working on same task
- Conflicting implementations

**Causes:**
- Unclear ownership
- Missing handoff
- Parallel work without coordination

**Fix:**
- Explicit ownership in artifacts (Assigned: @builder)
- Use handoff protocol (mention next agent)
- For parallel work, assign distinct areas (tester = functionality, security = OWASP)

---

### Issue: "Agent escalated unnecessarily"
**Symptoms:**
- Simple task escalated to specialist
- Wasted time/cost

**Causes:**
- Overly cautious escalation criteria
- Lack of confidence in own expertise

**Fix:**
- Review escalation matrix (when to escalate)
- Start with self-resolution, escalate only if blocked
- Use @analytics for metrics (e.g., complexity score) before escalating to @refactor

---

### Issue: "Security review slowing down releases"
**Symptoms:**
- Releases delayed waiting for @security
- Pressure to skip security reviews

**Causes:**
- Security review as bottleneck (at end of workflow)
- All changes require security review (unnecessary)

**Fix:**
- Front-load security reviews (threat modeling before implementation)
- Risk-based security reviews (only auth/payment/admin changes)
- Parallel security reviews (while @tester runs tests)

---

## Agent Performance Metrics

### Recommended Metrics

**Per-Agent Metrics:**
- Handoff time: Time from completion to next agent start (target: <1 hour)
- Rework rate: % of work requiring iterations (target: <20%)
- Artifact quality: % of artifacts meeting standards (target: >95%)

**Cross-Agent Metrics:**
- End-to-end time: User request to production deployment (target: <5 days for features)
- Escalation rate: % of tasks requiring human escalation (target: <5%)
- Integration failures: % of handoffs requiring clarification (target: <10%)

**Example Dashboard:**
```
Agent Performance (Last 30 Days)

@planner:
├─ Specs created: 24
├─ Avg spec quality: 9.2/10
├─ Handoff time: 45 min avg
└─ Rework rate: 12%

@builder:
├─ PRs merged: 32
├─ Avg code quality: 8.8/10
├─ Handoff time: 2.1 hours avg
└─ Rework rate: 18%

@tester:
├─ Test suites run: 156
├─ Avg coverage: 84%
├─ Handoff time: 1.3 hours avg
└─ Rework rate: 8%

@reviewer:
├─ PRs reviewed: 38
├─ Avg review time: 3.2 hours
├─ Approval rate: 76% (first review)
└─ Rework requested: 24%

@security:
├─ Security reviews: 8
├─ Avg security score: 9.1/10
├─ Critical findings: 0
└─ Avg review time: 4.5 hours

Overall:
├─ End-to-end time: 4.2 days avg (✅ under 5 day target)
├─ Escalation rate: 3% (✅ under 5% target)
└─ Integration failures: 7% (✅ under 10% target)
```

---

## Related Documentation

- **[Skills Integration Matrix](./skills-integration-matrix.md)** - Which skills work with which agents
- **[Workflow Guide](./workflow-guide.md)** - When to use which workflows
- **[Agents Directory](../agents/)** - Detailed agent prompts and capabilities
- **[Examples Directory](../examples/)** - Real-world multi-agent workflows

---

## Quick Reference

### Agent Handoff Template
```
@[current-agent] → @[next-agent]:
"[Task complete summary].

Artifacts:
- [Artifact 1]: [file path]
- [Artifact 2]: [file path]

Key points:
- [Important detail 1]
- [Important detail 2]

[Blocker status: None | Blocked by [X]]

@[next-agent], please [next action]."
```

### Escalation Decision Tree
```
Issue encountered?
├─ Can I resolve with current expertise? → YES → Resolve
└─ Can I resolve with current expertise? → NO → Escalate
    ├─ Security concern? → @security
    ├─ Performance issue? → @performance
    ├─ Test coverage low? → @refactor (improve testability)
    ├─ Code complexity high? → @refactor
    ├─ Database issue? → @migration
    ├─ Bug investigation? → @debug
    ├─ Production incident? → @debug + @release
    └─ Architecture decision? → Human
```

---

**Last updated:** 2026-02-16
**Version:** 3.0 (complete agent integration guide)
