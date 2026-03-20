// ═══════════════════════════════════════════════════════════
// MedOrder — JWT Authentication Middleware
// ═══════════════════════════════════════════════════════════

import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { env } from '../../config/env';
import { AppError } from '../utils/api-error';
import redis from '../../config/redis';

interface JwtPayload {
    sub: string;      // doctorId
    role: string;     // 'doctor' | 'admin'
    jti: string;      // unique token ID
    iat: number;
    exp: number;
}

declare global {
    namespace Express {
        interface Request {
            user?: {
                id: string;
                role: string;
                tokenJti: string;
            };
        }
    }
}

export const authenticate = async (
    req: Request,
    _res: Response,
    next: NextFunction,
): Promise<void> => {
    try {
        const authHeader = req.headers.authorization;
        if (!authHeader?.startsWith('Bearer ')) {
            throw AppError.unauthorized('Missing or invalid authorization header');
        }

        const token = authHeader.split(' ')[1];
        const decoded = jwt.verify(token, env.JWT_ACCESS_SECRET) as JwtPayload;

        // Check if token is blacklisted (revoked)
        const isBlacklisted = await redis.get(`blacklist:${decoded.jti}`);
        if (isBlacklisted) {
            throw AppError.unauthorized('Token has been revoked');
        }

        req.user = {
            id: decoded.sub,
            role: decoded.role,
            tokenJti: decoded.jti,
        };

        next();
    } catch (error) {
        if (error instanceof AppError) {
            next(error);
            return;
        }
        if (error instanceof jwt.TokenExpiredError) {
            next(AppError.unauthorized('Access token expired'));
            return;
        }
        if (error instanceof jwt.JsonWebTokenError) {
            next(AppError.unauthorized('Invalid access token'));
            return;
        }
        next(error);
    }
};
