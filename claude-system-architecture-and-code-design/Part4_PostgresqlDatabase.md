# MedOrder — System Architecture & Code Design Guidelines

## Tech Stack: Flutter + Node.js + PostgreSQL

---

# PART 4: DATABASE (POSTGRESQL) DESIGN GUIDELINES

---

## 4.1 Complete Database Schema

```sql
-- ============================================================
-- EXTENSIONS
-- ============================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";           -- UUID generation
CREATE EXTENSION IF NOT EXISTS "pg_trgm";             -- Trigram search for fuzzy matching
CREATE EXTENSION IF NOT EXISTS "btree_gin";           -- GIN index support

-- ============================================================
-- ENUMS
-- ============================================================
CREATE TYPE doctor_status AS ENUM ('pending', 'approved', 'rejected', 'suspended');
CREATE TYPE order_status AS ENUM ('pending', 'confirmed', 'processing', 'shipped', 'out_for_delivery', 'delivered', 'cancelled');
CREATE TYPE payment_method AS ENUM ('cod');
CREATE TYPE discount_type AS ENUM ('percentage', 'fixed');
CREATE TYPE notification_type AS ENUM ('order', 'promotion', 'system', 'approval');
CREATE TYPE banner_position AS ENUM ('home_slider', 'category_banner', 'flash_sale');

-- ============================================================
-- CORE TABLES
-- ============================================================

-- Admins (separate from doctors — different auth context)
CREATE TABLE admins (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email           VARCHAR(255) UNIQUE NOT NULL,
    password_hash   VARCHAR(255) NOT NULL,
    full_name       VARCHAR(200) NOT NULL,
    role            VARCHAR(50) NOT NULL DEFAULT 'admin',  -- admin, super_admin
    is_active       BOOLEAN NOT NULL DEFAULT true,
    last_login_at   TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Doctors (primary users of the mobile app)
CREATE TABLE doctors (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    full_name       VARCHAR(200) NOT NULL,
    email           VARCHAR(255) UNIQUE NOT NULL,
    phone           VARCHAR(20) UNIQUE NOT NULL,
    password_hash   VARCHAR(255) NOT NULL,
    avatar_url      TEXT,

    -- Professional info
    clinic_name     VARCHAR(300) NOT NULL,
    specialty       VARCHAR(100) NOT NULL,
    city            VARCHAR(100) NOT NULL,
    clinic_address  TEXT NOT NULL,

    -- Verification
    license_url     TEXT NOT NULL,                        -- S3 path to license image
    clinic_reg_url  TEXT,                                 -- Optional clinic registration doc
    status          doctor_status NOT NULL DEFAULT 'pending',
    rejection_reason TEXT,
    approved_at     TIMESTAMPTZ,
    approved_by     UUID REFERENCES admins(id),

    -- Tokens
    refresh_token_hash VARCHAR(255),
    fcm_token       TEXT,                                 -- Firebase push notification token

    -- Metadata
    last_login_at   TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_doctors_status ON doctors(status);
CREATE INDEX idx_doctors_email ON doctors(email);
CREATE INDEX idx_doctors_phone ON doctors(phone);
CREATE INDEX idx_doctors_specialty ON doctors(specialty);
CREATE INDEX idx_doctors_city ON doctors(city);

-- Doctor Addresses (multiple delivery addresses per doctor)
CREATE TABLE doctor_addresses (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    doctor_id       UUID NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
    label           VARCHAR(50) NOT NULL,                 -- 'Clinic', 'Hospital', 'Home'
    recipient_name  VARCHAR(200) NOT NULL,
    phone           VARCHAR(20) NOT NULL,
    city            VARCHAR(100) NOT NULL,
    street_address  TEXT NOT NULL,
    building_info   TEXT,
    landmark        TEXT,
    latitude        DECIMAL(10, 8),
    longitude       DECIMAL(11, 8),
    is_default      BOOLEAN NOT NULL DEFAULT false,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_doctor_addresses_doctor ON doctor_addresses(doctor_id);

-- ============================================================
-- PRODUCT CATALOG
-- ============================================================

-- Categories (self-referencing for subcategories)
CREATE TABLE categories (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    parent_id       UUID REFERENCES categories(id) ON DELETE SET NULL,
    name            VARCHAR(200) NOT NULL,
    slug            VARCHAR(200) UNIQUE NOT NULL,
    description     TEXT,
    icon_url        TEXT,
    sort_order      INTEGER NOT NULL DEFAULT 0,
    is_active       BOOLEAN NOT NULL DEFAULT true,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_categories_parent ON categories(parent_id);
CREATE INDEX idx_categories_slug ON categories(slug);

-- Brands
CREATE TABLE brands (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name            VARCHAR(200) NOT NULL,
    slug            VARCHAR(200) UNIQUE NOT NULL,
    logo_url        TEXT,
    description     TEXT,
    is_active       BOOLEAN NOT NULL DEFAULT true,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Products
CREATE TABLE products (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category_id     UUID NOT NULL REFERENCES categories(id),
    brand_id        UUID REFERENCES brands(id),
    name            VARCHAR(300) NOT NULL,
    slug            VARCHAR(300) UNIQUE NOT NULL,
    description     TEXT NOT NULL,
    sku             VARCHAR(50) UNIQUE NOT NULL,

    -- Pricing
    price           DECIMAL(10, 2) NOT NULL,              -- Regular price
    sale_price      DECIMAL(10, 2),                       -- Optional sale price
    cost_price      DECIMAL(10, 2),                       -- Internal cost (admin only)

    -- Stock
    stock           INTEGER NOT NULL DEFAULT 0,
    low_stock_threshold INTEGER NOT NULL DEFAULT 10,
    min_order_qty   INTEGER NOT NULL DEFAULT 1,

    -- Medical details (stored as JSONB for flexibility)
    medical_details JSONB NOT NULL DEFAULT '{}',
    /*
      {
        "intended_use": "...",
        "material": "Latex",
        "sterile": true,
        "latex_free": false,
        "manufacturer": "MedCare Inc.",
        "country_of_origin": "Germany",
        "expiry_date": "2026-08",
        "certifications": ["CE", "FDA", "ISO"],
        "storage_instructions": "Store below 25°C",
        "pack_size": "100 units"
      }
    */

    -- Search optimization
    search_vector   TSVECTOR,                             -- Full-text search

    -- Aggregated stats (denormalized for performance)
    avg_rating      DECIMAL(2, 1) NOT NULL DEFAULT 0.0,
    review_count    INTEGER NOT NULL DEFAULT 0,
    total_sold      INTEGER NOT NULL DEFAULT 0,

    -- Status
    is_active       BOOLEAN NOT NULL DEFAULT true,

    -- Metadata
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_brand ON products(brand_id);
CREATE INDEX idx_products_sku ON products(sku);
CREATE INDEX idx_products_slug ON products(slug);
CREATE INDEX idx_products_price ON products(price);
CREATE INDEX idx_products_active ON products(is_active) WHERE is_active = true;
CREATE INDEX idx_products_stock ON products(stock) WHERE stock > 0;
CREATE INDEX idx_products_search ON products USING GIN(search_vector);
CREATE INDEX idx_products_medical ON products USING GIN(medical_details);
CREATE INDEX idx_products_rating ON products(avg_rating DESC);
CREATE INDEX idx_products_sold ON products(total_sold DESC);

-- Trigger to auto-update search_vector
CREATE OR REPLACE FUNCTION products_search_trigger() RETURNS trigger AS $$
BEGIN
    NEW.search_vector :=
        setweight(to_tsvector('english', COALESCE(NEW.name, '')), 'A') ||
        setweight(to_tsvector('english', COALESCE(NEW.description, '')), 'B') ||
        setweight(to_tsvector('english', COALESCE(NEW.sku, '')), 'A') ||
        setweight(to_tsvector('english', COALESCE(NEW.medical_details->>'manufacturer', '')), 'C');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_products_search
    BEFORE INSERT OR UPDATE OF name, description, sku, medical_details
    ON products
    FOR EACH ROW
    EXECUTE FUNCTION products_search_trigger();

-- Product Images
CREATE TABLE product_images (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id      UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    url             TEXT NOT NULL,
    thumbnail_url   TEXT,
    alt_text        VARCHAR(300),
    sort_order      INTEGER NOT NULL DEFAULT 0,
    is_primary      BOOLEAN NOT NULL DEFAULT false,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_product_images_product ON product_images(product_id);

-- Bulk Pricing Tiers
CREATE TABLE bulk_pricing (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id      UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    min_quantity    INTEGER NOT NULL,
    max_quantity    INTEGER,                               -- NULL means unlimited
    unit_price      DECIMAL(10, 2) NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_bulk_pricing_product ON bulk_pricing(product_id);

-- ============================================================
-- SHOPPING & ORDERS
-- ============================================================

-- Cart (persistent server-side cart)
CREATE TABLE carts (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    doctor_id       UUID UNIQUE NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE cart_items (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cart_id         UUID NOT NULL REFERENCES carts(id) ON DELETE CASCADE,
    product_id      UUID NOT NULL REFERENCES products(id),
    quantity        INTEGER NOT NULL CHECK (quantity > 0),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(cart_id, product_id)
);

CREATE INDEX idx_cart_items_cart ON cart_items(cart_id);

-- Orders
CREATE TABLE orders (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_number    VARCHAR(20) UNIQUE NOT NULL,           -- MED-2024-000001 (human-readable)
    doctor_id       UUID NOT NULL REFERENCES doctors(id),

    -- Delivery snapshot (copied at order time, not referenced)
    delivery_address JSONB NOT NULL,
    /*
      {
        "label": "Main Clinic",
        "recipient_name": "Dr. Ahmad",
        "phone": "+970...",
        "city": "Ramallah",
        "street_address": "...",
        "building_info": "...",
        "latitude": 31.9,
        "longitude": 35.2
      }
    */

    -- Pricing
    subtotal        DECIMAL(12, 2) NOT NULL,
    discount_amount DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
    delivery_fee    DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    total           DECIMAL(12, 2) NOT NULL,

    -- Payment
    payment_method  payment_method NOT NULL DEFAULT 'cod',
    is_paid         BOOLEAN NOT NULL DEFAULT false,
    paid_at         TIMESTAMPTZ,

    -- Status
    status          order_status NOT NULL DEFAULT 'pending',

    -- Additional info
    notes           TEXT,                                  -- Doctor's delivery notes
    admin_notes     TEXT,                                  -- Internal admin notes
    cancel_reason   TEXT,
    cancelled_at    TIMESTAMPTZ,

    -- Discount reference
    discount_id     UUID REFERENCES discounts(id),

    -- Metadata
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_orders_doctor ON orders(doctor_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_number ON orders(order_number);
CREATE INDEX idx_orders_created ON orders(created_at DESC);
CREATE INDEX idx_orders_doctor_status ON orders(doctor_id, status);

-- Order Items (snapshot of product at order time)
CREATE TABLE order_items (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id        UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id      UUID NOT NULL REFERENCES products(id),

    -- Snapshot fields (prices at time of order — products may change later)
    product_name    VARCHAR(300) NOT NULL,
    product_sku     VARCHAR(50) NOT NULL,
    product_image   TEXT,
    unit_price      DECIMAL(10, 2) NOT NULL,
    quantity        INTEGER NOT NULL CHECK (quantity > 0),
    total_price     DECIMAL(12, 2) NOT NULL,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_order_items_product ON order_items(product_id);

-- Order Status History (audit trail)
CREATE TABLE order_status_history (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id        UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    status          order_status NOT NULL,
    notes           TEXT,
    changed_by      UUID,                                  -- admin or system
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_order_history_order ON order_status_history(order_id);

-- ============================================================
-- REVIEWS & RATINGS
-- ============================================================

CREATE TABLE reviews (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id      UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    doctor_id       UUID NOT NULL REFERENCES doctors(id),
    order_item_id   UUID REFERENCES order_items(id),       -- Verified purchase link
    rating          SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    title           VARCHAR(200),
    body            TEXT,
    is_verified     BOOLEAN NOT NULL DEFAULT false,         -- true if linked to purchase
    is_visible      BOOLEAN NOT NULL DEFAULT true,          -- admin can hide
    helpful_count   INTEGER NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(doctor_id, product_id)                          -- One review per product per doctor
);

CREATE INDEX idx_reviews_product ON reviews(product_id);
CREATE INDEX idx_reviews_doctor ON reviews(doctor_id);
CREATE INDEX idx_reviews_rating ON reviews(product_id, rating);
CREATE INDEX idx_reviews_visible ON reviews(product_id) WHERE is_visible = true;

-- ============================================================
-- PROMOTIONS & MARKETING
-- ============================================================

-- Discounts / Coupons
CREATE TABLE discounts (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code            VARCHAR(50) UNIQUE NOT NULL,
    description     TEXT,
    type            discount_type NOT NULL,                -- percentage or fixed
    value           DECIMAL(10, 2) NOT NULL,               -- percentage (e.g., 15) or fixed amount
    min_order_amount DECIMAL(10, 2),
    max_discount    DECIMAL(10, 2),                        -- Cap for percentage discounts
    usage_limit     INTEGER,                               -- Total uses allowed
    per_user_limit  INTEGER NOT NULL DEFAULT 1,
    used_count      INTEGER NOT NULL DEFAULT 0,
    starts_at       TIMESTAMPTZ NOT NULL,
    ends_at         TIMESTAMPTZ NOT NULL,
    is_active       BOOLEAN NOT NULL DEFAULT true,
    applies_to      JSONB DEFAULT '{"scope": "all"}',
    /*
      {"scope": "all"}
      {"scope": "categories", "ids": ["uuid1", "uuid2"]}
      {"scope": "products", "ids": ["uuid1", "uuid2"]}
    */
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_discounts_code ON discounts(code);
CREATE INDEX idx_discounts_active ON discounts(is_active, starts_at, ends_at);

-- Discount Usage Tracking
CREATE TABLE discount_usage (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    discount_id     UUID NOT NULL REFERENCES discounts(id),
    doctor_id       UUID NOT NULL REFERENCES doctors(id),
    order_id        UUID NOT NULL REFERENCES orders(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_discount_usage_discount ON discount_usage(discount_id, doctor_id);

-- Flash Sales
CREATE TABLE flash_sales (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title           VARCHAR(200) NOT NULL,
    banner_url      TEXT,
    starts_at       TIMESTAMPTZ NOT NULL,
    ends_at         TIMESTAMPTZ NOT NULL,
    is_active       BOOLEAN NOT NULL DEFAULT false,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_flash_sales_active ON flash_sales(is_active, starts_at, ends_at);

-- Flash Sale Products
CREATE TABLE flash_sale_products (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    flash_sale_id   UUID NOT NULL REFERENCES flash_sales(id) ON DELETE CASCADE,
    product_id      UUID NOT NULL REFERENCES products(id),
    flash_price     DECIMAL(10, 2) NOT NULL,
    flash_stock     INTEGER NOT NULL,                      -- Limited stock for flash sale
    sold_count      INTEGER NOT NULL DEFAULT 0,
    UNIQUE(flash_sale_id, product_id)
);

CREATE INDEX idx_flash_sale_products_sale ON flash_sale_products(flash_sale_id);

-- Banners / Sliders
CREATE TABLE banners (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title           VARCHAR(200),
    subtitle        TEXT,
    image_url       TEXT NOT NULL,
    link_type       VARCHAR(50),                           -- product, category, flash_sale, url
    link_target     TEXT,                                   -- UUID or URL depending on type
    position        banner_position NOT NULL DEFAULT 'home_slider',
    sort_order      INTEGER NOT NULL DEFAULT 0,
    is_active       BOOLEAN NOT NULL DEFAULT true,
    starts_at       TIMESTAMPTZ,
    ends_at         TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_banners_active ON banners(position, is_active, sort_order);

-- ============================================================
-- NOTIFICATIONS & ENGAGEMENT
-- ============================================================

CREATE TABLE notifications (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    doctor_id       UUID NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
    type            notification_type NOT NULL,
    title           VARCHAR(200) NOT NULL,
    body            TEXT NOT NULL,
    data            JSONB DEFAULT '{}',                     -- Deep link data
    is_read         BOOLEAN NOT NULL DEFAULT false,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notifications_doctor ON notifications(doctor_id, created_at DESC);
CREATE INDEX idx_notifications_unread ON notifications(doctor_id) WHERE is_read = false;

-- Wishlist
CREATE TABLE wishlist (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    doctor_id       UUID NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
    product_id      UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(doctor_id, product_id)
);

CREATE INDEX idx_wishlist_doctor ON wishlist(doctor_id);

-- Stock Notification Requests (Notify Me)
CREATE TABLE stock_alerts (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    doctor_id       UUID NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
    product_id      UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    notify_push     BOOLEAN NOT NULL DEFAULT true,
    notify_email    BOOLEAN NOT NULL DEFAULT false,
    notify_sms      BOOLEAN NOT NULL DEFAULT false,
    is_notified     BOOLEAN NOT NULL DEFAULT false,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(doctor_id, product_id)
);

CREATE INDEX idx_stock_alerts_product ON stock_alerts(product_id) WHERE is_notified = false;

-- ============================================================
-- AUDIT & SYSTEM
-- ============================================================

-- Refresh Tokens (for token family tracking)
CREATE TABLE refresh_tokens (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    doctor_id       UUID REFERENCES doctors(id) ON DELETE CASCADE,
    admin_id        UUID REFERENCES admins(id) ON DELETE CASCADE,
    token_hash      VARCHAR(255) NOT NULL,
    family_id       UUID NOT NULL,                         -- Token rotation family
    is_revoked      BOOLEAN NOT NULL DEFAULT false,
    expires_at      TIMESTAMPTZ NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CHECK (
        (doctor_id IS NOT NULL AND admin_id IS NULL) OR
        (doctor_id IS NULL AND admin_id IS NOT NULL)
    )
);

CREATE INDEX idx_refresh_tokens_doctor ON refresh_tokens(doctor_id);
CREATE INDEX idx_refresh_tokens_family ON refresh_tokens(family_id);

-- updated_at Trigger (apply to all tables)
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to every table with updated_at column:
-- CREATE TRIGGER trg_[table]_updated_at BEFORE UPDATE ON [table]
-- FOR EACH ROW EXECUTE FUNCTION update_updated_at();
```

