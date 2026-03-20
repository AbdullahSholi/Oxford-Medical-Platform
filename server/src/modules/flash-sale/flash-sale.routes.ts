import { Router, Request, Response } from 'express';
import { asyncHandler } from '../../shared/utils/async-handler';
import { ApiResponse } from '../../shared/utils/api-response';
import prisma from '../../config/database';

export const flashSaleRoutes = Router();

flashSaleRoutes.get('/active', asyncHandler(async (_req: Request, res: Response) => {
    const now = new Date();
    const flashSale = await prisma.flashSale.findFirst({
        where: {
            startsAt: { lte: now },
            endsAt: { gte: now },
        },
        include: {
            products: {
                include: {
                    product: {
                        select: {
                            id: true,
                            name: true,
                            slug: true,
                            price: true,
                            images: { take: 1, orderBy: { sortOrder: 'asc' as const } },
                            stock: true,
                        },
                    },
                },
            },
        },
        orderBy: { startsAt: 'desc' },
    });

    ApiResponse.success(res, { data: flashSale });
}));
