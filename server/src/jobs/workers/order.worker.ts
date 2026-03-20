// ═══════════════════════════════════════════════════════════
// MedOrder — Order Worker (BullMQ)
// Processes: new order confirmation, expired order cleanup
// ═══════════════════════════════════════════════════════════

import { Worker, Job } from 'bullmq';
import { env } from '../../config/env';
import { logger } from '../../config/logger';
import { OrderJobs } from '../queues';

const connection = { url: env.REDIS_URL };

export const orderWorker = new Worker(
    'orders',
    async (job: Job) => {
        switch (job.name) {
            case OrderJobs.PROCESS_NEW:
                await handleProcessNewOrder(job.data);
                break;
            case OrderJobs.CANCEL_EXPIRED:
                await handleCancelExpired(job.data);
                break;
            case OrderJobs.GENERATE_INVOICE:
                await handleGenerateInvoice(job.data);
                break;
            default:
                logger.warn({ jobName: job.name }, 'Unknown order job type');
        }
    },
    {
        connection,
        concurrency: 3,
    },
);

orderWorker.on('completed', (job) => {
    logger.info({ jobId: job.id, name: job.name }, 'Order job completed');
});

orderWorker.on('failed', (job, err) => {
    logger.error({ jobId: job?.id, name: job?.name, err }, 'Order job failed');
});

async function handleProcessNewOrder(data: any): Promise<void> {
    logger.info({ orderId: data.orderId }, 'Processing new order confirmation');
}

async function handleCancelExpired(data: any): Promise<void> {
    logger.info('Running expired order cleanup');
}

async function handleGenerateInvoice(data: any): Promise<void> {
    logger.info({ orderId: data.orderId }, 'Generating invoice PDF');
}

logger.info('📦 Order worker started');