## 4.2 Database Design Rules

**Naming Conventions:**
- Tables: `snake_case`, plural (e.g., `doctors`, `order_items`)
- Columns: `snake_case` (e.g., `created_at`, `doctor_id`)
- Primary keys: always `id` (UUID v4)
- Foreign keys: `{referenced_table_singular}_id` (e.g., `doctor_id`, `product_id`)
- Indexes: `idx_{table}_{columns}` (e.g., `idx_orders_doctor_status`)
- Enums: `snake_case` singular (e.g., `order_status`)
- Timestamps: always `TIMESTAMPTZ` (with timezone), never `TIMESTAMP`

**Data Integrity Rules:**
- Every table has `id` (UUID), `created_at`, and `updated_at` columns
- All foreign keys have explicit `ON DELETE` behavior (CASCADE, SET NULL, or RESTRICT)
- Use `CHECK` constraints for value ranges (e.g., rating BETWEEN 1 AND 5)
- Use `UNIQUE` constraints for business rules (e.g., one review per doctor per product)
- Use `JSONB` for semi-structured data that varies between products (medical details), NOT for relational data
- Snapshot order data at creation time — order_items store price/name snapshots because products can change
- Delivery address is copied into the order as JSONB, not referenced — addresses can be deleted later

**Indexing Strategy:**
- Every foreign key column gets an index
- Columns used in WHERE clauses get indexes
- Composite indexes for common query patterns (e.g., `doctor_id + status`)
- Partial indexes for boolean filters (e.g., `WHERE is_active = true`)
- GIN indexes for JSONB and full-text search
- Monitor query performance with `pg_stat_statements` and add indexes based on real usage

