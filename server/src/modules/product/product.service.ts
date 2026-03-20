import { AppError } from '../../shared/utils/api-error';
import { generateUniqueSlug } from '../../shared/utils/slug';
import { getPaginationMeta } from '../../shared/utils/pagination';
import { ProductRepository } from './product.repository';
import { GetProductsQuery, CreateProductInput, UpdateProductInput } from './product.schema';

export class ProductService {
    constructor(private repo: ProductRepository) {}

    async getProducts(query: GetProductsQuery) {
        const { data, total } = await this.repo.findMany(query);
        return { data, meta: getPaginationMeta(total, query.page, query.limit) };
    }

    async getProductById(id: string) {
        const product = await this.repo.findById(id);
        if (!product || !product.isActive) throw AppError.notFound('Product');
        return product;
    }

    async createProduct(input: CreateProductInput) {
        const slug = generateUniqueSlug(input.name, Date.now().toString(36));
        const { bulkPricing, categoryId, brandId, ...productData } = input;

        return this.repo.create({
            ...productData,
            slug,
            ...(categoryId && { category: { connect: { id: categoryId } } }),
            ...(brandId && { brand: { connect: { id: brandId } } }),
            ...(bulkPricing && {
                bulkPricing: {
                    create: bulkPricing.map((bp) => ({
                        minQuantity: bp.minQuantity,
                        maxQuantity: bp.maxQuantity ?? null,
                        unitPrice: bp.unitPrice,
                    })),
                },
            }),
        } as any);
    }

    async updateProduct(id: string, input: UpdateProductInput) {
        const existing = await this.repo.findById(id);
        if (!existing) throw AppError.notFound('Product');

        const { bulkPricing, categoryId, brandId, ...rest } = input;
        return this.repo.update(id, {
            ...rest,
            ...(categoryId && { category: { connect: { id: categoryId } } }),
            ...(brandId && { brand: { connect: { id: brandId } } }),
        } as any);
    }

    async deleteProduct(id: string) {
        const existing = await this.repo.findById(id);
        if (!existing) throw AppError.notFound('Product');
        return this.repo.delete(id);
    }

    async getProductReviews(productId: string, page: number = 1, limit: number = 20) {
        const { data, total } = await this.repo.getReviews(productId, page, limit);
        return { data, meta: getPaginationMeta(total, page, limit) };
    }
}
