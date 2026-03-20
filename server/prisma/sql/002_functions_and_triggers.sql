-- ============================================================
-- MedOrder — Database Functions & Triggers
-- Run AFTER Prisma migrate
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- 1. AUTO-UPDATE updated_at TRIGGER
--    Prisma @updatedAt handles this at the ORM level, but this
--    trigger provides a safety net for any raw SQL updates that
--    bypass Prisma.
-- ────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to all tables that have updated_at
DO $$
DECLARE
    tbl_name TEXT;
    trigger_name TEXT;
BEGIN
    FOR tbl_name IN
        SELECT table_name
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND column_name = 'updated_at'
          AND table_name NOT LIKE '_prisma%'
    LOOP
        trigger_name := 'trg_' || tbl_name || '_updated_at';
        
        -- Drop if exists, then recreate
        EXECUTE format(
            'DROP TRIGGER IF EXISTS %I ON %I',
            trigger_name, tbl_name
        );
        EXECUTE format(
            'CREATE TRIGGER %I BEFORE UPDATE ON %I FOR EACH ROW EXECUTE FUNCTION update_updated_at()',
            trigger_name, tbl_name
        );
        
        RAISE NOTICE 'Created trigger % on %', trigger_name, tbl_name;
    END LOOP;
END $$;

-- ────────────────────────────────────────────────────────────
-- 2. FULL-TEXT SEARCH TRIGGER FOR PRODUCTS
--    Auto-populates search_vector with weighted tsvector on
--    INSERT/UPDATE of searchable columns.
--    Weights: A = name/sku (highest), B = description, C = manufacturer
-- ────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION products_search_trigger()
RETURNS TRIGGER AS $$
BEGIN
    NEW.search_vector :=
        setweight(to_tsvector('english', COALESCE(NEW.name, '')), 'A') ||
        setweight(to_tsvector('english', COALESCE(NEW.description, '')), 'B') ||
        setweight(to_tsvector('english', COALESCE(NEW.sku, '')), 'A') ||
        setweight(to_tsvector('english', COALESCE(NEW.medical_details->>'manufacturer', '')), 'C');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_products_search ON products;
CREATE TRIGGER trg_products_search
    BEFORE INSERT OR UPDATE OF name, description, sku, medical_details
    ON products
    FOR EACH ROW
    EXECUTE FUNCTION products_search_trigger();

-- Populate search_vector for existing rows
UPDATE products SET search_vector =
    setweight(to_tsvector('english', COALESCE(name, '')), 'A') ||
    setweight(to_tsvector('english', COALESCE(description, '')), 'B') ||
    setweight(to_tsvector('english', COALESCE(sku, '')), 'A') ||
    setweight(to_tsvector('english', COALESCE(medical_details->>'manufacturer', '')), 'C')
WHERE search_vector IS NULL;

-- ────────────────────────────────────────────────────────────
-- 3. REVIEW RATING RECALCULATION TRIGGER
--    Automatically recalculates avg_rating and review_count
--    on the products table after review INSERT/UPDATE/DELETE.
-- ────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION recalculate_product_rating()
RETURNS TRIGGER AS $$
DECLARE
    target_product_id UUID;
BEGIN
    -- Determine which product to recalculate
    IF TG_OP = 'DELETE' THEN
        target_product_id := OLD.product_id;
    ELSE
        target_product_id := NEW.product_id;
    END IF;

    UPDATE products
    SET avg_rating = COALESCE(
            (SELECT ROUND(AVG(rating)::numeric, 1)
             FROM reviews
             WHERE product_id = target_product_id AND is_visible = true),
            0.0
        ),
        review_count = (
            SELECT COUNT(*)
            FROM reviews
            WHERE product_id = target_product_id AND is_visible = true
        )
    WHERE id = target_product_id;

    -- Handle case where product_id changed (UPDATE)
    IF TG_OP = 'UPDATE' AND OLD.product_id != NEW.product_id THEN
        UPDATE products
        SET avg_rating = COALESCE(
                (SELECT ROUND(AVG(rating)::numeric, 1)
                 FROM reviews
                 WHERE product_id = OLD.product_id AND is_visible = true),
                0.0
            ),
            review_count = (
                SELECT COUNT(*)
                FROM reviews
                WHERE product_id = OLD.product_id AND is_visible = true
            )
        WHERE id = OLD.product_id;
    END IF;

    RETURN NULL;  -- After trigger, return value is ignored
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_reviews_rating ON reviews;
CREATE TRIGGER trg_reviews_rating
    AFTER INSERT OR UPDATE OR DELETE ON reviews
    FOR EACH ROW
    EXECUTE FUNCTION recalculate_product_rating();

-- ────────────────────────────────────────────────────────────
-- 4. STOCK ALERT TRIGGER
--    Fires when product stock goes from 0 → positive,
--    marks pending stock_alerts for notification.
-- ────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION check_stock_alerts()
RETURNS TRIGGER AS $$
BEGIN
    -- Product came back in stock
    IF OLD.stock = 0 AND NEW.stock > 0 THEN
        UPDATE stock_alerts
        SET is_notified = false
        WHERE product_id = NEW.id AND is_notified = true;
        -- The application job will pick these up and send notifications
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_stock_alerts ON products;
CREATE TRIGGER trg_stock_alerts
    AFTER UPDATE OF stock ON products
    FOR EACH ROW
    WHEN (OLD.stock = 0 AND NEW.stock > 0)
    EXECUTE FUNCTION check_stock_alerts();

RAISE NOTICE '✅ All functions and triggers created successfully';
