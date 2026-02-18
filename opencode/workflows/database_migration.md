# Database Migration Workflow

Safe and reliable process for database schema changes and data migrations.

## Migration Types

### 1. Schema Migrations
Changes to database structure:
- Add/drop tables
- Add/drop columns
- Modify column types
- Add/drop indexes
- Add/drop constraints
- Modify relationships

### 2. Data Migrations
Changes to existing data:
- Backfill new columns
- Transform data formats
- Clean up bad data
- Merge duplicate records
- Archive old data

### 3. Combined Migrations
Both schema and data changes together (use with caution!)

---

## Risk Classification

### LOW RISK ✅
**Safe** - Can be applied with standard process

- Adding nullable columns
- Creating new tables (not yet used)
- Adding indexes (with CONCURRENTLY in PostgreSQL)
- Adding columns with defaults on small tables (<1000 rows)

### MEDIUM RISK ⚠️
**Careful** - Requires testing and coordination

- Renaming columns (requires code changes)
- Changing column types
- Adding NOT NULL constraints
- Removing unused columns
- Large table alterations (>100K rows)

### HIGH RISK ❌
**Dangerous** - Requires extensive planning

- Dropping tables with data
- Dropping columns with data
- Data type changes requiring transformation
- Changes to heavily-trafficked tables
- Migrations requiring downtime

---

## Migration Workflow

### Phase 1: Planning (Before Implementation)

#### 1. Create Migration Spec

```bash
# Use migration agent to plan
@migration Create migration plan for adding user_profiles table

# Planner should include:
# - What tables/columns affected
# - Risk assessment
# - Rollback procedure
# - Estimated duration
# - Downtime requirements
```

**Migration Spec Template:**
```markdown
# Migration: Add user_profiles table

## Risk Level: LOW / MEDIUM / HIGH

## Description
Add new user_profiles table with one-to-one relationship to users

## Schema Changes
```sql
CREATE TABLE user_profiles (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  bio TEXT,
  avatar_url VARCHAR(512),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id)
);

CREATE INDEX idx_user_profiles_user_id ON user_profiles(user_id);
```

## Data Impact
- No existing data affected
- No data transformation needed
- Additive only

## Estimated Duration
- Small DB (<10K users): < 1 second
- Medium DB (<1M users): < 5 seconds
- Large DB (>1M users): < 30 seconds

## Downtime Required
NO - this can run while application is live

## Rollback Procedure
```sql
DROP TABLE user_profiles CASCADE;
```

## Testing Plan
1. Test migration on local database
2. Test migration on staging database copy
3. Test rollback procedure
4. Verify application works with schema

## Application Changes Required
- Backend code must be deployed after migration
- Frontend can be deployed independently
```

#### 2. Review Migration Plan

**Checklist:**
- [ ] Risk level appropriate
- [ ] Rollback procedure tested
- [ ] Impact on application assessed
- [ ] Coordination plan for code changes
- [ ] Monitoring plan defined

---

### Phase 2: Migration Creation

#### 1. Generate Migration File

Most ORMs have migration generators:

**TypeORM:**
```bash
npm run typeorm migration:generate -- -n AddUserProfiles
```

**Prisma:**
```bash
npx prisma migrate dev --name add-user-profiles
```

**Sequelize:**
```bash
npx sequelize-cli migration:generate --name add-user-profiles
```

**Alembic (Python):**
```bash
alembic revision --autogenerate -m "add user profiles"
```

**Raw SQL:**
```bash
# Create migration file manually
touch migrations/2024-02-13-add-user-profiles.sql
```

#### 2. Write Safe Migration

**Key Principles:**
- Migrations should be idempotent (safe to run twice)
- Always include UP and DOWN
- Add validation checks
- Use transactions when possible
- Consider zero-downtime patterns

**Example Migration (PostgreSQL):**
```sql
-- migrations/2024-02-13-add-user-profiles.sql

-- ============================================
-- UP Migration
-- ============================================

BEGIN;

-- Create table only if it doesn't exist
CREATE TABLE IF NOT EXISTS user_profiles (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  bio TEXT,
  avatar_url VARCHAR(512),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT unique_user_id UNIQUE(user_id)
);

-- Create index (CONCURRENTLY to avoid locks)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_profiles_user_id
  ON user_profiles(user_id);

-- Validate migration succeeded
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_name = 'user_profiles'
  ) THEN
    RAISE EXCEPTION 'Migration failed: user_profiles table not created';
  END IF;
END $$;

COMMIT;

-- ============================================
-- DOWN Migration (Rollback)
-- ============================================

BEGIN;

DROP TABLE IF EXISTS user_profiles CASCADE;

-- Validate rollback succeeded
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_name = 'user_profiles'
  ) THEN
    RAISE EXCEPTION 'Rollback failed: user_profiles table still exists';
  END IF;
END $$;

COMMIT;
```

