# Pull Request Workflow

This workflow guides the process of creating a pull request from a completed feature implementation.

## Workflow: Plan → Build → Test → Review → PR

### Step 1: Ensure Implementation is Complete

**Checklist:**
- [ ] All acceptance criteria from spec are met
- [ ] Code follows project conventions
- [ ] Tests written and passing
- [ ] Documentation updated
- [ ] No debug statements or console.logs
- [ ] No TODOs without tickets

### Step 2: Run Local Validation

```bash
# Linting
npm run lint

# Type checking
npm run typecheck

# Tests
npm test

# Build (if applicable)
npm run build
```

**All checks must pass before proceeding.**

### Step 3: Commit Changes

```bash
# Stage changes
git add .

# Commit with conventional commit format
git commit -m "feat: add user profile editing

- Implement profile update endpoint
- Add validation for profile fields
- Create comprehensive test suite
- Update API documentation

Implements: specs/2026-02-13-user-profiles.md"
```

### Step 4: Push to Remote

```bash
# Push feature branch
git push origin feature/user-profiles
```

### Step 5: Create Pull Request

```bash
# Using GitHub CLI
gh pr create \
  --title "feat: Add user profile editing" \
  --body "$(cat <<'EOF'
## Summary
Implements user profile editing functionality allowing users to update their bio, avatar, and contact information.

## Spec
`specs/2026-02-13-user-profiles.md`

## Changes
- Added `ProfileController` with update endpoint
- Implemented validation for profile fields
- Created comprehensive test suite (unit + integration)
- Updated API documentation

## Testing
- [x] Unit tests: 18/18 passed
- [x] Integration tests: 4/4 passed
- [x] Manual testing complete
- [x] Coverage: 92% (above 80% threshold)

## Security Considerations
- Input validation on all fields
- Authorization check ensures users can only edit own profile
- XSS protection via output sanitization

## Performance
- Single database query for update
- Optimistic locking prevents race conditions

## Checklist
- [x] Code follows style guide
- [x] Tests added and passing
- [x] Documentation updated
- [x] No breaking changes
- [x] Backwards compatible
- [x] Security review (if needed)
- [x] Performance tested

## Screenshots (if applicable)
N/A - Backend API change only

## Additional Notes
None
EOF
)"
```

### Step 6: Wait for CI/CD

Monitor CI checks:
- Linting
- Type checking
- Test suite
- Coverage threshold
- Security scan
- Build process

**All CI checks must pass.**

### Step 7: Request Reviews

```bash
# Request specific reviewers
gh pr edit --add-reviewer @tech-lead,@team-member
```

**For changes requiring special review:**
- Security-sensitive code → Tag security team
- Database migrations → Tag DBA
- API changes → Tag API team
- Performance critical → Tag performance team

### Step 8: Address Feedback

When reviewers request changes:

1. **Read feedback carefully**
2. **Ask clarifying questions** if needed
3. **Make requested changes**
4. **Commit and push updates**
   ```bash
   git add .
   git commit -m "refactor: address review feedback

   - Extracted validation logic
   - Added error handling as suggested
   - Improved test coverage"
   git push
   ```
5. **Respond to comments**
6. **Re-request review**

### Step 9: Merge

Once approved and CI passes:

**Merge strategies:**
- **Squash merge**: For feature branches (clean history)
- **Merge commit**: For release branches (preserve history)
- **Rebase**: For small, clean branches

```bash
# Squash merge via CLI
gh pr merge --squash --delete-branch
```

**Post-merge:**
- [ ] Verify deployment (if auto-deploy enabled)
- [ ] Monitor for errors
- [ ] Update issue/ticket status
- [ ] Celebrate! 🎉

## Common Issues & Solutions

### CI Failing
```
Problem: Tests pass locally but fail in CI
Solution:
- Check for environment differences
- Verify dependencies installed correctly
- Look for timing/race condition issues
- Check for missing environment variables
```

### Merge Conflicts
```
Problem: Branch has conflicts with base
Solution:
git checkout feature/user-profiles
git pull origin main
# Resolve conflicts
git add .
git commit -m "chore: resolve merge conflicts"
git push
```

### Coverage Below Threshold
```
Problem: Code coverage dropped below required threshold
Solution:
- Add tests for untested paths
- Test error cases
- Test edge cases
- Aim for 80%+ coverage
```

## PR Description Template

```markdown
## Summary
[Brief description of changes]

## Spec
[Link to spec file]

## Changes
- [List of changes]

## Testing
- [ ] Unit tests
- [ ] Integration tests
- [ ] Manual testing
- [ ] Coverage: X%

## Security Considerations
[Any security implications]

## Performance
[Performance impact if any]

## Checklist
- [ ] Code follows style guide
- [ ] Tests added
- [ ] Documentation updated
- [ ] No breaking changes
- [ ] Security review (if needed)

## Screenshots
[If UI changes]

## Additional Notes
[Anything else reviewers should know]
```

## Automation Tips

### GitHub Actions Workflow
```yaml
# .github/workflows/pr.yml
name: PR Checks
on: [pull_request]
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - run: npm ci
      - run: npm run lint
      - run: npm run typecheck
      - run: npm test
      - run: npm run build
```

### Pre-push Hook
```bash
# .git/hooks/pre-push
#!/bin/bash
npm run lint && npm run typecheck && npm test
```

This workflow ensures high-quality pull requests that are easy to review and safe to merge.
