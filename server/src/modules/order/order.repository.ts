import { PrismaClient, Prisma, OrderStatus } from '@prisma/client';
import { getSkip } from '../../shared/utils/pagination';

export class OrderRepository {
    constructor(private prisma: PrismaClient) {}

    async findByDoctor(doctorId: string, page: number, limit: number, status?: string) {
        const where: Prisma.OrderWhereInput = {
            doctorId,
            ...(status && { status: status as OrderStatus }),
        };

        const [data, total] = await Promise.all([
            this.prisma.order.findMany({
                where,
                skip: getSkip(page, limit),
                take: limit,
                orderBy: { createdAt: 'desc' },
                include: {
                    items: {
                        include: {
                            product: { select: { id: true, images: { take: 1, orderBy: { sortOrder: 'asc' } } } },
                        },
                    },
                    _count: { select: { items: true } },
                },
            }),
            this.prisma.order.count({ where }),
        ]);

        return { data, total };
    }

    async findById(id: string) {
        return this.prisma.order.findUnique({
            where: { id },
            include: {
                items: {
                    include: {
                        product: { select: { id: true, images: { take: 1, orderBy: { sortOrder: 'asc' } } } },
                    },
                },
                statusHistory: { orderBy: { createdAt: 'desc' }, take: 20 },
                doctor: { select: { id: true, fullName: true, email: true, phone: true } },
            },
        });
    }

    async findAll(page: number, limit: number, status?: string) {
        const where: Prisma.OrderWhereInput = {
            ...(status && { status: status as OrderStatus }),
        };

        const [data, total] = await Promise.all([
            this.prisma.order.findMany({
                where,
                skip: getSkip(page, limit),
                take: limit,
                orderBy: { createdAt: 'desc' },
                include: {
                    doctor: { select: { id: true, fullName: true, email: true } },
                    items: true,
                    _count: { select: { items: true } },
                },
            }),
            this.prisma.order.count({ where }),
        ]);

        return { data, total };
    }

    async getLastOrderNumber(): Promise<string | null> {
        const last = await this.prisma.order.findFirst({
            orderBy: { createdAt: 'desc' },
            select: { orderNumber: true },
        });
        return last?.orderNumber ?? null;
    }
}
