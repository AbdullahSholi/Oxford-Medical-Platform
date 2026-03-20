import redis from '../../config/redis';
import { logger } from '../../config/logger';

export class CacheService {
    /**
     * Get cached value or fetch from source and cache it.
     */
    static async getOrSet<T>(key: string, ttlSeconds: number, fetcher: () => Promise<T>): Promise<T> {
        try {
            const cached = await redis.get(key);
            if (cached) return JSON.parse(cached) as T;
        } catch (e) {
            logger.warn({ err: e }, `Cache read failed for key: ${key}`);
        }

        const data = await fetcher();

        try {
            await redis.setex(key, ttlSeconds, JSON.stringify(data));
        } catch (e) {
            logger.warn({ err: e }, `Cache write failed for key: ${key}`);
        }

        return data;
    }

    /**
     * Invalidate cache keys by pattern prefix.
     */
    static async invalidate(...patterns: string[]): Promise<void> {
        try {
            for (const pattern of patterns) {
                const keys = await redis.keys(`${pattern}*`);
                if (keys.length > 0) {
                    await redis.del(...keys);
                }
            }
        } catch (e) {
            logger.warn({ err: e }, 'Cache invalidation failed');
        }
    }
}

// Cache key constants
export const CacheKeys = {
    ACTIVE_BANNERS: 'cache:banners:active',
    ALL_BANNERS: 'cache:banners:all',
    CATEGORIES: 'cache:categories',
    DASHBOARD_STATS: 'cache:dashboard:stats',
} as const;

// TTLs in seconds
export const CacheTTL = {
    BANNERS: 300,        // 5 minutes
    CATEGORIES: 1800,    // 30 minutes
    DASHBOARD: 120,      // 2 minutes
} as const;
