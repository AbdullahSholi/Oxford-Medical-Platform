// ═══════════════════════════════════════════════════════════
// MedOrder — Rate Limiting Middleware
// ═══════════════════════════════════════════════════════════

import rateLimit from 'express-rate-limit';
import { env } from '../../config/env';
import { ApiResponse } from '../utils/api-response';

// General API rate limiter: 100 requests per minute per IP
export const apiLimiter = rateLimit({
    windowMs: env.RATE_LIMIT_WINDOW_MS,
    max: env.RATE_LIMIT_MAX,
    standardHeaders: true,
    legacyHeaders: false,
    handler: (_req, res) => {
        ApiResponse.error(res, 429, 'RATE_LIMIT', 'Too many requests, please try again later');
    },
});

// Strict limiter for auth endpoints: 5 attempts per 15 minutes per IP
export const authLimiter = rateLimit({
    windowMs: env.LOGIN_RATE_LIMIT_WINDOW_MS,
    max: env.LOGIN_RATE_LIMIT_MAX,
    standardHeaders: true,
    legacyHeaders: false,
    handler: (_req, res) => {
        ApiResponse.error(
            res,
            429,
            'AUTH_RATE_LIMIT',
            'Too many authentication attempts, please try again after 15 minutes',
        );
    },
});
