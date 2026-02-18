# Example: Complete Feature Implementation

**Building a user profile feature from planning to deployment.**

---

## Scenario

We need to add user profile functionality to our application:
- Users can view their profile
- Users can edit their name, email, bio
- Profile data is validated
- Changes are saved to database

**Tech Stack:**
- TypeScript + Express backend
- React frontend
- PostgreSQL database

---

## Prerequisites

- OpenCode setup complete
- Git repository initialized
- Database running
- Test suite configured

**Verify:**
```bash
bash ~/.config/opencode/scripts/health-check.sh
```

---

## Step-by-Step Walkthrough

### Step 1: Planning (5 minutes)

**Command:**
```
@planner Create a spec for user profile feature with view and edit functionality
```

**Planner Output:**
```
Creating specification for user profile feature...

Analysis:
- Need profile viewing endpoint (GET /api/users/:id/profile)
- Need profile updating endpoint (PUT /api/users/:id/profile)
- Frontend components for ProfileView and ProfileEdit
- Validation for email format, bio length
- Authentication required for both operations

Spec created: specs/user-profile-2024-02-14.md

Key sections:
✓ Problem Statement
✓ Constraints
✓ Proposed Approach
✓ Acceptance Criteria
✓ Task Breakdown
✓ Risks Identified

Review spec before implementation.
```

**Review the Spec:**
```bash
cat specs/user-profile-2024-02-14.md
```

**Spec Contents (excerpt):**
```markdown
# Specification: User Profile Feature

## Problem Statement
Users need ability to view and edit their profile information.

## Constraints
- Must authenticate before accessing profile
- Email must be unique in database
- Bio limited to 500 characters
- Can only edit own profile

## Acceptance Criteria
- [ ] GET /api/users/:id/profile returns profile data
- [ ] PUT /api/users/:id/profile updates profile
- [ ] Validation errors return 400 with details
- [ ] Non-owners get 403 Forbidden
- [ ] Unit tests for all endpoints
- [ ] Integration tests for full flow

## Task Breakdown
1. Backend: GET endpoint
2. Backend: PUT endpoint with validation
3. Frontend: ProfileView component
4. Frontend: ProfileEdit component
5. Tests: Backend unit tests
6. Tests: Integration tests
7. Documentation: API docs updated

## Estimated Time: 45 minutes
```

**Duration:** 5 minutes

---

### Step 2: Implementation (25 minutes)

**Command:**
```
@builder Implement specs/user-profile-2024-02-14.md
```

**Builder Output:**
```
Implementing user profile feature based on spec...

Reading spec: specs/user-profile-2024-02-14.md
✓ Spec validated

Creating backend API:
✓ Created src/api/profile.ts (GET /api/users/:id/profile)
✓ Created src/api/profile.ts (PUT /api/users/:id/profile)
✓ Added validation with Joi schema
✓ Added authentication middleware check
✓ Added ownership check (user can only edit own profile)

Creating frontend components:
✓ Created src/components/ProfileView.tsx
✓ Created src/components/ProfileEdit.tsx
✓ Added form validation
✓ Added API integration
✓ Added loading/error states

Creating tests:
✓ Created src/api/profile.test.ts (unit tests)
✓ Created tests/integration/profile.test.ts (integration tests)
✓ Added test fixtures for user data
✓ Tests cover all acceptance criteria

Files created/modified: 8
Lines added: 487
Tests added: 23

Implementation complete.
```

**Verify Changes:**
```bash
git status
git diff src/api/profile.ts
```

**Created Files:**
```
src/api/profile.ts
src/components/ProfileView.tsx
src/components/ProfileEdit.tsx
src/api/profile.test.ts
tests/integration/profile.test.ts
```

**Duration:** 25 minutes

---

### Step 3: Testing (5 minutes)

**Command:**
```
@tester Run comprehensive tests
```

**Tester Output:**
```
Running test suite...

Test Results:
✓ Unit Tests: 23/23 passed (0 failed)
✓ Integration Tests: 5/5 passed (0 failed)

Total: 28/28 tests passed

Coverage Report:
src/api/profile.ts:        95.2% (60/63 lines)
src/components/ProfileView.tsx: 88.7% (47/53 lines)
src/components/ProfileEdit.tsx: 91.3% (42/46 lines)

Overall Coverage: 92.1%
Target: 80% ✓

Test Execution Time: 3.4s

All tests passing! ✓
```

