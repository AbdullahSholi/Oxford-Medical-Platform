// ═══════════════════════════════════════════════════════════
// MedOrder — Pagination Helper
// ═══════════════════════════════════════════════════════════

import { z } from 'zod';

export const paginationSchema = z.object({
    page: z.coerce.number().int().positive().default(1),
    limit: z.coerce.number().int().min(1).max(100).default(20),
    sort: z.string().optional().default('createdAt'),
    order: z.enum(['asc', 'desc']).optional().default('desc'),
});

export type PaginationParams = z.infer<typeof paginationSchema>;

export function getPaginationMeta(total: number, page: number, limit: number) {
    const totalPages = Math.ceil(total / limit);
    return {
        page,
        limit,
        total,
        totalPages,
        hasNext: page < totalPages,
        hasPrev: page > 1,
    };
}

export function getSkip(page: number, limit: number): number {
    return (page - 1) * limit;
}
