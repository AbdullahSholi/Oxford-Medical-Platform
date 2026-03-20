import { AppError } from '../../shared/utils/api-error';
import { CacheService, CacheKeys, CacheTTL } from '../../shared/utils/cache';
import { BannerRepository } from './banner.repository';
import { CreateBannerInput, UpdateBannerInput } from './banner.schema';

export class BannerService {
    constructor(private repo: BannerRepository) { }

    /** Public: returns only active banners within date range (cached) */
    async getActiveBanners() {
        return CacheService.getOrSet(CacheKeys.ACTIVE_BANNERS, CacheTTL.BANNERS, () => this.repo.findActive());
    }

    /** Admin: returns all banners (cached) */
    async getAllBanners() {
        return CacheService.getOrSet(CacheKeys.ALL_BANNERS, CacheTTL.BANNERS, () => this.repo.findAll());
    }

    async getBannerById(id: string) {
        const banner = await this.repo.findById(id);
        if (!banner) throw AppError.notFound('Banner');
        return banner;
    }

    async createBanner(input: CreateBannerInput) {
        const result = await this.repo.create(input);
        await CacheService.invalidate('cache:banners:');
        return result;
    }

    async updateBanner(id: string, input: UpdateBannerInput) {
        const existing = await this.repo.findById(id);
        if (!existing) throw AppError.notFound('Banner');
        const result = await this.repo.update(id, input as Record<string, unknown>);
        await CacheService.invalidate('cache:banners:');
        return result;
    }

    async toggleBanner(id: string) {
        const existing = await this.repo.findById(id);
        if (!existing) throw AppError.notFound('Banner');
        const result = await this.repo.update(id, { isActive: !existing.isActive });
        await CacheService.invalidate('cache:banners:');
        return result;
    }

    async deleteBanner(id: string) {
        const existing = await this.repo.findById(id);
        if (!existing) throw AppError.notFound('Banner');
        const result = await this.repo.delete(id);
        await CacheService.invalidate('cache:banners:');
        return result;
    }
}
