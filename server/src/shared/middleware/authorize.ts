// ═══════════════════════════════════════════════════════════
// MedOrder — Role-Based Authorization Middleware
// ═══════════════════════════════════════════════════════════

import { Request, Response, NextFunction } from 'express';
import { AppError } from '../utils/api-error';

export const authorize = (...allowedRoles: string[]) => {
    return (req: Request, _res: Response, next: NextFunction): void => {
        if (!req.user) {
            next(AppError.unauthorized());
            return;
        }

        if (!allowedRoles.includes(req.user.role)) {
            next(AppError.forbidden(`Role "${req.user.role}" is not authorized for this resource`));
            return;
        }

        next();
    };
};
