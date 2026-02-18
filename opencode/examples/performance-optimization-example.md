# Performance Optimization Example: Dashboard Query Optimization

**Scenario:** Optimize slow user dashboard query from 3 seconds to <200ms

**Complexity:** Medium
**Duration:** ~2 hours
**Agents Used:** @performance, @builder, @tester
**Skills Used:** `performance-profiler`, `run-tests`

---

## Scenario

### Performance Issue

**Severity:** HIGH (P1)
**Reporter:** Product Team
**User Impact:** Poor user experience, high bounce rate

**Description:**
> The user dashboard loads very slowly (~3 seconds). Users complain about the delay. Dashboard shows user stats, recent orders, and activity feed.

**Current Performance:**
```
GET /api/dashboard
Response Time: 2,847ms (95th percentile)
Timeout Rate: 2.3%
User Complaints: 45 in last week
```

**Business Impact:**
- Dashboard bounce rate: 23% (target: <5%)
- User satisfaction score: 3.2/5.0 (target: >4.5)
- Revenue impact: Slow dashboard correlates with 15% drop in conversions

---

## Agent Transcript

### Phase 1: Performance Analysis (@performance)

**User:** @performance Profile the dashboard endpoint and identify bottlenecks

**@performance:**
> **Profiling dashboard endpoint...**
>
> Running performance profiler...

**Command:**
```bash
# Profile dashboard endpoint
npx autocannon -c 10 -d 30 http://localhost:3000/api/dashboard
```

**Results:**
```
Requests/sec: 3.5
Latency (avg): 2,847ms
Latency (p95): 3,142ms
Latency (p99): 3,456ms
```

**Detailed Profiling:**
```bash
npx clinic doctor -- node server.js
# Then make requests to /api/dashboard
```

**Flamegraph Analysis:**

```
Main Thread (3000ms total)
├─ getDashboardData (2950ms) ← 98% of time!
│  ├─ getUserStats (1200ms) ← Database query
│  ├─ getRecentOrders (1100ms) ← Database query
│  ├─ getActivityFeed (500ms) ← Database query
│  └─ aggregateData (150ms) ← CPU-bound
└─ sendResponse (50ms)
```

**@performance:**
> **Bottleneck identified:** Database queries consuming 2,800ms (93% of time)
>
> Analyzing SQL queries...

**Output:** `reports/dashboard-performance-analysis.md`

```markdown
# Dashboard Performance Analysis

## Summary

**Current:** 2,847ms average
**Target:** <200ms
**Required Improvement:** 14x faster

## Bottleneck Breakdown

| Operation | Time | % Total | Issue |
|-----------|------|---------|-------|
| getUserStats query | 1,200ms | 42% | Full table scan |
| getRecentOrders query | 1,100ms | 39% | Missing index |
| getActivityFeed query | 500ms | 18% | N+1 query |
| Data aggregation | 150ms | 5% | JavaScript overhead |
| Network/JSON | 50ms | 2% | Acceptable |

## Query Analysis

### Query 1: User Stats (1,200ms)

**Current SQL:**
```sql
SELECT
  COUNT(*) as total_orders,
  SUM(total) as lifetime_value,
  AVG(total) as avg_order_value
FROM orders
WHERE user_id = $1;
```

**EXPLAIN ANALYZE:**
```
Seq Scan on orders  (cost=0.00..45234.56 rows=123456 width=16)
                    (actual time=0.023..1187.234 rows=1234 loops=1)
  Filter: (user_id = 123)
  Rows Removed by Filter: 1234567
Planning Time: 0.145 ms
Execution Time: 1198.456 ms
```

**Problem:** Full table scan (Seq Scan) on 1.2M orders
**Solution:** Add index on user_id

### Query 2: Recent Orders (1,100ms)

**Current SQL:**
```sql
SELECT
  o.*,
  (SELECT name FROM products WHERE id = o.product_id) as product_name
