// ═══════════════════════════════════════════════════════════
// MedOrder — Zod Validation Middleware
// Validates req.body, req.query, or req.params against schema
// ═══════════════════════════════════════════════════════════

import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { AppError } from '../utils/api-error';
import { logger } from '../../config/logger';

type ValidationTarget = 'body' | 'query' | 'params';

export const validate = (
    schema: z.ZodType<any>,
    target: ValidationTarget = 'body',
) => {
    return async (req: Request, _res: Response, next: NextFunction): Promise<void> => {
        try {
            const parsed = await schema.parseAsync(req[target]);
            if (target === 'query') {
                // req.query may be read-only getter; store parsed data as validatedQuery
                (req as any).validatedQuery = parsed;
                try {
                    (req as any).query = parsed;
                } catch {
                    // Fallback: override via defineProperty if direct assignment fails
                    Object.defineProperty(req, 'query', { value: parsed, writable: true, configurable: true });
                }
            } else {
                (req as any)[target] = parsed;
            }
            next();
        } catch (error) {
            if (error instanceof z.ZodError) {
                const issues = (error as any).issues || (error as any).errors || [];
                const details = issues.map((e: any) => ({
                    field: e.path ? e.path.join('.') : '',
                    message: e.message,
                }));
                logger.warn({ details }, 'Validation failed');
                next(AppError.badRequest('Validation failed', 'VALIDATION_ERROR', details));
                return;
            }
            next(error);
        }
    };
};
