# Feature Implementation Workflow

This workflow demonstrates the complete pipeline for implementing a new feature using the agent system.

## Overview: Spec → Execute → Verify → Ship

This is the production-grade workflow using specialized agents at each stage.

## Phase 1: Planning (Planner Agent)

### Input
User request or product requirement:
```
"Add user profile editing functionality where users can update their bio, avatar, and contact information"
```

### Process

**Invoke Planner Agent:**
```
@planner Create a spec for user profile editing feature
```

**Planner Responsibilities:**
1. Research existing user model
2. Identify authentication patterns
3. Review similar features in codebase
4. Create comprehensive specification
5. Define acceptance criteria
6. Identify risks and constraints

### Output

**Spec File:** `specs/2026-02-13-add-user-profiles.md`

```markdown
# User Profile Editing

## Problem
Users need ability to customize their profiles with bio, avatar, and contact info.

## Constraints
- Must respect privacy settings
- File uploads limited to 5MB
- Only user can edit their own profile
- No breaking changes to existing API

## Proposed Approach
Add PUT /api/users/:id/profile endpoint with validation.

## Acceptance Criteria
- [ ] User can update bio (max 500 chars)
- [ ] User can upload avatar image
- [ ] User can update contact information
- [ ] Validation prevents XSS
- [ ] Authorization ensures user edits own profile only
- [ ] API returns updated profile
- [ ] Tests cover happy path and errors

## Risks
- File upload security (XSS, malware)
- Race conditions on profile updates
- Privacy implications

## Task Breakdown
1. Create ProfileController
2. Add validation middleware
3. Implement file upload handling
4. Add authorization checks
5. Write comprehensive tests
6. Update API documentation
```

### Human Review
- [ ] Review spec for completeness
- [ ] Approve or request changes
- [ ] Clarify ambiguities

---

## Phase 2: Implementation (Builder Agent)

### Input
Approved spec from Phase 1

### Process

**Invoke Builder Agent:**
```
@builder Implement the feature according to specs/2026-02-13-add-user-profiles.md
```

**Builder Responsibilities:**
1. Read and understand spec
2. Follow existing code patterns
3. Implement specified functionality
4. Write/update tests
5. Run fast validation (lint, typecheck, unit tests)
6. Fix any validation failures

### Output

**Files Created/Modified:**
```
src/controllers/profile.controller.ts  (created)
src/middleware/validation.ts           (modified)
src/routes/profile.routes.ts           (created)
tests/profile.controller.spec.ts       (created)
tests/profile.integration.spec.ts      (created)
docs/api/profile.md                    (created)
```

**Validation Results:**
```
✅ Linting: Passed
✅ Type checking: Passed
✅ Unit tests: 18/18 passed
✅ Coverage: 92%
```

### Auto-Fix Loop
If validation fails:
1. Builder attempts to fix (max 2 attempts)
2. If still failing: escalate to Debug agent
3. Debug agent analyzes root cause
4. Provides fix recommendations

---

## Phase 3: Testing (Tester Agent)

### Input
Implementation from Builder

### Process

**Invoke Tester Agent:**
```
@tester Run comprehensive tests for the profile feature
```

**Tester Responsibilities:**
1. Run full test suite
2. Execute integration tests
3. Check coverage metrics
4. Generate structured report
5. Identify failure patterns

### Output

**Test Report:**
```json
{
  "status": "passed",
  "summary": {
    "total": 265,
    "passed": 265,
    "failed": 0,
    "duration_ms": 12340
  },
  "coverage": {
    "lines": 87,
    "branches": 82,
    "functions": 94
  },
  "new_files": {
    "profile.controller.ts": {
      "coverage": 92,
      "tests": 18
    }
  }
}
```

### If Tests Fail

**Failure Slice sent to Builder:**
```json
{
  "failures": [
    {
      "test": "profile.spec.ts:45 > should validate bio length",
      "error": "Expected 400, received 200",
      "relevant_code": "src/controllers/profile.controller.ts:67-75"
    }
  ],
  "suggested_fixes": [
    "Add bio length validation in controller"
  ]
}
```

Builder fixes → Tester re-runs → Repeat until passing (max 2 iterations)

---

## Phase 4: Review (Reviewer Agent)

### Input
Passing implementation from Builder + Tester

### Process

**Invoke Reviewer Agent:**
```
@reviewer Review the profile editing implementation
```

**Reviewer Responsibilities:**
1. Verify spec compliance
2. Check code quality
3. Security review
4. Performance assessment
5. Test coverage validation
6. Edge case verification

### Output

**Review Report:**
```markdown
## Code Review

### Status
**APPROVED WITH MINOR SUGGESTIONS**

### Spec Compliance
✅ All acceptance criteria met
✅ No unspecified features added
✅ Follows constraints

### Code Quality
✅ Clean, readable code
✅ Follows existing patterns
✅ Proper error handling

### Security Review
⚠️ **REQUIRES SECURITY AGENT REVIEW**
This change involves file uploads and user data.

### Test Coverage
✅ Coverage: 92% (above threshold)
✅ Comprehensive test suite
✅ Edge cases covered

### Minor Suggestions
1. Consider adding rate limiting for file uploads
2. Add monitoring for upload failures

### Verdict
Approve after security review.
```

