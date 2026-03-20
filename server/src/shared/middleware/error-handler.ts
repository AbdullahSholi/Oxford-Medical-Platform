// ═══════════════════════════════════════════════════════════
// MedOrder — Global Error Handler Middleware
// Catches all errors, logs them, optionally reports to Sentry,
// and returns sanitized JSON responses.
// ═══════════════════════════════════════════════════════════

import { Request, Response, NextFunction } from 'express';
import { ZodError } from 'zod';
import { AppError } from '../utils/api-error';
import { handleDatabaseError } from '../utils/db-error-handler';
import { logger } from '../../config/logger';
import { env } from '../../config/env';

// ── Sentry integration (lazy import, only if DSN is configured) ──
let sentryCapture: ((err: Error, context?: Record<string, unknown>) => void) | null = null;

async function initSentry(): Promise<void> {
    if (env.SENTRY_DSN && !sentryCapture) {
        try {
            const Sentry = await import('@sentry/node');
            Sentry.init({
                dsn: env.SENTRY_DSN,
                environment: env.NODE_ENV,
                tracesSampleRate: env.NODE_ENV === 'production' ? 0.1 : 1.0,
            });
            sentryCapture = (err, context) => {
                Sentry.withScope((scope) => {
                    if (context) {
                        scope.setExtras(context);
                    }
                    Sentry.captureException(err);
                });
            };
            logger.info('Sentry error reporting initialized');
        } catch {
            // Sentry not installed — skip silently
            logger.debug('Sentry SDK not installed, error reporting disabled');
        }
    }
}

// Initialize Sentry on module load
initSentry();

/**
 * Express global error handler.
 * Must be registered LAST in the middleware chain.
 *
 * Error handling priority:
 * 1. AppError (operational) — return as-is
 * 2. Zod validation errors — transform to 400
 * 3. Database errors — delegate to handleDatabaseError
 * 4. Unknown errors — log, report to Sentry, return 500
 */
export const errorHandler = (
    err: Error,
    req: Request,
    res: Response,
    _next: NextFunction,
): void => {
    // ── 1. AppError (operational errors) ─────────────────
    if (err instanceof AppError) {
        if (err.statusCode >= 500) {
            logger.error({ err, req: { method: req.method, url: req.url } }, err.message);
            reportToSentry(err, req);
        } else {
            logger.warn({ code: err.code, url: req.url }, err.message);
        }

        sendErrorResponse(res, err.statusCode, err.code, err.message, err.details);
        return;
    }

    // ── 2. JSON Parse Error (invalid body) ──────────────
    if (err instanceof SyntaxError && 'body' in err) {
        sendErrorResponse(res, 400, 'INVALID_JSON', 'Request body contains invalid JSON');
        return;
    }

    // ── 3. Zod Validation Error ──────────────────────────
    if (err instanceof ZodError) {
        const formatted = err.issues.map((e: any) => ({
            path: e.path.join('.'),
            message: e.message,
        }));

        sendErrorResponse(res, 400, 'VALIDATION_ERROR', 'Request validation failed', formatted);
        return;
    }

    // ── 3. Database / Prisma errors ──────────────────────
    const dbError = handleDatabaseError(err);
    if (dbError) {
        if (dbError.statusCode >= 500) {
            reportToSentry(err, req);
        }
        sendErrorResponse(res, dbError.statusCode, dbError.code, dbError.message, dbError.details);
        return;
    }

    // ── 4. Unknown / Unexpected errors ───────────────────
    logger.error(
        { err, req: { method: req.method, url: req.url } },
        'Unhandled error',
    );
    reportToSentry(err, req);

    sendErrorResponse(
        res,
        500,
        'INTERNAL_ERROR',
        env.NODE_ENV === 'production'
            ? 'An unexpected error occurred'
            : err.message || 'An unexpected error occurred',
    );
};

/**
 * Standardized error response format.
 */
function sendErrorResponse(
    res: Response,
    statusCode: number,
    code: string,
    message: string,
    details?: unknown,
): void {
    const body: Record<string, unknown> = {
        success: false,
        error: {
            code,
            message,
        },
    };

    if (details !== undefined) {
        (body.error as Record<string, unknown>).details = details;
    }

    res.status(statusCode).json(body);
}

/**
 * Report error to Sentry if configured.
 */
function reportToSentry(err: Error, req: Request): void {
    if (sentryCapture) {
        sentryCapture(err, {
            method: req.method,
            url: req.url,
            headers: {
                'user-agent': req.headers['user-agent'],
                'x-request-id': req.headers['x-request-id'],
            },
            body: req.body,
            params: req.params,
            query: req.query,
            userId: (req as any).user?.id,
        });
    }
}
