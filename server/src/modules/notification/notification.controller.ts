import { Request, Response } from 'express';
import { NotificationService } from './notification.service';
import { ApiResponse } from '../../shared/utils/api-response';

export class NotificationController {
    constructor(private service: NotificationService) { }

    getAll = async (req: Request, res: Response): Promise<void> => {
        const page = Number(req.query.page) || 1;
        const limit = Number(req.query.limit) || 20;
        const result = await this.service.getNotifications(req.user!.id, page, limit);
        ApiResponse.success(res, {
            data: result.data,
            meta: { ...result.meta, unreadCount: result.unreadCount },
        });
    };

    markRead = async (req: Request, res: Response): Promise<void> => {
        const notification = await this.service.markAsRead(req.user!.id, req.params.id as string);
        ApiResponse.success(res, { data: notification, message: 'Notification marked as read' });
    };

    markAllRead = async (req: Request, res: Response): Promise<void> => {
        const result = await this.service.markAllAsRead(req.user!.id);
        ApiResponse.success(res, { data: result, message: 'All notifications marked as read' });
    };

    remove = async (req: Request, res: Response): Promise<void> => {
        await this.service.deleteNotification(req.user!.id, req.params.id as string);
        ApiResponse.noContent(res);
    };
}
