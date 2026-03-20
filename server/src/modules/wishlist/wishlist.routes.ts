import { Router } from 'express';
import { authenticate } from '../../shared/middleware/authenticate';
import { asyncHandler } from '../../shared/utils/async-handler';
import { WishlistController } from './wishlist.controller';
import { WishlistService } from './wishlist.service';
import { WishlistRepository } from './wishlist.repository';
import prisma from '../../config/database';

const repo = new WishlistRepository(prisma);
const service = new WishlistService(repo, prisma);
const controller = new WishlistController(service);

export const wishlistRoutes = Router();
wishlistRoutes.use(authenticate);

wishlistRoutes.get('/', asyncHandler(controller.getAll));
wishlistRoutes.post('/:productId', asyncHandler(controller.add));
wishlistRoutes.delete('/:productId', asyncHandler(controller.remove));
