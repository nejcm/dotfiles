---
name: mutation-tester
description: Mutation testing to validate test suite quality
version: 1.0.0
category: testing
tools:
  - stryker
  - mutmut
  - pitest
permissions:
  - read
  - bash
---

# Mutation Tester Skill

Validates test quality through mutation testing.

## Purpose

Mutation testing introduces small changes (mutations) to your code to verify that your tests catch them. High-quality tests will fail when code is mutated; poor tests will pass despite bugs.

## What is Mutation Testing?

**Mutation:** Small code change that should break functionality
**Killed Mutant:** Test caught the mutation (good!)
**Survived Mutant:** Test didn't catch mutation (bad - weak test)

**Example:**
```typescript
// Original
if (age >= 18) return true;

// Mutated (boundary mutation)
if (age > 18) return true;  // Changed >= to >

// Good test would catch this
expect(canVote(18)).toBe(true);  // Fails with mutation
```

## Usage

### JavaScript/TypeScript (Stryker)

```bash
# Install
npm install --save-dev @stryker-mutator/core

# Run mutation testing
npx stryker run

# Configuration (stryker.conf.json)
{
  "mutate": ["src/**/*.ts"],
  "testRunner": "jest",
  "coverageAnalysis": "perTest",
  "thresholds": {
    "high": 80,
    "low": 60,
    "break": 50
  }
}
```

### Python (mutmut)

```bash
# Install
pip install mutmut

# Run mutation testing
mutmut run

# Show results
mutmut results
mutmut show <mutant-id>
```

### Java (PIT)

```xml
<!-- pom.xml -->
<plugin>
  <groupId>org.pitest</groupId>
  <artifactId>pitest-maven</artifactId>
  <version>1.9.0</version>
</plugin>
```

```bash
mvn org.pitest:pitest-maven:mutationCoverage
```

## Mutation Types

**Arithmetic mutations:**
- `+` ↔ `-`
- `*` ↔ `/`
- `%` ↔ `*`

**Relational mutations:**
- `>` ↔ `>=` ↔ `<` ↔ `<=`
- `==` ↔ `!=`

**Logical mutations:**
- `&&` ↔ `||`
- `!condition` ↔ `condition`

**Statement mutations:**
- Remove return statement
- Remove function call
- Change constant values

## Output Format

### Report
```
Mutation Testing Results
========================

Total Mutants: 156
Killed: 134 (85.9%)
Survived: 18 (11.5%)
Timeout: 3 (1.9%)
No Coverage: 1 (0.6%)

Mutation Score: 85.9%
Target: 80% ✓

Survived Mutants:
  1. src/auth/login.ts:45
     - (>=) → (>)
     - Test: auth.test.ts should fail but passed

  2. src/api/users.ts:23
     - Removed return statement
     - No test covers this path
```

### Per-File Breakdown
```
File                          Mutants  Killed  Survived  Score
-------------------------------------------------------------
src/auth/login.ts                 23      22         1   95.7%
src/api/users.ts                  45      40         5   88.9%
src/utils/validation.ts           34      29         5   85.3%
src/services/payment.ts           54      43        11   79.6% ⚠️
```

## Interpreting Results

**Mutation Score (Target: 80%+)**
- 90-100%: Excellent test quality
- 80-89%: Good test quality
- 70-79%: Acceptable, room for improvement
- <70%: Weak tests, needs attention

**Common Issues:**

1. **Survived boundary mutations**
   ```typescript
   // Weak test
   expect(isAdult(19)).toBe(true);  // Misses boundary at 18

   // Better test
   expect(isAdult(18)).toBe(true);  // Tests exact boundary
   expect(isAdult(17)).toBe(false);
   ```

2. **Survived logical mutations**
   ```typescript
   // Weak: Doesn't test both conditions
   if (isLoggedIn && hasPermission) { ... }

   // Strong: Tests all combinations
   test('logged in + permission', ...)
   test('logged in + no permission', ...)
   test('not logged in + permission', ...)
   test('not logged in + no permission', ...)
   ```

3. **No coverage survivors**
   - Code not tested at all
   - Add tests for uncovered paths

## Integration

### CI/CD
```yaml
- name: Mutation Testing
  run: npx stryker run
  env:
    STRYKER_DASHBOARD_API_KEY: ${{ secrets.STRYKER_KEY }}

- name: Check Threshold
  run: |
    SCORE=$(cat reports/mutation-report.json | jq '.mutationScore')
    if (( $(echo "$SCORE < 80" | bc -l) )); then
      echo "Mutation score $SCORE% below 80%"
      exit 1
    fi
```

### Pre-Commit Hook (Optional)
```bash
# Run on changed files only
npx stryker run --mutate $(git diff --name-only HEAD)
```

## Best Practices

### DO
✅ Run mutation testing regularly
✅ Focus on critical code paths first
✅ Aim for 80%+ mutation score
✅ Fix survived mutants
✅ Use mutation testing to find test gaps

### DON'T
❌ Aim for 100% (diminishing returns)
❌ Run on every commit (too slow)
❌ Ignore survived mutants
❌ Test trivial code (getters/setters)

## Performance

Mutation testing is **slow** (runs tests many times).

**Optimization:**
- Run on specific files/modules
- Use incremental mode
- Parallelize execution
- Cache results
- Run in CI, not locally

**Example timing:**
- Small project (1000 LOC): 5-10 minutes
- Medium project (10k LOC): 30-60 minutes
- Large project (100k LOC): 2-5 hours

## Related

- **Skills:** `run-tests`, `coverage-analyzer`
- **Agents:** `@tester`

---

*Version 1.0.0*
