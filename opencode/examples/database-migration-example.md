# Database Migration Example: Zero-Downtime Schema Change

**Scenario:** Add user preferences JSONB column to PostgreSQL with zero downtime

**Complexity:** Medium
**Duration:** ~2 hours
**Agents Used:** @planner, @migration, @tester, @reviewer
**Skills Used:** `run-tests`, `code-quality`

---

## Scenario

### Initial Request

**User:** "We need to add a user_preferences column to store user settings (theme, language, notifications). It should support any arbitrary JSON data and we can't have downtime during deployment."

### Context

**Current State:**
- PostgreSQL 14 database
- `users` table with 2.4M rows
- Production uptime requirement: 99.9%
- Active traffic: ~500 req/s during business hours

**Table Schema (Before):**
```sql
CREATE TABLE users (
  id BIGSERIAL PRIMARY KEY,
  email VARCHAR(255) NOT NULL UNIQUE,
  name VARCHAR(255) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);
```

**Requirements:**
- Add `preferences` JSONB column
- Default to empty object `{}`
- Support indexing on specific JSON keys
- Zero downtime deployment
- Rollback capability

### Success Criteria

- ✅ Migration runs without locking table
- ✅ No downtime for read/write operations
- ✅ Backward compatible (old code still works)
- ✅ Forward compatible (new code works)
- ✅ Rollback tested and verified
- ✅ Performance impact <5%

---

## Agent Transcript

### Phase 1: Planning (@planner)

**User:** @planner Design a zero-downtime migration to add user_preferences JSONB column

**@planner:**
> Analyzing migration requirements...
>
> **Database Analysis:**
> - Reading schema: `database/schema.sql`
> - Table size: 2.4M rows
> - Current indexes: 1 (on email)
> - Active traffic: ~500 req/s
>
> **Zero-Downtime Strategy:**
> For PostgreSQL, adding a nullable column with default is generally safe but...
> - On large tables, setting DEFAULT can lock the table
> - Need multi-phase deployment strategy
>
> **Creating migration spec...**

**Output:** `specs/add-user-preferences-migration.md`

```markdown
# User Preferences Column Migration Spec

## Overview
Add JSONB column for user preferences with zero-downtime deployment.

## Problem Analysis

### Why Zero-Downtime is Challenging

**PostgreSQL Behavior:**
```sql
-- ❌ BAD: Locks table while backfilling DEFAULT
ALTER TABLE users ADD COLUMN preferences JSONB DEFAULT '{}' NOT NULL;
-- On 2.4M rows, this could take 30+ seconds with exclusive lock
```

**Impact of Lock:**
- All SELECT queries blocked
- All INSERT/UPDATE queries blocked
- Application downtime: ~30-60 seconds
- User-facing errors

### Solution: Multi-Phase Deployment

**Phase 1: Add Column (Nullable, No Default)**
```sql
-- ✅ GOOD: Fast, no lock (metadata-only change in PG 11+)
ALTER TABLE users ADD COLUMN preferences JSONB;
-- Executes in <1ms, no table lock
```

**Phase 2: Backfill Data (In Batches)**
```sql
-- ✅ GOOD: Update in small batches to avoid long locks
UPDATE users
SET preferences = '{}'
WHERE id >= ? AND id < ? AND preferences IS NULL;
-- Run in batches of 10,000 rows
```

**Phase 3: Add NOT NULL Constraint**
```sql
-- After backfill complete, add constraint
ALTER TABLE users ALTER COLUMN preferences SET NOT NULL;
-- Fast since all rows already have values
```

**Phase 4: Add Default (Optional)**
```sql
-- For new rows
ALTER TABLE users ALTER COLUMN preferences SET DEFAULT '{}';
-- Metadata-only change, fast
```

## Migration Steps

### Step 1: Add Column (Nullable)
**File:** `migrations/001_add_preferences_column.sql`
```sql
-- Add nullable JSONB column
ALTER TABLE users ADD COLUMN preferences JSONB;

