import { Request, Response } from 'express';
import { BannerService } from './banner.service';
import { ApiResponse } from '../../shared/utils/api-response';

export class BannerController {
    constructor(private service: BannerService) { }

    /** Public: active banners only */
    getActive = async (_req: Request, res: Response): Promise<void> => {
        const banners = await this.service.getActiveBanners();
        ApiResponse.success(res, { data: banners });
    };

    /** Admin: all banners */
    getAll = async (_req: Request, res: Response): Promise<void> => {
        const banners = await this.service.getAllBanners();
        ApiResponse.success(res, { data: banners });
    };

    create = async (req: Request, res: Response): Promise<void> => {
        const banner = await this.service.createBanner(req.body);
        ApiResponse.created(res, banner);
    };

    update = async (req: Request, res: Response): Promise<void> => {
        const banner = await this.service.updateBanner(req.params.id as string, req.body);
        ApiResponse.success(res, { data: banner, message: 'Banner updated' });
    };

    toggle = async (req: Request, res: Response): Promise<void> => {
        const banner = await this.service.toggleBanner(req.params.id as string);
        ApiResponse.success(res, { data: banner, message: 'Banner toggled' });
    };

    remove = async (req: Request, res: Response): Promise<void> => {
        await this.service.deleteBanner(req.params.id as string);
        ApiResponse.noContent(res);
    };
}