---

### Phase 3: Local Testing

#### 1. Test Migration

```bash
# 1. Backup local database
pg_dump mydb > backup_before_migration.sql

# 2. Run migration
npm run migrate:up
# or
psql -d mydb -f migrations/2024-02-13-add-user-profiles.sql

# 3. Verify schema
psql -d mydb -c "\d user_profiles"

# 4. Test application
npm run dev
# Manually test features affected by migration

# 5. Test rollback
npm run migrate:down
# or run DOWN section of migration

# 6. Verify rollback
psql -d mydb -c "\d user_profiles"
# Should return "Did not find any relation named user_profiles"

# 7. Re-run migration (test idempotency)
npm run migrate:up
# Should succeed without errors
```

#### 2. Test Data Migration

If migration includes data changes:

```bash
# 1. Insert test data
psql -d mydb -c "INSERT INTO users (email) VALUES ('test@example.com');"

# 2. Run data migration
psql -d mydb -f migrations/2024-02-13-backfill-profiles.sql

# 3. Verify data
psql -d mydb -c "SELECT * FROM user_profiles WHERE user_id = 1;"

# 4. Test rollback with data
npm run migrate:down
```

---

### Phase 4: Staging Testing

#### 1. Deploy to Staging

```bash
# 1. Copy production data to staging (if needed)
pg_dump production_db | psql staging_db

# 2. Run migration on staging
npm run migrate:up -- --env=staging

# 3. Monitor migration
# - Check duration
# - Check for errors
# - Check for locks
```

#### 2. Staging Validation

- [ ] Migration completed successfully
- [ ] Application functions correctly
- [ ] No performance degradation
- [ ] No unexpected locks
- [ ] Rollback tested and works

#### 3. Measure Performance

```bash
# Run migration with timing
\timing on
\i migrations/2024-02-13-add-user-profiles.sql
# Note: "Time: 234.56 ms"

# Check table size
SELECT pg_size_pretty(pg_total_relation_size('user_profiles'));

# Check query performance
EXPLAIN ANALYZE SELECT * FROM user_profiles WHERE user_id = 1;
```

---

### Phase 5: Production Deployment

#### 1. Pre-Migration Checklist

- [ ] Backup completed (automated or manual)
- [ ] Rollback script tested and ready
- [ ] Team notified of migration window
- [ ] Monitoring dashboard open
- [ ] Estimated duration known
- [ ] Downtime announcement made (if needed)
- [ ] Off-peak time selected (if possible)

#### 2. Create Database Backup

```bash
# PostgreSQL
pg_dump -Fc mydb > backup_pre_migration_$(date +%Y%m%d_%H%M%S).dump

# MySQL
mysqldump --single-transaction mydb > backup_pre_migration_$(date +%Y%m%d_%H%M%S).sql

# Verify backup
pg_restore --list backup_pre_migration_*.dump | head
```

#### 3. Run Migration

**For Zero-Downtime Migrations:**
```bash
# Deploy migration (no downtime)
npm run migrate:up -- --env=production

# Monitor immediately
# - Check error logs
# - Check database connections
# - Check application health
```

**For Migrations Requiring Downtime:**
```bash
# 1. Enable maintenance mode
npm run maintenance:on

# 2. Wait for active connections to complete
# (30-60 seconds)

# 3. Run migration
npm run migrate:up -- --env=production

# 4. Disable maintenance mode
npm run maintenance:off

# 5. Verify application
curl https://api.yourapp.com/health
```

#### 4. Post-Migration Verification

```bash
# 1. Check migration status
npm run migrate:status

# 2. Verify schema
psql -d production_db -c "\d user_profiles"

# 3. Spot check data
psql -d production_db -c "SELECT COUNT(*) FROM user_profiles;"

# 4. Monitor application
# - Error rate
# - Response time
# - Database connections
# - Query performance

# 5. Run smoke tests
npm run test:smoke -- --env=production
```

---

### Phase 6: Code Deployment

#### Deploy Application Code

**Important:** Coordinate migration timing with code deployment

**Strategy 1: Migration First (Additive Changes)**
```
1. Deploy migration (adds new table/column)
2. Deploy code that uses new schema
3. Code is backwards compatible
```

**Strategy 2: Code First (Removal)**
```
1. Deploy code that stops using old column
2. Wait for all instances to update
3. Deploy migration that removes column
```

**Strategy 3: Multi-Phase (Renaming)**
```
Phase 1:
  - Add new column
  - Deploy code that writes to BOTH columns

Phase 2:
  - Backfill old data to new column
  - Deploy code that reads from new column

Phase 3:
  - Remove old column
```

---

## Zero-Downtime Migration Patterns

### Pattern 1: Expand-Migrate-Contract

**Use For:** Renaming columns, changing types