**Query Performance Rules:**
- Always paginate list queries (never return unbounded result sets)
- Use cursor-based pagination for infinite scroll, offset-based for admin tables
- Denormalize counters that are read frequently (`avg_rating`, `review_count`, `total_sold` on products)
- Update denormalized counters in the same transaction as the source data change
- Use materialized views for complex dashboard aggregations (refreshed periodically)
- Connection pooling with PgBouncer in production (limit: 20 connections per Node.js instance)

**Migration Rules:**
- Never modify existing migrations — always create new ones
- Every migration must be reversible (include both `up` and `down`)
- Test migrations on a copy of production data before deploying
- Use Prisma Migrate for schema management

## 4.3 Pessimistic Locking & Concurrency Rules

MedOrder uses **pessimistic row-level locking** (`SELECT ... FOR UPDATE`) to prevent race conditions in all write-heavy operations. This section defines the PostgreSQL-level locking strategy.

### Row-Level Lock Types Used

```sql
-- FOR UPDATE: Exclusive row lock. Blocks other FOR UPDATE and FOR SHARE.
-- Used for: stock deduction, order status changes, discount redemption.
SELECT * FROM products WHERE id = $1 FOR UPDATE;

-- FOR UPDATE NOWAIT: Same as above, but fails immediately if lock is held.
-- Used for: flash sale purchases (high contention, fail-fast preferred).
SELECT * FROM flash_sale_products WHERE id = $1 FOR UPDATE NOWAIT;

-- FOR UPDATE SKIP LOCKED: Skips locked rows instead of waiting.
-- Used for: background job processing (pick next unlocked job).
SELECT * FROM orders WHERE status = 'pending'
  ORDER BY created_at ASC LIMIT 1
  FOR UPDATE SKIP LOCKED;

-- FOR UPDATE OF <table>: Lock only rows from a specific table in a JOIN query.
-- Used for: flash sale queries that JOIN flash_sales and flash_sale_products.
SELECT fsp.*, fs.ends_at
  FROM flash_sale_products fsp
  JOIN flash_sales fs ON fs.id = fsp.flash_sale_id
  WHERE fsp.id = $1
  FOR UPDATE OF fsp;  -- Only lock the flash_sale_products row
```

