# Load & Concurrency Test Scenarios

## Critical Race Conditions

### 1. Last-Item Stock Race
- **Setup**: Product with `stock = 1`
- **Test**: 100 concurrent doctors attempt to add it to cart and checkout simultaneously
- **Expected**: Exactly 1 order succeeds, 99 get `INSUFFICIENT_STOCK` error
- **Validates**: `SELECT ... FOR UPDATE` row locking on products table

### 2. Simultaneous Checkout Same Cart
- **Setup**: Doctor with 3 items in cart
- **Test**: 10 rapid checkout requests from the same doctor (duplicate clicks / retry storms)
- **Expected**: Exactly 1 order created, others get `EMPTY_CART` error
- **Validates**: Cart row locking prevents double-order

### 3. Discount Code Exhaustion Race
- **Setup**: Discount with `usage_limit = 1`
- **Test**: 50 concurrent checkouts each applying the same discount code
- **Expected**: Exactly 1 order gets the discount, others get `DISCOUNT_EXHAUSTED`
- **Validates**: Discount row locking + `used_count` check under lock

### 4. Per-User Discount Limit Race
- **Setup**: Discount with `per_user_limit = 1`
- **Test**: Same doctor sends 20 concurrent checkout requests with the same discount
- **Expected**: At most 1 order applies the discount
- **Validates**: `discountUsage` count check inside transaction

### 5. Concurrent Cancel + Status Update
- **Setup**: Order in `pending` status
- **Test**: Doctor cancels while admin simultaneously updates to `confirmed`
- **Expected**: Exactly one operation wins; stock restored only if cancelled
- **Validates**: Order row `FOR UPDATE` lock, `isValidTransition` check

### 6. Cancel During Checkout (Stock Restore vs Deduct)
- **Setup**: Product with `stock = 5`, existing order with qty 3
- **Test**: Doctor A cancels their order (restoring 3) while Doctor B checks out buying 4
- **Expected**: Both succeed or fail atomically; final stock is consistent
- **Validates**: Product row locking prevents stock going negative or phantom reads

---

## High Throughput Scenarios

### 7. Burst Login Requests
- **Test**: 500 concurrent login attempts (mix of valid and invalid credentials)
- **Expected**: All valid logins get tokens, invalid get 401, no server crashes
- **Validates**: Auth service handles load, bcrypt doesn't block event loop

### 8. Home Page Storm
- **Test**: 300 concurrent `GET /api/v1/home` requests
- **Expected**: Responses under 500ms p95; Redis cache absorbs repeated reads
- **Validates**: Banner/category/flash-sale caching, no DB connection pool exhaustion

### 9. Product Listing Pagination
- **Test**: 200 concurrent requests to `GET /api/v1/products?page=1&limit=20` with varied filters
- **Expected**: Consistent results, no timeouts
- **Validates**: Composite indexes on `(isActive, createdAt)` and `(categoryId, isActive)`

### 10. Dashboard Stats Under Load
- **Test**: 50 concurrent admin dashboard requests while orders are being created
- **Expected**: Stats eventually consistent (2min cache TTL), no DB deadlocks
- **Validates**: Cache layer, aggregation query performance

### 11. WebSocket Broadcast Storm
- **Test**: 100 connected admin sockets, rapid order status updates on 50 orders
- **Expected**: All clients receive updates, no dropped connections
- **Validates**: Socket.IO broadcast under load

---

## Data Integrity Scenarios

### 12. Order Number Uniqueness
- **Test**: 100 concurrent order creations in the same second
- **Expected**: All order numbers unique (e.g., `MO2603-00001` through `MO2603-00100`)
- **Validates**: `generateOrderNumber` sequential logic under concurrency

### 13. Stock Never Goes Negative
- **Setup**: 10 products with stock between 1-5
- **Test**: 200 concurrent checkouts randomly buying these products
- **Expected**: No product ends with `stock < 0`; `total_sold + stock = original_stock`
- **Validates**: Atomic stock deduction in transaction

### 14. Cart Isolation
- **Test**: 100 different doctors modifying their carts simultaneously
- **Expected**: No cross-contamination; each doctor sees only their items
- **Validates**: `doctor_id` filtering, no shared state leaks

### 15. Concurrent Product Update + Checkout
- **Setup**: Admin editing product price while doctor checks out
- **Test**: Admin changes price from 100 to 200; doctor checks out at the same moment
- **Expected**: Order captures the price that was locked at checkout time
- **Validates**: Product row lock captures consistent snapshot

---

## Stress & Recovery

### 16. Connection Pool Exhaustion
- **Test**: 500 concurrent long-running requests (checkout with artificial delay)
- **Expected**: Pool queues requests; some get timeout errors but server stays alive
- **Validates**: `pool.max` config, 15s transaction timeout

### 17. Redis Down During Request
- **Test**: Kill Redis while 100 requests are in-flight to cached endpoints
- **Expected**: Requests fall through to DB (cache miss path); no 500 errors
- **Validates**: `CacheService.getOrSet` try/catch fallback

### 18. Transaction Timeout
- **Test**: Create artificial lock contention exceeding 15s checkout timeout
- **Expected**: Transaction rolls back cleanly, stock unchanged, cart preserved
- **Validates**: `setLockTimeout` and Prisma `{ timeout: 15000 }`

### 19. Notification Queue Backpressure
- **Test**: Create 500 orders rapidly, flooding the BullMQ notification queue
- **Expected**: All notifications eventually delivered; order creation not blocked
- **Validates**: Queue independence from order transaction

---

## Tools & Execution

### Recommended Tools
- **k6** (`grafana/k6`) — JavaScript-based load testing, ideal for these scenarios
- **Artillery** — YAML-defined load tests with good reporting
- **autocannon** — Simple HTTP benchmarking for throughput tests

### Example k6 Script Structure
```javascript
// k6 run --vus 100 --duration 30s last-item-race.js
import http from 'k6/http';
import { check } from 'k6';

const BASE = 'http://localhost:3000/api/v1';

export default function () {
  // Each VU logs in as a different doctor
  const login = http.post(`${BASE}/auth/login`, JSON.stringify({
    email: `doctor${__VU}@test.com`,
    password: 'Password123',
  }), { headers: { 'Content-Type': 'application/json' } });

  const token = JSON.parse(login.body).data.accessToken;

  // Attempt checkout
  const res = http.post(`${BASE}/orders`, JSON.stringify({
    addressId: ADDRESS_ID,
  }), { headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${token}`,
  }});

  check(res, {
    'got 201 or 400': (r) => [201, 400].includes(r.status),
  });
}
```

### Priority Order
1. Scenarios 1, 3, 12, 13 (data integrity — **must pass**)
2. Scenarios 2, 4, 5, 6, 15 (race conditions — **must pass**)
3. Scenarios 7, 8, 9 (throughput — **should meet SLAs**)
4. Scenarios 16, 17, 18 (resilience — **should degrade gracefully**)
