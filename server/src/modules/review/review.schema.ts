import { z } from 'zod';

export const createReviewSchema = z.object({
    productId: z.string().uuid(),
    orderItemId: z.string().uuid().optional(),
    rating: z.number().int().min(1).max(5),
    title: z.string().max(200).optional(),
    body: z.string().max(2000).optional(),
});

export const updateReviewSchema = z.object({
    rating: z.number().int().min(1).max(5).optional(),
    title: z.string().max(200).optional(),
    body: z.string().max(2000).optional(),
});

export type CreateReviewInput = z.infer<typeof createReviewSchema>;
export type UpdateReviewInput = z.infer<typeof updateReviewSchema>;
