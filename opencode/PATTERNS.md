# OpenCode Design Patterns & Best Practices

**Common patterns and best practices for the OpenCode agent architecture.**

---

## Table of Contents

1. [Core Patterns](#core-patterns)
2. [Agent Patterns](#agent-patterns)
3. [Workflow Patterns](#workflow-patterns)
4. [Error Handling Patterns](#error-handling-patterns)
5. [Testing Patterns](#testing-patterns)
6. [Security Patterns](#security-patterns)
7. [Performance Patterns](#performance-patterns)
8. [Anti-Patterns (Avoid These)](#anti-patterns-avoid-these)

---

## Core Patterns

### 1. Spec Artifact Pattern

**Problem:** Requirements get lost in conversation history, leading to miscommunication and rework.

**Solution:** Persist specifications as file artifacts that can be version-controlled and reviewed.

**Implementation:**
```markdown
## Using Planner Agent

@planner Create a spec for user authentication with OAuth2

# Planner creates: specs/auth-oauth2-2024-02-14.md
```

**Benefits:**
- ✅ Specifications are version-controlled
- ✅ Can be reviewed like code
- ✅ Persistent across sessions
- ✅ Clear source of truth
- ✅ Searchable and linkable

**When to Use:**
- All non-trivial features
- Any work lasting >1 hour
- Changes affecting multiple files
- Work requiring collaboration

**See:** `specs/template.md` for spec structure

---

### 2. Single Responsibility Agents

**Problem:** Monolithic agents try to do everything, leading to permission issues and unclear ownership.

**Solution:** Each agent has one clear responsibility with minimal permissions.

**Implementation:**
```
Planner:  READ only  → Create specs
Builder:  WRITE      → Implement code
Tester:   BASH       → Run tests
Reviewer: READ only  → Validate quality
Security: READ only  → Security audit
```

**Benefits:**
- ✅ Clear separation of concerns
- ✅ Minimal permissions = safer
- ✅ Easier to debug issues
- ✅ Predictable behavior

**Anti-Pattern:**
```
❌ Give builder agent security review responsibility
❌ Give planner agent code writing permissions
❌ One agent for "everything"
```

---

### 3. Read-Only Reviewers

**Problem:** Reviewers modifying code defeats the purpose of code review.

**Solution:** Review agents have READ permission only, builder must make changes.

**Implementation:**
```
@reviewer Review auth/login.ts for security

# Reviewer provides feedback but cannot modify
# Builder agent makes the changes
@builder Fix issues from review
```

**Benefits:**
- ✅ Clear separation: review vs. implementation
- ✅ Prevents accidental modifications during review
- ✅ Audit trail of who changed what
- ✅ Forces intentional fixes

---

### 4. Fail-Fast Validation

**Problem:** Errors discovered late in process waste time and resources.

**Solution:** Validate early and often, fail fast with clear errors.

**Implementation:**
```bash
# Guardrails check before execution
if spec_required && !spec_exists:
    return "ERROR: Specification required. Use @planner first."

if budget_exceeded:
    return "ERROR: Daily budget exceeded ($100). Try again tomorrow."

if sensitive_operation && !approved:
    return "ERROR: Blocked. Production changes require approval."
```

**Checkpoints:**
- Before implementation: Spec exists?
- Before commit: Tests pass?
- Before deployment: Security review done?
- Before API call: Budget available?

**Benefits:**
- ✅ Fast feedback
- ✅ Prevents expensive mistakes
- ✅ Clear error messages
- ✅ Saves time and money

---

### 5. Layered Guardrails

**Problem:** Single guardrail layer can be bypassed or fail silently.

**Solution:** Multiple overlapping guardrails at different levels.

**Layers:**
```
1. Agent Level:      Permission restrictions
2. Tool Level:       Operation validation
3. Config Level:     Guardrails enforcement
4. Audit Level:      Complete logging
5. Deployment Level: Pre-production checks
```

**Example:**
```
Attempt to delete production database:

Layer 1: Builder agent lacks permission for destructive ops
Layer 2: Bash tool checks blocked operations list
Layer 3: Guardrails detect "DROP DATABASE" pattern
Layer 4: Audit logs the attempt
Layer 5: Deployment protection requires approval

Result: Operation blocked at multiple levels
```

**Benefits:**
- ✅ Defense in depth
- ✅ Redundant safety
- ✅ Catches different failure modes
- ✅ Audit trail even for blocked operations

---

## Agent Patterns

### 1. Planner → Builder → Tester Flow

**Problem:** Ad-hoc development leads to incomplete implementations.

**Solution:** Structured three-phase flow with clear handoffs.

**Implementation:**
```
Phase 1: Planning
  @planner Create spec for feature X
  → Output: specs/feature-x.md

Phase 2: Implementation
  @builder Implement specs/feature-x.md
  → Output: Code changes, tests

Phase 3: Validation
  @tester Run tests
  → Output: Test results, coverage

Phase 4: Review
  @reviewer Review implementation against spec
  → Output: Approval or change requests
```

**Decision Points:**
```
Spec complete? → Yes → Proceed to Builder
                → No  → Clarify requirements

Implementation done? → Yes → Proceed to Tester
                    → No  → Continue building

Tests pass? → Yes → Proceed to Reviewer
           → No  → Fix and re-test

Review approved? → Yes → Merge
                → No  → Address feedback, re-review
```

**Benefits:**
- ✅ Complete specifications before coding
- ✅ Tests written with implementation
- ✅ Quality validation built-in
- ✅ Clear progress tracking

---

### 2. Agent Specialization Over Generalization

**Problem:** Generic agents produce mediocre results for specialized tasks.

**Solution:** Use specialized agents with domain expertise and optimized models.

**Examples:**

**Security Reviews:**
```
❌ @builder Also check for security issues
✅ @security Review auth/login.ts for vulnerabilities

Why: Security agent uses Opus-4 (most capable), has OWASP checklist
```

**Database Migrations:**
```
❌ @builder Also create database migration
✅ @migration Create migration to add user roles

Why: Migration agent knows zero-downtime patterns, rollback procedures
```

**Performance Optimization:**
```
❌ @builder Make this faster
✅ @performance Analyze and optimize checkout flow

Why: Performance agent knows profiling, benchmarking, optimization patterns
```

**Benefits:**
- ✅ Higher quality specialized work
- ✅ Domain-specific validation
- ✅ Appropriate model selection (Opus for security, Haiku for docs)
- ✅ Built-in best practices

---

### 3. Builder Requires Spec

**Problem:** Builders implementing without clear requirements causes rework.

**Solution:** Guardrail enforces spec artifact before implementation.

**Configuration:**
```json
{
  "guardrails": {
    "require_spec_for_builder": true
  }
}
```

**Implementation:**
```
User: @builder Add user authentication

Builder: ERROR - Specification required.
         Please create a spec first:
         @planner Create spec for user authentication

User: @planner Create spec for user authentication

Planner: [Creates specs/auth-2024-02-14.md]

User: @builder Implement specs/auth-2024-02-14.md

Builder: [Implements feature according to spec]
```

**Exceptions (disable guardrail):**
- Emergency hotfixes
- Trivial changes (1-2 lines)
- Experimental/prototype work

**Benefits:**
- ✅ Forces upfront planning
- ✅ Creates documentation artifact
- ✅ Reduces miscommunication
- ✅ Enables better code review

---

## Workflow Patterns

### 1. Feature Implementation Pattern

**Workflow:** `workflows/feature_implementation.md`

**Steps:**
1. **Plan**: Create specification
2. **Build**: Implement code + tests
3. **Test**: Validate functionality
4. **Review**: Code and spec compliance
5. **Deploy**: Merge and release

**Checkpoints:**
- ✅ Spec approved before coding
- ✅ Tests written with implementation
- ✅ Code review passed
- ✅ Security review if needed
- ✅ Documentation updated

**Duration:** 35-55 minutes typical

---

### 2. Hotfix Pattern

**Workflow:** `workflows/hotfix_workflow.md`

**When:** Production issue requiring immediate fix.

**Severity Levels:**
- **P0**: Complete outage → Fix within 1 hour
- **P1**: Major feature broken → Fix within 4 hours
- **P2**: Partial degradation → Fix within 24 hours
- **P3**: Minor issue → Fix within 1 week

**Steps (P0/P1):**
1. **Assess** (5 min): Severity, impact, root cause
2. **Prepare** (10 min): Create hotfix branch, backup plan
3. **Implement** (30 min): Minimal fix, tests
4. **Deploy** (15 min): Production deployment
5. **Verify** (10 min): Confirm fix works
6. **Post-Hotfix** (30 min): Post-mortem, permanent fix

**Guardrails Adjusted:**
- ✅ Spec requirement waived for emergency
- ✅ Fast-track deployment approval
- ⚠️ Security review still required if auth/payment touched

**Anti-Patterns:**
```
❌ Skip testing ("it's urgent!")
❌ Skip rollback plan
❌ Deploy directly to production without staging test
❌ Skip post-mortem
```

---

### 3. Incident Response Pattern

**Workflow:** `workflows/incident_response.md`

**Roles:**
- **IC (Incident Commander)**: Coordinates response
- **Tech Lead**: Diagnoses and fixes issue
- **Communications**: Updates stakeholders
- **Scribe**: Documents timeline

**8 Phases:**
1. **Detect**: Alert fires, monitoring detects issue
2. **Declare**: IC declares incident, assigns roles
3. **Triage**: Assess severity, impact, urgency
4. **Investigate**: Tech Lead finds root cause
5. **Resolve**: Implement fix, deploy
6. **Communicate**: Update internal + external stakeholders
7. **Close**: Verify resolution, stand down
8. **Learn**: Post-mortem within 3 days

**Communication Templates:**
```
Internal Update:
  Status: [INVESTIGATING|IDENTIFIED|MONITORING|RESOLVED]
  Impact: [Who is affected, what's broken]
  ETA: [When fix expected]
  Next update: [In X minutes]

Customer-Facing:
  We're aware of an issue affecting [feature].
  Our team is actively working on a fix.
  We'll provide updates every [timeframe].
```

**Escalation Path:**
```
P3 → Assign to on-call engineer
P2 → Page Tech Lead
P1 → Page Tech Lead + Engineering Manager
P0 → Page entire leadership + prepare customer communication
```

---

### 4. Security Review Pattern

**Workflow:** `workflows/security_review.md`

**Triggers (Automatic):**
- Changes to `auth/`, `payment/`, `admin/` paths
- Files matching `*password*`, `*secret*`, `*token*` patterns
- Deployment to production (if configured)

**Triggers (Manual):**
- User input handling
- File uploads
- Cryptography usage
- External API calls with credentials

**OWASP Top 10 Checklist:**
1. ✅ Broken Access Control
2. ✅ Cryptographic Failures
3. ✅ Injection (SQL, XSS, Command)
4. ✅ Insecure Design
5. ✅ Security Misconfiguration
6. ✅ Vulnerable Components
7. ✅ Authentication Failures
8. ✅ Software/Data Integrity
9. ✅ Security Logging Failures
10. ✅ Server-Side Request Forgery

**Severity Classification:**
- **CRITICAL**: Authentication bypass, RCE, SQL injection
- **HIGH**: XSS, CSRF, information disclosure
- **MEDIUM**: Missing rate limiting, weak validation
- **LOW**: Missing security headers, verbose errors

**Result:**
```
✅ APPROVED: No issues or low severity only
⚠️ APPROVED WITH CONDITIONS: Medium severity, must fix post-deploy
❌ BLOCKED: High or critical issues, must fix before deploy
```

---

## Error Handling Patterns

### 1. Graceful Degradation

**Problem:** Single failure crashes entire operation.

**Solution:** Fail gracefully, provide partial functionality.

**Implementation:**
```typescript
async function generateDocumentation() {
  const results = {
    api: await generateAPIDocs().catch(e => ({
      error: e.message,
      status: 'failed'
    })),
    types: await generateTypeDocs().catch(e => ({
      error: e.message,
      status: 'failed'
    })),
    examples: await generateExamples().catch(e => ({
      error: e.message,
      status: 'failed'
    }))
  };

  // Return partial success
  return results;
}
```

**Benefits:**
- ✅ Partial success better than total failure
- ✅ Clear visibility into what failed
- ✅ Can proceed with available data
- ✅ User decides whether to retry

---

### 2. Retry with Exponential Backoff

**Problem:** Transient failures waste retries with immediate retry.

**Solution:** Retry with increasing delay between attempts.

**Implementation:**
```typescript
async function retryWithBackoff<T>(
  operation: () => Promise<T>,
  maxRetries: number = 3,
  baseDelay: number = 1000
): Promise<T> {
  for (let attempt = 0; attempt < maxRetries; attempt++) {
    try {
      return await operation();
    } catch (error) {
      if (attempt === maxRetries - 1) throw error;

      const delay = baseDelay * Math.pow(2, attempt);
      await sleep(delay);
    }
  }
}
```

**Delays:**
- Attempt 1: Immediate
- Attempt 2: 1 second
- Attempt 3: 2 seconds
- Attempt 4: 4 seconds

**Benefits:**
- ✅ Gives service time to recover
- ✅ Avoids overwhelming failing service
- ✅ Higher success rate than fixed delay

**Configuration:**
```json
{
  "guardrails": {
    "max_retries": 2
  }
}
```

---

### 3. Circuit Breaker

**Problem:** Repeated calls to failing service waste resources.

**Solution:** After N failures, stop trying for cooldown period.

**States:**
- **CLOSED**: Normal operation, calls go through
- **OPEN**: Too many failures, calls blocked
- **HALF-OPEN**: Test if service recovered

**Implementation:**
```typescript
class CircuitBreaker {
  private failureCount = 0;
  private lastFailure: Date | null = null;
  private state: 'CLOSED' | 'OPEN' | 'HALF-OPEN' = 'CLOSED';

  async call<T>(operation: () => Promise<T>): Promise<T> {
    if (this.state === 'OPEN') {
      if (this.shouldAttemptReset()) {
        this.state = 'HALF-OPEN';
      } else {
        throw new Error('Circuit breaker OPEN');
      }
    }

    try {
      const result = await operation();
      this.onSuccess();
      return result;
    } catch (error) {
      this.onFailure();
      throw error;
    }
  }

  private onSuccess() {
    this.failureCount = 0;
    this.state = 'CLOSED';
  }

  private onFailure() {
    this.failureCount++;
    this.lastFailure = new Date();

    if (this.failureCount >= 5) {
      this.state = 'OPEN';
    }
  }

  private shouldAttemptReset(): boolean {
    if (!this.lastFailure) return false;
    const cooldown = 60000; // 1 minute
    return Date.now() - this.lastFailure.getTime() > cooldown;
  }
}
```

**Benefits:**
- ✅ Prevents cascading failures
- ✅ Gives failing service time to recover
- ✅ Fails fast during outages

---

## Testing Patterns

### 1. Test Pyramid

**Problem:** Too many E2E tests, too slow, flaky.

**Solution:** Pyramid shape - many unit tests, fewer integration, minimal E2E.

**Distribution:**
```
        /\
       /E2\      10% - End-to-End (slow, brittle)
      /E2E2\
     /------\
    /  INT  \    20% - Integration (moderate)
   /________\
  /   UNIT   \   70% - Unit Tests (fast, reliable)
 /____________\
```

**Coverage Targets:**
- **Unit**: 80%+ coverage
- **Integration**: Key workflows covered
- **E2E**: Critical user journeys only

**Benefits:**
- ✅ Fast test suite
- ✅ Reliable (unit tests rarely flake)
- ✅ Easy to maintain
- ✅ Clear failure location

---

### 2. Arrange-Act-Assert (AAA)

**Problem:** Tests hard to understand, unclear what's being tested.

**Solution:** Structure all tests with AAA pattern.

**Implementation:**
```typescript
test('authenticateUser returns token for valid credentials', async () => {
  // Arrange - Set up test data
  const email = 'user@example.com';
  const password = 'password123';
  const mockUser = { id: 1, email };

  // Act - Perform the operation
  const result = await authenticateUser(email, password);

  // Assert - Verify the outcome
  expect(result.token).toBeDefined();
  expect(result.user).toEqual(mockUser);
});
```

**Benefits:**
- ✅ Clear test structure
- ✅ Easy to understand intent
- ✅ Consistent across codebase

---

### 3. Test Data Builders

**Problem:** Tests cluttered with object construction code.

**Solution:** Builder pattern for test data creation.

**Implementation:**
```typescript
class UserBuilder {
  private user = {
    id: 1,
    email: 'test@example.com',
    name: 'Test User',
    role: 'user'
  };

  withEmail(email: string) {
    this.user.email = email;
    return this;
  }

  withRole(role: string) {
    this.user.role = role;
    return this;
  }

  build() {
    return this.user;
  }
}

// Usage
const admin = new UserBuilder()
  .withEmail('admin@example.com')
  .withRole('admin')
  .build();
```

**Benefits:**
- ✅ Readable test setup
- ✅ Reusable across tests
- ✅ Easy to customize

---

## Security Patterns

### 1. Defense in Depth

**Problem:** Single security control can fail.

**Solution:** Multiple overlapping security layers.

**Layers:**
```
1. Input Validation:    Validate all user input
2. Authentication:      Verify user identity
3. Authorization:       Check permissions
4. Data Validation:     Validate before database
5. Output Encoding:     Prevent XSS
6. Audit Logging:       Track all actions
7. Rate Limiting:       Prevent abuse
```

**Example (API Endpoint):**
```typescript
app.post('/api/users', [
  // Layer 1: Input validation
  validateInput(userSchema),

  // Layer 2: Authentication
  requireAuth,

  // Layer 3: Authorization
  requireRole('admin'),

  // Layer 4: Data validation
  async (req, res) => {
    const sanitized = sanitizeInput(req.body);

    // Layer 5: Database validation
    await createUser(sanitized);

    // Layer 6: Audit log
    auditLog.info('User created', { by: req.user.id });

    // Layer 7: Rate limit (middleware)
    res.json({ success: true });
  }
]);
```

---

### 2. Principle of Least Privilege

**Problem:** Over-privileged agents can cause damage.

**Solution:** Grant minimum permissions required for task.

**Agent Permissions:**
```
Planner:     READ only  (can't modify code)
Builder:     WRITE, EDIT, BASH (can't review itself)
Tester:      BASH, READ (can't modify code)
Reviewer:    READ only  (can't implement changes)
Security:    READ only  (audits, doesn't fix)
```

**Benefits:**
- ✅ Limits blast radius of errors
- ✅ Clear responsibility boundaries
- ✅ Prevents accidental modifications
- ✅ Easier audit trail

---

### 3. Secure Defaults

**Problem:** Users forget to enable security features.

**Solution:** Security on by default, must explicitly disable.

**Examples:**
```json
{
  "security": {
    "auto_trigger_security_review": true,  // ON by default
    "block_sensitive_operations": [        // Blocked by default
      "DROP DATABASE",
      "TRUNCATE TABLE users"
    ]
  },
  "deployment": {
    "production_require_approval": true,   // ON by default
    "production_require_security_review": true
  }
}
```

**Benefits:**
- ✅ Safe by default
- ✅ Conscious decision to disable security
- ✅ Prevents accidents

---

## Performance Patterns

### 1. Strategic Model Selection

**Problem:** Using Opus for everything is expensive and slow.

**Solution:** Match model capability to task complexity.

**Model Strategy:**
```
Haiku (Fast, Cheap):
  - Testing (tester agent)
  - Documentation (doc-generator)
  - Routine refactoring
  - Code formatting

Sonnet (Balanced):
  - Feature implementation (builder)
  - Planning (planner)
  - Code review (reviewer)
  - Debugging

Opus (Slow, Expensive):
  - Security reviews (security agent)
  - Complex architecture decisions
  - Critical production issues
```

**Cost Comparison (per 1M tokens):**
```
Haiku:  $0.25 input / $1.25 output  (baseline)
Sonnet: $3.00 input / $15.00 output (12x more)
Opus:   $15.00 input / $75.00 output (60x more)
```

**Savings:**
- Using strategic mix: 60-80% cost reduction vs. all-Opus
- Minimal quality impact for appropriate tasks

**Configuration:**
```json
{
  "agent": {
    "tester": {
      "model": "anthropic/claude-haiku-4-20250514",
      "temperature": 0
    },
    "security": {
      "model": "anthropic/claude-opus-4-20250514",
      "temperature": 0
    }
  }
}
```

---

### 2. Batch Operations

**Problem:** Individual API calls for each item is slow and expensive.

**Solution:** Batch multiple operations into single call.

**Anti-Pattern:**
```typescript
// ❌ Slow: N API calls
for (const file of files) {
  await analyzeFile(file);
}
```

**Better:**
```typescript
// ✅ Fast: 1 API call
await analyzeFiles(files);
```

**Benefits:**
- ✅ Fewer API calls = lower cost
- ✅ Faster overall execution
- ✅ Lower rate limit impact

---

### 3. Lazy Loading

**Problem:** Loading everything upfront is slow.

**Solution:** Load only what's needed, when it's needed.

**Implementation:**
```typescript
// ❌ Eager loading
const allAgents = loadAllAgents();
const allWorkflows = loadAllWorkflows();
const allSkills = loadAllSkills();

// ✅ Lazy loading
function getAgent(name: string) {
  if (!agentCache[name]) {
    agentCache[name] = loadAgent(name);
  }
  return agentCache[name];
}
```

**Benefits:**
- ✅ Faster startup
- ✅ Lower memory usage
- ✅ Load only what's used

---

## Anti-Patterns (Avoid These)

### 1. ❌ God Agent

**Problem:** One agent doing everything.

```
❌ @superagent Plan, implement, test, review, and deploy feature X
```

**Why Bad:**
- Mixed responsibilities
- Over-privileged (security risk)
- Hard to debug
- No separation of concerns

**Instead:**
```
✅ @planner Create spec for feature X
✅ @builder Implement specs/feature-x.md
✅ @tester Run tests
✅ @reviewer Review implementation
```

---

### 2. ❌ No Specification

**Problem:** Implementing without clear requirements.

```
❌ @builder Add user profiles feature
   (What fields? What permissions? What validation?)
```

**Why Bad:**
- Misunderstood requirements
- Rework needed
- Inconsistent implementation
- Hard to review

**Instead:**
```
✅ @planner Create spec for user profiles
✅ (Review and approve spec)
✅ @builder Implement specs/user-profiles.md
```

---

### 3. ❌ Skipping Tests

**Problem:** No tests written with implementation.

```
❌ @builder Implement feature X
   (Builder skips writing tests to "save time")
```

**Why Bad:**
- Bugs found late (expensive to fix)
- No regression protection
- Hard to refactor later
- Lower confidence in code

**Instead:**
```
✅ @builder Implement feature X with comprehensive tests
✅ @tester Run tests and check coverage
✅ (Coverage must be >80%)
```

---

### 4. ❌ Production Cowboy

**Problem:** Deploying to production without validation.

```
❌ git push origin main --force
   (No tests, no review, no approval)
```

**Why Bad:**
- Can break production
- No rollback plan
- No audit trail
- Can't reproduce issue

**Instead:**
```
✅ @tester Run full test suite
✅ @reviewer Review changes
✅ @security Review if auth/payment touched
✅ (Get approval from team lead)
✅ Deploy to staging first
✅ Run smoke tests
✅ Deploy to production with canary rollout
```

---

### 5. ❌ Ignoring Guardrails

**Problem:** Disabling safety controls for convenience.

```
❌ Set all guardrails to false
❌ Unlimited budget
❌ No audit logging
❌ Builder can do anything
```

**Why Bad:**
- No safety net
- Expensive mistakes possible
- No audit trail
- Security risks

**Instead:**
```
✅ Keep guardrails enabled
✅ Set appropriate budgets
✅ Enable full audit logging
✅ Minimal agent permissions
✅ Only disable specific guardrails when justified and documented
```

---

## Pattern Selection Guide

**For New Features:**
1. Spec Artifact Pattern (always)
2. Planner → Builder → Tester Flow
3. Single Responsibility Agents
4. Defense in Depth (if security-sensitive)

**For Hotfixes:**
1. Hotfix Pattern
2. Fail-Fast Validation
3. Graceful Degradation
4. Retry with Backoff

**For Production:**
1. Incident Response Pattern (if issue occurs)
2. Security Review Pattern (always)
3. Circuit Breaker (for external services)
4. Layered Guardrails

**For Cost Optimization:**
1. Strategic Model Selection
2. Batch Operations
3. Lazy Loading

**For Testing:**
1. Test Pyramid
2. Arrange-Act-Assert
3. Test Data Builders

---

## Summary

**Core Principles:**
1. ✅ Specifications before implementation
2. ✅ Single responsibility per agent
3. ✅ Defense in depth for security
4. ✅ Fail fast with clear errors
5. ✅ Strategic model selection for cost
6. ✅ Comprehensive testing always
7. ✅ Graceful degradation for resilience

**Anti-Patterns to Avoid:**
1. ❌ God agents (one agent for everything)
2. ❌ No specifications
3. ❌ Skipping tests
4. ❌ Production cowboy deployments
5. ❌ Ignoring guardrails

**For More:**
- **Workflows**: `workflows/` directory
- **Examples**: `examples/` directory (coming soon)
- **Architecture**: `ARCHITECTURE.md`
- **Troubleshooting**: `TROUBLESHOOTING.md`

---

*Last updated: 2026-02-17*