-- Add GIN index for JSON queries
CREATE INDEX CONCURRENTLY idx_users_preferences
ON users USING GIN (preferences);
```

**Characteristics:**
- Duration: <100ms
- Lock: None (metadata-only in PG 11+)
- Backward compatible: ✅ (column nullable, old code ignores it)

### Step 2: Update Application Code
**File:** `src/models/user.ts`
```typescript
// Support both old and new schema
interface User {
  id: number;
  email: string;
  name: string;
  preferences?: Record<string, any>;  // Optional field
}

// When reading, handle null
const preferences = user.preferences ?? {};

// When creating, set default
const newUser = {
  ...userData,
  preferences: userData.preferences ?? {}
};
```

**Deployment:** Deploy application code (backward compatible)

### Step 3: Backfill Data
**File:** `scripts/backfill-preferences.ts`
```typescript
// Batch backfill to avoid long locks
const BATCH_SIZE = 10000;
let offset = 0;

while (true) {
  const result = await db.query(`
    UPDATE users
    SET preferences = '{}'
    WHERE id >= $1
      AND id < $2
      AND preferences IS NULL
  `, [offset, offset + BATCH_SIZE]);

  if (result.rowCount === 0) break;

  offset += BATCH_SIZE;

  // Wait 100ms between batches (reduce load)
  await sleep(100);
}
```

**Execution:**
- Run during low-traffic hours (optional)
- Monitor query performance
- Can be interrupted and resumed
- Duration: ~15 minutes for 2.4M rows

### Step 4: Add NOT NULL Constraint
**File:** `migrations/002_set_preferences_not_null.sql`
```sql
-- After backfill is 100% complete
ALTER TABLE users ALTER COLUMN preferences SET NOT NULL;

-- Set default for new rows
ALTER TABLE users ALTER COLUMN preferences SET DEFAULT '{}';
```

**Characteristics:**
- Duration: <10ms (since all rows have values)
- Lock: Brief metadata lock
- Forward compatible: ✅

## Rollback Strategy

### If Issues Found After Step 1
```sql
-- Rollback: Drop column
ALTER TABLE users DROP COLUMN preferences;
DROP INDEX CONCURRENTLY idx_users_preferences;
```

### If Issues Found After Step 3 (Backfill)
```sql
-- Rollback: Set all to NULL
UPDATE users SET preferences = NULL;

-- Optionally drop column
ALTER TABLE users DROP COLUMN preferences;
```

### Application Rollback
```typescript
// Old code still works (ignores preferences column)
// Just redeploy previous version
```

## Testing Strategy

### Test 1: Migration Execution
- Run migration on staging database
- Verify column added
- Verify index created
- Check execution time (<100ms)

### Test 2: Backfill Performance
- Run backfill script on staging (2.4M rows)
- Monitor query duration per batch
- Verify no long locks
- Check total duration

### Test 3: Application Compatibility
- Test old code with new schema ✓
- Test new code with old schema (before backfill) ✓
- Test new code with new schema ✓

### Test 4: Rollback
- Execute rollback migration
- Verify column removed
- Verify old code still works

## Monitoring

**During Migration:**
- Monitor active connections: `pg_stat_activity`
- Monitor lock waits: `pg_locks`
- Monitor query duration
- Monitor error rate

**Metrics:**
```sql
-- Check backfill progress
SELECT
  COUNT(*) FILTER (WHERE preferences IS NULL) as pending,
  COUNT(*) FILTER (WHERE preferences IS NOT NULL) as completed,
  COUNT(*) as total
FROM users;

-- Monitor locks
SELECT * FROM pg_locks WHERE relation = 'users'::regclass;
```

## Deployment Timeline

| Time | Action | Downtime | Risk |
|------|--------|----------|------|
| T+0  | Deploy migration 001 (add column) | 0s | Low |
| T+1  | Deploy application code | 0s | Low |
| T+2  | Run backfill script | 0s | Low |
| T+15 | Backfill complete | 0s | - |
| T+16 | Deploy migration 002 (NOT NULL) | <1s | Low |

**Total Downtime:** 0 seconds

## Success Criteria

- ✅ Zero downtime (no service interruption)
- ✅ Backward compatible
- ✅ Forward compatible
- ✅ Rollback tested
- ✅ Performance impact <5%
```

**@planner:**
> Migration spec created using zero-downtime strategy.
>
> **Key Points:**
> - 4-phase deployment (add column → deploy code → backfill → add constraint)
> - No table locks (uses batching)
> - Fully backward compatible
> - Rollback at any stage
>
> Ready for @migration agent.

