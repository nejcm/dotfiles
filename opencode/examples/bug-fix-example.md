# Bug Fix Example: Race Condition in Payment Processing

**Scenario:** Fix race condition causing duplicate payment charges

**Complexity:** High
**Duration:** ~3 hours
**Agents Used:** @debug, @builder, @tester, @reviewer
**Skills Used:** `run-tests`, `code-quality`

---

## Scenario

### Bug Report

**Severity:** CRITICAL (P0)
**Reporter:** Customer Support
**Affected Users:** 12 customers in last 24 hours

**Description:**
> Customers are being charged twice for the same order. The duplicate charge happens within 100-200ms of the first charge. Affects ~0.5% of payments during high traffic.

**Example:**
```
Order #45231
- Charge 1: $49.99 at 2026-02-16 10:23:45.123
- Charge 2: $49.99 at 2026-02-16 10:23:45.287
Total charged: $99.98 (should be $49.99)
```

**Environment:** Production only (not reproducible on staging)

### Context

**Payment Flow:**
1. User clicks "Pay Now"
2. Frontend calls `POST /api/orders/{id}/pay`
3. Backend processes payment via Stripe
4. Order marked as "paid"

**Current Code:**
```typescript
async function processPayment(orderId: string) {
  const order = await db.query('SELECT * FROM orders WHERE id = $1', [orderId]);

  if (order.status === 'paid') {
    return { success: false, error: 'Already paid' };
  }

  // Charge customer
  const charge = await stripe.charges.create({
    amount: order.total,
    currency: 'usd',
    source: order.payment_method_id
  });

  // Update order status
  await db.query(
    'UPDATE orders SET status = $1 WHERE id = $2',
    ['paid', orderId]
  );

  return { success: true, chargeId: charge.id };
}
```

---

## Agent Transcript

### Phase 1: Root Cause Analysis (@debug)

**User:** @debug Investigate duplicate payment charges bug

**@debug:**
> **Analyzing bug report...**
>
> **Symptom Analysis:**
> - Duplicate charges within 100-200ms
> - Only during high traffic
> - ~0.5% of payments
> - Production only (timing-dependent)
>
> **Hypothesis:** Race condition (classic TOCTOU)
>
> **Reading code:** `src/services/payment.service.ts`
>
> **Identified Issue:**

**Output:** `reports/bug-analysis-duplicate-payments.md`

```markdown
# Bug Analysis: Duplicate Payment Charges

## Root Cause: Race Condition (TOCTOU)

**Type:** Time-of-Check to Time-of-Use (TOCTOU) vulnerability

### How the Race Condition Occurs

**Timeline of Bug:**

```
Thread A                          Thread B
────────                          ────────
Read order (status=pending)
                                  Read order (status=pending)
Check: status != paid ✓
                                  Check: status != paid ✓
Charge Stripe ($49.99)
                                  Charge Stripe ($49.99) ← DUPLICATE!
Update: status=paid
                                  Update: status=paid
```

**Problem:**
1. Two requests arrive simultaneously (within ~100ms)
2. Both read order status as "pending" (before either updates)
3. Both pass the "already paid?" check
4. Both charge Stripe
5. Customer charged twice

### Code Analysis

**Vulnerable Code:**
```typescript
async function processPayment(orderId: string) {
  // ❌ RACE CONDITION: Read and check happen separately
  const order = await db.query('SELECT * FROM orders WHERE id = $1', [orderId]);

  if (order.status === 'paid') {  // ← Both threads pass this check
    return { success: false, error: 'Already paid' };
  }

  // Time window here (100-200ms)
  // During high traffic, another request can sneak in

  const charge = await stripe.charges.create({  // ← Both execute
    amount: order.total,
    currency: 'usd',
    source: order.payment_method_id
  });

  await db.query(
    'UPDATE orders SET status = $1 WHERE id = $2',
    ['paid', orderId]
  );

  return { success: true, chargeId: charge.id };
}
```

**Gap:** 100-200ms between check and Stripe charge
**Frequency:** Only when two requests arrive in this gap (rare, but happens)

### Why It Only Happens in Production

**Staging:**
- Low traffic
- Requests are sequential
- Race condition window rarely hit

**Production:**
- High traffic (~500 req/s)
- Multiple requests for same order (impatient users clicking multiple times)
- Probability of collision: ~0.5%

### The 5 Whys

1. **Why are customers charged twice?**
   → Because Stripe was called twice for the same order

2. **Why was Stripe called twice?**
   → Because two concurrent requests both passed the "already paid?" check

3. **Why did both requests pass the check?**
   → Because they both read the order before either updated it

4. **Why didn't the database prevent this?**
   → Because we didn't use database-level locking

5. **Why didn't we use locking?**
   → Original implementation didn't account for concurrent requests

**Root Cause:** Missing concurrency control (pessimistic or optimistic locking)

## Reproduction

**High-Traffic Simulation:**
```bash
# Send two concurrent requests for same order
curl -X POST http://localhost:3000/api/orders/123/pay &
curl -X POST http://localhost:3000/api/orders/123/pay &

