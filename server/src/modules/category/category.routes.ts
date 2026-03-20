import { Router } from 'express';
import { asyncHandler } from '../../shared/utils/async-handler';
import { CategoryController } from './category.controller';
import { CategoryService } from './category.service';
import { CategoryRepository } from './category.repository';
import prisma from '../../config/database';

const repo = new CategoryRepository(prisma);
const service = new CategoryService(repo);
const controller = new CategoryController(service);

export const categoryRoutes = Router();

categoryRoutes.get('/', asyncHandler(controller.getAll));
categoryRoutes.get('/:id/products', asyncHandler(controller.getProducts));

// Export for admin module
export { service as categoryService, controller as categoryController };