**Manual Verification (Optional):**
```bash
npm test
npm run coverage
```

**Duration:** 5 minutes

---

### Step 4: Code Review (8 minutes)

**Command:**
```
@reviewer Review implementation against specs/user-profile-2024-02-14.md
```

**Reviewer Output:**
```
Reviewing implementation for spec compliance...

Spec Compliance:
✓ GET /api/users/:id/profile implemented
✓ PUT /api/users/:id/profile implemented
✓ Validation implemented (email, bio length)
✓ Authentication check present
✓ Ownership check present
✓ Unit tests cover all endpoints
✓ Integration tests cover full flow
✓ All acceptance criteria met

Code Quality Review:

Positives:
✓ Clean separation of concerns
✓ Proper error handling
✓ Good test coverage (92.1%)
✓ TypeScript types properly defined
✓ Input validation comprehensive

Issues Found: 2 MEDIUM, 1 LOW

MEDIUM - src/api/profile.ts:45
  Missing rate limiting on PUT endpoint
  Recommendation: Add rate limit (10 updates/minute)

MEDIUM - src/components/ProfileEdit.tsx:78
  No client-side debouncing on form validation
  Recommendation: Debounce validation by 300ms

LOW - src/api/profile.ts:23
  Magic number 500 for bio length
  Recommendation: Extract to constant BIO_MAX_LENGTH

Overall Assessment: APPROVED with recommendations

The implementation meets all spec requirements. Address MEDIUM issues
before production deployment.
```

**Address Issues:**
```
@builder Fix the issues from code review
```

**Builder:**
```
Addressing code review feedback...

✓ Added rate limiting middleware to PUT endpoint (10/min)
✓ Added debouncing to ProfileEdit form validation (300ms)
✓ Extracted BIO_MAX_LENGTH constant

Files modified: 2
Re-running tests...
✓ All tests still passing

Issues resolved.
```

**Duration:** 8 minutes

---

### Step 5: Commit Changes (2 minutes)

**Check Changes:**
```bash
git status
git diff
```

**Create Commit:**
```bash
git add src/ tests/
git commit -m "feat: add user profile view and edit functionality

- Add GET /api/users/:id/profile endpoint
- Add PUT /api/users/:id/profile endpoint
- Add ProfileView and ProfileEdit components
- Add comprehensive test coverage (92.1%)
- Add rate limiting and input validation

Closes #USER-123

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

**Output:**
```
[feature/user-profile abc1234] feat: add user profile view and edit functionality
 8 files changed, 487 insertions(+), 2 deletions(-)
 create mode 100644 src/api/profile.ts
 create mode 100644 src/components/ProfileView.tsx
 create mode 100644 src/components/ProfileEdit.tsx
 create mode 100644 src/api/profile.test.ts
 create mode 100644 tests/integration/profile.test.ts
```

**Duration:** 2 minutes

---

### Step 6: Create Pull Request (5 minutes)

**Push Branch:**
```bash
git push origin feature/user-profile
```

**Create PR:**
```bash
gh pr create --title "feat: Add user profile view and edit functionality" \
  --body "## Summary
- Adds user profile viewing (GET /api/users/:id/profile)
- Adds user profile editing (PUT /api/users/:id/profile)
- Adds ProfileView and ProfileEdit React components
- Comprehensive validation and error handling
- 92.1% test coverage

## Implementation Details
- Authentication required for all endpoints
- Users can only view/edit their own profile
- Email validation and uniqueness check
- Bio limited to 500 characters
- Rate limiting on update endpoint (10/min)
- Form validation debounced on frontend

## Test Plan
- [x] All unit tests passing (23/23)
- [x] All integration tests passing (5/5)
- [x] Manual testing in development
- [ ] QA testing in staging
- [ ] Product review

## Security Considerations
- Authentication required
- Ownership verification prevents unauthorized edits
- Input validation prevents injection attacks
- Rate limiting prevents abuse

