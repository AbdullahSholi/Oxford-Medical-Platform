# MedOrder — System Architecture & Code Design Guidelines

## Tech Stack: Flutter + Node.js + PostgreSQL

---

# PART 1: SYSTEM ARCHITECTURE

---

## 1.1 High-Level Architecture Overview

MedOrder follows a **Clean Layered Architecture** with clear separation of concerns across all three tiers: mobile client, backend API, and database. The system is designed for scalability, maintainability, and security — critical for a medical supply B2B platform handling sensitive professional data.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          CLIENT TIER                                    │
│                                                                         │
│   ┌──────────────────────┐         ┌──────────────────────────┐        │
│   │   Flutter Mobile App  │         │   Admin Dashboard (Web)   │        │
│   │   (Doctor / Clinic)   │         │   (React / Next.js)       │        │
│   └──────────┬───────────┘         └────────────┬─────────────┘        │
│              │                                   │                      │
└──────────────┼───────────────────────────────────┼──────────────────────┘
               │              HTTPS/TLS            │
               ▼                                   ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                        API GATEWAY / LOAD BALANCER                      │
│                     (Nginx / AWS ALB / Traefik)                         │
│                   Rate Limiting · SSL Termination                       │
└──────────────────────────────┬──────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         BACKEND TIER (Node.js)                          │
│                                                                         │
│   ┌───────────────────────────────────────────────────────────────┐    │
│   │                     Express / Fastify Server                   │    │
│   │                                                                │    │
│   │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────┐  │    │
│   │  │   Auth    │  │ Product  │  │  Order   │  │    Admin     │  │    │
│   │  │  Module   │  │  Module  │  │  Module  │  │   Module     │  │    │
│   │  └──────────┘  └──────────┘  └──────────┘  └──────────────┘  │    │
│   │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────┐  │    │
│   │  │  Review   │  │ Discount │  │  Flash   │  │ Notification │  │    │
│   │  │  Module   │  │  Module  │  │  Sale    │  │   Module     │  │    │
│   │  └──────────┘  └──────────┘  └──────────┘  └──────────────┘  │    │
│   │                                                                │    │
│   │  ── Middleware Layer ──────────────────────────────────────    │    │
│   │  Auth · Validation · Error Handling · Logging · Rate Limit    │    │
│   │                                                                │    │
│   │  ── Service Layer ────────────────────────────────────────    │    │
│   │  Business Logic · Data Transformation · External Services     │    │
│   │                                                                │    │
│   │  ── Data Access Layer ────────────────────────────────────    │    │
│   │  Prisma ORM / Knex.js · Query Builders · Repositories        │    │
│   └───────────────────────────────────────────────────────────────┘    │
│                                                                         │
└────────────┬──────────────────┬──────────────────┬──────────────────────┘
             │                  │                  │
             ▼                  ▼                  ▼
┌────────────────────┐ ┌──────────────┐ ┌─────────────────────┐
│    PostgreSQL       │ │    Redis      │ │   Object Storage    │
│    (Primary DB)     │ │  (Cache +     │ │   (AWS S3 / MinIO)  │
│                     │ │   Sessions)   │ │   Product Images    │
│  Users · Products   │ │              │ │   Licenses · Docs   │
│  Orders · Reviews   │ │  OTP Codes   │ │   Banners           │
│  Categories · etc.  │ │  Flash Sales │ │                     │
└────────────────────┘ └──────────────┘ └─────────────────────┘
```

## 1.2 Architecture Pattern: Modular Monolith (Phase 1) → Microservices (Phase 2)

Start with a **Modular Monolith**: a single deployable Node.js application internally organized into independent, loosely-coupled modules. Each module owns its routes, controllers, services, and repositories. This approach gives you the organizational benefits of microservices without the operational overhead — ideal for an MVP.

**Module Boundaries:**

```
src/
├── modules/
│   ├── auth/           → Registration, login, OTP, token management
│   ├── doctor/         → Doctor profiles, verification, addresses
│   ├── product/        → Catalog, search, filtering, stock
│   ├── category/       → Category tree, subcategories
│   ├── cart/           → Cart operations, pricing calculations
│   ├── order/          → Order lifecycle, status management
│   ├── review/         → Ratings, reviews, moderation
│   ├── discount/       → Coupons, bulk pricing rules
│   ├── flash-sale/     → Time-bound promotions
│   ├── notification/   → Push, SMS, email dispatch
│   ├── upload/         → File handling, image processing
│   ├── banner/         → Promotional banners/sliders
│   └── admin/          → Admin-specific operations, dashboard aggregation
```

**Rule:** Modules communicate only through their public service interfaces — never by directly accessing another module's database queries or internal functions.

## 1.3 Communication Patterns

```
Mobile App  ←──  REST API (JSON)  ──→  Node.js Backend
                                              │
                 WebSocket (Socket.io)  ──────┤  (Order tracking, live notifications)
                                              │
                 Background Jobs  ────────────┤  (Bull/BullMQ + Redis)
                                              │   - Email sending
                                              │   - Push notifications
                                              │   - Image processing
                                              │   - Flash sale scheduling
                                              │   - Report generation
