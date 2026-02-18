---
name: coverage-analyzer
description: Analyzes test coverage and identifies untested code paths
version: 1.0.0
category: testing
tools:
  - nyc
  - istanbul
  - coverage.py
  - jest
  - pytest-cov
permissions:
  - read
  - bash
---

# Coverage Analyzer Skill

Comprehensive test coverage analysis to ensure code quality and identify untested paths.

## Purpose

Track and report:
- **Line coverage**: Percentage of lines executed
- **Branch coverage**: Percentage of code branches (if/else) tested
- **Function coverage**: Percentage of functions called
- **Statement coverage**: Percentage of statements executed
- **Uncovered code**: Specific lines/functions without tests

## Supported Frameworks

### JavaScript/TypeScript
- **Jest**: Built-in coverage via `--coverage`
- **NYC/Istanbul**: Coverage tool for any test framework
- **c8**: Native V8 coverage

### Python
- **coverage.py**: Standard Python coverage tool
- **pytest-cov**: pytest plugin for coverage

## Usage

### Invoke from Agent

```
@tester Use coverage-analyzer skill to check test coverage
```

### Command Line

```bash
# JavaScript/Jest
npm test -- --coverage

# JavaScript/NYC
nyc npm test

# Python/pytest
pytest --cov=src --cov-report=html

# Python/coverage.py
coverage run -m pytest
coverage report
```

## Coverage Targets

| Coverage Type | Minimum | Good | Excellent |
|---------------|---------|------|-----------|
| **Line**      | 70%     | 80%  | 90%+      |
| **Branch**    | 65%     | 75%  | 85%+      |
| **Function**  | 75%     | 85%  | 95%+      |
| **Statement** | 70%     | 80%  | 90%+      |

**Industry Standards:**
- **Startups/MVPs**: 60-70% acceptable
- **Production apps**: 80%+ recommended
- **Critical systems**: 90%+ required
- **Libraries/Frameworks**: 95%+ expected

## Configuration

### Jest Coverage

**jest.config.js**:
```javascript
module.exports = {
  collectCoverage: true,
  coverageDirectory: 'coverage',
  coverageReporters: ['text', 'lcov', 'html'],
  coverageThreshold: {
    global: {
      branches: 75,
      functions: 80,
      lines: 80,
      statements: 80
    }
  },
  collectCoverageFrom: [
    'src/**/*.{js,jsx,ts,tsx}',
    '!src/**/*.d.ts',
    '!src/**/*.test.{js,ts}',
    '!src/**/__tests__/**'
  ]
};
```

### NYC Configuration

**.nycrc.json**:
```json
{
  "all": true,
  "include": ["src/**/*.js"],
  "exclude": [
    "**/*.test.js",
    "**/__tests__/**",
    "**/node_modules/**"
  ],
  "reporter": ["html", "text", "lcov"],
  "check-coverage": true,
  "lines": 80,
  "statements": 80,
  "functions": 80,
  "branches": 75
}
```

### pytest-cov Configuration

**pytest.ini** or **pyproject.toml**:
```ini
[pytest]
addopts = --cov=src --cov-report=html --cov-report=term --cov-fail-under=80

[coverage:run]
omit =
    */tests/*
    */test_*.py
    */__pycache__/*
```

```toml
[tool.coverage.run]
source = ["src"]
omit = [
    "*/tests/*",
    "*/test_*.py"
]

[tool.coverage.report]
fail_under = 80
show_missing = true
```

## Implementation

### Analyze Jest Coverage

```typescript
async function analyzeJestCoverage() {
  const result = await runCommand('npm test -- --coverage --json');
  const coverageData = JSON.parse(result.stdout);

  const summary = {
    totalLines: 0,
    coveredLines: 0,
    totalBranches: 0,
    coveredBranches: 0,
    totalFunctions: 0,
    coveredFunctions: 0,
    uncoveredFiles: []
  };

  for (const [file, data] of Object.entries(coverageData.coverageMap)) {
    const fileSummary = data.toSummary();

    summary.totalLines += fileSummary.lines.total;
    summary.coveredLines += fileSummary.lines.covered;
    summary.totalBranches += fileSummary.branches.total;
    summary.coveredBranches += fileSummary.branches.covered;
    summary.totalFunctions += fileSummary.functions.total;
    summary.coveredFunctions += fileSummary.functions.covered;

    if (fileSummary.lines.pct < 80) {
      summary.uncoveredFiles.push({
        file,
        coverage: fileSummary.lines.pct,
        uncoveredLines: getUncoveredLines(data)
      });
    }
  }

  return {
    lineCoverage: (summary.coveredLines / summary.totalLines) * 100,
    branchCoverage: (summary.coveredBranches / summary.totalBranches) * 100,
    functionCoverage: (summary.coveredFunctions / summary.totalFunctions) * 100,
    uncoveredFiles: summary.uncoveredFiles
  };
}
```

