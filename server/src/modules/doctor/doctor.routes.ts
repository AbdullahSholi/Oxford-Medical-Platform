import { Router } from 'express';
import { authenticate } from '../../shared/middleware/authenticate';
import { authorize } from '../../shared/middleware/authorize';
import { validate } from '../../shared/middleware/validate';
import { asyncHandler } from '../../shared/utils/async-handler';
import { DoctorController } from './doctor.controller';
import { DoctorService } from './doctor.service';
import { DoctorRepository } from './doctor.repository';
import { updateProfileSchema, createAddressSchema, updateAddressSchema } from './doctor.schema';
import prisma from '../../config/database';

const repo = new DoctorRepository(prisma);
const service = new DoctorService(repo);
const controller = new DoctorController(service);

export const doctorRoutes = Router();
doctorRoutes.use(authenticate);
doctorRoutes.use(authorize('doctor'));

doctorRoutes.get('/me', asyncHandler(controller.getProfile));
doctorRoutes.patch('/me', validate(updateProfileSchema), asyncHandler(controller.updateProfile));
doctorRoutes.get('/me/addresses', asyncHandler(controller.getAddresses));
doctorRoutes.post('/me/addresses', validate(createAddressSchema), asyncHandler(controller.createAddress));
doctorRoutes.patch('/me/addresses/:id', validate(updateAddressSchema), asyncHandler(controller.updateAddress));
doctorRoutes.delete('/me/addresses/:id', asyncHandler(controller.deleteAddress));
