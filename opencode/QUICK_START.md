# Quick Start Guide

Get started with the production-grade agent architecture in 5 minutes.

## Prerequisites

✅ OpenCode installed and working
✅ Git configured
✅ Node.js/npm installed (for MCP servers)

## Step 1: Configure MCP Servers (Optional but Recommended)

### GitHub MCP

1. Create a GitHub Personal Access Token:
   - Go to https://github.com/settings/tokens
   - Generate new token (classic)
   - Select scopes: `repo`, `read:org`, `read:user`

2. Edit `~/.config/opencode/opencode.json`:
   ```json
   "mcp": {
     "github": {
       "environment": {
         "GITHUB_PERSONAL_ACCESS_TOKEN": "your_token_here"
       }
     }
   }
   ```

### Linear MCP

1. Get Linear API key:
   - Go to https://linear.app/settings/api
   - Create new API key

2. Edit `~/.config/opencode/opencode.json`:
   ```json
   "mcp": {
     "linear": {
       "environment": {
         "LINEAR_API_KEY": "your_api_key_here"
       }
     }
   }
   ```

### Context7 MCP

Context7 requires no configuration - it works out of the box!

## Step 2: Test Basic Agents

### Test Planner Agent

```
@planner Create a spec for adding a simple health check endpoint
```

**Expected**: Creates a spec file in `~/.config/opencode/specs/`

### Test Builder Agent

```
@builder Implement a hello world function in a new file
```

**Expected**: Creates code file with implementation

### Test Reviewer Agent

```
@reviewer Review the hello world implementation
```

**Expected**: Provides code review feedback

## Step 3: Try a Complete Workflow

### Example: Add a Simple Feature

**1. Plan it:**
```
@planner Create a spec for adding user email validation to the registration form
```

**2. Review the spec:**
- Check the generated spec in `~/.config/opencode/specs/`
- Make sure it matches your requirements

**3. Implement it:**
```
@builder Implement the feature from specs/2026-02-13-email-validation.md
```

**4. Test it:**
```
@tester Run all tests and provide coverage report
```

**5. Review it:**
```
@reviewer Review the email validation implementation
```

**6. If it's security-sensitive:**
```
@security Review the email validation for security issues
```

## Step 4: Use Specialized Agents

### When to Use Each Agent

**@planner** - Start every feature here
```
@planner Plan implementation for [feature description]
```

**@builder** - After spec is approved
```
@builder Implement specs/[spec-file].md
```

**@tester** - After implementation
```
@tester Run comprehensive tests
```

**@reviewer** - Before creating PR
```
@reviewer Review the implementation
```

**@security** - For sensitive code
```
@security Review authentication implementation
```

**@migration** - For database changes
```
@migration Create migration for adding users.email_verified column
```

**@performance** - For optimization
```
@performance Optimize the user search endpoint
```

**@refactor** - For code cleanup
```
@refactor Improve the authentication service code quality
```

**@debug** - When stuck on a bug
```
@debug Analyze why login tests are failing
```

## Step 5: Create Your First Feature (Full Example)

Let's add a simple feature together:

**Feature**: Add a `/health` endpoint that returns system status

### 1. Planning Phase

```
@planner Create a spec for adding a health check endpoint that returns:
- status (ok/error)
- timestamp
- version from package.json
```

**Planner creates**: `specs/2026-02-13-health-endpoint.md`

### 2. Implementation Phase

```
@builder Implement the health endpoint from specs/2026-02-13-health-endpoint.md
```

**Builder creates**:
- `src/routes/health.ts`
- `src/controllers/health.controller.ts`
- `tests/health.spec.ts`

### 3. Testing Phase

```
@tester Run tests for the health endpoint
```

**Tester reports**:
```json
{
  "status": "passed",
  "summary": { "total": 5, "passed": 5, "failed": 0 },
  "coverage": { "lines": 100 }
}
```

### 4. Review Phase

```
@reviewer Review the health endpoint implementation
```

**Reviewer provides**:
```markdown
## Code Review

### Status: APPROVED

✅ Spec compliance met
✅ Tests comprehensive
✅ Clean implementation

### Minor suggestions:
- Consider caching version info
```

### 5. Ship It!

```bash
git add .
git commit -m "feat: add health check endpoint"
git push
gh pr create
```

Done! ✅

## Common Commands

### Quick Reference

```bash
# Planning
@planner Plan [feature description]

# Implementation
@builder Implement specs/[spec-file].md
@builder Fix the failing tests in auth.spec.ts

# Testing
@tester Run all tests
@tester Run unit tests only
@tester Test with coverage

# Review
@reviewer Review the implementation
@reviewer Check spec compliance

# Specialized
@security Review [security-sensitive code]
@migration Create migration for [schema change]
@performance Optimize [slow component]
@refactor Clean up [messy code]
@debug Analyze [failure/bug]
```

## Tips for Success

### ✅ DO

1. **Always start with a spec** - Don't skip planning
2. **Review specs before implementing** - Catch issues early
3. **Keep specs focused** - One feature per spec
4. **Trust the process** - Let agents do their specialized jobs
5. **Use appropriate agents** - Right tool for the job

### ❌ DON'T

1. **Don't skip planning** - Leads to rework
2. **Don't combine multiple features** - Keep specs atomic
3. **Don't manually fix what agents should do** - Use the right agent
4. **Don't bypass security reviews** - Safety first
5. **Don't ignore agent feedback** - They catch real issues

## Troubleshooting

### Agent not responding?

Check `opencode.json`:
```json
{
  "agent": {
    "planner": {
      "mode": "subagent",  // Should be "subagent" or "all"
      "model": "anthropic/claude-sonnet-4-20250514"
    }
  }
}
```

### Tests failing?

```
@debug Analyze the test failures in [test-file]
```

### Can't merge PR?

```
@reviewer Review why CI is failing
```

### Need to optimize?

```
@performance Profile and optimize [component]
```

### Code is messy?

```
@refactor Improve code quality in [file]
```

## Next Steps

1. **Read the full docs**: [README.md](README.md)
2. **Understand architecture**: [ARCHITECTURE.md](ARCHITECTURE.md)
3. **Study workflows**: [workflows/](workflows/)
4. **Review examples**: [specs/example-user-profiles.md](specs/example-user-profiles.md)

## Getting Help

- Check [README.md](README.md) for detailed documentation
- Review [workflows/](workflows/) for common patterns
- Look at [specs/example-user-profiles.md](specs/example-user-profiles.md) for a complete example
- Consult [ARCHITECTURE.md](ARCHITECTURE.md) for system design details

## Success Metrics

Track these to measure your agent system effectiveness:

- ⚡ **Speed**: Time from idea to implementation
- ✅ **Quality**: Test coverage, bug rate
- 💰 **Cost**: API costs per feature
- 🎯 **Success Rate**: First-time implementation success

---

**You're ready! Start with a simple feature and work your way up.** 🚀

Remember: **Reliability beats flash. Build for control first, autonomy second.**
