// ═══════════════════════════════════════════════════════════
// MedOrder — Redis Client (ioredis)
// Used for: caching, sessions, OTP, BullMQ, real-time counters
// ═══════════════════════════════════════════════════════════

import Redis from 'ioredis';
import { env } from './env';
import { logger } from './logger';

export const redis = new Redis(env.REDIS_URL, {
    maxRetriesPerRequest: null,   // Required for BullMQ
    enableReadyCheck: true,
    retryStrategy(times: number) {
        const delay = Math.min(times * 200, 5000);
        logger.warn(`Redis reconnecting... attempt ${times}, delay ${delay}ms`);
        return delay;
    },
});

redis.on('connect', () => {
    logger.info('✅ Redis connected');
});

redis.on('error', (err) => {
    logger.error({ err }, '❌ Redis connection error');
});

// Separate connection for BullMQ (recommended by BullMQ docs)
export const createBullConnection = () =>
    new Redis(env.REDIS_URL, {
        maxRetriesPerRequest: null,
        enableReadyCheck: true,
    });

export default redis;
