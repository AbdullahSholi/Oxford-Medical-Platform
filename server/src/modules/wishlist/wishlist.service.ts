import { PrismaClient } from '@prisma/client';
import { AppError } from '../../shared/utils/api-error';
import { getPaginationMeta } from '../../shared/utils/pagination';
import { WishlistRepository } from './wishlist.repository';

export class WishlistService {
    constructor(
        private repo: WishlistRepository,
        private prisma: PrismaClient,
    ) { }

    async getWishlist(doctorId: string, page = 1, limit = 20) {
        const { data, total } = await this.repo.findByDoctor(doctorId, page, limit);
        return { data, meta: getPaginationMeta(total, page, limit) };
    }

    async addToWishlist(doctorId: string, productId: string) {
        // Verify product exists
        const product = await this.prisma.product.findUnique({
            where: { id: productId },
            select: { id: true, isActive: true },
        });
        if (!product || !product.isActive) throw AppError.notFound('Product');

        // Check if already in wishlist
        const existing = await this.repo.findByDoctorAndProduct(doctorId, productId);
        if (existing) throw AppError.conflict('Product already in wishlist');

        return this.repo.add(doctorId, productId);
    }

    async removeFromWishlist(doctorId: string, productId: string) {
        const existing = await this.repo.findByDoctorAndProduct(doctorId, productId);
        if (!existing) throw AppError.notFound('Wishlist item');
        return this.repo.remove(doctorId, productId);
    }
}