### Analyze Python Coverage

```python
async def analyze_python_coverage():
    # Run tests with coverage
    await run_command('pytest --cov=src --cov-report=json')

    # Read coverage.json
    with open('coverage.json') as f:
        coverage_data = json.load(f)

    summary = {
        'total_lines': 0,
        'covered_lines': 0,
        'total_branches': 0,
        'covered_branches': 0,
        'uncovered_files': []
    }

    for file, data in coverage_data['files'].items():
        summary['total_lines'] += data['summary']['num_statements']
        summary['covered_lines'] += data['summary']['covered_lines']
        summary['total_branches'] += data['summary']['num_branches']
        summary['covered_branches'] += data['summary']['covered_branches']

        coverage_pct = data['summary']['percent_covered']
        if coverage_pct < 80:
            summary['uncovered_files'].append({
                'file': file,
                'coverage': coverage_pct,
                'missing_lines': data['missing_lines']
            })

    return {
        'line_coverage': (summary['covered_lines'] / summary['total_lines']) * 100,
        'branch_coverage': (summary['covered_branches'] / summary['total_branches']) * 100,
        'uncovered_files': summary['uncovered_files']
    }
```

## Output Format

### Success Output (Good Coverage)

```
✅ Coverage Analysis: PASSED

Overall Coverage:
  Lines:     87.5% (892/1020) ✅
  Branches:  82.3% (412/501)  ✅
  Functions: 91.2% (124/136) ✅
  Statements: 88.1% (901/1023) ✅

Files with 100% Coverage: 23
Files with 90%+ Coverage: 45
Files with 80%+ Coverage: 12
Files with <80% Coverage: 3

Excellent test coverage! 🎉

Coverage Report: ./coverage/index.html
```

### Warning Output (Moderate Coverage)

```
⚠️  Coverage Analysis: WARNING

Overall Coverage:
  Lines:     74.2% (756/1020) ⚠️
  Branches:  68.9% (345/501)  ⚠️
  Functions: 79.4% (108/136) ⚠️
  Statements: 75.1% (768/1023) ⚠️

Target: 80% (Below threshold)
Gap: -5.8% lines, -11.1% branches

Files with <80% Coverage:
  1. src/auth/permissions.ts - 62.5% (25/40 lines)
     Missing: Lines 23-28, 45-51, 89
     Impact: HIGH (auth logic)

  2. src/api/billing.ts - 58.3% (35/60 lines)
     Missing: Lines 12-18, 34-42, 67-75
     Impact: HIGH (payment processing)

  3. src/utils/validation.ts - 71.4% (50/70 lines)
     Missing: Lines 23, 45-48, 92-97
     Impact: MEDIUM (input validation)

Recommendations:
  1. Add tests for auth/permissions.ts (critical security code)
  2. Add tests for api/billing.ts (critical payment code)
  3. Add tests for edge cases in validation.ts
  4. Target: Increase coverage to 80%+

Next Steps:
  @builder Add missing tests for critical files
  @tester Re-run coverage after new tests
```

### Failure Output (Low Coverage)

