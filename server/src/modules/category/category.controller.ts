import { Request, Response } from 'express';
import { CategoryService } from './category.service';
import { ApiResponse } from '../../shared/utils/api-response';

export class CategoryController {
    constructor(private service: CategoryService) { }

    getAll = async (_req: Request, res: Response): Promise<void> => {
        const categories = await this.service.getAll();
        ApiResponse.success(res, { data: categories });
    };

    getProducts = async (req: Request, res: Response): Promise<void> => {
        const page = Number(req.query.page) || 1;
        const limit = Number(req.query.limit) || 20;
        const result = await this.service.getProductsByCategory(req.params.id as string, page, limit);
        ApiResponse.paginated(res, result.data, result.meta.total, result.meta.page, result.meta.limit);
    };
}
