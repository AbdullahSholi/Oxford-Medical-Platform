import { Router } from 'express';
import { authLimiter } from '../../shared/middleware/rate-limit';
import { validate } from '../../shared/middleware/validate';
import { authenticate } from '../../shared/middleware/authenticate';
import { asyncHandler } from '../../shared/utils/async-handler';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { AuthRepository } from './auth.repository';
import {
    registerSchema,
    loginSchema,
    sendOtpSchema,
    verifyOtpSchema,
    resetPasswordSchema,
    refreshTokenSchema,
} from './auth.schema';
import prisma from '../../config/database';

const repo = new AuthRepository(prisma);
const service = new AuthService(repo);
const controller = new AuthController(service);

export const authRoutes = Router();

authRoutes.post('/register', authLimiter, validate(registerSchema), asyncHandler(controller.register));
authRoutes.post('/login', authLimiter, validate(loginSchema), asyncHandler(controller.login));
authRoutes.post('/admin/login', authLimiter, validate(loginSchema), asyncHandler(controller.adminLogin));
authRoutes.post('/otp/send', authLimiter, validate(sendOtpSchema), asyncHandler(controller.sendOtp));
authRoutes.post('/otp/verify', authLimiter, validate(verifyOtpSchema), asyncHandler(controller.verifyOtp));
authRoutes.post('/password/reset', authLimiter, validate(resetPasswordSchema), asyncHandler(controller.resetPassword));
authRoutes.post('/refresh-token', validate(refreshTokenSchema), asyncHandler(controller.refreshToken));
authRoutes.post('/logout', authenticate, asyncHandler(controller.logout));