FROM orders o
WHERE user_id = $1
ORDER BY created_at DESC
LIMIT 10;
```

**EXPLAIN ANALYZE:**
```
Limit  (cost=0.00..23456.78 rows=10 width=256)
       (actual time=12.345..1098.567 rows=10 loops=1)
  -> Sort  (cost=23456.78..23457.12 rows=1234 width=256)
             (actual time=1097.234..1097.456 rows=10 loops=1)
    Sort Key: created_at DESC
    -> Seq Scan on orders  (cost=0.00..45234.56 rows=1234 width=256)
                          (actual time=0.023..1034.567 rows=1234 loops=1)
      Filter: (user_id = 123)
  SubPlan 1
    -> Seq Scan on products  (cost=0.00..34.56 rows=1 width=64)
         (actual time=5.234..5.456 rows=1 loops=10)
      Filter: (id = o.product_id)
```

**Problems:**
1. No index on (user_id, created_at) for sorting
2. N+1 query pattern (subquery per row)

**Solutions:**
1. Add composite index on (user_id, created_at)
2. Use JOIN instead of subquery

### Query 3: Activity Feed (500ms)

**Current Code:**
```typescript
// N+1 query problem
const activities = await db.query(
  'SELECT * FROM activities WHERE user_id = $1 LIMIT 20',
  [userId]
);

for (const activity of activities) {
  activity.user = await db.query(
    'SELECT name, avatar FROM users WHERE id = $1',
    [activity.related_user_id]
  );
}
```

**Problems:**
1. 20 separate queries for related users
2. Total time: 500ms (20 queries × 25ms each)

**Solution:** Single JOIN query

## Optimization Recommendations

### 1. Add Database Indexes

```sql
-- Index for getUserStats
CREATE INDEX idx_orders_user_id ON orders(user_id);

-- Composite index for getRecentOrders
CREATE INDEX idx_orders_user_created
ON orders(user_id, created_at DESC);

-- Index for activity feed
CREATE INDEX idx_activities_user_id ON activities(user_id);
```

**Expected Impact:** 1,200ms → 50ms for indexed queries

### 2. Fix N+1 Query Pattern

Replace subqueries with JOINs:
```sql
SELECT
  o.*,
  p.name as product_name
FROM orders o
JOIN products p ON p.id = o.product_id
WHERE o.user_id = $1
ORDER BY o.created_at DESC
LIMIT 10;
```

**Expected Impact:** 1,100ms → 80ms

### 3. Implement Caching

Cache user stats (updated hourly):
```typescript
const cacheKey = `user:${userId}:stats`;
let stats = await redis.get(cacheKey);

if (!stats) {
  stats = await getUserStats(userId);
  await redis.setex(cacheKey, 3600, JSON.stringify(stats));
}
```

**Expected Impact:** 1,200ms → 2ms (cache hit)

### 4. Parallelize Queries

Instead of sequential:
```typescript
// ❌ Sequential (3000ms total)
const stats = await getUserStats(userId);       // 1200ms
const orders = await getRecentOrders(userId);   // 1100ms
const feed = await getActivityFeed(userId);     // 500ms
```

Use parallel:
```typescript
// ✅ Parallel (1200ms total = slowest query)
const [stats, orders, feed] = await Promise.all([
  getUserStats(userId),       // 1200ms
  getRecentOrders(userId),    // 1100ms
  getActivityFeed(userId)     // 500ms
]);
```

**Expected Impact:** 2,800ms → 1,200ms (no indexes yet)

## Projected Performance

**Current:**
- getUserStats: 1,200ms
- getRecentOrders: 1,100ms
- getActivityFeed: 500ms
- **Total:** 2,800ms (sequential)

**After Indexes + JOINs:**
- getUserStats: 50ms (indexed)
- getRecentOrders: 80ms (indexed + JOIN)
- getActivityFeed: 30ms (JOIN instead of N+1)
- **Total:** 80ms (parallel) ← Slowest query

**After Caching:**
- getUserStats: 2ms (cache hit, 95% of requests)
- getRecentOrders: 80ms
- getActivityFeed: 30ms
- **Total:** 80ms

**Final:** ~80-100ms (10-15x faster than current)
```

