import { Router } from 'express';
import { authenticate } from '../../shared/middleware/authenticate';
import { validate } from '../../shared/middleware/validate';
import { asyncHandler } from '../../shared/utils/async-handler';
import { CartController } from './cart.controller';
import { CartService } from './cart.service';
import { CartRepository } from './cart.repository';
import { addToCartSchema, updateCartItemSchema, applyCouponSchema } from './cart.schema';
import prisma from '../../config/database';

const repo = new CartRepository(prisma);
const service = new CartService(repo, prisma);
const controller = new CartController(service);

export const cartRoutes = Router();
cartRoutes.use(authenticate);

cartRoutes.get('/', asyncHandler(controller.getCart));
cartRoutes.post('/items', validate(addToCartSchema), asyncHandler(controller.addItem));
cartRoutes.patch('/items/:productId', validate(updateCartItemSchema), asyncHandler(controller.updateItem));
cartRoutes.delete('/items/:productId', asyncHandler(controller.removeItem));
cartRoutes.post('/coupon', validate(applyCouponSchema), asyncHandler(controller.applyCoupon));
cartRoutes.delete('/coupon', asyncHandler(controller.removeCoupon));
cartRoutes.delete('/', asyncHandler(controller.clearCart));
