// ═══════════════════════════════════════════════════════════
// MedOrder — Flash Sale Scheduler
// Automatically activates/deactivates flash sales at scheduled times
// ═══════════════════════════════════════════════════════════

import { Queue } from 'bullmq';
import { createBullConnection } from '../../config/redis';
import { logger } from '../../config/logger';
import prisma from '../../config/database';
import { flashSaleQueue, FlashSaleJobs } from '../queues';

/**
 * Scans for upcoming flash sales and schedules activation/deactivation jobs.
 * Should be called periodically (e.g., every 5 minutes via a cron job or on server start).
 */
export async function scheduleFlashSales(): Promise<void> {
    const now = new Date();
    const lookAhead = new Date(now.getTime() + 10 * 60 * 1000); // 10 minutes ahead

    // Find sales that should start soon
    const upcomingSales = await prisma.flashSale.findMany({
        where: {
            isActive: false,
            startsAt: {
                gte: now,
                lte: lookAhead,
            },
        },
    });

    for (const sale of upcomingSales) {
        const delay = sale.startsAt.getTime() - now.getTime();
        await flashSaleQueue.add(
            FlashSaleJobs.ACTIVATE,
            { flashSaleId: sale.id },
            { delay, jobId: `activate-${sale.id}` },
        );
        logger.info({ flashSaleId: sale.id, delay }, 'Scheduled flash sale activation');
    }

    // Find sales that should end soon
    const endingSales = await prisma.flashSale.findMany({
        where: {
            isActive: true,
            endsAt: {
                gte: now,
                lte: lookAhead,
            },
        },
    });

    for (const sale of endingSales) {
        const delay = sale.endsAt.getTime() - now.getTime();
        await flashSaleQueue.add(
            FlashSaleJobs.DEACTIVATE,
            { flashSaleId: sale.id },
            { delay, jobId: `deactivate-${sale.id}` },
        );
        logger.info({ flashSaleId: sale.id, delay }, 'Scheduled flash sale deactivation');
    }
}