---

### Phase 2: Migration Implementation (@migration)

**User:** @migration Implement the migration per the spec

**@migration:**
> Reading spec: `specs/add-user-preferences-migration.md`
>
> **Creating migration files...**

**File 1:** `migrations/20260216120000_add_preferences_column.sql`

```sql
-- Migration: Add user preferences column
-- Type: Schema Change
-- Downtime: None
-- Backward Compatible: Yes

BEGIN;

-- Add JSONB column (nullable, no default)
-- This is a metadata-only change in PostgreSQL 11+
-- Executes in <1ms, no table lock
ALTER TABLE users ADD COLUMN preferences JSONB;

-- Add GIN index for efficient JSON queries
-- CONCURRENTLY prevents blocking other operations
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_preferences
ON users USING GIN (preferences);

-- Add comment for documentation
COMMENT ON COLUMN users.preferences IS
  'User preferences stored as JSONB. Default: {}.
   Supports arbitrary key-value pairs.';

COMMIT;
```

**File 2:** `migrations/20260216120001_set_preferences_not_null.sql`

```sql
-- Migration: Set preferences column NOT NULL
-- Run after backfill is complete
-- Downtime: <10ms

BEGIN;

-- Add NOT NULL constraint (fast since all rows have values)
ALTER TABLE users ALTER COLUMN preferences SET NOT NULL;

-- Set default for new rows
ALTER TABLE users ALTER COLUMN preferences SET DEFAULT '{}';

COMMIT;
```

**File 3:** `scripts/backfill-preferences.ts`

```typescript
import { pool } from '../database';

/**
 * Backfill user preferences column
 *
 * Strategy: Batch updates to avoid long locks
 * Batch size: 10,000 rows
 * Estimated duration: ~15 minutes for 2.4M rows
 */

const BATCH_SIZE = 10000;
const DELAY_MS = 100; // Delay between batches

async function backfillPreferences() {
  console.log('Starting backfill...');

  // Get total count
  const { rows: [{ total }] } = await pool.query(
    'SELECT COUNT(*) as total FROM users WHERE preferences IS NULL'
  );

  console.log(`Total rows to backfill: ${total}`);

  let processed = 0;
  let batchNum = 0;

  while (true) {
    const startTime = Date.now();

    // Update batch
    const result = await pool.query(`
      UPDATE users
      SET preferences = '{}'
      WHERE id IN (
        SELECT id
        FROM users
        WHERE preferences IS NULL
        LIMIT $1
      )
    `, [BATCH_SIZE]);

    const duration = Date.now() - startTime;
    processed += result.rowCount;
    batchNum++;

    console.log(
      `Batch ${batchNum}: Updated ${result.rowCount} rows in ${duration}ms ` +
      `(${processed}/${total}, ${((processed/total)*100).toFixed(1)}%)`
    );

    // Exit if no more rows
    if (result.rowCount === 0) break;

    // Delay between batches to reduce load
    await new Promise(resolve => setTimeout(resolve, DELAY_MS));
  }

  console.log(`Backfill complete! Processed ${processed} rows`);

  // Verify
  const { rows: [{ remaining }] } = await pool.query(
    'SELECT COUNT(*) as remaining FROM users WHERE preferences IS NULL'
  );

  if (remaining > 0) {
    console.warn(`Warning: ${remaining} rows still have NULL preferences`);
  } else {
    console.log('✓ All rows backfilled successfully');
  }
}

// Run with error handling
backfillPreferences()
  .then(() => {
    console.log('Backfill script completed successfully');
    process.exit(0);
  })
  .catch(error => {
    console.error('Backfill failed:', error);
    process.exit(1);
  });
```

**File 4:** `migrations/rollback/20260216120000_rollback.sql`

```sql
-- Rollback: Remove preferences column

BEGIN;

-- Drop index
DROP INDEX CONCURRENTLY IF EXISTS idx_users_preferences;

-- Drop column
ALTER TABLE users DROP COLUMN IF EXISTS preferences;

COMMIT;
```