### Deadlock Prevention: Consistent Lock Ordering

```
┌──────────────────────────────────────────────────────────────────┐
│  RULE: When locking multiple rows of the same table,             │
│  ALWAYS sort by primary key (id) in ascending order.             │
│                                                                   │
│  ✅ CORRECT:                                                     │
│     SELECT * FROM products                                        │
│     WHERE id IN ('aaa', 'bbb', 'ccc')                            │
│     ORDER BY id ASC                                               │
│     FOR UPDATE;                                                   │
│                                                                   │
│  ❌ WRONG (potential deadlock):                                   │
│     -- Transaction A locks product 'ccc' then 'aaa'              │
│     -- Transaction B locks product 'aaa' then 'ccc'              │
│     -- Result: DEADLOCK → one transaction is killed               │
│                                                                   │
│  RULE: When locking rows from MULTIPLE tables,                   │
│  use this lock acquisition order:                                │
│     1. carts                                                      │
│     2. products           (sorted by id ASC)                      │
│     3. flash_sale_products (sorted by id ASC)                     │
│     4. discounts                                                  │
│     5. orders                                                     │
│                                                                   │
│  This ordering is consistent across ALL services and modules.    │
└──────────────────────────────────────────────────────────────────┘
```

### Lock Timeout Configuration

