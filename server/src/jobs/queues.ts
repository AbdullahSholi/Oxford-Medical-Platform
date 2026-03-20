// ═══════════════════════════════════════════════════════════
// MedOrder — BullMQ Job Queue Definitions
// Queues: notifications, orders, media, flash-sales, reports
// ═══════════════════════════════════════════════════════════

import { Queue } from 'bullmq';
import { env } from '../config/env';
import { logger } from '../config/logger';

// BullMQ works with a Redis connection URL directly
const connection = { url: env.REDIS_URL };

// ── Queue Definitions ───────────────────────────────────
export const notificationQueue = new Queue('notifications', {
    connection,
    defaultJobOptions: {
        removeOnComplete: { count: 1000 },
        removeOnFail: { count: 5000 },
        attempts: 3,
        backoff: { type: 'exponential', delay: 2000 },
    },
});

export const orderQueue = new Queue('orders', {
    connection,
    defaultJobOptions: {
        removeOnComplete: { count: 500 },
        removeOnFail: { count: 2000 },
        attempts: 3,
        backoff: { type: 'exponential', delay: 3000 },
    },
});

export const mediaQueue = new Queue('media', {
    connection,
    defaultJobOptions: {
        removeOnComplete: { count: 200 },
        removeOnFail: { count: 500 },
        attempts: 2,
        backoff: { type: 'fixed', delay: 5000 },
    },
});

export const flashSaleQueue = new Queue('flash-sales', {
    connection,
    defaultJobOptions: {
        removeOnComplete: { count: 100 },
        removeOnFail: { count: 200 },
        attempts: 3,
        backoff: { type: 'exponential', delay: 1000 },
    },
});

export const reportQueue = new Queue('reports', {
    connection,
    defaultJobOptions: {
        removeOnComplete: { count: 50 },
        removeOnFail: { count: 100 },
        attempts: 2,
        backoff: { type: 'fixed', delay: 10000 },
    },
});

// ── Job Type Enums ──────────────────────────────────────
export const NotificationJobs = {
    SEND_PUSH: 'send-push',
    SEND_SMS: 'send-sms',
    SEND_EMAIL: 'send-email',
} as const;

export const OrderJobs = {
    PROCESS_NEW: 'process-new-order',
    CANCEL_EXPIRED: 'cancel-expired',
    GENERATE_INVOICE: 'generate-invoice',
} as const;

export const MediaJobs = {
    PROCESS_IMAGE: 'process-image',
    PROCESS_LICENSE: 'process-license',
} as const;

export const FlashSaleJobs = {
    ACTIVATE: 'activate-sale',
    DEACTIVATE: 'deactivate-sale',
    RESTORE_STOCK: 'restore-stock',
} as const;

export const ReportJobs = {
    GENERATE: 'generate-report',
} as const;

logger.info('📋 BullMQ queues initialized: notifications, orders, media, flash-sales, reports');
