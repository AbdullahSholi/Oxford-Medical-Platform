// ═══════════════════════════════════════════════════════════
// MedOrder — Custom Application Error
// ═══════════════════════════════════════════════════════════

export class AppError extends Error {
    public readonly statusCode: number;
    public readonly code: string;
    public readonly isOperational: boolean;
    public readonly details?: unknown;

    constructor(
        code: string,
        message: string,
        statusCode: number = 500,
        details?: unknown,
        isOperational: boolean = true,
    ) {
        super(message);
        this.code = code;
        this.statusCode = statusCode;
        this.isOperational = isOperational;
        this.details = details;
        Object.setPrototypeOf(this, AppError.prototype);
        Error.captureStackTrace(this, this.constructor);
    }

    // ── Factory methods for common errors ─────────────────
    static badRequest(message: string, code = 'BAD_REQUEST', details?: unknown): AppError {
        return new AppError(code, message, 400, details);
    }

    static unauthorized(message = 'Authentication required', code = 'UNAUTHORIZED'): AppError {
        return new AppError(code, message, 401);
    }

    static forbidden(message = 'Insufficient permissions', code = 'FORBIDDEN'): AppError {
        return new AppError(code, message, 403);
    }

    static notFound(resource = 'Resource', code = 'NOT_FOUND'): AppError {
        return new AppError(code, `${resource} not found`, 404);
    }

    static conflict(message: string, code = 'CONFLICT'): AppError {
        return new AppError(code, message, 409);
    }

    static unprocessable(message: string, code = 'UNPROCESSABLE', details?: unknown): AppError {
        return new AppError(code, message, 422, details);
    }

    static tooManyRequests(message = 'Too many requests', code = 'RATE_LIMIT'): AppError {
        return new AppError(code, message, 429);
    }

    static internal(message = 'Internal server error', code = 'INTERNAL_ERROR'): AppError {
        return new AppError(code, message, 500, undefined, false);
    }

    // ── Lock-related errors ───────────────────────────────
    static lockTimeout(message = 'Resource is temporarily busy, please retry'): AppError {
        return new AppError('LOCK_TIMEOUT', message, 409);
    }

    static deadlock(message = 'Transaction conflict, please retry'): AppError {
        return new AppError('DEADLOCK_DETECTED', message, 409);
    }

    static insufficientStock(product: string, available: number, requested: number): AppError {
        return new AppError(
            'INSUFFICIENT_STOCK',
            `Insufficient stock for "${product}" (available: ${available}, requested: ${requested})`,
            422,
        );
    }

    static discountExhausted(code: string): AppError {
        return new AppError('DISCOUNT_EXHAUSTED', `Discount "${code}" usage limit reached`, 410);
    }

    static flashSaleEnded(reason = 'Flash sale has ended or sold out'): AppError {
        return new AppError('FLASH_SALE_ENDED', reason, 410);
    }

    static concurrentCheckout(): AppError {
        return new AppError(
            'CONCURRENT_CHECKOUT',
            'You already have a checkout in progress, please wait',
            409,
        );
    }

    static stockRace(product: string): AppError {
        return new AppError(
            'STOCK_RACE',
            `Stock for "${product}" changed during your transaction, please retry`,
            422,
        );
    }

    static invalidTransition(from: string, to: string): AppError {
        return new AppError(
            'INVALID_TRANSITION',
            `Cannot transition from "${from}" to "${to}"`,
            400,
        );
    }

    static queryTimeout(message = 'Operation timed out, please retry'): AppError {
        return new AppError('QUERY_TIMEOUT', message, 504);
    }
}