**@performance:**
> ✅ **Analysis complete**
>
> **Bottlenecks:** Database queries (missing indexes, N+1 queries)
> **Recommended fixes:**
> 1. Add 3 indexes (user_id, composite, etc.)
> 2. Replace subqueries with JOINs
> 3. Parallelize queries
> 4. Add Redis caching
>
> **Expected improvement:** 2,847ms → 80ms (35x faster)
>
> Passing to @builder for implementation.

---

### Phase 2: Implementation (@builder)

**User:** @builder Implement the performance optimizations

**@builder:**
> Reading performance report...
>
> **Implementation plan:**
> 1. Database indexes (migration)
> 2. Rewrite queries (JOIN instead of subquery)
> 3. Parallelize queries
> 4. Add Redis caching
>
> **Implementing...**

**File 1:** `migrations/20260216140000_add_dashboard_indexes.sql`

```sql
-- Dashboard Performance Optimization Indexes

BEGIN;

-- Index 1: Orders by user_id (for getUserStats)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_orders_user_id
ON orders(user_id);

-- Index 2: Composite index for recent orders query
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_orders_user_created
ON orders(user_id, created_at DESC);

-- Index 3: Activities by user_id
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_activities_user_id
ON activities(user_id);

COMMIT;

-- Analyze tables to update statistics
ANALYZE orders;
ANALYZE activities;
```

**File 2:** `src/services/dashboard.service.ts` (Optimized)

```typescript
import { pool } from '../database';
import { redis } from '../redis';

/**
 * Get user dashboard data
 * OPTIMIZED: Added indexes, JOINs, parallelization, caching
 */
export async function getDashboardData(userId: string) {
  // Execute all queries in parallel
  const [stats, orders, feed] = await Promise.all([
    getUserStats(userId),
    getRecentOrders(userId),
    getActivityFeed(userId)
  ]);

  return {
    stats,
    recentOrders: orders,
    activityFeed: feed
  };
}

/**
 * Get user statistics
 * OPTIMIZED: Added caching (1 hour TTL)
 */
async function getUserStats(userId: string) {
  // Check cache first
  const cacheKey = `dashboard:stats:${userId}`;
  const cached = await redis.get(cacheKey);

  if (cached) {
    return JSON.parse(cached);
  }

  // Query database (now uses index on user_id)
  const result = await pool.query(
    `SELECT
      COUNT(*) as total_orders,
      COALESCE(SUM(total_cents), 0) as lifetime_value_cents,
      COALESCE(AVG(total_cents), 0) as avg_order_value_cents
    FROM orders
    WHERE user_id = $1`,
    [userId]
  );

  const stats = {
    totalOrders: parseInt(result.rows[0].total_orders),
    lifetimeValue: result.rows[0].lifetime_value_cents / 100,
    avgOrderValue: result.rows[0].avg_order_value_cents / 100
  };

  // Cache for 1 hour
  await redis.setex(cacheKey, 3600, JSON.stringify(stats));

  return stats;
}

/**
 * Get recent orders
 * OPTIMIZED: Use JOIN instead of subquery, use composite index
 */
async function getRecentOrders(userId: string) {
  // Single query with JOIN (was N+1 pattern)
  // Uses composite index on (user_id, created_at)
  const result = await pool.query(
    `SELECT
      o.id,
      o.total_cents,
      o.status,
      o.created_at,
      p.name as product_name,
      p.image_url as product_image
    FROM orders o
    INNER JOIN products p ON p.id = o.product_id
    WHERE o.user_id = $1
    ORDER BY o.created_at DESC
    LIMIT 10`,
    [userId]
  );

  return result.rows.map(row => ({
    id: row.id,
    total: row.total_cents / 100,
    status: row.status,
    createdAt: row.created_at,
    product: {
      name: row.product_name,
      image: row.product_image
    }
  }));
}

/**
 * Get activity feed
 * OPTIMIZED: Single JOIN query instead of N+1
 */
async function getActivityFeed(userId: string) {
  // Single query with JOIN (was 20 separate queries)
  const result = await pool.query(
    `SELECT
      a.id,
      a.type,
      a.description,
      a.created_at,
      u.name as related_user_name,
      u.avatar_url as related_user_avatar
    FROM activities a
    LEFT JOIN users u ON u.id = a.related_user_id
    WHERE a.user_id = $1
    ORDER BY a.created_at DESC
    LIMIT 20`,
    [userId]
  );

  return result.rows.map(row => ({
    id: row.id,
    type: row.type,
    description: row.description,
    createdAt: row.created_at,
    relatedUser: row.related_user_name ? {
      name: row.related_user_name,
      avatar: row.related_user_avatar
    } : null
  }));
}
```

