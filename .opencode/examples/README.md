# OpenCode Examples

**Real-world examples of using OpenCode agents and workflows.**

---

## Available Examples

### 1. [Complete Feature Implementation](feature-implementation-example.md)

Full walkthrough of implementing a user profile feature from planning to deployment.

**Covers:**
- Specification creation
- Implementation
- Testing
- Code review
- Deployment

**Duration:** ~45 minutes
**Agents Used:** @planner, @builder, @tester, @reviewer

---

### 2. [Security-Sensitive Feature](security-feature-example.md)

Implementing OAuth2 authentication with comprehensive security review.

**Covers:**
- Security-first planning
- Secure implementation
- OWASP Top 10 checklist
- Security review process
- Deployment approval

**Duration:** ~75 minutes
**Agents Used:** @planner, @security, @builder, @tester, @reviewer

---

### 3. [Database Migration](database-migration-example.md)

Zero-downtime database migration using Expand-Migrate-Contract pattern.

**Covers:**
- Migration planning
- Zero-downtime strategy
- Rollback procedures
- Testing on staging
- Production deployment

**Duration:** ~60 minutes
**Agents Used:** @planner, @migration, @tester, @reviewer

---

### 4. [Bug Investigation and Fix](bug-fix-example.md)

Debugging a production issue, finding root cause, and deploying fix.

**Covers:**
- Root cause analysis
- Fix implementation
- Regression testing
- Hotfix deployment

**Duration:** ~30 minutes
**Agents Used:** @debug, @builder, @tester

---

### 5. [Performance Optimization](performance-optimization-example.md)

Optimizing a slow API endpoint from investigation to deployment.

**Covers:**
- Performance profiling
- Bottleneck identification
- Optimization implementation
- Benchmarking results

**Duration:** ~45 minutes
**Agents Used:** @performance, @builder, @tester

---

## Example Categories

### Getting Started
- Simple feature implementation
- Basic bug fix
- Code refactoring

### Intermediate
- Security-sensitive features
- Database migrations
- Performance optimization

### Advanced
- Complex multi-agent workflows
- Custom skill creation
- CI/CD integration

---

## How to Use These Examples

### 1. Read the Example

Each example includes:
- **Scenario**: What we're building/fixing
- **Prerequisites**: What you need
- **Step-by-Step**: Exact agent commands
- **Expected Output**: What to expect
- **Common Issues**: Troubleshooting

### 2. Adapt to Your Project

Examples are templates. Customize:
- File paths
- Feature names
- Tech stack specific details
- Your team's workflow

### 3. Practice

Try examples in a test project:
```bash
# Create test project
mkdir opencode-practice
cd opencode-practice
git init

# Follow example steps
```

---

## Example Format

All examples follow this structure:

```markdown
# Example Title

## Scenario
What we're building/fixing

## Prerequisites
- Required tools
- Existing code
- Configuration

## Step-by-Step Walkthrough

### Step 1: Planning
Agent commands and output

### Step 2: Implementation
Agent commands and output

### Step 3: Testing
Agent commands and output

### Step 4: Review
Agent commands and output

### Step 5: Deployment
Agent commands and output

## Expected Outcome
What you should have at the end

## Common Issues
Troubleshooting tips

## Time Breakdown
How long each step takes

## Related
- Similar examples
- Documentation references
```

---

## Contributing Examples

Have a great OpenCode workflow? Share it!

**Template:**
```markdown
# Your Example Title

## Scenario
Brief description (2-3 sentences)

## Prerequisites
- List prerequisites

## Walkthrough
Step-by-step with agent commands

## Outcome
What's achieved

## Time: ~XX minutes
```

Save as: `examples/your-example-name.md`

---

## Quick Reference

**By Task Type:**
- New Feature → `feature-implementation-example.md`
- Auth/Security → `security-feature-example.md`
- Database Change → `database-migration-example.md`
- Bug Fix → `bug-fix-example.md`
- Performance → `performance-optimization-example.md`

**By Complexity:**
- Beginner → `feature-implementation-example.md`
- Intermediate → `security-feature-example.md`, `database-migration-example.md`
- Advanced → `performance-optimization-example.md`

**By Duration:**
- Quick (~30 min) → `bug-fix-example.md`
- Medium (~45 min) → `feature-implementation-example.md`, `performance-optimization-example.md`
- Thorough (~60-75 min) → `security-feature-example.md`, `database-migration-example.md`

---

## Related Documentation

- **Workflows**: `../workflows/` - Detailed workflow documentation
- **Agents**: `../agents/` - Individual agent documentation
- **Patterns**: `../PATTERNS.md` - Design patterns and best practices
- **Quick Reference**: `../agents/QUICK_REFERENCE.md` - Agent command reference

---

*Last updated: 2026-02-17*
