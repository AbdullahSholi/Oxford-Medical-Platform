import { Router } from 'express';
import { authenticate } from '../../shared/middleware/authenticate';
import { validate } from '../../shared/middleware/validate';
import { asyncHandler } from '../../shared/utils/async-handler';
import { OrderController } from './order.controller';
import { OrderService } from './order.service';
import { OrderRepository } from './order.repository';
import { createOrderSchema, getOrdersQuerySchema, cancelOrderSchema } from './order.schema';
import prisma from '../../config/database';

const repo = new OrderRepository(prisma);
const service = new OrderService(repo, prisma);
const controller = new OrderController(service);

export const orderRoutes = Router();
orderRoutes.use(authenticate);

orderRoutes.post('/', validate(createOrderSchema), asyncHandler(controller.create));
orderRoutes.get('/', validate(getOrdersQuerySchema, 'query'), asyncHandler(controller.getAll));
orderRoutes.get('/:id', asyncHandler(controller.getById));
orderRoutes.post('/:id/cancel', validate(cancelOrderSchema), asyncHandler(controller.cancel));
orderRoutes.get('/:id/tracking', asyncHandler(controller.getTracking));

// Export service for admin usage
export { service as orderService };
