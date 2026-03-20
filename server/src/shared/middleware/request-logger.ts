// ═══════════════════════════════════════════════════════════
// MedOrder — Request Logger Middleware (Pino-based)
// ═══════════════════════════════════════════════════════════

import { Request, Response, NextFunction } from 'express';
import { randomUUID } from 'crypto';
import { logger } from '../../config/logger';

export const requestLogger = (req: Request, res: Response, next: NextFunction): void => {
    const requestId = (req.headers['x-request-id'] as string) || randomUUID();
    const startTime = Date.now();

    // Attach request ID for correlation
    req.headers['x-request-id'] = requestId;
    res.setHeader('X-Request-Id', requestId);

    res.on('finish', () => {
        const duration = Date.now() - startTime;
        const logData = {
            requestId,
            method: req.method,
            url: req.originalUrl,
            statusCode: res.statusCode,
            duration: `${duration}ms`,
            userAgent: req.headers['user-agent'],
            ip: req.ip,
            userId: req.user?.id,
        };

        if (res.statusCode >= 400) {
            logger.warn(logData, `${req.method} ${req.originalUrl} ${res.statusCode}`);
        } else {
            logger.info(logData, `${req.method} ${req.originalUrl} ${res.statusCode}`);
        }
    });

    next();
};