```

## 1.4 API Design Standard: RESTful with Versioning

All APIs follow REST conventions with `/api/v1/` prefix:

```
Authentication:
  POST   /api/v1/auth/register
  POST   /api/v1/auth/login
  POST   /api/v1/auth/otp/send
  POST   /api/v1/auth/otp/verify
  POST   /api/v1/auth/password/reset
  POST   /api/v1/auth/refresh-token

Doctors:
  GET    /api/v1/doctors/me
  PATCH  /api/v1/doctors/me
  GET    /api/v1/doctors/me/addresses
  POST   /api/v1/doctors/me/addresses
  PATCH  /api/v1/doctors/me/addresses/:id
  DELETE /api/v1/doctors/me/addresses/:id

Products:
  GET    /api/v1/products                    ?category=&brand=&minPrice=&maxPrice=&sort=&page=&limit=
  GET    /api/v1/products/:id
  GET    /api/v1/products/:id/reviews
  GET    /api/v1/products/search             ?q=&filters=
  GET    /api/v1/products/flash-sales/active

Categories:
  GET    /api/v1/categories
  GET    /api/v1/categories/:id/products

Cart:
  GET    /api/v1/cart
  POST   /api/v1/cart/items
  PATCH  /api/v1/cart/items/:productId
  DELETE /api/v1/cart/items/:productId
  DELETE /api/v1/cart                         (clear cart)

Orders:
  POST   /api/v1/orders
  GET    /api/v1/orders
  GET    /api/v1/orders/:id
  POST   /api/v1/orders/:id/cancel
  POST   /api/v1/orders/:id/reorder
  GET    /api/v1/orders/:id/tracking

Reviews:
  POST   /api/v1/reviews
  PATCH  /api/v1/reviews/:id
  DELETE /api/v1/reviews/:id

Wishlist:
  GET    /api/v1/wishlist
  POST   /api/v1/wishlist/:productId
  DELETE /api/v1/wishlist/:productId

Notifications:
  GET    /api/v1/notifications
  PATCH  /api/v1/notifications/:id/read
  POST   /api/v1/notifications/read-all

Banners:
  GET    /api/v1/banners                     ?position=home_slider

Admin (prefixed):
  GET    /api/v1/admin/dashboard/stats
  GET    /api/v1/admin/doctors                ?status=pending
  PATCH  /api/v1/admin/doctors/:id/approve
  PATCH  /api/v1/admin/doctors/:id/reject
  CRUD   /api/v1/admin/products
  CRUD   /api/v1/admin/categories
  CRUD   /api/v1/admin/orders
  CRUD   /api/v1/admin/discounts
  CRUD   /api/v1/admin/flash-sales
  CRUD   /api/v1/admin/banners
  GET    /api/v1/admin/reports/revenue
  GET    /api/v1/admin/reports/products
  GET    /api/v1/admin/reports/doctors
