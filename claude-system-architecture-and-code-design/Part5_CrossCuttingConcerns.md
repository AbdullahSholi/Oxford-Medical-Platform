# MedOrder — System Architecture & Code Design Guidelines

## Tech Stack: Flutter + Node.js + PostgreSQL

---

# PART 5: CROSS-CUTTING CONCERNS

---

## 5.1 Environment Configuration

```bash
# .env.example — All required variables
# ── Server ──────────────────
NODE_ENV=development                # development | staging | production
PORT=3000
API_PREFIX=/api/v1
CORS_ORIGINS=http://localhost:3000,http://localhost:8080

# ── Database ────────────────
DATABASE_URL=postgresql://user:pass@localhost:5432/medorder?schema=public
DATABASE_POOL_MIN=2
DATABASE_POOL_MAX=10

# ── Redis ───────────────────
REDIS_URL=redis://localhost:6379

# ── Auth ────────────────────
JWT_ACCESS_SECRET=<rsa-private-key-path>
JWT_ACCESS_EXPIRY=15m
JWT_REFRESH_EXPIRY=7d
BCRYPT_ROUNDS=12
OTP_EXPIRY_SECONDS=300

# ── Storage ─────────────────
S3_BUCKET=medorder-uploads
S3_REGION=eu-central-1
S3_ACCESS_KEY=
S3_SECRET_KEY=
CDN_BASE_URL=https://cdn.medorder.com

# ── Notifications ───────────
FIREBASE_PROJECT_ID=
FIREBASE_CREDENTIALS_PATH=
TWILIO_SID=
TWILIO_AUTH_TOKEN=
TWILIO_PHONE=
SENDGRID_API_KEY=
EMAIL_FROM=noreply@medorder.com

# ── Rate Limiting ───────────
RATE_LIMIT_WINDOW_MS=60000
RATE_LIMIT_MAX=100
LOGIN_RATE_LIMIT_MAX=5
LOGIN_RATE_LIMIT_WINDOW_MS=900000
```

## 5.2 Error Handling Strategy

```
Flutter App                          Node.js Backend
──────────                          ──────────────
DioException ───┐                   ┌──── AppError (custom)
NetworkError ───┤                   │     ├── ValidationError
TimeoutError ───┤    HTTP 4xx/5xx   │     ├── AuthError
                ├──── ← response ── ┤     ├── NotFoundError
                │                   │     ├── ConflictError
                │                   │     ├── InternalError
                │                   │     ├── LockTimeoutError  ← lock contention
                │                   │     ├── DeadlockError      ← deadlock detected
                │                   │     └── StockRaceError     ← stock changed during tx
                ▼                   │
         Failure class              └──── Global Error Handler
         (domain layer)                   ├── Log full error (Pino)
                │                         ├── Sentry capture
                ▼                         ├── Retry on deadlock (max 3 attempts)
         BLoC State                       └── Send sanitized response
         (ErrorState)
                │
                ▼
         UI Error Widget
         (retry button)
```

## 5.3 Testing Strategy

```
Layer             │ Test Type      │ Tools              │ Coverage Target
──────────────────┼────────────────┼────────────────────┼────────────────
Flutter Widgets   │ Widget Tests   │ flutter_test       │ All pages
Flutter BLoCs     │ Unit Tests     │ bloc_test, mocktail│ 100% of BLoCs
Flutter UseCases  │ Unit Tests     │ mocktail           │ All use cases
Node.js Services  │ Unit Tests     │ Jest, mock repos   │ All services
Node.js Routes    │ Integration    │ Supertest + Jest   │ All endpoints
Node.js E2E       │ E2E Tests      │ Supertest + test DB│ Critical flows
Node.js Concurr.  │ Race Condition │ Jest + parallel tx │ Checkout, cancel, flash sale
Database          │ Migration Tests│ Prisma test utils  │ All migrations
Database Locking  │ Lock Tests     │ pg_advisory_lock   │ All FOR UPDATE queries
```

