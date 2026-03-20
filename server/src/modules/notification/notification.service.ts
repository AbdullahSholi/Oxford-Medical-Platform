import { AppError } from '../../shared/utils/api-error';
import { getPaginationMeta } from '../../shared/utils/pagination';
import { NotificationRepository } from './notification.repository';

export class NotificationService {
    constructor(private repo: NotificationRepository) { }

    async getNotifications(doctorId: string, page = 1, limit = 20) {
        const { data, total } = await this.repo.findByDoctor(doctorId, page, limit);
        const unreadCount = await this.repo.getUnreadCount(doctorId);
        return {
            data,
            unreadCount,
            meta: getPaginationMeta(total, page, limit),
        };
    }

    async markAsRead(doctorId: string, notificationId: string) {
        const notification = await this.repo.findById(notificationId);
        if (!notification || notification.doctorId !== doctorId) {
            throw AppError.notFound('Notification');
        }
        return this.repo.markAsRead(notificationId);
    }

    async markAllAsRead(doctorId: string) {
        const result = await this.repo.markAllAsRead(doctorId);
        return { markedCount: result.count };
    }

    async deleteNotification(doctorId: string, notificationId: string) {
        const notification = await this.repo.findById(notificationId);
        if (!notification || notification.doctorId !== doctorId) {
            throw AppError.notFound('Notification');
        }
        await this.repo.delete(notificationId);
    }
}
