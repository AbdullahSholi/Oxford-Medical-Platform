-- ============================================================
-- MedOrder — PostgreSQL Extensions
-- Run: psql -f 001_extensions.sql
-- Requires superuser or extension creation privileges
-- ============================================================

-- UUID generation (used by DEFAULT uuid_generate_v4())
-- NOTE: Prisma uses gen_random_uuid() in newer versions, but uuid-ossp
-- is still needed for any raw SQL that references uuid_generate_v4()
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Trigram-based fuzzy search (enables LIKE '%term%' with index support
-- and pg_trgm similarity scoring)
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Extends GIN index to cover btree-opclass data types (varchar, int, etc.)
-- Enables composite GIN indexes that mix JSONB with plain columns
CREATE EXTENSION IF NOT EXISTS "btree_gin";

-- Verify installation
DO $$
BEGIN
    RAISE NOTICE 'Extensions installed: uuid-ossp=%, pg_trgm=%, btree_gin=%',
        (SELECT installed_version FROM pg_available_extensions WHERE name = 'uuid-ossp'),
        (SELECT installed_version FROM pg_available_extensions WHERE name = 'pg_trgm'),
        (SELECT installed_version FROM pg_available_extensions WHERE name = 'btree_gin');
END $$;
