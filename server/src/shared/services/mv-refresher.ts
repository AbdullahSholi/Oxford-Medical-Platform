// ═══════════════════════════════════════════════════════════
// MedOrder — Materialized View Refresh Service
// Periodically refreshes pre-computed materialized views
// for admin dashboard and reporting queries.
// ═══════════════════════════════════════════════════════════

import { PrismaClient } from '@prisma/client';
import { logger } from '../../config/logger';

/** Refresh interval presets in milliseconds */
const REFRESH_INTERVALS = {
    DASHBOARD: 5 * 60 * 1000,     // Every 5 minutes
    TOP_PRODUCTS: 60 * 60 * 1000, // Every 1 hour
    DAILY_REVENUE: 6 * 60 * 60 * 1000, // Every 6 hours
} as const;

/**
 * Materialized View Refresher
 *
 * Manages periodic refresh of PostgreSQL materialized views
 * used for dashboard analytics. Uses CONCURRENTLY to avoid
 * blocking reads during refresh.
 */
export class MaterializedViewRefresher {
    private intervals: NodeJS.Timeout[] = [];
    private isRunning = false;

    constructor(private prisma: PrismaClient) { }

    /**
     * Start periodic refresh of all materialized views.
     * Call this during application startup.
     */
    start(): void {
        if (this.isRunning) return;
        this.isRunning = true;

        logger.info('[MV Refresher] Starting periodic materialized view refresh');

        // Initial refresh (delay 30s after startup to let DB stabilize)
        setTimeout(() => this.refreshAll(), 30_000);

        // Schedule periodic refreshes
        this.intervals.push(
            setInterval(() => this.refreshDashboard(), REFRESH_INTERVALS.DASHBOARD),
            setInterval(() => this.refreshTopProducts(), REFRESH_INTERVALS.TOP_PRODUCTS),
            setInterval(() => this.refreshDailyRevenue(), REFRESH_INTERVALS.DAILY_REVENUE),
        );
    }

    /**
     * Stop all periodic refresh intervals.
     * Call during graceful shutdown.
     */
    stop(): void {
        this.isRunning = false;
        for (const interval of this.intervals) {
            clearInterval(interval);
        }
        this.intervals = [];
        logger.info('[MV Refresher] Stopped');
    }

    /**
     * Refresh all materialized views.
     * Can also be called on-demand (e.g., after bulk import).
     */
    async refreshAll(): Promise<void> {
        const start = Date.now();
        try {
            await Promise.allSettled([
                this.refreshDashboard(),
                this.refreshTopProducts(),
                this.refreshDailyRevenue(),
            ]);
            logger.info(`[MV Refresher] All views refreshed in ${Date.now() - start}ms`);
        } catch (error) {
            logger.error({ err: error }, '[MV Refresher] Failed to refresh all views');
        }
    }

    /** Refresh the dashboard summary view */
    async refreshDashboard(): Promise<void> {
        try {
            await this.prisma.$executeRawUnsafe(
                'REFRESH MATERIALIZED VIEW CONCURRENTLY mv_dashboard_summary',
            );
        } catch (error: any) {
            // View might not exist yet if bootstrap hasn't run
            if (error.code !== '42P01') {
                logger.error({ err: error }, '[MV Refresher] dashboard refresh failed');
            }
        }
    }

    /** Refresh the top products view */
    async refreshTopProducts(): Promise<void> {
        try {
            await this.prisma.$executeRawUnsafe(
                'REFRESH MATERIALIZED VIEW CONCURRENTLY mv_top_products',
            );
        } catch (error: any) {
            if (error.code !== '42P01') {
                logger.error({ err: error }, '[MV Refresher] top_products refresh failed');
            }
        }
    }

    /** Refresh the daily revenue view */
    async refreshDailyRevenue(): Promise<void> {
        try {
            await this.prisma.$executeRawUnsafe(
                'REFRESH MATERIALIZED VIEW CONCURRENTLY mv_daily_revenue',
            );
        } catch (error: any) {
            if (error.code !== '42P01') {
                logger.error({ err: error }, '[MV Refresher] daily_revenue refresh failed');
            }
        }
    }

    /**
     * Read dashboard stats from the materialized view.
     * Returns cached data for near-instant dashboard loading.
     */
    async getDashboardFromView(): Promise<Record<string, unknown> | null> {
        try {
            const rows = await this.prisma.$queryRawUnsafe<Record<string, unknown>[]>(
                'SELECT * FROM mv_dashboard_summary LIMIT 1',
            );
            return rows[0] ?? null;
        } catch {
            return null; // View doesn't exist, fallback to live query
        }
    }

    /**
     * Read top products from the materialized view.
     */
    async getTopProductsFromView(limit = 20): Promise<Record<string, unknown>[]> {
        try {
            return this.prisma.$queryRawUnsafe<Record<string, unknown>[]>(
                `SELECT * FROM mv_top_products LIMIT $1`,
                limit,
            );
        } catch {
            return []; // View doesn't exist
        }
    }

    /**
     * Read daily revenue from the materialized view.
     */
    async getDailyRevenueFromView(days = 30): Promise<Record<string, unknown>[]> {
        try {
            return this.prisma.$queryRawUnsafe<Record<string, unknown>[]>(
                `SELECT * FROM mv_daily_revenue WHERE order_date >= CURRENT_DATE - $1 ORDER BY order_date DESC`,
                days,
            );
        } catch {
            return []; // View doesn't exist
        }
    }
}