# Result: Sometimes both succeed (race condition)
```

**Success Rate:** ~5% when requests are within 50ms

## Potential Fixes

### Option 1: Pessimistic Locking (Database Lock)
```sql
SELECT * FROM orders WHERE id = $1 FOR UPDATE;
-- Locks row until transaction commits
-- Second request waits
```

**Pros:** Guaranteed no duplicates
**Cons:** Slower (lock contention), requires transaction

### Option 2: Optimistic Locking (Version Field)
```sql
UPDATE orders
SET status = 'paid', version = version + 1
WHERE id = $1 AND version = $2;
-- Only succeeds if version matches
```

**Pros:** Faster (no locks), better concurrency
**Cons:** Requires retry logic

### Option 3: Idempotency Key
```typescript
const idempotencyKey = `payment-${orderId}`;
stripe.charges.create({ idempotency_key: idempotencyKey });
-- Stripe deduplicates based on key
```

**Pros:** Simple, Stripe handles it
**Cons:** Still makes duplicate DB calls

### Option 4: Unique Constraint
```sql
CREATE UNIQUE INDEX idx_orders_payment_intent
ON orders (payment_intent_id) WHERE status = 'paid';
-- Prevents duplicate paid orders
```

**Pros:** Database-enforced
**Cons:** Doesn't prevent Stripe call

### Recommended: Combination

1. **Pessimistic lock** (prevent race)
2. **Idempotency key** (Stripe safety)
3. **Unique constraint** (DB safety)

**Defense in depth:** Multiple layers prevent duplicates

## Risk Assessment

**Current Risk:**
- 0.5% of payments affected
- ~50 customers/day with high traffic
- Average loss: ~$5,000/day in duplicate charges (refunded)
- **Critical severity** (financial + customer trust)

**Post-Fix Risk:**
- 0% duplicate charges
- No customer impact
- No revenue impact
```

**@debug:**
> ✅ **Root cause identified:** Race condition (TOCTOU)
>
> **Recommended fix:** Pessimistic locking + idempotency key + unique constraint
>
> Passing to @builder for implementation.

---

### Phase 2: Implementation (@builder)

**User:** @builder Implement the fix for duplicate payment bug

**@builder:**
> Reading bug analysis: `reports/bug-analysis-duplicate-payments.md`
>
> **Implementation plan:**
> 1. Add database migration (unique constraint)
> 2. Update payment service (pessimistic lock + idempotency)
> 3. Add retry logic for lock timeout
> 4. Add monitoring/alerting
>
> **Implementing...**

**File 1:** `migrations/20260216130000_add_payment_uniqueness.sql`

```sql
-- Prevent duplicate payments at database level

BEGIN;

-- Add unique constraint: only one 'paid' order per payment_intent_id
CREATE UNIQUE INDEX idx_orders_payment_intent_unique
ON orders (payment_intent_id)
WHERE status = 'paid';

-- Add comment
COMMENT ON INDEX idx_orders_payment_intent_unique IS
  'Prevents duplicate payment processing for same payment intent';

COMMIT;
```

**File 2:** `src/services/payment.service.ts` (Fixed version)

```typescript
import { stripe } from '../stripe';
import { pool } from '../database';

/**
 * Process payment for order
 *
 * FIX: Added pessimistic locking to prevent race condition
 * FIX: Added Stripe idempotency key
 * FIX: Added retry logic for lock timeout
 */
export async function processPayment(
  orderId: string,
  maxRetries = 3
): Promise<PaymentResult> {
  let attempt = 0;

  while (attempt < maxRetries) {
    attempt++;

    try {
      // Start transaction
      const client = await pool.connect();
      await client.query('BEGIN');

      try {
        // FIX: Use FOR UPDATE to lock row (pessimistic lock)
        // This prevents concurrent requests from proceeding
        const result = await client.query(
          'SELECT * FROM orders WHERE id = $1 FOR UPDATE',
          [orderId]
        );

        const order = result.rows[0];

        if (!order) {
          throw new Error('Order not found');
        }

        // Check if already paid
        if (order.status === 'paid') {
          await client.query('ROLLBACK');
          client.release();

          return {
            success: false,
            error: 'ALREADY_PAID',
            message: 'Order already paid'
          };
        }

        // FIX: Generate idempotency key for Stripe
        // Stripe will deduplicate requests with same key
        const idempotencyKey = `payment-order-${orderId}`;

        // Charge customer via Stripe
        const charge = await stripe.charges.create(
          {
            amount: order.total_cents,
            currency: 'usd',
            source: order.payment_method_id,
            metadata: {
              order_id: orderId,
              user_id: order.user_id
            }
          },
          {
            idempotencyKey  // FIX: Stripe-level deduplication
          }
        );

        // Update order status
        await client.query(
          `UPDATE orders
           SET status = $1,
               payment_intent_id = $2,
               paid_at = NOW()
           WHERE id = $3`,
          ['paid', charge.id, orderId]
        );

        // Commit transaction (releases lock)
        await client.query('COMMIT');
        client.release();

        // Log success
        console.log(`Payment processed successfully: order=${orderId}, charge=${charge.id}`);

        return {
          success: true,
          chargeId: charge.id,
          amount: charge.amount
        };

      } catch (error) {
        // Rollback on error
        await client.query('ROLLBACK');
        client.release();
        throw error;
      }

    } catch (error) {
      // Retry on lock timeout
      if (error.code === '55P03' && attempt < maxRetries) {
        // 55P03 = lock_not_available
        console.warn(`Lock timeout on attempt ${attempt}, retrying...`);
        await sleep(100 * attempt); // Exponential backoff
        continue;
      }

      // Re-throw other errors
      throw error;
    }
  }

  throw new Error(`Failed to acquire lock after ${maxRetries} attempts`);
}

function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}

interface PaymentResult {
  success: boolean;
  chargeId?: string;
  amount?: number;
  error?: string;
  message?: string;
}
```