```
❌ Coverage Analysis: FAILED

Overall Coverage:
  Lines:     54.8% (559/1020) ❌
  Branches:  47.2% (237/501)  ❌
  Functions: 61.8% (84/136)  ❌
  Statements: 56.2% (575/1023) ❌

Target: 80% (Significantly below threshold)
Gap: -25.2% lines, -32.8% branches

CRITICAL: 18 files with <50% coverage!

Most Critical Files Needing Tests:
  1. src/auth/oauth.ts - 28.5% (12/42 lines) 🚨
     Missing: Lines 5-15, 23-35, 48-67, 78-85
     Impact: CRITICAL (authentication)

  2. src/payment/stripe.ts - 31.2% (18/58 lines) 🚨
     Missing: Lines 8-22, 34-48, 61-73
     Impact: CRITICAL (payment processing)

  3. src/admin/users.ts - 42.1% (32/76 lines) 🚨
     Missing: Lines 12-28, 45-59, 82-91
     Impact: CRITICAL (admin functionality)

  4. src/db/migrations.ts - 18.9% (7/37 lines) 🚨
     Missing: Lines 5-12, 18-28, 35-42
     Impact: CRITICAL (data integrity)

⚠️  BLOCKING DEPLOYMENT: Coverage below minimum threshold (80%)

Required Actions:
  1. IMMEDIATE: Add tests for all critical files (auth, payment, admin)
  2. URGENT: Add tests for database migration logic
  3. Write tests for all remaining files to reach 80%+
  4. Do not merge/deploy until coverage improves

Estimated Work: 2-3 days to reach 80% coverage

Next Steps:
  @planner Create spec for comprehensive test coverage
  @builder Implement missing tests
  @reviewer Review test quality
```

## Coverage Reports

### HTML Report

Generated by default in `coverage/` directory.

**Features:**
- Visual file tree
- Line-by-line coverage highlighting
- Branch coverage visualization
- Interactive drill-down

**Access:**
```bash
open coverage/index.html
```

### LCOV Report

Machine-readable format for CI/CD integration.

**Location:** `coverage/lcov.info`

**Usage:**
```bash
# Upload to Codecov
bash <(curl -s https://codecov.io/bash) -f coverage/lcov.info

# Upload to Coveralls
cat coverage/lcov.info | coveralls
```

### Text Report

Console output for quick review.

```
----------|---------|----------|---------|---------|-------------------
File      | % Stmts | % Branch | % Funcs | % Lines | Uncovered Line #s
----------|---------|----------|---------|---------|-------------------
All files |   87.5  |   82.3   |   91.2  |   88.1  |
 auth/    |   92.1  |   88.5   |   95.0  |   93.2  |
  login.ts|   95.2  |   91.2   |  100.0  |   96.1  | 23,45
  oauth.ts|   88.5  |   84.7   |   90.0  |   89.8  | 12-15,67
 api/     |   81.3  |   75.2   |   85.7  |   82.5  |
  user.ts |   87.3  |   82.1   |   92.3  |   88.9  | 34
  admin.ts|   73.5  |   65.8   |   75.0  |   74.2  | 12-18,45-51
----------|---------|----------|---------|---------|-------------------
```

## Uncovered Code Analysis

### Identify Critical Gaps

```typescript
function identifyCriticalGaps(coverageData) {
  const criticalFiles = [
    'auth/', 'payment/', 'admin/', 'security/', 'db/'
  ];

  const criticalGaps = [];

  for (const [file, data] of Object.entries(coverageData)) {
    const isCritical = criticalFiles.some(path => file.includes(path));
    const coverage = data.lines.pct;

    if (isCritical && coverage < 90) {
      criticalGaps.push({
        file,
        coverage,
        severity: coverage < 70 ? 'CRITICAL' : coverage < 80 ? 'HIGH' : 'MEDIUM',
        uncoveredLines: getUncoveredLines(data)
      });
    }
  }

  return criticalGaps.sort((a, b) => a.coverage - b.coverage);
}
```

### Generate Test Suggestions

```typescript
function generateTestSuggestions(uncoveredFile) {
  const suggestions = [];

  for (const lineRange of uncoveredFile.uncoveredLines) {
    const code = readLines(uncoveredFile.file, lineRange);
    const testType = detectTestType(code);

    suggestions.push({
      lines: lineRange,
      testType,
      suggestion: getTestSuggestion(testType, code)
    });
  }

  return suggestions;
}
```

**Output:**
```
Suggested Tests for src/auth/login.ts:

Lines 23-28 (Error Handling):
  ✓ Test invalid email format
  ✓ Test missing password
  ✓ Test account locked
  ✓ Test too many attempts

Lines 45-51 (Edge Case):
  ✓ Test empty credentials
  ✓ Test SQL injection attempt
  ✓ Test XSS in input

Lines 89 (Async Flow):
  ✓ Test network timeout
  ✓ Test concurrent login attempts
```

## Integration with Agents

### Tester Agent

```markdown
After running tests:
1. Generate coverage report
2. Check if coverage meets threshold (80%)
3. If below threshold, identify gaps
4. Generate test suggestions
5. Report back to user with action items
```