**Concurrency Test Requirements:**
- Every endpoint using pessimistic locking must have a race condition test that spawns 2+ concurrent requests against the same resource
- Checkout race test: Two doctors purchase the last N units simultaneously → only one succeeds, the other gets `INSUFFICIENT_STOCK`
- Discount race test: N concurrent orders with the same coupon (usage_limit=1) → only one succeeds, others get `DISCOUNT_EXHAUSTED`
- Flash sale race test: 50 concurrent purchases with only 10 units → exactly 10 succeed, 40 get `INSUFFICIENT_STOCK`
- Order cancel race test: Double-cancel same order → first succeeds, second gets `INVALID_STATUS`
- Lock timeout test: Verify that `lock_timeout` correctly aborts long-waiting transactions

## 5.4 Git Workflow & Branch Strategy

```
main (production)
  └── develop (staging)
        ├── feature/auth-registration
        ├── feature/product-catalog
        ├── feature/order-flow
        ├── fix/cart-calculation-bug
        └── hotfix/stock-race-condition (→ main directly)

Branch naming: {type}/{description}
  Types: feature/, fix/, hotfix/, refactor/, chore/

Commit format (Conventional Commits):
  feat(auth): add OTP verification endpoint
  fix(cart): correct bulk pricing calculation for edge case
  refactor(product): extract search service from product service
  chore(deps): update prisma to v5.10
```

## 5.5 Concurrency Error Codes & Handling

These error codes are specific to pessimistic locking and concurrency control. The global error handler must translate PostgreSQL lock errors into user-friendly API responses.

```typescript
// Error code mapping for lock-related failures:

// PostgreSQL error codes to catch:
//   55P03 → lock_not_available    (FOR UPDATE NOWAIT failed)
//   40P01 → deadlock_detected      (two transactions deadlocked)
//   57014 → query_cancelled         (statement_timeout exceeded)

// Application error codes:
LOCK_TIMEOUT          → 409  // Lock contention — retry after brief delay
DEADLOCK_DETECTED     → 409  // Deadlock — auto-retry up to 3 times
INSUFFICIENT_STOCK    → 422  // Stock was claimed by another transaction
DISCOUNT_EXHAUSTED    → 410  // Discount used_count reached limit
FLASH_SALE_ENDED      → 410  // Flash sale expired or sold out
INVALID_TRANSITION    → 400  // Order status transition blocked by lock check
CONCURRENT_CHECKOUT   → 409  // Same doctor already has checkout in progress
```

```typescript
// Global error handler — catch PostgreSQL lock errors:
function handleDatabaseError(error: unknown): AppError {
  if (error instanceof Prisma.PrismaClientKnownRequestError) {
    // Prisma wraps PostgreSQL errors
    const pgCode = (error.meta as any)?.code;

    if (pgCode === '55P03') {
      // NOWAIT lock failed — flash sale contention
      return new AppError('LOCK_TIMEOUT', 'Resource is temporarily busy, please retry', 409);
    }
    if (pgCode === '40P01') {
      // Deadlock — should be auto-retried before reaching here
      return new AppError('DEADLOCK_DETECTED', 'Transaction conflict, please retry', 409);
    }
  }
  // ... other error handling
}

// Auto-retry wrapper for deadlock-prone operations:
async function withDeadlockRetry<T>(
  operation: () => Promise<T>,
  maxRetries = 3,
): Promise<T> {
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await operation();
    } catch (error) {
      const isDeadlock = (error as any)?.meta?.code === '40P01';
      if (isDeadlock && attempt < maxRetries) {
        // Exponential backoff: 50ms, 100ms, 200ms
        await sleep(50 * Math.pow(2, attempt - 1));
        continue;
      }
      throw error;
    }
  }
  throw new Error('Unreachable');
}
```

---

This document serves as the architectural blueprint for building MedOrder. Follow these guidelines strictly to ensure the codebase remains maintainable, scalable, and production-ready as the platform grows from MVP to a full-scale B2B medical marketplace.
