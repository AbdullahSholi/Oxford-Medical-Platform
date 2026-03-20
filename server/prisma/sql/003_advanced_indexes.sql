-- ============================================================
-- MedOrder — Advanced Indexes
-- Partial indexes, GIN indexes, trigram indexes
-- These complement the basic indexes created by Prisma
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- PRODUCTS
-- ────────────────────────────────────────────────────────────

-- Partial index: only active products (most queries filter on active)
CREATE INDEX IF NOT EXISTS idx_products_active
    ON products (is_active)
    WHERE is_active = true;

-- Partial index: in-stock products
CREATE INDEX IF NOT EXISTS idx_products_in_stock
    ON products (stock)
    WHERE stock > 0;

-- Full-text search (GIN on tsvector)
CREATE INDEX IF NOT EXISTS idx_products_search
    ON products USING GIN (search_vector);

-- JSONB GIN index for medical_details queries
CREATE INDEX IF NOT EXISTS idx_products_medical
    ON products USING GIN (medical_details);

-- Trigram index for fuzzy name search (LIKE '%term%')
CREATE INDEX IF NOT EXISTS idx_products_name_trgm
    ON products USING GIN (name gin_trgm_ops);

-- Sorting indexes for common ordering patterns
CREATE INDEX IF NOT EXISTS idx_products_rating_desc
    ON products (avg_rating DESC)
    WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_products_sold_desc
    ON products (total_sold DESC)
    WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_products_price_asc
    ON products (price ASC)
    WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_products_created_desc
    ON products (created_at DESC)
    WHERE is_active = true;

-- Composite: category + active + price (category browsing)
CREATE INDEX IF NOT EXISTS idx_products_cat_active_price
    ON products (category_id, is_active, price)
    WHERE is_active = true;

-- ────────────────────────────────────────────────────────────
-- ORDERS
-- ────────────────────────────────────────────────────────────

-- Composite: doctor + status (doctor's order list filtered by status)
CREATE INDEX IF NOT EXISTS idx_orders_doctor_status
    ON orders (doctor_id, status);

-- Composite: created_at descending for admin order listing
CREATE INDEX IF NOT EXISTS idx_orders_created_desc
    ON orders (created_at DESC);

-- Partial: pending orders for background job processing
CREATE INDEX IF NOT EXISTS idx_orders_pending
    ON orders (created_at ASC)
    WHERE status = 'pending';

-- ────────────────────────────────────────────────────────────
-- REVIEWS
-- ────────────────────────────────────────────────────────────

-- Partial: only visible reviews (public product page)
CREATE INDEX IF NOT EXISTS idx_reviews_visible
    ON reviews (product_id)
    WHERE is_visible = true;

-- Composite: product + rating for distribution queries
CREATE INDEX IF NOT EXISTS idx_reviews_product_rating
    ON reviews (product_id, rating);

-- ────────────────────────────────────────────────────────────
-- NOTIFICATIONS
-- ────────────────────────────────────────────────────────────

-- Composite: doctor + created (paginated fetch)
CREATE INDEX IF NOT EXISTS idx_notifications_doctor_created
    ON notifications (doctor_id, created_at DESC);

-- Partial: unread notifications count
CREATE INDEX IF NOT EXISTS idx_notifications_unread
    ON notifications (doctor_id)
    WHERE is_read = false;

-- ────────────────────────────────────────────────────────────
-- DISCOUNTS
-- ────────────────────────────────────────────────────────────

-- Composite: active + date range (validation check)
CREATE INDEX IF NOT EXISTS idx_discounts_active_dates
    ON discounts (is_active, starts_at, ends_at)
    WHERE is_active = true;

-- ────────────────────────────────────────────────────────────
-- FLASH SALES
-- ────────────────────────────────────────────────────────────

-- Active flash sales by date range
CREATE INDEX IF NOT EXISTS idx_flash_sales_active_dates
    ON flash_sales (is_active, starts_at, ends_at)
    WHERE is_active = true;

-- ────────────────────────────────────────────────────────────
-- BANNERS
-- ────────────────────────────────────────────────────────────

-- Active banners by position with sort order
CREATE INDEX IF NOT EXISTS idx_banners_active_position
    ON banners (position, is_active, sort_order)
    WHERE is_active = true;

-- ────────────────────────────────────────────────────────────
-- WISHLIST & STOCK ALERTS
-- ────────────────────────────────────────────────────────────

-- Wishlist doctor lookup
CREATE INDEX IF NOT EXISTS idx_wishlist_doctor
    ON wishlist (doctor_id);

-- Pending stock alerts (not yet notified)
CREATE INDEX IF NOT EXISTS idx_stock_alerts_pending
    ON stock_alerts (product_id)
    WHERE is_notified = false;

-- ────────────────────────────────────────────────────────────
-- REFRESH TOKENS
-- ────────────────────────────────────────────────────────────

-- Family-based lookup for token rotation
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_family
    ON refresh_tokens (family_id);

-- Doctor token lookup
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_doctor
    ON refresh_tokens (doctor_id)
    WHERE doctor_id IS NOT NULL;

-- ────────────────────────────────────────────────────────────
-- DOCTORS
-- ────────────────────────────────────────────────────────────

-- Trigram index for doctor name search (admin panel)
CREATE INDEX IF NOT EXISTS idx_doctors_name_trgm
    ON doctors USING GIN (full_name gin_trgm_ops);

-- Composite: status + city (admin filtering)
CREATE INDEX IF NOT EXISTS idx_doctors_status_city
    ON doctors (status, city);