```sql
-- Set at the session/transaction level to prevent long lock waits.
-- PostgreSQL default is to wait indefinitely — override this.

-- For checkout operations (15 seconds max):
SET LOCAL lock_timeout = '15s';

-- For flash sale purchases (2 seconds max — fail fast):
SET LOCAL lock_timeout = '2s';

-- For background workers (5 seconds max):
SET LOCAL lock_timeout = '5s';

-- Global fallback (set in postgresql.conf):
lock_timeout = '30s'

-- Statement timeout (kill any query running longer than this):
statement_timeout = '30s'
```

### Concurrency-Critical Queries Reference

```sql
-- ═════════════════════════════════════════════════════════
-- ORDER CHECKOUT: Lock cart + products + discount
-- ═════════════════════════════════════════════════════════

BEGIN;
SET LOCAL lock_timeout = '15s';

-- 1. Lock cart
SELECT * FROM carts WHERE doctor_id = $1 FOR UPDATE;

-- 2. Lock products (sorted)
SELECT * FROM products
  WHERE id = ANY($product_ids::uuid[])
  ORDER BY id ASC
  FOR UPDATE;

-- 3. Lock discount (if applicable)
SELECT * FROM discounts WHERE code = $1 FOR UPDATE;

-- 4. Verify stock, deduct, create order...
UPDATE products SET stock = stock - $qty WHERE id = $id;
-- ...
COMMIT;

-- ═════════════════════════════════════════════════════════
-- ORDER CANCELLATION: Lock order + products for stock restore
-- ═════════════════════════════════════════════════════════

BEGIN;
SELECT * FROM orders WHERE id = $1 FOR UPDATE;
-- (validate status is cancellable)
SELECT id FROM products WHERE id = ANY($ids) ORDER BY id ASC FOR UPDATE;
UPDATE products SET stock = stock + $qty WHERE id = $id;
UPDATE orders SET status = 'cancelled' WHERE id = $1;
COMMIT;

-- ═════════════════════════════════════════════════════════
-- FLASH SALE: NOWAIT for immediate fail
-- ═════════════════════════════════════════════════════════

BEGIN;
SET LOCAL lock_timeout = '2s';

SELECT * FROM flash_sale_products WHERE id = $1 FOR UPDATE NOWAIT;
-- If another transaction holds the lock → ERROR: could not obtain lock
-- Application catches this and returns 409 Conflict

SELECT id FROM products WHERE id = $1 FOR UPDATE;
UPDATE flash_sale_products SET sold_count = sold_count + $qty WHERE id = $1;
UPDATE products SET stock = stock - $qty WHERE id = $1;
COMMIT;

-- ═════════════════════════════════════════════════════════
-- BACKGROUND JOB: SKIP LOCKED for non-blocking job processing
-- ═════════════════════════════════════════════════════════

BEGIN;
SELECT * FROM orders
  WHERE status = 'pending'
  AND created_at < NOW() - INTERVAL '24 hours'
  ORDER BY created_at ASC
  LIMIT 10
  FOR UPDATE SKIP LOCKED;
-- Process only unlocked rows — other workers skip them
UPDATE orders SET status = 'cancelled' WHERE id = ANY($ids);
COMMIT;
```

### Monitoring Lock Contention

```sql
-- Query to detect current lock waits (run during load testing):
SELECT
  blocked_locks.pid     AS blocked_pid,
  blocked_activity.usename AS blocked_user,
  blocking_locks.pid    AS blocking_pid,
  blocking_activity.usename AS blocking_user,
  blocked_activity.query AS blocked_query,
  blocking_activity.query AS blocking_query
FROM pg_catalog.pg_locks blocked_locks
JOIN pg_catalog.pg_stat_activity blocked_activity
  ON blocked_activity.pid = blocked_locks.pid
JOIN pg_catalog.pg_locks blocking_locks
  ON blocking_locks.locktype = blocked_locks.locktype
  AND blocking_locks.relation = blocked_locks.relation
  AND blocking_locks.pid != blocked_locks.pid
JOIN pg_catalog.pg_stat_activity blocking_activity
  ON blocking_activity.pid = blocking_locks.pid
WHERE NOT blocked_locks.granted;

-- Query to see deadlock statistics:
SELECT deadlocks FROM pg_stat_database WHERE datname = 'medorder';

-- Enable deadlock logging (in postgresql.conf):
-- log_lock_waits = on
-- deadlock_timeout = '1s'
```