**Steps:**
```
1. EXPAND: Add new column
   ALTER TABLE users ADD COLUMN full_name VARCHAR(255);

2. MIGRATE: Dual-write (code changes)
   - Write to both old and new columns
   - Backfill existing data

3. CONTRACT: Remove old column
   ALTER TABLE users DROP COLUMN name;
```

### Pattern 2: Shadow Table

**Use For:** Large table transformations

**Steps:**
```
1. Create new table with desired schema
   CREATE TABLE users_new (...)

2. Copy data in background
   INSERT INTO users_new SELECT * FROM users

3. Swap tables atomically
   BEGIN;
   ALTER TABLE users RENAME TO users_old;
   ALTER TABLE users_new RENAME TO users;
   COMMIT;

4. Clean up
   DROP TABLE users_old;
```

### Pattern 3: Online Schema Change

**Use For:** MySQL large tables

**Tools:**
- pt-online-schema-change (Percona Toolkit)
- gh-ost (GitHub)

```bash
# Using pt-online-schema-change
pt-online-schema-change \
  --alter "ADD COLUMN bio TEXT" \
  D=mydb,t=users \
  --execute
```

---

## Common Migration Scenarios

### Scenario 1: Add Nullable Column

```sql
-- ✅ SAFE - No downtime needed
ALTER TABLE users ADD COLUMN phone VARCHAR(20);

-- Idempotent version
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'users' AND column_name = 'phone'
  ) THEN
    ALTER TABLE users ADD COLUMN phone VARCHAR(20);
  END IF;
END $$;
```

### Scenario 2: Add Column with Default

```sql
-- ⚠️ CAREFUL - Can lock table on large datasets

-- For SMALL tables (<10K rows):
ALTER TABLE users ADD COLUMN role VARCHAR(20) DEFAULT 'user';

-- For LARGE tables (use multi-step):
-- Step 1: Add nullable column
ALTER TABLE users ADD COLUMN role VARCHAR(20);

-- Step 2: Backfill in batches
UPDATE users SET role = 'user' WHERE role IS NULL AND id >= 1 AND id < 10000;
-- Repeat for each batch

-- Step 3: Add default
ALTER TABLE users ALTER COLUMN role SET DEFAULT 'user';

-- Step 4: Add NOT NULL (if needed)
ALTER TABLE users ALTER COLUMN role SET NOT NULL;
```

### Scenario 3: Rename Column

```sql
-- ❌ AVOID - Breaks running application
ALTER TABLE users RENAME COLUMN name TO full_name;

-- ✅ SAFE - Multi-phase migration

-- Phase 1 Migration:
ALTER TABLE users ADD COLUMN full_name VARCHAR(255);
UPDATE users SET full_name = name WHERE full_name IS NULL;

-- Phase 1 Code:
-- Write to BOTH name and full_name
-- Read from name (or full_name as fallback)

-- Phase 2 Migration (after code deployed):
ALTER TABLE users DROP COLUMN name;

-- Phase 2 Code:
-- Read/write only full_name
```

### Scenario 4: Change Column Type

```sql
-- Example: Change price from INTEGER to DECIMAL

-- ❌ DANGEROUS - Can lose data
ALTER TABLE products ALTER COLUMN price TYPE DECIMAL(10,2);

-- ✅ SAFE - Shadow column approach

-- Step 1: Add new column
ALTER TABLE products ADD COLUMN price_decimal DECIMAL(10,2);

-- Step 2: Backfill
UPDATE products SET price_decimal = price::DECIMAL(10,2);

-- Step 3: Deploy code using price_decimal

-- Step 4: Drop old column, rename new
BEGIN;
ALTER TABLE products DROP COLUMN price;
ALTER TABLE products RENAME COLUMN price_decimal TO price;
COMMIT;
```

### Scenario 5: Add Index

```sql
-- ⚠️ CAREFUL - Can lock table

-- For PostgreSQL:
CREATE INDEX CONCURRENTLY idx_users_email ON users(email);
-- CONCURRENTLY prevents locks but takes longer

-- For MySQL:
ALTER TABLE users ADD INDEX idx_users_email (email), ALGORITHM=INPLACE, LOCK=NONE;

-- Verify index created
\di idx_users_email
```

### Scenario 6: Remove Column

```sql
-- ❌ DANGEROUS - Immediate data loss
ALTER TABLE users DROP COLUMN deprecated_field;

-- ✅ SAFE - Phased approach

-- Phase 1: Stop writing to column (code deploy)
-- Monitor for 1-2 weeks to ensure nothing breaks

-- Phase 2: Drop column
ALTER TABLE users DROP COLUMN deprecated_field;

-- Rollback: Cannot restore data! Must restore from backup.
```

---

## Rollback Procedures

### Successful Rollback

