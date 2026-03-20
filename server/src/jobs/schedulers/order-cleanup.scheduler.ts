// ═══════════════════════════════════════════════════════════
// MedOrder — Order Cleanup Scheduler
// Auto-cancels pending orders older than 24 hours
// ═══════════════════════════════════════════════════════════

import prisma from '../../config/database';
import { logger } from '../../config/logger';
import { orderQueue, OrderJobs } from '../queues';

/**
 * Finds expired pending orders (older than 24h) and queues cancellation jobs.
 * Should be run periodically (e.g., every hour).
 */
export async function scheduleOrderCleanup(): Promise<void> {
    const expiryThreshold = new Date(Date.now() - 24 * 60 * 60 * 1000); // 24 hours ago

    const expiredOrders = await prisma.order.findMany({
        where: {
            status: 'pending',
            createdAt: {
                lt: expiryThreshold,
            },
        },
        select: { id: true, orderNumber: true },
    });

    if (expiredOrders.length > 0) {
        logger.info(`Found ${expiredOrders.length} expired pending orders`);

        for (const order of expiredOrders) {
            await orderQueue.add(
                OrderJobs.CANCEL_EXPIRED,
                { orderId: order.id, orderNumber: order.orderNumber },
                { jobId: `cancel-expired-${order.id}` },
            );
        }
    }
}
