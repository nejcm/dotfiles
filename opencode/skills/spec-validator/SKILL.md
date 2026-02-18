---
name: spec-validator
description: Validate that implementation matches specification acceptance criteria
---

# Spec Validator Skill

This skill validates that an implementation meets all acceptance criteria defined in the specification.

## Purpose

Read a SPEC file and validate that:
1. All acceptance criteria are addressed
2. No unspecified features were added
3. Requirements are fully implemented
4. Tests cover all acceptance criteria

## Usage

```
Validate implementation against spec: specs/2026-02-13-feature-name.md
```

## Validation Checks

### 1. Acceptance Criteria Coverage
- Parse acceptance criteria from spec
- Check if tests exist for each criterion
- Verify implementation includes required functionality

### 2. Scope Adherence
- Ensure no features outside spec were added
- Verify constraints were followed
- Check that approach matches proposed solution

### 3. Test Coverage
- Confirm tests for happy path
- Confirm tests for error cases
- Confirm tests for edge cases mentioned in spec

## Output Format

```json
{
  "valid": true,
  "spec_file": "specs/2026-02-13-add-user-profiles.md",
  "acceptance_criteria": {
    "total": 5,
    "met": 5,
    "unmet": 0,
    "details": [
      {
        "criterion": "User can edit profile bio",
        "status": "met",
        "evidence": "Test: user.spec.ts:45, Implementation: user.controller.ts:67"
      }
    ]
  },
  "scope_check": {
    "in_scope": true,
    "unspecified_features": []
  },
  "test_coverage": {
    "happy_path": true,
    "error_cases": true,
    "edge_cases": true
  },
  "issues": []
}
```

## When to Use

- After Builder completes implementation
- During code review process
- As part of CI/CD pipeline
- Before merging pull requests

## Integration

This skill is typically used by the **Reviewer Agent** to ensure spec compliance before approval.