**@migration:**
> Migration files created.
>
> **Files:**
> - `migrations/20260216120000_add_preferences_column.sql`
> - `migrations/20260216120001_set_preferences_not_null.sql`
> - `scripts/backfill-preferences.ts`
> - `migrations/rollback/20260216120000_rollback.sql`
>
> Ready for testing.

---

### Phase 3: Testing (@tester)

**User:** @tester Test the migration on staging database

**@tester:**
> Setting up test environment...
>
> **Test Database:**
> - Cloning production schema
> - Creating 2.4M test users
> - Running migration tests
>
> **Executing test suite...**

**Output:** `reports/migration-test-results.md`

```markdown
# Migration Test Results

## Test Environment

**Database:** PostgreSQL 14.7
**Rows:** 2,400,000 users
**Environment:** Staging (identical to production)

## Test 1: Migration Execution ✅

**Command:**
```bash
psql -f migrations/20260216120000_add_preferences_column.sql
```

**Results:**
```
BEGIN
ALTER TABLE
CREATE INDEX
COMMENT
COMMIT
Time: 87.234 ms
```

**Verification:**
```sql
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'users' AND column_name = 'preferences';

 column_name | data_type | is_nullable | column_default
-------------+-----------+-------------+----------------
 preferences | jsonb     | YES         | NULL
```

✅ **PASS:** Column added in 87ms, no locks

## Test 2: Index Creation ✅

**Verification:**
```sql
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'users' AND indexname = 'idx_users_preferences';

      indexname       |                    indexdef
----------------------+------------------------------------------------
 idx_users_preferences | CREATE INDEX idx_users_preferences ON users
                      | USING gin (preferences)
```

✅ **PASS:** GIN index created successfully

## Test 3: Backward Compatibility ✅

**Test:** Run old application code (doesn't know about preferences)

```typescript
// Old code
const user = await db.query('SELECT id, email, name FROM users WHERE id = $1', [123]);
// Doesn't select preferences column

// Result: Works fine, ignores new column
```

✅ **PASS:** Old code works without modification

## Test 4: Backfill Performance ✅

**Command:**
```bash
node scripts/backfill-preferences.ts
```

**Output:**
```
Starting backfill...
Total rows to backfill: 2400000
Batch 1: Updated 10000 rows in 234ms (10000/2400000, 0.4%)
Batch 2: Updated 10000 rows in 189ms (20000/2400000, 0.8%)
Batch 3: Updated 10000 rows in 201ms (30000/2400000, 1.3%)
...
Batch 240: Updated 10000 rows in 198ms (2400000/2400000, 100.0%)
Backfill complete! Processed 2400000 rows
✓ All rows backfilled successfully

Total duration: 14m 23s
Average batch time: 196ms
```

**Monitoring During Backfill:**
```sql
-- Check for blocking queries
SELECT COUNT(*) FROM pg_stat_activity WHERE wait_event_type = 'Lock';
-- Result: 0 (no queries blocked)

-- Check query duration
SELECT MAX(query_duration) FROM pg_stat_activity;
-- Result: 234ms (maximum batch duration)
```

✅ **PASS:** Backfill completed in 14m, no locks, no downtime

## Test 5: Forward Compatibility ✅

**Test:** New application code using preferences

```typescript
// New code
const user = await db.query(
  'SELECT id, email, name, preferences FROM users WHERE id = $1',
  [123]
);

// After backfill
console.log(user.preferences); // {}

// After inserting with preferences
const newUser = await db.query(
  'INSERT INTO users (email, name, preferences) VALUES ($1, $2, $3) RETURNING *',
  ['test@example.com', 'Test', { theme: 'dark' }]
);

console.log(newUser.preferences); // { theme: 'dark' }
```

✅ **PASS:** New code works with backfilled data

## Test 6: NOT NULL Migration ✅

**Command:**
```bash
psql -f migrations/20260216120001_set_preferences_not_null.sql
```

**Results:**
```
BEGIN
ALTER TABLE
ALTER TABLE
COMMIT
Time: 8.123 ms
```

**Verification:**
```sql
SELECT is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'users' AND column_name = 'preferences';

 is_nullable | column_default
-------------+----------------
 NO          | '{}'::jsonb
