-- ============================================================
-- MedOrder — Monitoring & Operations Queries
-- Run these ad-hoc for diagnostics. NOT part of migrations.
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- 1. LOCK CONTENTION: Current lock waits
--    Run during load testing to find bottlenecks.
-- ────────────────────────────────────────────────────────────

-- Active lock waits (who is blocking whom)
SELECT
    blocked_locks.pid            AS blocked_pid,
    blocked_activity.usename     AS blocked_user,
    blocked_activity.query       AS blocked_query,
    blocked_activity.wait_event  AS blocked_wait_event,
    blocking_locks.pid           AS blocking_pid,
    blocking_activity.usename    AS blocking_user,
    blocking_activity.query      AS blocking_query,
    blocking_activity.state      AS blocking_state,
    NOW() - blocked_activity.query_start AS blocked_duration
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

-- ────────────────────────────────────────────────────────────
-- 2. DEADLOCK COUNT (since last stats reset)
-- ────────────────────────────────────────────────────────────

SELECT
    datname,
    deadlocks,
    conflicts,
    blk_read_time,
    blk_write_time
FROM pg_stat_database
WHERE datname = 'medorder';

-- ────────────────────────────────────────────────────────────
-- 3. TABLE BLOAT & VACUUM STATUS
--    Identify tables needing VACUUM or REINDEX.
-- ────────────────────────────────────────────────────────────

SELECT
    schemaname,
    relname AS table_name,
    n_live_tup AS live_tuples,
    n_dead_tup AS dead_tuples,
    CASE WHEN n_live_tup > 0
        THEN ROUND(100.0 * n_dead_tup / n_live_tup, 2)
        ELSE 0
    END AS dead_ratio_pct,
    last_vacuum,
    last_autovacuum,
    last_analyze,
    last_autoanalyze
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY n_dead_tup DESC
LIMIT 20;

-- ────────────────────────────────────────────────────────────
-- 4. INDEX USAGE STATS
--    Find unused indexes (candidates for removal).
-- ────────────────────────────────────────────────────────────

SELECT
    schemaname,
    relname AS table_name,
    indexrelname AS index_name,
    idx_scan AS times_used,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_scan ASC
LIMIT 30;

-- ────────────────────────────────────────────────────────────
-- 5. SLOW QUERIES (requires pg_stat_statements extension)
-- ────────────────────────────────────────────────────────────

-- Uncomment after enabling pg_stat_statements:
-- SELECT
--     calls,
--     ROUND(total_exec_time::numeric, 2) AS total_time_ms,
--     ROUND(mean_exec_time::numeric, 2) AS avg_time_ms,
--     ROUND(max_exec_time::numeric, 2) AS max_time_ms,
--     rows,
--     LEFT(query, 200) AS query_preview
-- FROM pg_stat_statements
-- ORDER BY mean_exec_time DESC
-- LIMIT 20;

-- ────────────────────────────────────────────────────────────
-- 6. CONNECTION POOL STATUS
-- ────────────────────────────────────────────────────────────

SELECT
    datname,
    state,
    COUNT(*) AS connections,
    MAX(NOW() - query_start) AS longest_running
FROM pg_stat_activity
WHERE datname = 'medorder'
GROUP BY datname, state
ORDER BY state;

-- ────────────────────────────────────────────────────────────
-- 7. TABLE & INDEX SIZE OVERVIEW
-- ────────────────────────────────────────────────────────────

SELECT
    relname AS table_name,
    pg_size_pretty(pg_total_relation_size(relid)) AS total_size,
    pg_size_pretty(pg_relation_size(relid)) AS data_size,
    pg_size_pretty(pg_total_relation_size(relid) - pg_relation_size(relid)) AS index_size,
    n_live_tup AS row_estimate
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(relid) DESC;

-- ────────────────────────────────────────────────────────────
-- 8. RECOMMENDED postgresql.conf SETTINGS FOR PRODUCTION
-- ────────────────────────────────────────────────────────────
--
-- # Locking
-- lock_timeout = '30s'
-- statement_timeout = '30s'
-- deadlock_timeout = '1s'
-- log_lock_waits = on
--
-- # Memory (adjust based on available RAM)
-- shared_buffers = '256MB'          -- 25% of RAM if ≤1GB, else ~4GB max
-- effective_cache_size = '768MB'    -- 75% of RAM
-- work_mem = '16MB'                 -- per sort/hash operation
-- maintenance_work_mem = '128MB'    -- for VACUUM, CREATE INDEX
--
-- # WAL & Checkpoints
-- wal_buffers = '8MB'
-- checkpoint_completion_target = 0.9
-- min_wal_size = '100MB'
-- max_wal_size = '1GB'
--
-- # Connections
-- max_connections = 100             -- PgBouncer recommended in front
--
-- # Logging
-- log_min_duration_statement = 200  -- Log queries >200ms
-- log_checkpoints = on
-- log_temp_files = 0                -- Log all temp file usage
