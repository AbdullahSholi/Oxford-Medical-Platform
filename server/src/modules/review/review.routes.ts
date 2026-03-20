import { Router } from 'express';
import { authenticate } from '../../shared/middleware/authenticate';
import { validate } from '../../shared/middleware/validate';
import { asyncHandler } from '../../shared/utils/async-handler';
import { ReviewController } from './review.controller';
import { ReviewService } from './review.service';
import { ReviewRepository } from './review.repository';
import { createReviewSchema, updateReviewSchema } from './review.schema';
import prisma from '../../config/database';

const repo = new ReviewRepository(prisma);
const service = new ReviewService(repo, prisma);
const controller = new ReviewController(service);

export const reviewRoutes = Router();
reviewRoutes.use(authenticate);

reviewRoutes.post('/', validate(createReviewSchema), asyncHandler(controller.create));
reviewRoutes.patch('/:id', validate(updateReviewSchema), asyncHandler(controller.update));
reviewRoutes.delete('/:id', asyncHandler(controller.remove));
