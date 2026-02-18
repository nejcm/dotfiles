# Production-Grade Agent Architecture - Technical Design

This document describes the complete system architecture, agent interaction patterns, and implementation details.

---

## Table of Contents

1. [System Philosophy](#system-philosophy)
2. [Architecture Overview](#architecture-overview)
3. [Agent Design Patterns](#agent-design-patterns)
4. [Workflow Orchestration](#workflow-orchestration)
5. [Permission Model](#permission-model)
6. [Skill System](#skill-system)
7. [Spec Artifact Pattern](#spec-artifact-pattern)
8. [Failure Recovery](#failure-recovery)
9. [Cost Optimization](#cost-optimization)
10. [Security Model](#security-model)
11. [Implementation Roadmap](#implementation-roadmap)

---

## System Philosophy

### Agents as Microservices

Traditional approach (anti-pattern):
```
SuperAgent
├── Plans
├── Implements
├── Tests
├── Reviews
├── Deploys
└── [Too many responsibilities]
```

Production approach:
```
Planner → Builder → Tester → Reviewer → Release
   ↓         ↓         ↓         ↓         ↓
[Focused] [Clear]  [Safe]  [Critical] [Controlled]
```

### Core Principles

1. **Single Responsibility**: Each agent does one thing well
2. **Clear Contracts**: Inputs/outputs well-defined
3. **Limited Permissions**: Principle of least privilege
4. **Observable Behavior**: All actions logged
5. **Replaceable**: Agents can be swapped without system redesign

### Why This Works

- **Smaller context = better reasoning**: Focused agents are more intelligent
- **Easier debugging**: Clear boundaries make issues obvious
- **Predictable outputs**: Deterministic > raw intelligence
- **Lower inference cost**: Smaller models for specific tasks
- **Safer automation**: Limited blast radius

**Design Goal**: Deterministic behavior over raw intelligence

---

## Architecture Overview

### High-Level Flow

```
                    User Request
                         ↓
                 ┌───────────────┐
                 │ Planner Agent │ (Read-only)
                 │ - Research    │
                 │ - Decompose   │
                 │ - Create Spec │
                 └───────┬───────┘
                         │
                    SPEC.md (artifact)
                         │
                    Human Review
                         ↓
                 ┌───────────────┐
                 │ Builder Agent │ (Write + Execute)
                 │ - Implement   │
                 │ - Test        │
                 │ - Validate    │
                 └───────┬───────┘
                         │
                  Implementation
                         │
                         ↓
                 ┌───────────────┐
                 │ Tester Agent  │ (Execute-only)
                 │ - Run tests   │
                 │ - Coverage    │
                 │ - Report      │
                 └───────┬───────┘
                         │
                   Test Results
                    ┌────┴────┐
                    │  Pass?  │
                    └────┬────┘
                     Yes │  No (< 3 failures)
                    ┌────┴────┐
                    │         └─→ Failure Slice → Builder
                    ↓
            ┌───────────────┐
            │ Reviewer Agent│ (Read-only)
            │ - Compliance  │
            │ - Quality     │
            │ - Security    │
            └───────┬───────┘
                    │
                 Review
                    │
            ┌───────┴───────┐
            │ Security?     │
            └───────┬───────┘
                Yes │  No
                    ↓
        ┌──────────────────┐
        │ Security Agent   │ (Read-only)
        │ - Deep analysis  │
        │ - Vulns          │
        │ - OWASP Top 10   │
        └──────────┬───────┘
                   │
              All Approved
                   ↓
    ┌──────────────────────────────┐
    │ PR → CI → Review → Merge    │
    └──────────────────────────────┘
                   ↓
             Deploy to Production
```

### Component Diagram

```
┌─────────────────────────────────────────────────────────┐
│                     OpenCode Host                        │
│  ┌───────────────────────────────────────────────────┐  │
│  │              Agent Orchestration Layer            │  │
│  └───────────────────────────────────────────────────┘  │
│                           │                              │
│        ┌──────────────────┼──────────────────┐          │
│        │                  │                  │          │
│  ┌─────▼──────┐   ┌──────▼────┐   ┌────────▼──────┐   │
│  │   Core     │   │Specialized│   │    Skills     │   │
│  │   Agents   │   │  Agents   │   │  (Tools)      │   │
│  │            │   │           │   │               │   │
│  │ - Planner  │   │ - Security│   │ - run-tests   │   │
│  │ - Builder  │   │ - Migration│   │ - git-workflow│   │
│  │ - Tester   │   │ - Performance│ │ - ci-status   │   │
│  │ - Reviewer │   │ - Refactor│   │ - spec-validator│  │
│  │            │   │ - Debug   │   │               │   │
│  └─────┬──────┘   └──────┬────┘   └────────┬──────┘   │
│        │                  │                  │          │
│        └──────────────────┼──────────────────┘          │
│                           │                              │
│  ┌────────────────────────▼───────────────────────┐    │
│  │           MCP Server Integration              │    │
│  │  ┌─────────┐  ┌─────────┐  ┌──────────┐      │    │
│  │  │ GitHub  │  │ Linear  │  │Context7  │      │    │
│  │  └─────────┘  └─────────┘  └──────────┘      │    │
│  └───────────────────────────────────────────────┘    │
│                                                         │
│  ┌───────────────────────────────────────────────┐    │
│  │           Artifact Storage                    │    │
│  │  ┌─────────┐  ┌──────────┐  ┌──────────┐     │    │
│  │  │  Specs  │  │   Logs   │  │  Reports │     │    │
│  │  └─────────┘  └──────────┘  └──────────┘     │    │
│  └───────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
```

---

## Agent Design Patterns

### Pattern 1: Read-Only Reviewer

**Agents**: Planner, Reviewer, Security

**Characteristics**:
- Cannot modify files
- Cannot execute commands
- Focus on analysis and recommendations

**Benefits**:
- Separation of duties
- Independent verification
- Bias-free reviews

**Implementation**:
```json
{
  "tools": {
    "write": false,
    "edit": false,
    "bash": false,
    "read": true,
    "search": true
  }
}
```

### Pattern 2: Execute-Only Validator

**Agents**: Tester

**Characteristics**:
- Can run commands
- Cannot modify source code
- Returns structured data

**Benefits**:
- Validation without side effects
- Machine-readable results
- Repeatable testing

**Implementation**:
```json
{
  "tools": {
    "write": false,
    "edit": false,
    "bash": true,
    "read": true
  }
}
```

### Pattern 3: Scoped Writer

**Agents**: Builder, Migration

**Characteristics**:
- Limited write permissions
- Diff-based edits preferred
- Validation required before handoff

**Benefits**:
- Controlled changes
- Audit trail
- Rollback capability

**Implementation**:
```json
{
  "tools": {
    "write": true,
    "edit": true,
    "bash": true,
    "read": true
  },
  "guardrails": {
    "max_files_per_edit": 5,
    "allow_full_file_rewrites": false
  }
}
```

### Pattern 4: Specialist Subagent

**Agents**: Security, Performance, Refactor, Debug

**Characteristics**:
- Invoked conditionally
- Deep domain expertise
- May use different model

**Benefits**:
- Cost-effective (only when needed)
- Expert-level analysis
- Parallel execution possible

**Implementation**:
```json
{
  "mode": "subagent",
  "model": "anthropic/claude-opus-4-20250514",  // More powerful model
  "trigger_conditions": ["file_upload", "authentication", "payments"]
}
```

---

## Workflow Orchestration

### Sequential Pipeline

Most common pattern:

```python
def feature_workflow(request):
    # Phase 1: Planning
    spec = planner_agent.plan(request)
    if not human_approves(spec):
        return spec  # Iterate on spec

    # Phase 2: Implementation
    implementation = builder_agent.build(spec)

    # Phase 3: Validation
    test_results = tester_agent.test(implementation)

    if test_results.failed:
        if test_results.failure_count < 3:
            # Auto-fix attempt
            implementation = builder_agent.fix(test_results.failure_slice)
            test_results = tester_agent.test(implementation)
        else:
            # Escalate to debug agent
            root_cause = debug_agent.analyze(test_results)
            return root_cause  # Human intervention

    # Phase 4: Review
    review = reviewer_agent.review(spec, implementation, test_results)

    if review.requires_security_review:
        security_review = security_agent.review(implementation)
        if security_review.critical_issues:
            return security_review  # Block

    # Phase 5: Approval
    if review.approved and (not security_review or security_review.approved):
        return create_pr(implementation)
    else:
        return review.required_changes
```

### Parallel Execution

For independent tasks:

```python
def parallel_fixes(failures):
    tasks = []

    # Separate failures by type
    lint_failures = filter_lint(failures)
    type_failures = filter_type(failures)
    test_failures = filter_test(failures)

    # Run fixes in parallel
    tasks.append(async_run(refactor_agent.fix_lint, lint_failures))
    tasks.append(async_run(builder_agent.fix_types, type_failures))
    tasks.append(async_run(builder_agent.fix_tests, test_failures))

    return await_all(tasks)
```

### Conditional Branching

Trigger specialist agents:

```python
def conditional_agents(code_changes):
    reviews = []

    # Always run standard review
    reviews.append(reviewer_agent.review(code_changes))

    # Conditional specialist reviews
    if touches_auth(code_changes):
        reviews.append(security_agent.review(code_changes))

    if touches_migrations(code_changes):
        reviews.append(migration_agent.review(code_changes))

    if has_performance_concerns(code_changes):
        reviews.append(performance_agent.review(code_changes))

    return aggregate_reviews(reviews)
```

---

## Permission Model

### Three-Tier System

```
┌──────────┬────────┬────────┬─────────┐
│  Agent   │  READ  │ WRITE  │ EXECUTE │
├──────────┼────────┼────────┼─────────┤
│ Planner  │   ✅   │   ❌   │   ❌    │
│ Builder  │   ✅   │   ✅   │   ✅    │
│ Tester   │   ✅   │   ❌   │   ✅    │
│ Reviewer │   ✅   │   ❌   │   ❌    │
│ Security │   ✅   │   ❌   │   ❌    │
│ Migration│   ✅   │   ✅   │   ✅    │
│ Perform. │   ✅   │   ❌*  │   ✅    │
│ Refactor │   ✅   │   ❌*  │   ✅    │
│ Debug    │   ✅   │   ❌   │   ✅    │
└──────────┴────────┴────────┴─────────┘

* Can edit but not write new files
```

### Permission Boundaries

```json
{
  "permission": {
    "tool": {
      "read": "allow",      // Most agents need this
      "search": "allow",    // Most agents need this
      "write": "ask",       // Prompt for confirmation
      "edit": "ask",        // Prompt for confirmation
      "bash": "ask"         // Prompt for confirmation
    },
    "skill": {
      "*": "ask",           // Default: ask
      "read-*": "allow",    // Auto-allow read operations
      "internal-*": "deny"  // Block internal tools
    }
  }
}
```

### Scoped Execution

```json
{
  "builder": {
    "bash_allowed_commands": [
      "npm test",
      "npm run lint",
      "npm run typecheck",
      "npm run build"
    ],
    "bash_forbidden_commands": [
      "rm -rf",
      "npm publish",
      "git push --force",
      "docker push"
    ]
  }
}
```

---

## Skill System

### Skill Architecture

```
skill/
├── run-tests/
│   └── SKILL.md          # Skill definition
├── spec-validator/
│   └── SKILL.md
├── git-workflow/
│   └── SKILL.md
└── ci-status/
    └── SKILL.md
```

### Skill Contract

```yaml
---
name: skill-name
description: What this skill does (1-line)
---

# Skill Name

## Purpose
Detailed description

## Usage
How agents invoke this skill

## Input Format
Expected parameters

## Output Format
Structured response (JSON preferred)

## Error Handling
How errors are returned

## Integration
Which agents use this skill
```

### Skill Design Principles

1. **Narrow Scope**: One skill = one job
2. **Structured Output**: JSON over text
3. **Hide Complexity**: Abstract implementation details
4. **Idempotent**: Safe to run twice
5. **Observable**: Return logs + status

### Example: Test Execution Skill

```typescript
interface TestSkillInput {
  test_type: 'unit' | 'integration' | 'e2e' | 'all';
  files?: string[];  // Optional: specific test files
}

interface TestSkillOutput {
  status: 'passed' | 'failed' | 'partial';
  summary: {
    total: number;
    passed: number;
    failed: number;
    skipped: number;
    duration_ms: number;
  };
  coverage?: {
    lines: number;
    branches: number;
    functions: number;
  };
  failures?: Array<{
    test: string;
    error: string;
    file: string;
    line: number;
  }>;
  artifacts: {
    junit?: string;
    coverage_html?: string;
  };
}
```

---

## Spec Artifact Pattern

### Why Specs Matter

**Problem**: Conversational memory is unreliable

**Solution**: Explicit artifact files

**Benefits**:
- Audit trail
- Reproducibility
- Debuggable failures
- Team visibility
- Version control

### Spec Lifecycle

```
1. User Request
   ↓
2. Planner creates spec file
   specs/2026-02-13-feature-name.md
   ↓
3. Human reviews & approves
   ↓
4. Builder implements against spec
   ↓
5. Reviewer validates spec compliance
   ↓
6. Spec archived (not deleted)
```

### Spec Template Structure

```markdown
# Feature Name

## Problem
[What needs solving]

## Constraints
[Limits and requirements]

## Proposed Approach
[Implementation strategy]

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2

## Risks
[What could go wrong]

## Task Breakdown
1. Step 1
2. Step 2
```

### Spec as Contract

The spec is a **contract between planner and builder**:
- Builder implements **exactly** what spec says
- Builder does **not** add unspecified features
- Reviewer validates **spec compliance**

---

## Failure Recovery

### Retry Strategy

```
Builder implements
  ↓
Tester validates
  ↓
Failed? → Count < 2? → Builder auto-fix (with failure slice)
           │
           No (≥ 2 retries)
           ↓
       Debug Agent analyzes
           ↓
       Human intervention
```

### Failure Slice Pattern

Instead of sending entire context:

```json
{
  "failure_slice": {
    "failed_tests": [
      "auth.spec.ts:45 > should validate email"
    ],
    "relevant_code": {
      "file": "src/auth.controller.ts",
      "lines": "67-85",
      "context": "Email validation logic"
    },
    "error_message": "Expected 400, received 200",
    "suggested_fix": "Add email format validation before processing"
  }
}
```

**Benefits**:
- Smaller context = better reasoning
- Faster fixes
- Lower cost

### Escalation Path

```
Level 1: Builder auto-fix (< 2 retries)
  ↓
Level 2: Debug agent analysis
  ↓
Level 3: Human developer
```

### Circuit Breaker

Prevent infinite loops:

```json
{
  "guardrails": {
    "max_tool_calls_per_session": 100,
    "max_retries": 2,
    "timeout_seconds": 600
  }
}
```

---

## Cost Optimization

### Model Selection Strategy

```
┌─────────────────┬──────────┬──────┬────────┐
│ Task Type       │  Model   │ Cost │ Speed  │
├─────────────────┼──────────┼──────┼────────┤
│ Planning        │ Sonnet-4 │  $$  │ Medium │
│ Architecture    │ Sonnet-4 │  $$  │ Medium │
│ Implementation  │ Sonnet-4 │  $$  │ Medium │
│ Security Review │  Opus-4  │ $$$  │  Slow  │
│ Testing         │ Haiku-4  │   $  │  Fast  │
│ Refactoring     │ Haiku-4  │   $  │  Fast  │
│ Documentation   │ Haiku-4  │   $  │  Fast  │
│ Code Review     │ Sonnet-4 │  $$  │ Medium │
│ Debug Analysis  │ Sonnet-4 │  $$  │ Medium │
└─────────────────┴──────────┴──────┴────────┘
```

**Typical Cost Breakdown**:
- Single model: $10/feature
- Optimized strategy: $2-3/feature
- **Savings: 60-80%**

### Context Optimization

**Bad** (High Cost):
```
Load entire monorepo → 150K tokens → $$$
```

**Good** (Lower Cost):
```
Load relevant files only → 15K tokens → $
```

**Strategies**:
- Scope subagents to specific directories
- Use failure slices (not full context)
- Cache specs (don't regenerate)
- Prune dependencies from context

### Parallel Execution

Run cheap tasks in parallel:

```python
# Sequential (slow)
lint_result = refactor_agent.lint()      # $
type_result = refactor_agent.typecheck() # $
test_result = tester_agent.test()        # $
Total time: 15 seconds, Cost: $$$

# Parallel (fast)
results = await_all([
    refactor_agent.lint(),
    refactor_agent.typecheck(),
    tester_agent.test()
])
Total time: 5 seconds, Cost: $$$ (same cost, faster)
```

---

## Security Model

### Defense in Depth

```
Layer 1: Agent Permissions (least privilege)
   ↓
Layer 2: Skill Permissions (scoped tools)
   ↓
Layer 3: Review Gates (human-in-loop)
   ↓
Layer 4: Execution Sandbox (isolated environment)
   ↓
Layer 5: Audit Logs (full traceability)
```

### Secrets Management

**Never** expose secrets to agents:

```json
// ❌ Bad
{
  "environment": {
    "API_KEY": "sk-1234567890"
  }
}

// ✅ Good
{
  "environment": {
    "API_KEY_PATH": "/secure/api-key"
  }
}
```

### Audit Trail

Log everything:

```json
{
  "timestamp": "2026-02-13T10:30:00Z",
  "agent": "builder",
  "action": "file_write",
  "file": "src/auth.controller.ts",
  "diff_size": 234,
  "spec": "specs/2026-02-13-auth.md",
  "user_approved": true
}
```

### Approval Gates

```
Low Risk: Auto-approve (lint fixes)
   ↓
Medium Risk: Ask user (file edits)
   ↓
High Risk: Require explicit approval (deployments)
   ↓
Critical: Multiple approvals (production deploys)
```

---

## Implementation Roadmap

### Week 1: Foundation

**Goal**: Get Planner + Builder working

**Tasks**:
1. Set up directory structure
2. Configure Planner agent
3. Configure Builder agent
4. Create spec template
5. Test workflow: Request → Spec → Implementation

**Deliverables**:
- Working Planner agent
- Working Builder agent
- Spec template
- Basic documentation

**Success Metric**: Can implement simple features end-to-end

---

### Week 2: Quality Gates

**Goal**: Add Tester + Reviewer

**Tasks**:
1. Configure Tester agent
2. Create test execution skill
3. Configure Reviewer agent
4. Implement retry logic
5. Create PR workflow

**Deliverables**:
- Working Tester agent
- Working Reviewer agent
- PR workflow template
- Retry logic (max 2 attempts)

**Success Metric**: Full pipeline works with quality gates

---

### Week 3: Specialization

**Goal**: Add specialist agents and safety

**Tasks**:
1. Configure Security agent
2. Configure Migration agent
3. Configure Performance agent
4. Configure Refactor agent
5. Configure Debug agent
6. Implement guardrails
7. Add logging infrastructure

**Deliverables**:
- All specialist agents
- Guardrails configuration
- Logging and monitoring
- Incident triage workflow

**Success Metric**: Can handle complex, security-sensitive features

---

### Week 4: Optimization

**Goal**: MCP integration and cost optimization

**Tasks**:
1. Set up GitHub MCP server
2. Set up Linear MCP server
3. Set up Context7 MCP server
4. Implement model strategy (Sonnet/Haiku/Opus)
5. Create release workflow
6. Complete documentation
7. Add cost tracking

**Deliverables**:
- MCP servers configured
- Model strategy implemented
- Release workflow
- Complete documentation
- Cost monitoring

**Success Metric**: Production-ready system with optimal costs

---

## Conclusion

This architecture provides:

✅ **Safety**: Limited permissions, review gates, audit trails
✅ **Speed**: Parallel execution, optimized models, focused agents
✅ **Quality**: Spec compliance, comprehensive testing, expert review
✅ **Cost**: 60-80% savings through strategic model selection
✅ **Reliability**: Deterministic behavior, failure recovery, observability

**Remember**: Start simple, add complexity only when needed. The best systems are boring, predictable, and observable.

Build for control first, autonomy second.
