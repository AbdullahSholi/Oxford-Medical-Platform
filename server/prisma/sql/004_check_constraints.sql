-- ============================================================
-- MedOrder — CHECK Constraints
-- Additional data integrity constraints not expressible in Prisma
-- Run AFTER Prisma migrate
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- PRODUCTS
-- ────────────────────────────────────────────────────────────

-- Price must be positive
ALTER TABLE products
    DROP CONSTRAINT IF EXISTS chk_products_price_positive;
ALTER TABLE products
    ADD CONSTRAINT chk_products_price_positive
    CHECK (price > 0);

-- Sale price must be less than regular price when set
ALTER TABLE products
    DROP CONSTRAINT IF EXISTS chk_products_sale_price;
ALTER TABLE products
    ADD CONSTRAINT chk_products_sale_price
    CHECK (sale_price IS NULL OR sale_price < price);

-- Stock cannot go negative
ALTER TABLE products
    DROP CONSTRAINT IF EXISTS chk_products_stock_non_negative;
ALTER TABLE products
    ADD CONSTRAINT chk_products_stock_non_negative
    CHECK (stock >= 0);

-- ────────────────────────────────────────────────────────────
-- CART ITEMS
-- ────────────────────────────────────────────────────────────

-- Quantity must be positive
ALTER TABLE cart_items
    DROP CONSTRAINT IF EXISTS chk_cart_items_quantity_positive;
ALTER TABLE cart_items
    ADD CONSTRAINT chk_cart_items_quantity_positive
    CHECK (quantity > 0);

-- ────────────────────────────────────────────────────────────
-- ORDER ITEMS
-- ────────────────────────────────────────────────────────────

-- Quantity must be positive
ALTER TABLE order_items
    DROP CONSTRAINT IF EXISTS chk_order_items_quantity_positive;
ALTER TABLE order_items
    ADD CONSTRAINT chk_order_items_quantity_positive
    CHECK (quantity > 0);

-- Unit price must be non-negative
ALTER TABLE order_items
    DROP CONSTRAINT IF EXISTS chk_order_items_price_non_negative;
ALTER TABLE order_items
    ADD CONSTRAINT chk_order_items_price_non_negative
    CHECK (unit_price >= 0);

-- ────────────────────────────────────────────────────────────
-- ORDERS
-- ────────────────────────────────────────────────────────────

-- Total must be non-negative
ALTER TABLE orders
    DROP CONSTRAINT IF EXISTS chk_orders_total_non_negative;
ALTER TABLE orders
    ADD CONSTRAINT chk_orders_total_non_negative
    CHECK (total >= 0);

-- Subtotal must be positive
ALTER TABLE orders
    DROP CONSTRAINT IF EXISTS chk_orders_subtotal_positive;
ALTER TABLE orders
    ADD CONSTRAINT chk_orders_subtotal_positive
    CHECK (subtotal > 0);

-- Discount can't exceed subtotal
ALTER TABLE orders
    DROP CONSTRAINT IF EXISTS chk_orders_discount_reasonable;
ALTER TABLE orders
    ADD CONSTRAINT chk_orders_discount_reasonable
    CHECK (discount_amount >= 0 AND discount_amount <= subtotal);

-- ────────────────────────────────────────────────────────────
-- REVIEWS
-- ────────────────────────────────────────────────────────────

-- Rating range: 1 to 5
ALTER TABLE reviews
    DROP CONSTRAINT IF EXISTS chk_reviews_rating_range;
ALTER TABLE reviews
    ADD CONSTRAINT chk_reviews_rating_range
    CHECK (rating BETWEEN 1 AND 5);

-- ────────────────────────────────────────────────────────────
-- DISCOUNTS
-- ────────────────────────────────────────────────────────────

-- Discount value must be positive
ALTER TABLE discounts
    DROP CONSTRAINT IF EXISTS chk_discounts_value_positive;
ALTER TABLE discounts
    ADD CONSTRAINT chk_discounts_value_positive
    CHECK (value > 0);

-- Start date must be before end date
ALTER TABLE discounts
    DROP CONSTRAINT IF EXISTS chk_discounts_date_range;
ALTER TABLE discounts
    ADD CONSTRAINT chk_discounts_date_range
    CHECK (starts_at < ends_at);

-- Percentage discounts can't exceed 100%
ALTER TABLE discounts
    DROP CONSTRAINT IF EXISTS chk_discounts_percentage_max;
ALTER TABLE discounts
    ADD CONSTRAINT chk_discounts_percentage_max
    CHECK (type != 'percentage' OR value <= 100);

-- ────────────────────────────────────────────────────────────
-- FLASH SALES
-- ────────────────────────────────────────────────────────────

ALTER TABLE flash_sales
    DROP CONSTRAINT IF EXISTS chk_flash_sales_date_range;
ALTER TABLE flash_sales
    ADD CONSTRAINT chk_flash_sales_date_range
    CHECK (starts_at < ends_at);

-- ────────────────────────────────────────────────────────────
-- FLASH SALE PRODUCTS
-- ────────────────────────────────────────────────────────────

ALTER TABLE flash_sale_products
    DROP CONSTRAINT IF EXISTS chk_fsp_flash_price_positive;
ALTER TABLE flash_sale_products
    ADD CONSTRAINT chk_fsp_flash_price_positive
    CHECK (flash_price > 0);

ALTER TABLE flash_sale_products
    DROP CONSTRAINT IF EXISTS chk_fsp_flash_stock_positive;
ALTER TABLE flash_sale_products
    ADD CONSTRAINT chk_fsp_flash_stock_positive
    CHECK (flash_stock > 0);

ALTER TABLE flash_sale_products
    DROP CONSTRAINT IF EXISTS chk_fsp_sold_count_non_negative;
ALTER TABLE flash_sale_products
    ADD CONSTRAINT chk_fsp_sold_count_non_negative
    CHECK (sold_count >= 0 AND sold_count <= flash_stock);

-- ────────────────────────────────────────────────────────────
-- REFRESH TOKENS (exclusive ownership)
-- ────────────────────────────────────────────────────────────

ALTER TABLE refresh_tokens
    DROP CONSTRAINT IF EXISTS chk_refresh_tokens_owner;
ALTER TABLE refresh_tokens
    ADD CONSTRAINT chk_refresh_tokens_owner
    CHECK (
        (doctor_id IS NOT NULL AND admin_id IS NULL) OR
        (doctor_id IS NULL AND admin_id IS NOT NULL)
    );

-- ────────────────────────────────────────────────────────────
-- BULK PRICING
-- ────────────────────────────────────────────────────────────

ALTER TABLE bulk_pricing
    DROP CONSTRAINT IF EXISTS chk_bulk_pricing_quantity;
ALTER TABLE bulk_pricing
    ADD CONSTRAINT chk_bulk_pricing_quantity
    CHECK (min_quantity > 0 AND (max_quantity IS NULL OR max_quantity >= min_quantity));

ALTER TABLE bulk_pricing
    DROP CONSTRAINT IF EXISTS chk_bulk_pricing_unit_price;
ALTER TABLE bulk_pricing
    ADD CONSTRAINT chk_bulk_pricing_unit_price
    CHECK (unit_price > 0);
