import { Router } from 'express';
import { authenticate } from '../../shared/middleware/authenticate';
import { asyncHandler } from '../../shared/utils/async-handler';
import { ApiResponse } from '../../shared/utils/api-response';
import { NotificationController } from './notification.controller';
import { NotificationService } from './notification.service';
import { NotificationRepository } from './notification.repository';
import prisma from '../../config/database';

const repo = new NotificationRepository(prisma);
const service = new NotificationService(repo);
const controller = new NotificationController(service);

export const notificationRoutes = Router();
notificationRoutes.use(authenticate);

notificationRoutes.get('/', asyncHandler(controller.getAll));
notificationRoutes.patch('/:id/read', asyncHandler(controller.markRead));
notificationRoutes.post('/read-all', asyncHandler(controller.markAllRead));
notificationRoutes.delete('/:id', asyncHandler(controller.remove));

notificationRoutes.post(
    '/fcm-token',
    asyncHandler(async (req, res) => {
        const { fcmToken } = req.body;
        if (!fcmToken || typeof fcmToken !== 'string') {
            res.status(400).json({ success: false, error: { code: 'BAD_REQUEST', message: 'fcmToken is required' } });
            return;
        }
        await prisma.doctor.update({
            where: { id: req.user!.id },
            data: { fcmToken },
        });
        ApiResponse.success(res, { message: 'FCM token registered' });
    }),
);
