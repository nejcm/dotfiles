---
name: run-tests
description: Execute test suites and return structured results with coverage metrics
---

# Run Tests Skill

This skill provides a structured way to execute tests and return machine-readable results.

## Purpose

Execute comprehensive test suites (unit, integration, e2e) and return structured JSON output including pass/fail status, coverage metrics, and detailed failure information.

## Usage

```
Run all tests and provide structured results
```

## Expected Output Format

```json
{
  "status": "passed" | "failed" | "partial",
  "summary": {
    "total": 45,
    "passed": 42,
    "failed": 3,
    "skipped": 0,
    "duration_ms": 2340
  },
  "coverage": {
    "lines": 82,
    "branches": 76,
    "functions": 88,
    "statements": 81
  },
  "failures": [
    {
      "test": "auth.spec.ts > login > should validate email format",
      "error": "Expected 400, received 200",
      "file": "tests/auth.spec.ts",
      "line": 45,
      "type": "assertion_error"
    }
  ],
  "artifacts": {
    "junit": "artifacts/junit.xml",
    "coverage_html": "artifacts/coverage/index.html"
  }
}
```

## Commands by Framework

### JavaScript/TypeScript
- `npm test` or `pnpm test` or `yarn test`
- `npm run test:unit` - Unit tests only
- `npm run test:integration` - Integration tests
- `npm run test:e2e` - End-to-end tests
- `npm run test:coverage` - With coverage

### Python
- `pytest`
- `pytest --cov` - With coverage
- `python -m unittest discover`

### Go
- `go test ./...`
- `go test -cover ./...`

### Rust
- `cargo test`

## Responsibilities

- Execute appropriate test commands
- Parse test output
- Generate structured JSON response
- Include coverage metrics if available
- Provide actionable failure information
- Save artifacts (JUnit XML, coverage reports)

## Integration

This skill is typically used by the **Tester Agent** to validate implementations against specifications.