```

## 1.5 Authentication & Security Architecture

```
┌──────────────┐      ┌─────────────────────────────────────────────┐
│  Flutter App  │      │              Node.js Backend                 │
│               │      │                                              │
│  Login ───────┼─────→│  POST /auth/login                           │
│               │      │    ├─ Validate credentials                   │
│               │      │    ├─ Check doctor.status === 'approved'     │
│               │      │    ├─ Generate Access Token (JWT, 15min)     │
│               │      │    ├─ Generate Refresh Token (JWT, 7 days)   │
│               │      │    ├─ Store refresh token hash in DB         │
│               │      │    └─ Return { accessToken, refreshToken }   │
│               │      │                                              │
│  API Call ────┼─────→│  Authorization: Bearer <accessToken>        │
│               │      │    ├─ Verify JWT signature                   │
│               │      │    ├─ Check token expiry                     │
│               │      │    ├─ Extract doctorId + role                │
│               │      │    └─ Attach to req.user                     │
│               │      │                                              │
│  Refresh ─────┼─────→│  POST /auth/refresh-token                   │
│               │      │    ├─ Verify refresh token                   │
│               │      │    ├─ Check against stored hash              │
│               │      │    ├─ Rotate: new access + refresh tokens    │
│               │      │    └─ Invalidate old refresh token           │
└──────────────┘      └─────────────────────────────────────────────┘
```

**Security layers:**
- JWT with RS256 (asymmetric keys) — public key on client, private key on server
- Refresh token rotation with family detection (if a used refresh token is reused, invalidate all tokens for that user — potential theft detected)
- Bcrypt for password hashing (cost factor 12)
- OTP codes: 6 digits, stored hashed in Redis with 5-minute TTL, max 3 attempts
- Rate limiting: 5 login attempts per 15 minutes per IP, 100 API requests per minute per user
- Helmet.js for HTTP security headers
- CORS restricted to known origins
- Input sanitization on every endpoint
- File upload validation: MIME type + magic bytes check, max 5MB, images only for products

## 1.6 Caching Strategy

```
Redis Cache Layers:

Layer 1 — Session & Auth (TTL: varies)
  ├── otp:{phone}              → hashed OTP code (TTL: 5min)
  ├── refresh:{userId}         → refresh token hash (TTL: 7d)
  └── blacklist:{tokenJti}     → revoked access tokens (TTL: 15min)

Layer 2 — Application Cache (TTL: 5–60 min)
  ├── categories:tree          → full category hierarchy (TTL: 60min)
  ├── products:featured        → home page products (TTL: 15min)
  ├── products:flash-sale      → active flash sale data (TTL: 1min)
  ├── product:{id}             → individual product detail (TTL: 30min)
  ├── banners:home             → home page banners (TTL: 60min)
  └── search:{queryHash}       → search results (TTL: 10min)

Layer 3 — Counters & Real-time
  ├── stock:{productId}        → real-time stock count
  ├── flash-sale:{id}:stock    → flash sale remaining stock
  └── cart:{userId}            → cart data (TTL: 7d)

Cache Invalidation Strategy:
  - Write-through: Update cache immediately on DB write
  - Event-based: Publish invalidation events when admin updates products/categories
  - TTL-based: All cache entries have explicit TTL as safety net
```

## 1.7 Background Job Queue Architecture

```
BullMQ (Redis-backed) Job Queues:

Queue: notifications
  ├── Job: send-push          → Firebase Cloud Messaging
  ├── Job: send-sms           → Twilio / local SMS gateway
  └── Job: send-email         → SendGrid / Nodemailer

Queue: orders
  ├── Job: process-new-order  → Stock reservation, confirmation
  ├── Job: cancel-expired     → Auto-cancel unpaid orders after 24h
  └── Job: generate-invoice   → PDF invoice generation

Queue: media
  ├── Job: process-image      → Resize, compress, generate thumbnails
  └── Job: process-license    → Store doctor license securely

Queue: flash-sales
  ├── Job: activate-sale      → Scheduled activation
  ├── Job: deactivate-sale    → Scheduled deactivation
  └── Job: restore-stock      → Return unsold flash sale stock

Queue: reports
  └── Job: generate-report    → CSV/PDF export for admin
```

## 1.8 Deployment Architecture

```
Production Environment:

