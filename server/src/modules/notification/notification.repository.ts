import { PrismaClient, NotificationType } from '@prisma/client';
import { getSkip } from '../../shared/utils/pagination';

export class NotificationRepository {
    constructor(private prisma: PrismaClient) { }

    async findByDoctor(doctorId: string, page: number, limit: number) {
        const skip = getSkip(page, limit);
        const [data, total] = await Promise.all([
            this.prisma.notification.findMany({
                where: { doctorId },
                orderBy: { createdAt: 'desc' },
                skip,
                take: limit,
            }),
            this.prisma.notification.count({ where: { doctorId } }),
        ]);
        return { data, total };
    }

    async findById(id: string) {
        return this.prisma.notification.findUnique({ where: { id } });
    }

    async getUnreadCount(doctorId: string): Promise<number> {
        return this.prisma.notification.count({
            where: { doctorId, isRead: false },
        });
    }

    async markAsRead(id: string) {
        return this.prisma.notification.update({
            where: { id },
            data: { isRead: true },
        });
    }

    async markAllAsRead(doctorId: string) {
        return this.prisma.notification.updateMany({
            where: { doctorId, isRead: false },
            data: { isRead: true },
        });
    }

    async create(data: {
        doctorId: string;
        type: NotificationType;
        title: string;
        body: string;
        data?: any;
    }) {
        return this.prisma.notification.create({ data });
    }

    async delete(id: string) {
        return this.prisma.notification.delete({ where: { id } });
    }
}
