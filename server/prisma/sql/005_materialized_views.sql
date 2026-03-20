-- ============================================================
-- MedOrder — Materialized Views
-- Pre-computed aggregations for dashboard & reporting
-- Refreshed periodically via cron or application timer
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- 1. DASHBOARD SUMMARY VIEW
--    Pre-computes key metrics for the admin dashboard.
--    Refresh every 5 minutes via pg_cron or application timer.
-- ────────────────────────────────────────────────────────────

DROP MATERIALIZED VIEW IF EXISTS mv_dashboard_summary;

CREATE MATERIALIZED VIEW mv_dashboard_summary AS
WITH order_stats AS (
    SELECT
        COUNT(*)                                             AS total_orders,
        COUNT(*) FILTER (WHERE status = 'pending')           AS pending_orders,
        COUNT(*) FILTER (WHERE status = 'processing')        AS processing_orders,
        COUNT(*) FILTER (WHERE status = 'shipped')           AS shipped_orders,
        COUNT(*) FILTER (WHERE status = 'delivered')         AS delivered_orders,
        COUNT(*) FILTER (WHERE status = 'cancelled')         AS cancelled_orders,
        COALESCE(SUM(total) FILTER (WHERE status != 'cancelled'), 0) AS total_revenue,
        COALESCE(SUM(total) FILTER (
            WHERE status != 'cancelled'
            AND created_at >= date_trunc('month', CURRENT_DATE)
        ), 0)                                                AS month_revenue,
        COALESCE(SUM(total) FILTER (
            WHERE status != 'cancelled'
            AND created_at >= CURRENT_DATE
        ), 0)                                                AS today_revenue,
        COALESCE(AVG(total) FILTER (WHERE status != 'cancelled'), 0) AS avg_order_value
    FROM orders
),
doctor_stats AS (
    SELECT
        COUNT(*)                                             AS total_doctors,
        COUNT(*) FILTER (WHERE status = 'approved')          AS approved_doctors,
        COUNT(*) FILTER (WHERE status = 'pending')           AS pending_doctors,
        COUNT(*) FILTER (WHERE status = 'rejected')          AS rejected_doctors,
        COUNT(*) FILTER (WHERE status = 'suspended')         AS suspended_doctors
    FROM doctors
),
product_stats AS (
    SELECT
        COUNT(*)                                             AS total_products,
        COUNT(*) FILTER (WHERE is_active = true)             AS active_products,
        COUNT(*) FILTER (WHERE stock <= low_stock_threshold) AS low_stock_products,
        COUNT(*) FILTER (WHERE stock = 0)                    AS out_of_stock_products
    FROM products
)
SELECT
    os.*,
    ds.*,
    ps.*,
    NOW() AS refreshed_at
FROM order_stats os, doctor_stats ds, product_stats ps;

-- Unique index required for CONCURRENT refresh
CREATE UNIQUE INDEX IF NOT EXISTS mv_dashboard_summary_unique
    ON mv_dashboard_summary (refreshed_at);

-- ────────────────────────────────────────────────────────────
-- 2. TOP-SELLING PRODUCTS VIEW (Refreshed hourly)
-- ────────────────────────────────────────────────────────────

DROP MATERIALIZED VIEW IF EXISTS mv_top_products;

CREATE MATERIALIZED VIEW mv_top_products AS
SELECT
    p.id,
    p.name,
    p.sku,
    p.price,
    p.sale_price,
    p.stock,
    p.total_sold,
    p.avg_rating,
    p.review_count,
    c.name AS category_name,
    COALESCE(
        (SELECT SUM(oi.quantity)
         FROM order_items oi
         JOIN orders o ON o.id = oi.order_id
         WHERE oi.product_id = p.id
           AND o.status != 'cancelled'
           AND o.created_at >= CURRENT_DATE - INTERVAL '30 days'),
        0
    ) AS sold_last_30_days,
    COALESCE(
        (SELECT SUM(oi.total_price)
         FROM order_items oi
         JOIN orders o ON o.id = oi.order_id
         WHERE oi.product_id = p.id
           AND o.status != 'cancelled'
           AND o.created_at >= CURRENT_DATE - INTERVAL '30 days'),
        0
    ) AS revenue_last_30_days
FROM products p
LEFT JOIN categories c ON c.id = p.category_id
WHERE p.is_active = true
ORDER BY sold_last_30_days DESC
LIMIT 100;

CREATE UNIQUE INDEX IF NOT EXISTS mv_top_products_id
    ON mv_top_products (id);

-- ────────────────────────────────────────────────────────────
-- 3. REVENUE BY PERIOD VIEW (Refreshed daily)
-- ────────────────────────────────────────────────────────────

DROP MATERIALIZED VIEW IF EXISTS mv_daily_revenue;

CREATE MATERIALIZED VIEW mv_daily_revenue AS
SELECT
    DATE(created_at) AS order_date,
    COUNT(*)         AS order_count,
    SUM(subtotal)    AS gross_revenue,
    SUM(discount_amount) AS total_discounts,
    SUM(delivery_fee)    AS total_delivery_fees,
    SUM(total)       AS net_revenue,
    AVG(total)       AS avg_order_value
FROM orders
WHERE status != 'cancelled'
GROUP BY DATE(created_at)
ORDER BY order_date DESC;

CREATE UNIQUE INDEX IF NOT EXISTS mv_daily_revenue_date
    ON mv_daily_revenue (order_date);

-- ────────────────────────────────────────────────────────────
-- 4. HELPER: Refresh all materialized views
-- ────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION refresh_all_materialized_views()
RETURNS void AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_dashboard_summary;
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_top_products;
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_daily_revenue;
    RAISE NOTICE 'All materialized views refreshed at %', NOW();
END;
$$ LANGUAGE plpgsql;

-- Schedule with pg_cron (if available):
-- SELECT cron.schedule('refresh_mv', '*/5 * * * *', 'SELECT refresh_all_materialized_views()');