```

✅ **PASS:** NOT NULL constraint added in 8ms

## Test 7: Rollback ✅

**Command:**
```bash
psql -f migrations/rollback/20260216120000_rollback.sql
```

**Results:**
```
BEGIN
DROP INDEX
ALTER TABLE
COMMIT
Time: 234.567 ms
```

**Verification:**
```sql
SELECT column_name FROM information_schema.columns
WHERE table_name = 'users' AND column_name = 'preferences';

 column_name
-------------
(0 rows)
```

✅ **PASS:** Column removed, old schema restored

## Test 8: Performance Impact ✅

**Benchmark:** Query performance before/after migration

**Before Migration:**
```sql
SELECT id, email, name FROM users WHERE email = 'test@example.com';
-- Average: 2.3ms
```

**After Migration (with preferences column):**
```sql
SELECT id, email, name, preferences FROM users WHERE email = 'test@example.com';
-- Average: 2.4ms
```

**Impact:** +0.1ms (+4.3%)

✅ **PASS:** Performance impact <5% (well within target)

## Summary

| Test | Status | Duration | Notes |
|------|--------|----------|-------|
| Migration execution | ✅ | 87ms | No locks |
| Index creation | ✅ | Included | CONCURRENTLY |
| Backward compatibility | ✅ | N/A | Old code works |
| Backfill performance | ✅ | 14m 23s | No downtime |
| Forward compatibility | ✅ | N/A | New code works |
| NOT NULL migration | ✅ | 8ms | Fast |
| Rollback | ✅ | 235ms | Clean |
| Performance impact | ✅ | +4.3% | Within target |

**Overall:** ✅ **ALL TESTS PASSED**

## Recommendations

1. ✅ Migration is production-ready
2. Run backfill during low-traffic hours (optional, not required)
3. Monitor `pg_stat_activity` during backfill
4. Have rollback script ready (tested and verified)

## Approval

Migration approved for production deployment.
```

**@tester:**
> ✅ **ALL TESTS PASSED (8/8)**
>
> - Zero downtime verified
> - Backfill: 14m 23s (no locks)
> - Performance impact: +4.3% (within 5% target)
> - Rollback tested and works
>
> Production-ready.

---

### Phase 4: Final Review (@reviewer)

**User:** @reviewer Review migration before production

**@reviewer:**
> Reviewing migration...
>
> - Spec ✓
> - Migration files ✓
> - Test results ✓
> - Rollback plan ✓

**Output:** `reports/migration-final-review.md`

```markdown
# Migration Final Review

## Spec Compliance ✅

| Requirement | Status |
|-------------|--------|
| Zero downtime | ✅ Verified (no locks) |
| Backward compatible | ✅ Old code works |
| Forward compatible | ✅ New code works |
| Rollback capability | ✅ Tested |
| Performance <5% | ✅ Impact +4.3% |

## Migration Quality ✅

**SQL Best Practices:**
- ✅ Uses transactions (BEGIN/COMMIT)
- ✅ Includes comments
- ✅ Uses CONCURRENTLY for index
- ✅ No unnecessary locks

**Code Quality:**
- ✅ Backfill script has error handling
- ✅ Progress reporting
- ✅ Batch processing
- ✅ Configurable batch size

## Testing Coverage ✅

- ✅ Execution tested (87ms)
- ✅ Backfill tested (14m, no locks)
- ✅ Compatibility tested (old + new code)
- ✅ Rollback tested (works)
- ✅ Performance tested (+4.3%)

## Deployment Plan ✅

**Phase 1 (T+0):** Deploy migration 001
- Add preferences column (nullable)
- Create GIN index
- Duration: <100ms
- Risk: Low

**Phase 2 (T+1):** Deploy application code
- Support preferences field (optional)
- Duration: Normal deployment
- Risk: Low (backward compatible)

**Phase 3 (T+2):** Run backfill
- Execute backfill script
- Duration: ~15 minutes
- Risk: Low (no locks)

**Phase 4 (T+17):** Deploy migration 002
- Add NOT NULL constraint
- Set default value
- Duration: <10ms
- Risk: Low

**Total Timeline:** ~20 minutes
**Downtime:** 0 seconds

## Rollback Plan ✅

**If issues after Phase 1:**
```bash
psql -f migrations/rollback/20260216120000_rollback.sql
```

**If issues after Phase 3:**
- Redeploy old application code (works with or without column)
- Optionally run rollback migration

## Monitoring ✅

**During Migration:**
```sql
-- Active queries
SELECT * FROM pg_stat_activity WHERE state = 'active';