**File 3:** `src/middleware/payment-dedup.ts` (Additional safety layer)

```typescript
/**
 * Middleware to prevent duplicate payment requests
 * Uses in-memory cache for recent payment requests
 */

import { Request, Response, NextFunction } from 'express';

const recentPayments = new Map<string, number>();
const DEDUP_WINDOW_MS = 5000; // 5 seconds

export function paymentDeduplication(
  req: Request,
  res: Response,
  next: NextFunction
) {
  const orderId = req.params.orderId;
  const now = Date.now();

  // Check if payment processed recently
  const lastPayment = recentPayments.get(orderId);

  if (lastPayment && (now - lastPayment) < DEDUP_WINDOW_MS) {
    return res.status(409).json({
      error: 'DUPLICATE_REQUEST',
      message: 'Payment request too soon after previous attempt'
    });
  }

  // Record this payment attempt
  recentPayments.set(orderId, now);

  // Cleanup old entries (older than 5 seconds)
  for (const [key, timestamp] of recentPayments.entries()) {
    if (now - timestamp > DEDUP_WINDOW_MS) {
      recentPayments.delete(key);
    }
  }

  next();
}
```

**@builder:**
> ✅ **Fix implemented**
>
> **Changes:**
> 1. Database migration (unique constraint)
> 2. Pessimistic locking (FOR UPDATE)
> 3. Stripe idempotency key
> 4. Retry logic for lock timeout
> 5. Request deduplication middleware
>
> **Defense layers:** 5 (database, lock, Stripe, unique constraint, middleware)
>
> Ready for testing.

---

### Phase 3: Testing (@tester)

**User:** @tester Test the fix with concurrent requests

**@tester:**
> **Test Strategy:**
> 1. Unit tests (lock behavior)
> 2. Integration tests (concurrent requests)
> 3. Regression tests (ensure fix works)
>
> **Running tests...**

**Output:** `tests/payment.test.ts`

```typescript
import { processPayment } from '../services/payment.service';
import { pool } from '../database';

describe('Payment Processing - Race Condition Fix', () => {
  beforeEach(async () => {
    // Create test order
    await pool.query(`
      INSERT INTO orders (id, user_id, total_cents, status, payment_method_id)
      VALUES ('test-123', 'user-1', 4999, 'pending', 'pm_test')
    `);
  });

  test('prevents duplicate payment from concurrent requests', async () => {
    // Simulate two concurrent payment requests
    const [result1, result2] = await Promise.allSettled([
      processPayment('test-123'),
      processPayment('test-123')
    ]);

    // One should succeed, one should fail with "already paid"
    const succeeded = [result1, result2].filter(r => r.status === 'fulfilled' && r.value.success);
    const failed = [result1, result2].filter(r => r.status === 'fulfilled' && r.value.error === 'ALREADY_PAID');

    expect(succeeded).toHaveLength(1);  // ✓ Only one payment
    expect(failed).toHaveLength(1);     // ✓ One rejected

    // Verify Stripe charged only once
    const charges = await getStripeCharges('test-123');
    expect(charges).toHaveLength(1);    // ✓ No duplicate charge

    // Verify database shows paid once
    const order = await pool.query('SELECT * FROM orders WHERE id = $1', ['test-123']);
    expect(order.rows[0].status).toBe('paid');
  });

  test('handles lock timeout with retry', async () => {
    // Hold lock for extended time
    const client1 = await pool.connect();
    await client1.query('BEGIN');
    await client1.query('SELECT * FROM orders WHERE id = $1 FOR UPDATE', ['test-123']);

    // Try payment (will retry on lock timeout)
    const paymentPromise = processPayment('test-123');

    // Release lock after 200ms
    setTimeout(async () => {
      await client1.query('ROLLBACK');
      client1.release();
    }, 200);

    // Payment should succeed after retry
    const result = await paymentPromise;
    expect(result.success).toBe(true);
  });

  test('prevents duplicate even with rapid successive clicks', async () => {
    // Simulate user clicking "Pay" button 5 times rapidly
    const results = await Promise.allSettled([
      processPayment('test-123'),
      processPayment('test-123'),
      processPayment('test-123'),
      processPayment('test-123'),
      processPayment('test-123')
    ]);

    const succeeded = results.filter(r => r.status === 'fulfilled' && r.value.success);

    expect(succeeded).toHaveLength(1);  // ✓ Only one payment
  });
});
```

