import { Router } from 'express';
import { asyncHandler } from '../../shared/utils/async-handler';
import { BannerController } from './banner.controller';
import { BannerService } from './banner.service';
import { BannerRepository } from './banner.repository';
import prisma from '../../config/database';

const repo = new BannerRepository(prisma);
const service = new BannerService(repo);
const controller = new BannerController(service);

export const bannerRoutes = Router();

// Public: no auth required
bannerRoutes.get('/', asyncHandler(controller.getActive));

// Export service + controller for admin routes
export { service as bannerService, controller as bannerController };