### Builder Agent

```markdown
After implementing feature:
1. Write tests
2. Run coverage-analyzer
3. If coverage <80%, add more tests
4. Iterate until threshold met
5. Mark feature complete
```

### Reviewer Agent

```markdown
During code review:
1. Check diff coverage (new code coverage)
2. Ensure new code has 100% coverage
3. Block merge if coverage decreases
```

## Diff Coverage

Track coverage of changed lines only.

### Configuration

**.nycrc.json**:
```json
{
  "check-coverage": true,
  "per-file": true,
  "skip-full": false
}
```

### Usage

```bash
# Generate baseline coverage
npm test -- --coverage --json > coverage-base.json

# Make changes and generate new coverage
npm test -- --coverage --json > coverage-new.json

# Compare
diff-cover coverage-new.json coverage-base.json
```

### Output

```
Diff Coverage: 85.7% (42/49 new lines covered)

New Lines Not Covered:
  src/auth/login.ts:45-48
  src/api/user.ts:23
  src/utils/validate.ts:67-69

⚠️ Please add tests for new code before merging
```

## CI/CD Integration

### GitHub Actions

```yaml
name: Coverage

on: [push, pull_request]

jobs:
  coverage:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3

      - name: Install dependencies
        run: npm ci

      - name: Run tests with coverage
        run: npm test -- --coverage

      - name: Check coverage threshold
        run: |
          COVERAGE=$(cat coverage/coverage-summary.json | jq '.total.lines.pct')
          if (( $(echo "$COVERAGE < 80" | bc -l) )); then
            echo "Coverage ($COVERAGE%) below threshold (80%)"
            exit 1
          fi

      - name: Upload to Codecov
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage/lcov.info
          fail_ci_if_error: true

      - name: Comment on PR
        uses: actions/github-script@v6
        with:
          script: |
            const coverage = require('./coverage/coverage-summary.json');
            const comment = `## Coverage Report\n\n` +
              `Lines: ${coverage.total.lines.pct}%\n` +
              `Branches: ${coverage.total.branches.pct}%\n` +
              `Functions: ${coverage.total.functions.pct}%`;
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: comment
            });
```

## Coverage Badges

### Codecov Badge

```markdown
[![codecov](https://codecov.io/gh/username/repo/branch/main/graph/badge.svg)](https://codecov.io/gh/username/repo)
```

### Coveralls Badge

```markdown
[![Coverage Status](https://coveralls.io/repos/github/username/repo/badge.svg?branch=main)](https://coveralls.io/github/username/repo?branch=main)
```

### Shields.io Badge

```markdown
![Coverage](https://img.shields.io/badge/coverage-87.5%25-brightgreen)
```

## Best Practices

### DO
✅ Aim for 80%+ coverage on production code
✅ Require 100% coverage on critical paths (auth, payment)
✅ Track diff coverage on PRs
✅ Fail CI if coverage decreases
✅ Focus on meaningful tests, not just coverage %
✅ Exclude test files and generated code from coverage
✅ Review uncovered lines manually

### DON'T
❌ Chase 100% coverage blindly
❌ Write tests just to increase coverage %
❌ Include test files in coverage metrics
❌ Ignore uncovered critical code
❌ Trust coverage % without code review
❌ Deploy with <80% coverage (production apps)

## Troubleshooting

### Coverage Report Not Generated

**Problem:** No `coverage/` directory created

**Solution:**
```bash
# Ensure coverage is enabled
npm test -- --coverage

# Check jest.config.js
collectCoverage: true
```

### Incorrect Coverage %

**Problem:** Coverage shows 100% but some code not tested

**Solution:** Check for:
- Dead code (never executed)
- Conditional logic with single path
- Code in excluded files

### Coverage Too Low

**Problem:** Can't reach 80% threshold

**Strategy:**
1. Start with critical files (auth, payment)
2. Test happy path first
3. Add error handling tests
4. Add edge case tests
5. Review and remove dead code

## Related Skills

- **run-tests**: Execute test suite
- **code-quality**: Code linting and formatting

## Version History

- **1.0.0** (2024-02-14): Initial implementation
  - Jest coverage support
  - NYC/Istanbul support
  - pytest-cov support
  - HTML/LCOV/text reports
  - Diff coverage tracking
  - CI/CD integration

---

*For more information, see [skills README](../README.md) or [main documentation](../../README.md)*
