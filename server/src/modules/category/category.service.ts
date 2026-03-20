import { AppError } from '../../shared/utils/api-error';
import { getPaginationMeta } from '../../shared/utils/pagination';
import { generateUniqueSlug } from '../../shared/utils/slug';
import { CacheService, CacheKeys, CacheTTL } from '../../shared/utils/cache';
import { CategoryRepository } from './category.repository';

export class CategoryService {
    constructor(private repo: CategoryRepository) {}

    async getAll() {
        return CacheService.getOrSet(CacheKeys.CATEGORIES, CacheTTL.CATEGORIES, async () => {
            const categories = await this.repo.findAll();
            return categories.filter((c) => !c.parentId);
        });
    }

    async getProductsByCategory(categoryId: string, page: number = 1, limit: number = 20) {
        const category = await this.repo.findById(categoryId);
        if (!category) throw AppError.notFound('Category');

        const { data, total } = await this.repo.getProductsByCategory(categoryId, page, limit);
        return { data, meta: getPaginationMeta(total, page, limit) };
    }

    async create(input: { name: string; description?: string; parentId?: string; iconUrl?: string; sortOrder?: number }) {
        const slug = generateUniqueSlug(input.name, Date.now().toString(36));
        const result = await this.repo.create({ ...input, slug });
        await CacheService.invalidate(CacheKeys.CATEGORIES);
        return result;
    }

    async update(id: string, data: Record<string, unknown>) {
        const existing = await this.repo.findById(id);
        if (!existing) throw AppError.notFound('Category');
        const result = await this.repo.update(id, data);
        await CacheService.invalidate(CacheKeys.CATEGORIES);
        return result;
    }

    async delete(id: string) {
        const existing = await this.repo.findById(id);
        if (!existing) throw AppError.notFound('Category');
        const result = await this.repo.delete(id);
        await CacheService.invalidate(CacheKeys.CATEGORIES);
        return result;
    }
}
