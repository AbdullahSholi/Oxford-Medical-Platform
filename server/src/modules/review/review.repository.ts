import { PrismaClient } from '@prisma/client';

export class ReviewRepository {
    constructor(private prisma: PrismaClient) {}

    async findByDoctorAndProduct(doctorId: string, productId: string) {
        return this.prisma.review.findUnique({
            where: { doctorId_productId: { doctorId, productId } },
        });
    }

    async findById(id: string) {
        return this.prisma.review.findUnique({ where: { id } });
    }

    async create(data: {
        productId: string;
        doctorId: string;
        orderItemId?: string;
        rating: number;
        title?: string;
        body?: string;
        isVerified: boolean;
    }) {
        const review = await this.prisma.review.create({ data });

        // Update product avg rating
        const stats = await this.prisma.review.aggregate({
            where: { productId: data.productId, isVisible: true },
            _avg: { rating: true },
            _count: { rating: true },
        });

        await this.prisma.product.update({
            where: { id: data.productId },
            data: {
                avgRating: stats._avg.rating ?? 0,
                reviewCount: stats._count.rating,
            },
        });

        return review;
    }

    async update(id: string, data: { rating?: number; title?: string; body?: string }) {
        const review = await this.prisma.review.update({
            where: { id },
            data,
        });

        // Recalculate avg
        const stats = await this.prisma.review.aggregate({
            where: { productId: review.productId, isVisible: true },
            _avg: { rating: true },
            _count: { rating: true },
        });
        await this.prisma.product.update({
            where: { id: review.productId },
            data: { avgRating: stats._avg.rating ?? 0, reviewCount: stats._count.rating },
        });

        return review;
    }

    async delete(id: string, productId: string) {
        await this.prisma.review.delete({ where: { id } });

        const stats = await this.prisma.review.aggregate({
            where: { productId, isVisible: true },
            _avg: { rating: true },
            _count: { rating: true },
        });
        await this.prisma.product.update({
            where: { id: productId },
            data: { avgRating: stats._avg.rating ?? 0, reviewCount: stats._count.rating },
        });
    }
}