## Related
- Spec: specs/user-profile-2024-02-14.md
- Issue: #USER-123

🤖 Generated with OpenCode"
```

**PR Created:**
```
https://github.com/yourorg/yourrepo/pull/456
```

**Duration:** 5 minutes

---

## Step 7: Deployment (After PR Approval)

**Merge PR:**
```bash
gh pr merge 456 --squash
```

**Deploy to Staging:**
```bash
git checkout main
git pull origin main
npm run deploy:staging
```

**Verify on Staging:**
```bash
# Test endpoints
curl https://staging.example.com/api/users/123/profile

# Check frontend
open https://staging.example.com/profile
```

**Deploy to Production:**
```bash
npm run deploy:production
```

**Verify on Production:**
```bash
curl https://example.com/api/users/123/profile
```

**Duration:** Variable (depends on CI/CD)

---

## Expected Outcome

**What You Built:**
- ✅ Complete user profile feature
- ✅ Backend API endpoints
- ✅ Frontend React components
- ✅ Comprehensive tests (92.1% coverage)
- ✅ Input validation and security
- ✅ Rate limiting
- ✅ Clean, reviewed code
- ✅ Deployed to production

**Files Created:**
- `specs/user-profile-2024-02-14.md` (specification)
- `src/api/profile.ts` (backend API)
- `src/components/ProfileView.tsx` (frontend view)
- `src/components/ProfileEdit.tsx` (frontend edit)
- `src/api/profile.test.ts` (unit tests)
- `tests/integration/profile.test.ts` (integration tests)

**Metrics:**
- Lines of code: 487
- Tests: 28
- Coverage: 92.1%
- Time: ~45 minutes (planning to PR)

---

## Common Issues

### Issue 1: Tests Failing After Implementation

**Symptom:**
```
@tester Run tests
❌ 3 tests failing
```

**Solution:**
```
@debug Investigate test failures
@builder Fix issues based on debug findings
@tester Re-run tests
```

---

### Issue 2: Spec Too Vague

**Symptom:**
```
@builder implementation doesn't match expectations
```

**Solution:**
```
@planner Refine spec with more details
@reviewer Review spec before implementation
@builder Re-implement with clarified spec
```

---

### Issue 3: Security Review Needed

**Symptom:**
```
@reviewer flags security concerns
```

**Solution:**
```
@security Review src/api/profile.ts for vulnerabilities
@builder Address security issues
@security Re-review
```

---

## Time Breakdown

| Phase | Duration | Agent |
|-------|----------|-------|
| Planning | 5 min | @planner |
| Implementation | 25 min | @builder |
| Testing | 5 min | @tester |
| Review | 8 min | @reviewer |
| Fixes | (included above) | @builder |
| Commit | 2 min | Manual |
| PR Creation | 5 min | Manual |
| **Total** | **~45 min** | |

**Note:** Deployment time excluded (varies by CI/CD setup)

---

## Variations

### With Security Review (Add 10 minutes)

```
@planner Create spec
@security Review spec for security issues
@builder Implement spec
@tester Run tests
@security Review implementation
@reviewer Review code quality
```

**Total:** ~55 minutes

---

### With Database Migration (Add 15 minutes)

```
@planner Create spec
@migration Create migration for profile table
@builder Implement spec
@tester Test migration + feature
@reviewer Review all changes
```

**Total:** ~60 minutes

---

### Quick Prototype (Skip Some Steps)

```
@planner Create brief spec
@builder Implement with tests
@tester Run tests
```

**Total:** ~30 minutes
**Trade-off:** Less thorough review, higher risk

---

## Related Examples

- **Security Feature**: `security-feature-example.md`
- **Database Migration**: `database-migration-example.md`
- **Bug Fix**: `bug-fix-example.md`

---

## Related Documentation

- **Workflow**: `../workflows/feature_implementation.md`
- **Patterns**: `../PATTERNS.md`
- **Agents**: `../agents/QUICK_REFERENCE.md`

---

**Congratulations!** You've completed a full feature implementation using OpenCode agents. This workflow ensures high-quality, well-tested, reviewed code in under an hour.

*Last updated: 2026-02-17*