---

## Phase 5: Security Review (Security Agent)

**Triggered by Reviewer for file upload functionality**

### Process

**Invoke Security Agent:**
```
@security Review file upload security in profile feature
```

**Security Agent Responsibilities:**
1. Validate file upload security
2. Check for XSS vulnerabilities
3. Verify authorization
4. Review input validation
5. Check for common OWASP issues

### Output

**Security Report:**
```markdown
## Security Review

### Risk Level: MEDIUM

### Findings

#### File Upload Security
✅ File type validation present
✅ File size limits enforced (5MB)
✅ Files stored outside web root
⚠️ Add virus scanning for production

#### Authorization
✅ User can only edit own profile
✅ JWT validation present

#### Input Validation
✅ Bio sanitized against XSS
✅ SQL injection prevented (parameterized queries)

#### Recommendations
1. Add virus scanning via ClamAV or similar
2. Implement rate limiting (5 uploads/hour)
3. Add Content Security Policy headers
4. Log upload attempts for monitoring

### Verdict
**APPROVED** with recommendations for production hardening.
```

---

## Phase 6: PR Creation & Merge

### Create Pull Request

**Using git-workflow skill:**
```bash
git add .
git commit -m "feat: add user profile editing

- Implement profile update endpoint
- Add file upload handling
- Include comprehensive test suite
- Pass security review

Implements: specs/2026-02-13-add-user-profiles.md"

git push origin feature/user-profiles

gh pr create --title "feat: Add user profile editing" \
  --body "[PR description with spec link, testing results, security notes]"
```

### CI/CD Pipeline

**Automated checks:**
- Linting ✅
- Type checking ✅
- Test suite ✅
- Coverage threshold ✅
- Security scan ✅
- Build ✅

### Human Approval

- [ ] Tech lead review
- [ ] Product manager approval
- [ ] (Optional) Security team sign-off

### Merge

```bash
gh pr merge --squash --delete-branch
```

---

## Phase 7: Deployment

### Staging Deployment

```bash
# Deploy to staging
npm run deploy:staging

# Smoke tests
npm run test:smoke -- --env=staging
```

**Monitoring:**
- [ ] Application healthy
- [ ] No errors in logs
- [ ] Feature works as expected

### Production Deployment

```bash
# Gradual rollout
npm run deploy:production --canary=5

# Monitor for 30 minutes
# If healthy: full deployment
npm run deploy:production --percentage=100
```

---

## Complete Workflow Diagram

```
User Request
    ↓
┌─────────────────┐
│ Planner Agent   │ → Create spec
│ (Read-only)     │
└────────┬────────┘
         │ spec artifact
         ↓
    Human Review
         ↓ (approved)
┌─────────────────┐
│ Builder Agent   │ → Implement code
│ (Write + Exec)  │ → Write tests
└────────┬────────┘
         │ implementation
         ↓
┌─────────────────┐
│ Tester Agent    │ → Run tests
│ (Execute-only)  │ → Generate report
└────────┬────────┘
         │ test results
         ↓
    ┌───────┐
    │ Pass? │
    └───┬───┘
        │ No (< 3 failures)
        ├──→ Failure Slice → Builder (fix)
        │
        │ Yes
        ↓
┌─────────────────┐
│ Reviewer Agent  │ → Code review
│ (Read-only)     │ → Check quality
└────────┬────────┘
         │ review
         ↓
  ┌──────────────┐
  │ Security     │
  │ sensitive?   │
  └──┬───────────┘
     │ Yes
     ↓
┌─────────────────┐
│ Security Agent  │ → Security audit
│ (Read-only)     │
└────────┬────────┘
         │
         ↓
    All Approved
         ↓
  Create PR → CI → Human Approval → Merge → Deploy
```

---

## Agent Interaction Examples

### Parallel Agent Invocation
For large features, run agents in parallel:

```bash
# In parallel:
@planner Research authentication patterns
@planner Research database schema
@planner Research API patterns

# Results combined into single spec
```

### Sequential Agent Chain
For complex debugging:

```
Builder fails → Tester identifies failures → Debug agent analyzes → Builder fixes
```

### Conditional Agent Triggers
Automatic invocations:

```
If touching:
  - auth/ → Security agent
  - migrations/ → Migration agent
  - performance-critical/ → Performance agent
```

---

## Metrics & Success Criteria

### Speed
- Planning: 5-10 minutes
- Implementation: 15-30 minutes
- Testing: 5 minutes
- Review: 10 minutes
- **Total: 35-55 minutes** (for medium feature)

### Quality
- Test coverage > 80%
- No security vulnerabilities
- Spec compliance: 100%
- Code review approval

### Reliability
- < 5% of features require human debugging
- < 2% rollback rate
- First-time merge success > 90%

---

## Best Practices

1. **Always start with spec** - Never skip planning
2. **Keep specs focused** - One feature per spec
3. **Trust the agents** - But verify critical changes
4. **Monitor agent outputs** - Improve prompts over time
5. **Human in the loop** - For critical decisions
6. **Iterate quickly** - Fast feedback loops
7. **Document learnings** - Update agent prompts based on patterns

This workflow represents the ideal path from idea to production using the production-grade agent architecture.
