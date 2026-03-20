import { PrismaClient } from '@prisma/client';
import { AppError } from '../../shared/utils/api-error';
import { ReviewRepository } from './review.repository';
import { CreateReviewInput, UpdateReviewInput } from './review.schema';

export class ReviewService {
    constructor(
        private repo: ReviewRepository,
        private prisma: PrismaClient,
    ) {}

    async createReview(doctorId: string, input: CreateReviewInput) {
        // Check for duplicate review
        const existing = await this.repo.findByDoctorAndProduct(doctorId, input.productId);
        if (existing) throw AppError.conflict('You have already reviewed this product');

        // Verify product exists
        const product = await this.prisma.product.findUnique({ where: { id: input.productId } });
        if (!product) throw AppError.notFound('Product');

        // Check if doctor has purchased this product (verified review)
        let isVerified = false;
        if (input.orderItemId) {
            const orderItem = await this.prisma.orderItem.findFirst({
                where: {
                    id: input.orderItemId,
                    productId: input.productId,
                    order: { doctorId, status: 'delivered' },
                },
            });
            isVerified = !!orderItem;
        }

        return this.repo.create({
            productId: input.productId,
            doctorId,
            orderItemId: input.orderItemId,
            rating: input.rating,
            title: input.title,
            body: input.body,
            isVerified,
        });
    }

    async updateReview(doctorId: string, reviewId: string, input: UpdateReviewInput) {
        const review = await this.repo.findById(reviewId);
        if (!review || review.doctorId !== doctorId) throw AppError.notFound('Review');
        return this.repo.update(reviewId, input);
    }

    async deleteReview(doctorId: string, reviewId: string) {
        const review = await this.repo.findById(reviewId);
        if (!review || review.doctorId !== doctorId) throw AppError.notFound('Review');
        await this.repo.delete(reviewId, review.productId);
    }
}