┌─────────────────────────────────────────────────────┐
│                    Cloud Provider                     │
│                (AWS / GCP / DigitalOcean)             │
│                                                       │
│  ┌───────────────┐                                   │
│  │  CDN (images,  │                                   │
│  │  static assets)│                                   │
│  └───────┬───────┘                                   │
│          │                                            │
│  ┌───────▼────────────────────────────────┐          │
│  │         Load Balancer (Nginx/ALB)       │          │
│  │     SSL Termination · Rate Limiting     │          │
│  └───────┬────────────────┬───────────────┘          │
│          │                │                           │
│  ┌───────▼──────┐ ┌──────▼───────┐                   │
│  │  Node.js #1   │ │  Node.js #2   │  (PM2 cluster   │
│  │  (API Server) │ │  (API Server) │   or Docker)     │
│  └───────┬──────┘ └──────┬───────┘                   │
│          │                │                           │
│  ┌───────▼────────────────▼───────────────┐          │
│  │                                         │          │
│  │  ┌─────────────┐  ┌─────────────────┐  │          │
│  │  │ PostgreSQL   │  │     Redis       │  │          │
│  │  │ (Primary +   │  │  (Cache + Jobs  │  │          │
│  │  │  Read Replica)│  │   + Sessions)   │  │          │
│  │  └─────────────┘  └─────────────────┘  │          │
│  │                                         │          │
│  │  ┌─────────────────────────────────┐   │          │
│  │  │  Object Storage (S3 / Spaces)    │   │          │
│  │  │  Product images, licenses, docs  │   │          │
│  │  └─────────────────────────────────┘   │          │
│  └─────────────────────────────────────────┘          │
│                                                       │
│  ┌─────────────────────────────────────────┐          │
│  │  Worker Process (BullMQ)                 │          │
│  │  Notifications · Image Processing · Jobs │          │
│  └─────────────────────────────────────────┘          │
│                                                       │
│  ┌─────────────────────────────────────────┐          │
│  │  Monitoring: Prometheus + Grafana        │          │
│  │  Logging: Pino → ELK / CloudWatch        │          │
│  │  APM: Sentry for error tracking          │          │
│  └─────────────────────────────────────────┘          │
└─────────────────────────────────────────────────────┘
```

## 1.9 Concurrency Control & Pessimistic Locking Strategy

MedOrder operates in a concurrent environment (multiple Node.js instances, multiple doctors checking out simultaneously). **Pessimistic locking** (`SELECT ... FOR UPDATE`) is the primary strategy to prevent race conditions, especially during write-intensive operations that involve checking-then-modifying shared mutable state.

### Why Pessimistic Over Optimistic?

In a medical supply platform, overselling or double-applying a discount is unacceptable. Pessimistic locking guarantees correctness at the cost of slightly higher latency — a worthwhile trade-off for financial and inventory integrity.

```
Race Condition Threat Model:

