import { PrismaClient, Prisma } from '@prisma/client';
import { GetProductsQuery } from './product.schema';
import { getSkip } from '../../shared/utils/pagination';

export class ProductRepository {
    constructor(private prisma: PrismaClient) {}

    async findMany(query: GetProductsQuery) {
        const { page, limit, categoryId, brandId, minPrice, maxPrice, inStock, sort, search } = query;

        const where: Prisma.ProductWhereInput = {
            isActive: true,
            ...(categoryId && { categoryId }),
            ...(brandId && { brandId }),
            ...(inStock !== undefined && { stock: inStock ? { gt: 0 } : { equals: 0 } }),
            ...(minPrice !== undefined && { price: { gte: minPrice } }),
            ...(maxPrice !== undefined && { price: { ...(minPrice !== undefined ? { gte: minPrice } : {}), lte: maxPrice } }),
            ...(search && {
                OR: [
                    { name: { contains: search, mode: 'insensitive' as const } },
                    { description: { contains: search, mode: 'insensitive' as const } },
                    { sku: { contains: search, mode: 'insensitive' as const } },
                ],
            }),
        };

        const orderBy = this.getSortOrder(sort);

        const [data, total] = await Promise.all([
            this.prisma.product.findMany({
                where,
                orderBy,
                skip: getSkip(page, limit),
                take: limit,
                include: {
                    category: { select: { id: true, name: true, slug: true } },
                    brand: { select: { id: true, name: true, slug: true } },
                    images: { orderBy: { sortOrder: 'asc' }, take: 3 },
                },
            }),
            this.prisma.product.count({ where }),
        ]);

        return { data, total };
    }

    async findById(id: string) {
        return this.prisma.product.findUnique({
            where: { id },
            include: {
                category: { select: { id: true, name: true, slug: true } },
                brand: { select: { id: true, name: true, slug: true } },
                images: { orderBy: { sortOrder: 'asc' } },
                bulkPricing: { orderBy: { minQuantity: 'asc' } },
            },
        });
    }

    async findBySlug(slug: string) {
        return this.prisma.product.findUnique({
            where: { slug },
            include: {
                category: { select: { id: true, name: true, slug: true } },
                brand: { select: { id: true, name: true, slug: true } },
                images: { orderBy: { sortOrder: 'asc' } },
                bulkPricing: { orderBy: { minQuantity: 'asc' } },
            },
        });
    }

    async create(data: Prisma.ProductCreateInput) {
        return this.prisma.product.create({
            data,
            include: {
                category: { select: { id: true, name: true } },
                images: true,
            },
        });
    }

    async update(id: string, data: Prisma.ProductUpdateInput) {
        return this.prisma.product.update({
            where: { id },
            data,
            include: {
                category: { select: { id: true, name: true } },
                images: true,
            },
        });
    }

    async delete(id: string) {
        return this.prisma.product.update({
            where: { id },
            data: { isActive: false },
        });
    }

    async getReviews(productId: string, page: number, limit: number) {
        const where = { productId, isVisible: true };
        const [data, total] = await Promise.all([
            this.prisma.review.findMany({
                where,
                skip: getSkip(page, limit),
                take: limit,
                orderBy: { createdAt: 'desc' },
                include: {
                    doctor: { select: { id: true, fullName: true, avatarUrl: true, specialty: true } },
                },
            }),
            this.prisma.review.count({ where }),
        ]);
        return { data, total };
    }

    private getSortOrder(sort: string): Prisma.ProductOrderByWithRelationInput {
        switch (sort) {
            case 'price_asc': return { price: 'asc' };
            case 'price_desc': return { price: 'desc' };
            case 'rating': return { avgRating: 'desc' };
            case 'best_selling': return { totalSold: 'desc' };
            case 'newest':
            default: return { createdAt: 'desc' };
        }
    }
}