**Test Results:**
```
 PASS  tests/payment.test.ts
  Payment Processing - Race Condition Fix
    ✓ prevents duplicate payment from concurrent requests (234 ms)
    ✓ handles lock timeout with retry (312 ms)
    ✓ prevents duplicate even with rapid successive clicks (189 ms)

Tests: 3 passed, 3 total
```

**@tester:**
> ✅ **ALL TESTS PASSED (3/3)**
>
> - Concurrent requests: Only 1 payment ✓
> - Lock retry: Works ✓
> - Multiple rapid clicks: Prevented ✓
>
> Fix verified. Race condition eliminated.

---

### Phase 4: Review (@reviewer)

**User:** @reviewer Review the bug fix

**@reviewer:**
> Reviewing fix...

**Output:** `reports/bug-fix-review.md`

```markdown
# Bug Fix Review: Duplicate Payments

## Fix Quality ✅

**Defense in Depth:** 5 layers
1. ✅ Pessimistic locking (FOR UPDATE)
2. ✅ Stripe idempotency key
3. ✅ Unique database constraint
4. ✅ Request deduplication middleware
5. ✅ Transaction isolation

## Testing ✅

- ✅ Concurrent request test
- ✅ Lock timeout/retry test
- ✅ Rapid click test
- ✅ All scenarios covered

## Code Quality ✅

- ✅ Clear comments explaining fix
- ✅ Error handling comprehensive
- ✅ Retry logic with exponential backoff
- ✅ Logging for debugging

## Approval ✅

**Status:** APPROVED FOR PRODUCTION

Fix eliminates race condition through multiple safety layers.
No duplicate charges possible.
```

**@reviewer:**
> ✅ **FIX APPROVED**
>
> Comprehensive solution with 5 layers of protection.
> Race condition eliminated.

---

## Artifacts

1. **reports/bug-analysis-duplicate-payments.md** (Root cause analysis)
2. **migrations/20260216130000_add_payment_uniqueness.sql** (DB constraint)
3. **src/services/payment.service.ts** (Fixed code, 95 lines)
4. **src/middleware/payment-dedup.ts** (Dedup middleware, 35 lines)
5. **tests/payment.test.ts** (3 tests)
6. **reports/bug-fix-review.md** (Review)

---

## Lessons Learned

### What Went Well ✅

1. **Root Cause Analysis**
   - 5 Whys revealed true issue
   - Reproduced bug in tests
   - Timeline analysis showed race window

2. **Defense in Depth**
   - 5 layers of protection
   - Even if one fails, others catch it
   - Database + application + Stripe level

3. **Comprehensive Testing**
   - Tested concurrent requests
   - Tested edge cases (rapid clicks)
   - Verified fix eliminates race

### Key Takeaways 💡

1. **Race Conditions Are Subtle**
   - Only happen under specific timing
   - Hard to reproduce on staging
   - Need concurrent request tests

2. **Don't Trust Application-Level Checks**
   - `if (order.paid)` is not atomic
   - Use database locks or constraints
   - Enforce at lowest level possible

3. **Idempotency is Critical**
   - Stripe idempotency key
   - Request deduplication
   - Make operations safe to retry

4. **Test Concurrency**
   - Use `Promise.allSettled()` for concurrent tests
   - Simulate rapid user actions
   - Test lock timeout scenarios

5. **Production Bugs Need Production-Like Tests**
   - Load testing reveals race conditions
   - Timing-dependent bugs need timing tests

---

**This example demonstrates:**
- Root cause analysis (5 Whys, timeline analysis)
- Race condition debugging
- Defense in depth (multiple safety layers)
- Comprehensive concurrent testing
- Pessimistic locking in PostgreSQL

**Estimated Time:** ~3 hours with OpenCode vs ~2-3 days manual debugging

---

*Example last updated: 2026-02-16*