┌──────────────────────────────────────────────────────────────────────┐
│  CRITICAL: Operations requiring pessimistic locking (FOR UPDATE)     │
│                                                                      │
│  1. Order Checkout (highest priority)                                │
│     ├── Lock: product rows being purchased                           │
│     ├── Lock: cart row (prevent concurrent checkouts)                │
│     ├── Lock: discount row (if coupon applied)                       │
│     └── Why: Two doctors could buy the last 5 units simultaneously  │
│                                                                      │
│  2. Order Cancellation + Stock Restore                               │
│     ├── Lock: order row (prevent double-cancel)                      │
│     ├── Lock: product rows (restore stock atomically)                │
│     └── Why: Concurrent cancel requests could double-restore stock  │
│                                                                      │
│  3. Flash Sale Purchase                                              │
│     ├── Lock: flash_sale_products row (flash_stock + sold_count)     │
│     ├── Lock: products row (main stock)                              │
│     └── Why: Flash sales have extremely limited stock, high burst    │
│                                                                      │
│  4. Discount / Coupon Redemption                                     │
│     ├── Lock: discounts row (used_count vs usage_limit)              │
│     ├── Check: discount_usage for per-user limit                     │
│     └── Why: Concurrent orders could exceed usage_limit              │
│                                                                      │
│  5. Cart Modification (add/update quantity)                          │
│     ├── Lock: cart row (prevent stale reads during checkout)         │
│     └── Why: Adding to cart while checkout is in-flight = data loss  │
│                                                                      │
│  6. Admin Stock Adjustment                                           │
│     ├── Lock: product row (prevent conflict with ongoing checkouts)  │
│     └── Why: Admin restocking while orders are processing            │
│                                                                      │
│  7. Order Status Transition                                          │
│     ├── Lock: order row (enforce valid state machine transitions)    │
│     └── Why: Admin and system workers could race on status updates   │
│                                                                      │
│  8. Review Submission (per-product-per-doctor uniqueness)            │
│     ├── Lock: use UNIQUE constraint + ON CONFLICT                    │
│     └── Why: Double-tap on submit button = duplicate reviews         │
│                                                                      │
│  9. Refresh Token Rotation                                           │
│     ├── Lock: refresh_tokens family row                              │
│     └── Why: Concurrent refresh requests with same token = theft     │
│              detection false positive if not serialized               │
└──────────────────────────────────────────────────────────────────────┘
```

### Locking Rules (System-Wide)

```
Rule                                            │ Details
────────────────────────────────────────────────┼──────────────────────────────────────
Always lock inside a transaction                │ BEGIN → SELECT FOR UPDATE → modify → COMMIT
Lock rows in a consistent order                 │ Sort product IDs ascending before locking
                                                │ to prevent deadlocks across transactions
Use NOWAIT or lock_timeout for flash sales      │ NOWAIT immediately fails if lock is held
                                                │ — better UX than hanging for 30s
Keep lock duration minimal                      │ Do NOT call external APIs (S3, FCM) inside
                                                │ the locked transaction — queue them after
Use FOR UPDATE, not FOR SHARE                   │ We're always modifying the locked row
Never lock in read-only endpoints               │ GET /products, GET /orders → no locks needed
Set statement_timeout on all transactions       │ Prevent runaway transactions from holding
                                                │ locks indefinitely (default: 10s)
Log lock wait events                            │ Monitor pg_stat_activity for lock waits
                                                │ to detect contention hotspots
```

### Checkout Flow with Pessimistic Locking (Sequence)

```
Doctor clicks "Place Order"
        │
        ▼
┌─ BEGIN TRANSACTION ──────────────────────────────────────────────┐
│                                                                   │
│  1. SELECT * FROM carts WHERE doctor_id = $1 FOR UPDATE          │
│     └─ Locks cart row → blocks concurrent checkout by same user  │
│                                                                   │
│  2. SELECT * FROM products WHERE id IN ($ids)                    │
│     ORDER BY id ASC   ← consistent ordering prevents deadlocks  │
│     FOR UPDATE                                                   │
│     └─ Locks all product rows → no other tx can modify stock     │
│                                                                   │
│  3. Verify stock >= quantity for each item                       │
│     └─ If insufficient → ROLLBACK + return 422                   │
│                                                                   │
│  4. (If coupon applied)                                          │
│     SELECT * FROM discounts WHERE id = $1 FOR UPDATE             │
│     └─ Lock discount → check used_count < usage_limit            │
│     └─ Check per-user limit in discount_usage                    │
│                                                                   │
│  5. UPDATE products SET stock = stock - $qty WHERE id = $id      │
│     └─ Deduct stock for each item                                │
│                                                                   │
│  6. INSERT INTO orders (...)                                     │
│     INSERT INTO order_items (...)                                │
│     INSERT INTO order_status_history (...)                       │
│                                                                   │
│  7. UPDATE discounts SET used_count = used_count + 1             │
│     INSERT INTO discount_usage (...)                             │
│                                                                   │
│  8. DELETE FROM cart_items WHERE cart_id = $cartId                │
│     └─ Clear cart inside the same transaction                    │
│                                                                   │
│  COMMIT                                                          │
└──────────────────────────────────────────────────────────────────┘
        │
        ▼ (after commit — NOT inside the locked transaction)
  Queue notification job (BullMQ)
  Invalidate cache (Redis)
```
