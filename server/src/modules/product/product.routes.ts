import { Router } from 'express';
import { validate } from '../../shared/middleware/validate';
import { asyncHandler } from '../../shared/utils/async-handler';
import { ProductController } from './product.controller';
import { ProductService } from './product.service';
import { ProductRepository } from './product.repository';
import { getProductsQuerySchema } from './product.schema';
import prisma from '../../config/database';

const repo = new ProductRepository(prisma);
const service = new ProductService(repo);
const controller = new ProductController(service);

export const productRoutes = Router();

productRoutes.get('/', validate(getProductsQuerySchema, 'query'), asyncHandler(controller.getAll));
productRoutes.get('/search', asyncHandler(async (req, res) => {
    // Map ?q= to ?search= and delegate to getAll
    req.query.search = req.query.q as string || req.query.search as string || '';
    return controller.getAll(req, res);
}));
productRoutes.get('/:id', asyncHandler(controller.getById));
productRoutes.get('/:id/reviews', asyncHandler(controller.getReviews));

// Export for admin module
export { service as productService, controller as productController };
