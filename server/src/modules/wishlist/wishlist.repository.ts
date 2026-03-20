import { PrismaClient } from '@prisma/client';
import { getSkip } from '../../shared/utils/pagination';

export class WishlistRepository {
    constructor(private prisma: PrismaClient) { }

    async findByDoctor(doctorId: string, page: number, limit: number) {
        const skip = getSkip(page, limit);
        const [data, total] = await Promise.all([
            this.prisma.wishlist.findMany({
                where: { doctorId },
                include: {
                    product: {
                        select: {
                            id: true,
                            name: true,
                            slug: true,
                            price: true,
                            salePrice: true,
                            stock: true,
                            avgRating: true,
                            images: {
                                where: { isPrimary: true },
                                take: 1,
                                select: { url: true, thumbnailUrl: true },
                            },
                        },
                    },
                },
                orderBy: { createdAt: 'desc' },
                skip,
                take: limit,
            }),
            this.prisma.wishlist.count({ where: { doctorId } }),
        ]);
        return { data, total };
    }

    async findByDoctorAndProduct(doctorId: string, productId: string) {
        return this.prisma.wishlist.findUnique({
            where: { doctorId_productId: { doctorId, productId } },
        });
    }

    async add(doctorId: string, productId: string) {
        return this.prisma.wishlist.create({
            data: { doctorId, productId },
        });
    }

    async remove(doctorId: string, productId: string) {
        return this.prisma.wishlist.delete({
            where: { doctorId_productId: { doctorId, productId } },
        });
    }

    async isInWishlist(doctorId: string, productId: string): Promise<boolean> {
        const item = await this.findByDoctorAndProduct(doctorId, productId);
        return !!item;
    }
}