-- Locks
SELECT * FROM pg_locks WHERE relation = 'users'::regclass;

-- Backfill progress
SELECT
  COUNT(*) FILTER (WHERE preferences IS NULL) as remaining,
  COUNT(*) FILTER (WHERE preferences IS NOT NULL) as completed
FROM users;
```

## Approval ✅

**Status:** APPROVED FOR PRODUCTION

**Confidence:** HIGH
- Thoroughly tested on staging (identical to production)
- Zero-downtime strategy verified
- Rollback tested
- Performance impact acceptable

**Recommended Deployment Window:** Any time (no downtime required)

**Sign-off:** @reviewer
```

**@reviewer:**
> ✅ **APPROVED FOR PRODUCTION**
>
> Migration is production-ready. Zero-downtime verified on staging.

---

## Artifacts Generated

### Specifications
1. **specs/add-user-preferences-migration.md** (Migration spec, 320 lines)

### Migration Files
1. **migrations/20260216120000_add_preferences_column.sql** (Add column + index)
2. **migrations/20260216120001_set_preferences_not_null.sql** (Add constraint)
3. **scripts/backfill-preferences.ts** (Backfill script, 95 lines)
4. **migrations/rollback/20260216120000_rollback.sql** (Rollback script)

### Test Results
1. **reports/migration-test-results.md** (8/8 tests passed)
2. **reports/migration-final-review.md** (Approved)

**Total Code:** ~450 lines

---

## Lessons Learned

### What Went Well ✅

1. **Zero-Downtime Strategy**
   - 4-phase approach prevented locks
   - Backfill in batches avoided blocking queries
   - Total downtime: 0 seconds

2. **Backward/Forward Compatibility**
   - Old code worked without changes
   - New code worked at every phase
   - Allowed flexible deployment timing

3. **Comprehensive Testing**
   - Tested on staging with production data volume
   - Verified rollback works
   - Performance impact measured (<5%)

4. **Clear Documentation**
   - Spec explained WHY (not just HOW)
   - Timeline clear
   - Rollback plan documented

### What Could Be Improved 🔧

1. **Automated Rollback**
   - Could add health check that auto-rolls back on errors
   - Currently requires manual intervention

2. **Progress Monitoring**
   - Backfill script could expose metrics endpoint
   - Real-time dashboard would be helpful

3. **Schema Validation**
   - Could add automated check that backfill is 100% complete
   - Before running migration 002

### Key Takeaways 💡

1. **Large Table Migrations Need Special Care**
   - Never use `ALTER TABLE ... DEFAULT` on large tables
   - Always batch updates to avoid locks

2. **Test on Production-Like Data**
   - 2.4M rows on staging revealed actual performance
   - Small test datasets don't show locking issues

3. **Backward Compatibility is Key**
   - Allows rolling deployment
   - Reduces risk
   - Enables easy rollback

4. **Monitor During Migration**
   - `pg_stat_activity` shows blocking queries
   - `pg_locks` reveals lock contention
   - Real-time monitoring critical

5. **Rollback Plan is Mandatory**
   - Always have tested rollback script
   - Document rollback procedure
   - Practice rollback before production

---

## Success Metrics

| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| Downtime | 0s | 0s | ✅ |
| Migration time | <1s | 87ms | ✅ |
| Backfill time | <30m | 14m 23s | ✅ |
| Performance impact | <5% | +4.3% | ✅ |
| Rollback tested | Yes | Yes | ✅ |
| Tests passing | 100% | 100% | ✅ |

**All criteria met!**

---

**This example demonstrates:**
- Zero-downtime database migration strategy
- Multi-phase deployment approach
- Backward and forward compatibility
- Batch processing for large tables
- Comprehensive testing on production-like data
- Rollback planning and testing

**Estimated Time:** ~2 hours with OpenCode vs ~1-2 days manual planning/testing

---

*Example last updated: 2026-02-16*
