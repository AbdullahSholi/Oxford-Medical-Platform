// ═══════════════════════════════════════════════════════════
// MedOrder — Async Handler Wrapper
// Catches rejected promises and forwards to error middleware
// ═══════════════════════════════════════════════════════════

import { Request, Response, NextFunction, RequestHandler } from 'express';

export const asyncHandler = (
    fn: (req: Request, res: Response, next: NextFunction) => Promise<any>,
): RequestHandler => {
    return (req, res, next) => {
        Promise.resolve(fn(req, res, next)).catch(next);
    };
};
