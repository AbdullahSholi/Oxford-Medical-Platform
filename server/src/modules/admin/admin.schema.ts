import { z } from 'zod';

// ── Doctor Management ───────────────────────────────────
export const rejectDoctorSchema = z.object({
    reason: z.string().min(5).max(1000),
});

// ── Order Management ────────────────────────────────────
export const updateOrderStatusSchema = z.object({
    status: z.enum(['confirmed', 'processing', 'shipped', 'out_for_delivery', 'delivered', 'cancelled']),
    notes: z.string().max(1000).optional(),
});

// ── Discount Management ─────────────────────────────────
const discountBaseSchema = z.object({
    code: z.string().min(3).max(50).transform(v => v.toUpperCase()),
    description: z.string().max(500).optional(),
    type: z.enum(['percentage', 'fixed']),
    value: z.number().positive(),
    minOrderAmount: z.number().positive().optional(),
    maxDiscount: z.number().positive().optional(),
    usageLimit: z.number().int().positive().optional(),
    perUserLimit: z.number().int().positive().default(1),
    startsAt: z.coerce.date(),
    endsAt: z.coerce.date(),
    appliesTo: z.any().optional(),
    isActive: z.boolean().default(true),
});

export const createDiscountSchema = discountBaseSchema.refine(
    (data) => data.type !== 'percentage' || data.value <= 100,
    { message: 'Percentage discount cannot exceed 100%', path: ['value'] },
);

export const updateDiscountSchema = discountBaseSchema.partial().extend({
    isActive: z.boolean().optional(),
}).refine(
    (data) => !data.type || data.type !== 'percentage' || !data.value || data.value <= 100,
    { message: 'Percentage discount cannot exceed 100%', path: ['value'] },
);

// ── Flash Sale Management ───────────────────────────────
export const createFlashSaleSchema = z.object({
    title: z.string().min(1).max(200),
    bannerUrl: z.string().url().optional(),
    startsAt: z.coerce.date(),
    endsAt: z.coerce.date(),
    products: z.array(z.object({
        productId: z.string().uuid(),
        flashPrice: z.number().positive(),
        flashStock: z.number().int().positive(),
    })).min(1),
});

export type RejectDoctorInput = z.infer<typeof rejectDoctorSchema>;
export type UpdateOrderStatusInput = z.infer<typeof updateOrderStatusSchema>;
export type CreateDiscountInput = z.infer<typeof createDiscountSchema>;
export type UpdateDiscountInput = z.infer<typeof updateDiscountSchema>;
export type CreateFlashSaleInput = z.infer<typeof createFlashSaleSchema>;
