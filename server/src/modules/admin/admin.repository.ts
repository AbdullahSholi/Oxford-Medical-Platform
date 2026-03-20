import { PrismaClient } from '@prisma/client';
import { getSkip } from '../../shared/utils/pagination';

export class AdminRepository {
    constructor(private prisma: PrismaClient) { }

    // ── Dashboard ───────────────────────────────────────
    async getDashboardStats() {
        const [
            totalDoctors,
            pendingDoctors,
            totalProducts,
            totalOrders,
            pendingOrders,
            revenueResult,
        ] = await Promise.all([
            this.prisma.doctor.count(),
            this.prisma.doctor.count({ where: { status: 'pending' } }),
            this.prisma.product.count({ where: { isActive: true } }),
            this.prisma.order.count(),
            this.prisma.order.count({ where: { status: 'pending' } }),
            this.prisma.order.aggregate({
                _sum: { total: true },
                where: { status: { in: ['delivered'] } },
            }),
        ]);

        return {
            totalDoctors,
            pendingDoctors,
            totalProducts,
            totalOrders,
            pendingOrders,
            totalRevenue: revenueResult._sum.total || 0,
        };
    }

    async getRecentOrders(limit = 10) {
        return this.prisma.order.findMany({
            take: limit,
            orderBy: { createdAt: 'desc' },
            include: {
                doctor: { select: { fullName: true, email: true } },
            },
        });
    }

    // ── Doctor Management ───────────────────────────────
    async findDoctors(page: number, limit: number, status?: string) {
        const skip = getSkip(page, limit);
        const where = status ? { status: status as any } : {};
        const [data, total] = await Promise.all([
            this.prisma.doctor.findMany({
                where,
                select: {
                    id: true,
                    fullName: true,
                    email: true,
                    phone: true,
                    clinicName: true,
                    specialty: true,
                    city: true,
                    status: true,
                    licenseUrl: true,
                    createdAt: true,
                },
                orderBy: { createdAt: 'desc' },
                skip,
                take: limit,
            }),
            this.prisma.doctor.count({ where }),
        ]);
        return { data, total };
    }

    async findDoctorById(id: string) {
        return this.prisma.doctor.findUnique({
            where: { id },
            include: {
                addresses: true,
                _count: { select: { orders: true, reviews: true } },
            },
        });
    }

    async approveDoctor(id: string, adminId: string) {
        return this.prisma.doctor.update({
            where: { id },
            data: {
                status: 'approved',
                approvedAt: new Date(),
                approvedBy: adminId,
            },
        });
    }

    async rejectDoctor(id: string, reason: string) {
        return this.prisma.doctor.update({
            where: { id },
            data: {
                status: 'rejected',
                rejectionReason: reason,
            },
        });
    }

    async suspendDoctor(id: string) {
        return this.prisma.doctor.update({
            where: { id },
            data: { status: 'suspended' },
        });
    }

    // ── Discount Management ─────────────────────────────
    async findDiscounts(page: number, limit: number) {
        const skip = getSkip(page, limit);
        const [data, total] = await Promise.all([
            this.prisma.discount.findMany({
                orderBy: { createdAt: 'desc' },
                skip,
                take: limit,
            }),
            this.prisma.discount.count(),
        ]);
        return { data, total };
    }

    async findDiscountById(id: string) {
        return this.prisma.discount.findUnique({ where: { id } });
    }

    async createDiscount(data: any) {
        return this.prisma.discount.create({ data });
    }

    async updateDiscount(id: string, data: any) {
        return this.prisma.discount.update({ where: { id }, data });
    }

    // ── Flash Sale Management ───────────────────────────
    async findFlashSales(page: number, limit: number) {
        const skip = getSkip(page, limit);
        const [data, total] = await Promise.all([
            this.prisma.flashSale.findMany({
                include: {
                    products: {
                        include: {
                            product: {
                                select: { id: true, name: true, price: true, stock: true },
                            },
                        },
                    },
                },
                orderBy: { startsAt: 'desc' },
                skip,
                take: limit,
            }),
            this.prisma.flashSale.count(),
        ]);
        return { data, total };
    }

    async createFlashSale(data: {
        title: string;
        bannerUrl?: string;
        startsAt: Date;
        endsAt: Date;
        products: Array<{ productId: string; flashPrice: number; flashStock: number }>;
    }) {
        return this.prisma.flashSale.create({
            data: {
                title: data.title,
                bannerUrl: data.bannerUrl,
                startsAt: data.startsAt,
                endsAt: data.endsAt,
                products: {
                    create: data.products.map(p => ({
                        productId: p.productId,
                        flashPrice: p.flashPrice,
                        flashStock: p.flashStock,
                    })),
                },
            },
            include: { products: true },
        });
    }

    // ── Reports ─────────────────────────────────────────
    async getRevenueReport(startDate: Date, endDate: Date) {
        return this.prisma.order.groupBy({
            by: ['status'],
            _sum: { total: true, subtotal: true, discountAmount: true },
            _count: { id: true },
            where: {
                createdAt: { gte: startDate, lte: endDate },
            },
        });
    }

    async getTopProducts(limit = 10) {
        return this.prisma.product.findMany({
            select: {
                id: true,
                name: true,
                sku: true,
                price: true,
                totalSold: true,
                stock: true,
                avgRating: true,
            },
            orderBy: { totalSold: 'desc' },
            take: limit,
        });
    }

    async getDoctorStats() {
        const byStatus = await this.prisma.doctor.groupBy({
            by: ['status'],
            _count: { id: true },
        });
        const byCity = await this.prisma.doctor.groupBy({
            by: ['city'],
            _count: { id: true },
            orderBy: { _count: { id: 'desc' } },
            take: 10,
        });
        return { byStatus, byCity };
    }
}
