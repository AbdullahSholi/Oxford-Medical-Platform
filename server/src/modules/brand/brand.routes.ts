import { Router, Request, Response } from 'express';
import { asyncHandler } from '../../shared/utils/async-handler';
import { ApiResponse } from '../../shared/utils/api-response';
import prisma from '../../config/database';

export const brandRoutes = Router();

brandRoutes.get(
    '/',
    asyncHandler(async (_req: Request, res: Response) => {
        const brands = await prisma.brand.findMany({
            where: { isActive: true },
            select: { id: true, name: true, slug: true, logoUrl: true },
            orderBy: { name: 'asc' },
        });
        ApiResponse.success(res, { data: brands });
    }),
);
