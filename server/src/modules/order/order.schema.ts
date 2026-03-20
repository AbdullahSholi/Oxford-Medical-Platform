import { z } from 'zod';

export const createOrderSchema = z.object({
    addressId: z.string().uuid(),
    discountCode: z.string().max(50).optional(),
    notes: z.string().max(1000).optional(),
});

export const getOrdersQuerySchema = z.object({
    page: z.coerce.number().int().positive().default(1),
    limit: z.coerce.number().int().min(1).max(50).default(20),
    status: z.enum(['pending', 'confirmed', 'processing', 'shipped', 'out_for_delivery', 'delivered', 'cancelled']).optional(),
});

export const cancelOrderSchema = z.object({
    reason: z.string().max(500).optional(),
});

export const updateOrderStatusSchema = z.object({
    status: z.enum(['confirmed', 'processing', 'shipped', 'out_for_delivery', 'delivered', 'cancelled']),
    notes: z.string().max(500).optional(),
});

export type CreateOrderInput = z.infer<typeof createOrderSchema>;
export type GetOrdersQuery = z.infer<typeof getOrdersQuerySchema>;
export type CancelOrderInput = z.infer<typeof cancelOrderSchema>;
export type UpdateOrderStatusInput = z.infer<typeof updateOrderStatusSchema>;