**@builder:**
> ✅ **Optimization implemented**
>
> **Changes:**
> 1. 3 database indexes created
> 2. Queries rewritten (JOINs instead of subqueries)
> 3. Parallel query execution
> 4. Redis caching (1-hour TTL for stats)
>
> Ready for performance testing.

---

### Phase 3: Performance Testing (@tester)

**User:** @tester Benchmark the optimized dashboard endpoint

**@tester:**
> Running performance benchmarks...

**Benchmark 1: Response Time**

```bash
# Before optimization
npx autocannon -c 10 -d 30 http://localhost:3000/api/dashboard

Requests/sec: 3.5
Latency (avg): 2,847ms
Latency (p95): 3,142ms
Latency (p99): 3,456ms

# After optimization
npx autocannon -c 10 -d 30 http://localhost:3000/api/dashboard

Requests/sec: 125.3
Latency (avg): 79ms
Latency (p95): 134ms
Latency (p99): 187ms
```

**Improvement:**
- Average: 2,847ms → 79ms (**36x faster**)
- p95: 3,142ms → 134ms (**23x faster**)
- p99: 3,456ms → 187ms (**18x faster**)
- Throughput: 3.5 → 125.3 req/s (**35x higher**)

**Benchmark 2: Database Query Performance**

```sql
-- Before: getUserStats
EXPLAIN ANALYZE SELECT COUNT(*), SUM(total_cents), AVG(total_cents)
FROM orders WHERE user_id = 123;

-- Result: 1,198ms (Seq Scan)

-- After: getUserStats (with index)
-- Result: 48ms (Index Scan)
-- Improvement: 25x faster

-- Before: getRecentOrders
-- Result: 1,097ms (Seq Scan + Sort + Subquery)

-- After: getRecentOrders (with index + JOIN)
-- Result: 82ms (Index Scan + Nested Loop)
-- Improvement: 13x faster

-- Before: getActivityFeed
-- Result: 500ms (20 queries × 25ms)

-- After: getActivityFeed (single JOIN)
-- Result: 31ms (1 query with JOIN)
-- Improvement: 16x faster
```

**Benchmark 3: Cache Hit Rate**

```
Cache Statistics (after 1 hour):
- Total requests: 12,456
- Cache hits: 11,834 (95%)
- Cache misses: 622 (5%)

Cached response time: 2ms
Uncached response time: 79ms
Average (with cache): 6ms
```

**Output:** `reports/dashboard-performance-test-results.md`

```markdown
# Dashboard Performance Test Results

## Performance Metrics

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| Avg response time | 2,847ms | 79ms | **36x faster** |
| p95 response time | 3,142ms | 134ms | **23x faster** |
| p99 response time | 3,456ms | 187ms | **18x faster** |
| Throughput | 3.5 req/s | 125 req/s | **35x higher** |
| Timeout rate | 2.3% | 0% | **Eliminated** |

## With Cache (95% hit rate)

| Metric | After (cached) |
|--------|----------------|
| Avg response time | 6ms |
| Throughput | 1,200+ req/s |

## Database Query Improvements

| Query | Before | After | Improvement |
|-------|--------|-------|-------------|
| getUserStats | 1,198ms | 48ms | 25x |
| getRecentOrders | 1,097ms | 82ms | 13x |
| getActivityFeed | 500ms | 31ms | 16x |

## Success Criteria

✅ Response time <200ms (achieved: 79ms avg, 187ms p99)
✅ Throughput >50 req/s (achieved: 125 req/s)
✅ Zero timeouts (achieved: 0%)
✅ Cache hit rate >80% (achieved: 95%)

## All performance targets exceeded!
```

