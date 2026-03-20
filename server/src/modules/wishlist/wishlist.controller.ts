import { Request, Response } from 'express';
import { WishlistService } from './wishlist.service';
import { ApiResponse } from '../../shared/utils/api-response';

export class WishlistController {
    constructor(private service: WishlistService) { }

    getAll = async (req: Request, res: Response): Promise<void> => {
        const page = Number(req.query.page) || 1;
        const limit = Number(req.query.limit) || 20;
        const result = await this.service.getWishlist(req.user!.id, page, limit);
        ApiResponse.success(res, { data: result.data, meta: result.meta });
    };

    add = async (req: Request, res: Response): Promise<void> => {
        const item = await this.service.addToWishlist(req.user!.id, req.params.productId as string);
        ApiResponse.created(res, item, 'Added to wishlist');
    };

    remove = async (req: Request, res: Response): Promise<void> => {
        await this.service.removeFromWishlist(req.user!.id, req.params.productId as string);
        ApiResponse.noContent(res);
    };
}
