import { Request, Response } from 'express';
import { ProductService } from './product.service';
import { ApiResponse } from '../../shared/utils/api-response';

export class ProductController {
    constructor(private service: ProductService) { }

    getAll = async (req: Request, res: Response): Promise<void> => {
        const result = await this.service.getProducts(req.query as any);
        ApiResponse.paginated(res, result.data, result.meta.total, result.meta.page, result.meta.limit);
    };

    getById = async (req: Request, res: Response): Promise<void> => {
        const product = await this.service.getProductById(req.params.id as string);
        ApiResponse.success(res, { data: product });
    };

    getReviews = async (req: Request, res: Response): Promise<void> => {
        const page = Number(req.query.page) || 1;
        const limit = Number(req.query.limit) || 20;
        const result = await this.service.getProductReviews(req.params.id as string, page, limit);
        ApiResponse.paginated(res, result.data, result.meta.total, result.meta.page, result.meta.limit);
    };

    create = async (req: Request, res: Response): Promise<void> => {
        const product = await this.service.createProduct(req.body);
        ApiResponse.created(res, product);
    };

    update = async (req: Request, res: Response): Promise<void> => {
        const product = await this.service.updateProduct(req.params.id as string, req.body);
        ApiResponse.success(res, { data: product, message: 'Product updated' });
    };

    remove = async (req: Request, res: Response): Promise<void> => {
        await this.service.deleteProduct(req.params.id as string);
        ApiResponse.noContent(res);
    };
}