**@tester:**
> ✅ **PERFORMANCE TARGETS EXCEEDED**
>
> - Response time: 2,847ms → 79ms (36x faster)
> - Target was <200ms, achieved 79ms
> - With cache: 6ms average
> - Zero timeouts
>
> Ready for production deployment.

---

## Artifacts

1. **reports/dashboard-performance-analysis.md** (Analysis, 320 lines)
2. **migrations/20260216140000_add_dashboard_indexes.sql** (3 indexes)
3. **src/services/dashboard.service.ts** (Optimized, 145 lines)
4. **reports/dashboard-performance-test-results.md** (Benchmark results)

---

## Results Summary

### Performance Improvements

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| Average latency | 2,847ms | 79ms | **36x** |
| Requests/second | 3.5 | 125 | **35x** |
| Timeout rate | 2.3% | 0% | **100%** |
| User bounce rate | 23% | 4% | **82% reduction** |

### Techniques Used

1. **Database Indexing**
   - Added 3 indexes (user_id, composite, activities)
   - Seq Scan → Index Scan
   - 25x faster queries

2. **Query Optimization**
   - Replaced N+1 pattern with JOINs
   - Single query instead of 20
   - 16x faster

3. **Parallelization**
   - Sequential → Parallel execution
   - Promise.all() for independent queries
   - Reduced total time to slowest query

4. **Caching**
   - Redis for user stats (1-hour TTL)
   - 95% cache hit rate
   - 2ms response time for cache hits

---

## Lessons Learned

### What Went Well ✅

1. **Profiling Identified Root Cause**
   - Flamegraph showed database time (93%)
   - EXPLAIN ANALYZE revealed missing indexes
   - Targeted optimization (not premature)

2. **Systematic Optimization**
   - Measured baseline first
   - Applied optimizations incrementally
   - Measured after each change

3. **Multiple Optimization Layers**
   - Database (indexes)
   - Query patterns (JOINs)
   - Application (parallelization)
   - Caching (Redis)

### Key Takeaways 💡

1. **Always Profile First**
   - Don't guess what's slow
   - Use flamegraphs to see time distribution
   - EXPLAIN ANALYZE for SQL queries

2. **Indexes are Low-Hanging Fruit**
   - Seq Scan → Index Scan = 10-100x faster
   - Check EXPLAIN ANALYZE for Seq Scans
   - Add indexes for WHERE and ORDER BY columns

3. **Fix N+1 Query Patterns**
   - 1 + N queries → 1 query (JOIN)
   - Common in ORMs (watch for loops with queries)
   - Can be 10-100x faster

4. **Parallelize Independent Operations**
   - Promise.all() for concurrent queries
   - Reduces total time to slowest operation
   - Easy win with no code changes

5. **Cache Computed Values**
   - User stats don't change every second
   - 1-hour cache = 95% hit rate
   - 40x faster (79ms → 2ms)

6. **Set Performance Budgets**
   - <200ms for dashboard
   - >50 req/s throughput
   - Measurable targets drive optimization

---

## Business Impact

**Before:**
- Dashboard bounce rate: 23%
- User complaints: 45/week
- Conversion drop: 15%

**After:**
- Dashboard bounce rate: 4% (**82% reduction**)
- User complaints: 2/week (**96% reduction**)
- Conversion recovery: 12% (**$50K/month revenue**)

**ROI:** 2 hours of optimization → $600K/year revenue recovery

---

**This example demonstrates:**
- Performance profiling with flamegraphs
- Database query optimization (indexes, JOINs)
- N+1 query pattern elimination
- Query parallelization
- Redis caching strategy
- Systematic benchmarking

**Estimated Time:** ~2 hours with OpenCode vs ~1-2 weeks trial-and-error optimization

---

*Example last updated: 2026-02-16*
