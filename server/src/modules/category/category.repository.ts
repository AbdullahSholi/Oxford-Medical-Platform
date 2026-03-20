import { PrismaClient, Prisma } from '@prisma/client';
import { getSkip } from '../../shared/utils/pagination';

export class CategoryRepository {
    constructor(private prisma: PrismaClient) {}

    async findAll() {
        return this.prisma.category.findMany({
            where: { isActive: true },
            orderBy: { sortOrder: 'asc' },
            include: {
                children: {
                    where: { isActive: true },
                    orderBy: { sortOrder: 'asc' },
                },
                _count: { select: { products: true } },
            },
        });
    }

    async findById(id: string) {
        return this.prisma.category.findUnique({ where: { id } });
    }

    async getProductsByCategory(categoryId: string, page: number, limit: number) {
        const where: Prisma.ProductWhereInput = {
            categoryId,
            isActive: true,
        };
        const [data, total] = await Promise.all([
            this.prisma.product.findMany({
                where,
                skip: getSkip(page, limit),
                take: limit,
                orderBy: { createdAt: 'desc' },
                include: {
                    images: { take: 1, orderBy: { sortOrder: 'asc' } },
                    category: { select: { id: true, name: true } },
                },
            }),
            this.prisma.product.count({ where }),
        ]);
        return { data, total };
    }

    async create(data: { name: string; slug: string; description?: string; parentId?: string; iconUrl?: string; sortOrder?: number }) {
        return this.prisma.category.create({ data });
    }

    async update(id: string, data: Prisma.CategoryUpdateInput) {
        return this.prisma.category.update({ where: { id }, data });
    }

    async delete(id: string) {
        return this.prisma.category.update({ where: { id }, data: { isActive: false } });
    }
}