```bash
# 1. Run rollback migration
npm run migrate:down

# 2. Verify rollback
npm run migrate:status

# 3. Restart application
# (may be needed to clear schema cache)

# 4. Verify application
npm run test:smoke
```

### Failed Rollback

**If rollback fails:**

```bash
# 1. DON'T PANIC

# 2. Check error message
# Common issues:
# - Foreign key constraints
# - Data still exists
# - Permissions

# 3. Manual rollback
psql -d mydb

# 4. Check dependencies
\d+ tablename

# 5. Drop dependencies first
ALTER TABLE child_table DROP CONSTRAINT fk_parent;
DROP TABLE parent_table;

# 6. Restore from backup if necessary
pg_restore -d mydb backup_pre_migration.dump
```

---

## Monitoring During Migration

### Key Metrics to Watch

```bash
# Database Connections
SELECT count(*) FROM pg_stat_activity;

# Long Running Queries
SELECT pid, now() - pg_stat_activity.query_start AS duration, query
FROM pg_stat_activity
WHERE state = 'active'
ORDER BY duration DESC;

# Table Locks
SELECT * FROM pg_locks WHERE NOT granted;

# Table Sizes
SELECT
  table_name,
  pg_size_pretty(pg_total_relation_size(quote_ident(table_name)))
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY pg_total_relation_size(quote_ident(table_name)) DESC;
```

### Alert Triggers

Set alerts for:
- Database connection pool > 80%
- Query duration > 10 seconds
- Lock wait time > 5 seconds
- Migration duration > estimated time

---

## Migration Checklist

### Planning Phase
- [ ] Migration spec created
- [ ] Risk assessment completed
- [ ] Rollback procedure documented
- [ ] Estimated duration calculated
- [ ] Downtime requirements identified

### Development Phase
- [ ] Migration file created
- [ ] Both UP and DOWN migrations written
- [ ] Idempotency ensured
- [ ] Validation checks added

### Testing Phase
- [ ] Tested on local database
- [ ] Tested on staging database (with production-like data)
- [ ] Rollback tested successfully
- [ ] Performance measured
- [ ] Application tested with new schema

### Deployment Phase
- [ ] Team notified of migration window
- [ ] Database backup completed
- [ ] Monitoring dashboard ready
- [ ] Rollback script ready
- [ ] Migration executed successfully

### Post-Deployment Phase
- [ ] Schema verified
- [ ] Application verified
- [ ] Monitoring shows normal metrics
- [ ] Code deployed (if needed)
- [ ] Documentation updated

---

## Tools & Utilities

### Migration Tools by Framework

**Node.js / TypeScript:**
- TypeORM
- Prisma
- Sequelize
- Knex.js
- db-migrate

**Python:**
- Alembic (SQLAlchemy)
- Django Migrations
- Flyway (Java but works with Python)

**Ruby:**
- ActiveRecord Migrations (Rails)

**Go:**
- golang-migrate
- Goose

**Database-Agnostic:**
- Flyway
- Liquibase

### Online Schema Change Tools

- **pt-online-schema-change** (Percona) - MySQL/MariaDB
- **gh-ost** (GitHub) - MySQL
- **pg_repack** - PostgreSQL

---

## Best Practices

### ✅ DO

1. Always test migrations locally first
2. Always test rollback procedure
3. Make migrations idempotent
4. Use transactions when possible
5. Take backups before production migrations
6. Add validation checks to migrations
7. Document migration thoroughly
8. Monitor during and after migration
9. Run migrations during low-traffic periods
10. Keep migrations small and focused

### ❌ DON'T

1. Modify existing migration files
2. Skip rollback script
3. Run untested migrations in production
4. Make destructive changes without backup
5. Bundle multiple unrelated changes
6. Assume migration will be fast
7. Skip staging environment testing
8. Ignore database locks
9. Deploy code before compatible migration
10. Rush migrations under pressure

---

## Emergency Procedures

### If Migration is Taking Too Long

```bash
# 1. Check progress
SELECT pid, query, state, wait_event
FROM pg_stat_activity
WHERE state = 'active';

# 2. If safe to cancel:
SELECT pg_cancel_backend(PID);

# 3. Rollback
npm run migrate:down

# 4. Investigate why it's slow
EXPLAIN ANALYZE [your migration query]

# 5. Optimize and retry
```

### If Application Breaks After Migration

```bash
# 1. Quick assessment
# - Can we rollback migration?
# - Can we rollback code?
# - Can we add quick fix?

# 2. If yes to rollback:
npm run migrate:down

# 3. If no to rollback:
# Apply emergency hotfix
@builder Create hotfix for migration issue

# 4. Restore from backup if necessary
pg_restore -d mydb backup_pre_migration.dump
```

---

**Remember**: Measure twice, migrate once. Database migrations are some of the riskiest operations in software deployment. Take your time, test thoroughly, and always have a rollback plan!
