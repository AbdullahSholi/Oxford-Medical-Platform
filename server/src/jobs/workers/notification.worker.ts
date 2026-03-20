// ═══════════════════════════════════════════════════════════
// MedOrder — Notification Worker (BullMQ)
// Processes: push notifications, SMS, email
// ═══════════════════════════════════════════════════════════

import { Worker, Job } from 'bullmq';
import { env } from '../../config/env';
import { logger } from '../../config/logger';
import { NotificationJobs } from '../queues';
import prisma from '../../config/database';
import { NotificationType } from '@prisma/client';
import { emitToUser } from '../../websocket/socket';

const connection = { url: env.REDIS_URL };

export const notificationWorker = new Worker(
    'notifications',
    async (job: Job) => {
        switch (job.name) {
            case NotificationJobs.SEND_PUSH:
                await handleSendPush(job.data);
                break;
            case NotificationJobs.SEND_SMS:
                await handleSendSms(job.data);
                break;
            case NotificationJobs.SEND_EMAIL:
                await handleSendEmail(job.data);
                break;
            default:
                logger.warn({ jobName: job.name }, 'Unknown notification job type');
        }
    },
    {
        connection,
        concurrency: 5,
    },
);

notificationWorker.on('completed', (job) => {
    logger.info({ jobId: job.id, name: job.name }, 'Notification job completed');
});

notificationWorker.on('failed', (job, err) => {
    logger.error({ jobId: job?.id, name: job?.name, err }, 'Notification job failed');
});

async function handleSendPush(data: any): Promise<void> {
    logger.info({ userId: data.userId, title: data.title }, 'Sending push notification');

    // Persist notification to database
    const notification = await prisma.notification.create({
        data: {
            doctorId: data.userId,
            type: (data.type as NotificationType) || 'order',
            title: data.title,
            body: data.body,
            data: data.data || {},
        },
    });

    // Emit real-time notification via Socket.io
    emitToUser(data.userId, 'notification:new', notification);

    logger.info({ notificationId: notification.id }, 'Push notification persisted and emitted');
}

async function handleSendSms(data: any): Promise<void> {
    logger.info({ phone: data.phone }, 'Sending SMS');
}

async function handleSendEmail(data: any): Promise<void> {
    logger.info({ email: data.email, subject: data.subject }, 'Sending email');
}

logger.info('🔔 Notification worker started');
