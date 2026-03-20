// ═══════════════════════════════════════════════════════════
// MedOrder — Express Application Setup
// Configures middleware stack, mounts module routes
// ═══════════════════════════════════════════════════════════

import express, { Request, Response } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import compression from 'compression';
import cookieParser from 'cookie-parser';
import { env } from './config/env';
import { requestLogger } from './shared/middleware/request-logger';
import { errorHandler } from './shared/middleware/error-handler';
import { apiLimiter } from './shared/middleware/rate-limit';
import { sanitizeInput } from './shared/middleware/sanitize';

// ── Module route imports ────────────────────────────────
import { authRoutes } from './modules/auth/auth.routes';
import { doctorRoutes } from './modules/doctor/doctor.routes';
import { productRoutes } from './modules/product/product.routes';
import { categoryRoutes } from './modules/category/category.routes';
import { cartRoutes } from './modules/cart/cart.routes';
import { orderRoutes } from './modules/order/order.routes';
import { reviewRoutes } from './modules/review/review.routes';
import { wishlistRoutes } from './modules/wishlist/wishlist.routes';
import { notificationRoutes } from './modules/notification/notification.routes';
import { bannerRoutes } from './modules/banner/banner.routes';
import { flashSaleRoutes } from './modules/flash-sale/flash-sale.routes';
import { brandRoutes } from './modules/brand/brand.routes';
import { adminRoutes } from './modules/admin/admin.routes';
import { uploadRoutes } from './modules/upload/upload.routes';

const app = express();

// Trust proxy when behind Nginx/Cloudflare (needed for rate limiting & real IP)
if (env.NODE_ENV === 'production') {
    app.set('trust proxy', 1);
}

// ═══════════════════════════════════════════════════════════
// MIDDLEWARE STACK (order matters!)
// ═══════════════════════════════════════════════════════════

// 1. Security headers
app.use(helmet({
    hsts: {
        maxAge: 31536000, // 1 year
        includeSubDomains: true,
        preload: true,
    },
    contentSecurityPolicy: env.NODE_ENV === 'production' ? undefined : false,
    crossOriginEmbedderPolicy: false, // Allow loading images from external sources
}));

// 2. CORS
app.use(
    cors({
        origin: (origin, callback) => {
            if (env.NODE_ENV === 'development') {
                callback(null, true);
            } else {
                const origins = env.CORS_ORIGINS.split(',').map((o) => o.trim());
                callback(null, origins.includes(origin || ''));
            }
        },
        credentials: true,
        methods: ['GET', 'POST', 'PATCH', 'DELETE', 'OPTIONS'],
        allowedHeaders: ['Content-Type', 'Authorization', 'X-Request-Id', 'X-App-Version', 'X-Platform'],
        maxAge: 86400, // 24 hours — reduces preflight requests
    }),
);

// 3. Body parsing
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));
app.use(cookieParser());

// 4. Input sanitization (strip XSS payloads)
app.use(sanitizeInput);

// 5. Compression
app.use(compression());

// 5. Request logging
app.use(requestLogger);

// 6. Rate limiting (applied to all API routes)
app.use(`${env.API_PREFIX}`, apiLimiter);

// ═══════════════════════════════════════════════════════════
// ROUTES — Mounted per module
// ═══════════════════════════════════════════════════════════

const prefix = env.API_PREFIX;

// Health check (no auth required)
app.get('/health', (_req: Request, res: Response) => {
    res.status(200).json({
        status: 'ok',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        environment: env.NODE_ENV,
    });
});

// Public + protected module routes
app.use(`${prefix}/auth`, authRoutes);
app.use(`${prefix}/doctors`, doctorRoutes);
app.use(`${prefix}/products`, productRoutes);
app.use(`${prefix}/categories`, categoryRoutes);
app.use(`${prefix}/cart`, cartRoutes);
app.use(`${prefix}/orders`, orderRoutes);
app.use(`${prefix}/reviews`, reviewRoutes);
app.use(`${prefix}/wishlist`, wishlistRoutes);
app.use(`${prefix}/notifications`, notificationRoutes);
app.use(`${prefix}/banners`, bannerRoutes);
app.use(`${prefix}/flash-sales`, flashSaleRoutes);
app.use(`${prefix}/brands`, brandRoutes);

// Upload routes (authenticated)
app.use(`${prefix}/uploads`, uploadRoutes);

// Admin routes (all require admin role)
app.use(`${prefix}/admin`, adminRoutes);

// ═══════════════════════════════════════════════════════════
// 404 HANDLER
// ═══════════════════════════════════════════════════════════
app.use((_req: Request, res: Response) => {
    res.status(404).json({
        success: false,
        error: {
            code: 'NOT_FOUND',
            message: 'The requested endpoint does not exist',
        },
    });
});

// ═══════════════════════════════════════════════════════════
// GLOBAL ERROR HANDLER (must be last)
// ═══════════════════════════════════════════════════════════
app.use(errorHandler);

export default app;
