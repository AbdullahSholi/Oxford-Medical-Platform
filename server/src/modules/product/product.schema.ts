import { z } from 'zod';

export const getProductsQuerySchema = z.object({
    page: z.coerce.number().int().positive().default(1),
    limit: z.coerce.number().int().min(1).max(50).default(20),
    categoryId: z.string().uuid().optional(),
    brandId: z.string().uuid().optional(),
    minPrice: z.coerce.number().positive().optional(),
    maxPrice: z.coerce.number().positive().optional(),
    inStock: z.coerce.boolean().optional(),
    sort: z.enum(['price_asc', 'price_desc', 'newest', 'rating', 'best_selling']).default('newest'),
    search: z.string().max(100).optional(),
});

export const createProductSchema = z.object({
    name: z.string().min(3).max(200),
    description: z.string().min(10).max(5000),
    categoryId: z.string().uuid(),
    brandId: z.string().uuid().optional(),
    sku: z.string().regex(/^[A-Z0-9-]+$/),
    price: z.number().positive(),
    salePrice: z.number().positive().optional(),
    costPrice: z.number().positive().optional(),
    stock: z.number().int().min(0),
    lowStockThreshold: z.number().int().min(0).default(10),
    minOrderQty: z.number().int().min(1).default(1),
    medicalDetails: z.record(z.string(), z.unknown()).default({}),
    bulkPricing: z.array(z.object({
        minQuantity: z.number().int().positive(),
        maxQuantity: z.number().int().positive().nullable().optional(),
        unitPrice: z.number().positive(),
    })).optional(),
    isActive: z.boolean().default(true),
});

export const updateProductSchema = createProductSchema.partial();

export type GetProductsQuery = z.infer<typeof getProductsQuerySchema>;
export type CreateProductInput = z.infer<typeof createProductSchema>;
export type UpdateProductInput = z.infer<typeof updateProductSchema>;
