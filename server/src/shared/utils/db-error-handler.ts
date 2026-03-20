// ═══════════════════════════════════════════════════════════
// MedOrder — Database Error Handler
// Translates PostgreSQL & Prisma errors into AppError
// Used both in the global error middleware and at the service level
// ═══════════════════════════════════════════════════════════

import { Prisma } from '@prisma/client';
import { AppError } from './api-error';
import { logger } from '../../config/logger';

/**
 * PostgreSQL error code mapping.
 * @see https://www.postgresql.org/docs/current/errcodes-appendix.html
 */
const PG_ERROR_CODES = {
    LOCK_NOT_AVAILABLE: '55P03',
    DEADLOCK_DETECTED: '40P01',
    QUERY_CANCELLED: '57014',
    UNIQUE_VIOLATION: '23505',
    CHECK_VIOLATION: '23514',
    FOREIGN_KEY_VIOLATION: '23503',
    NOT_NULL_VIOLATION: '23502',
} as const;

/**
 * Translates a database-level error into an appropriate AppError.
 * Call this from services or from the global error handler.
 *
 * @param error - The raw error from Prisma or raw SQL
 * @returns An AppError if the error is recognized, or null if it should be re-thrown
 */
export function handleDatabaseError(error: unknown): AppError | null {
    // ── Prisma known request errors ───────────────────────
    if (error instanceof Prisma.PrismaClientKnownRequestError) {
        const pgCode = (error.meta as Record<string, unknown>)?.code as string | undefined;

        // PostgreSQL lock errors (from raw SQL / FOR UPDATE)
        if (pgCode === PG_ERROR_CODES.LOCK_NOT_AVAILABLE) {
            logger.warn({ pgCode, meta: error.meta }, 'Lock timeout — resource contention');
            return AppError.lockTimeout();
        }

        if (pgCode === PG_ERROR_CODES.DEADLOCK_DETECTED) {
            logger.warn({ pgCode, meta: error.meta }, 'Deadlock detected');
            return AppError.deadlock();
        }

        if (pgCode === PG_ERROR_CODES.QUERY_CANCELLED) {
            logger.warn({ pgCode, meta: error.meta }, 'Query cancelled — statement timeout');
            return new AppError('QUERY_TIMEOUT', 'Operation timed out, please retry', 504);
        }

        // Prisma unique constraint (P2002)
        if (error.code === 'P2002') {
            const target = (error.meta?.target as string[])?.join(', ') || 'field';
            return new AppError('DUPLICATE_ENTRY', `A record with this ${target} already exists`, 409);
        }

        // Prisma record not found (P2025)
        if (error.code === 'P2025') {
            return AppError.notFound('Record');
        }

        // Prisma invalid argument value (P2023) — e.g. invalid UUID
        if (error.code === 'P2023') {
            return new AppError('INVALID_ID', 'Invalid ID format', 400);
        }

        // Check constraint violation
        if (pgCode === PG_ERROR_CODES.CHECK_VIOLATION) {
            const constraint = (error.meta as Record<string, unknown>)?.constraint as string || 'validation';
            return new AppError('VALIDATION_FAILED', `Database constraint violated: ${constraint}`, 422);
        }

        // Foreign key violation
        if (pgCode === PG_ERROR_CODES.FOREIGN_KEY_VIOLATION) {
            return new AppError('REFERENCE_ERROR', 'Referenced record does not exist', 422);
        }

        // Catch-all for invalid UUID in known request errors
        if (error.message.includes('invalid input syntax for type uuid')) {
            return new AppError('INVALID_ID', 'Invalid ID format', 400);
        }

        return null; // Unknown Prisma error — let caller handle
    }

    // ── Prisma validation error (e.g. invalid UUID) ──────
    if (error instanceof Prisma.PrismaClientValidationError) {
        if (error.message.includes('uuid') || error.message.includes('Uuid')) {
            return new AppError('INVALID_ID', 'Invalid ID format', 400);
        }
        return new AppError('VALIDATION_ERROR', 'Invalid request parameters', 400);
    }

    // ── Prisma initialization error ───────────────────────
    if (error instanceof Prisma.PrismaClientInitializationError) {
        logger.error({ err: error }, 'Database connection failed');
        return AppError.internal('Database connection failed');
    }

    // ── Raw PostgreSQL errors (from $queryRaw / $executeRaw) ──
    if (typeof error === 'object' && error !== null) {
        const rawError = error as Record<string, unknown>;
        const code = rawError.code as string | undefined;

        if (code === PG_ERROR_CODES.LOCK_NOT_AVAILABLE) {
            return AppError.lockTimeout();
        }
        if (code === PG_ERROR_CODES.DEADLOCK_DETECTED) {
            return AppError.deadlock();
        }
        if (code === PG_ERROR_CODES.QUERY_CANCELLED) {
            return new AppError('QUERY_TIMEOUT', 'Operation timed out, please retry', 504);
        }
        // Invalid input syntax (e.g. invalid UUID format)
        if (code === '22P02') {
            return new AppError('INVALID_ID', 'Invalid ID format', 400);
        }
    }

    // ── Prisma raw query error with invalid UUID ──────────
    if (error instanceof Error && error.message.includes('invalid input syntax for type uuid')) {
        return new AppError('INVALID_ID', 'Invalid ID format', 400);
    }

    return null; // Not a recognized database error
}

/**
 * Checks if an error is a deadlock error (for retry logic).
 */
export function isDeadlockError(error: unknown): boolean {
    if (error instanceof Prisma.PrismaClientKnownRequestError) {
        return (error.meta as Record<string, unknown>)?.code === PG_ERROR_CODES.DEADLOCK_DETECTED;
    }
    if (typeof error === 'object' && error !== null) {
        return (error as Record<string, unknown>).code === PG_ERROR_CODES.DEADLOCK_DETECTED;
    }
    return false;
}

/**
 * Checks if an error is a lock timeout error (NOWAIT).
 */
export function isLockTimeoutError(error: unknown): boolean {
    if (error instanceof Prisma.PrismaClientKnownRequestError) {
        return (error.meta as Record<string, unknown>)?.code === PG_ERROR_CODES.LOCK_NOT_AVAILABLE;
    }
    if (typeof error === 'object' && error !== null) {
        return (error as Record<string, unknown>).code === PG_ERROR_CODES.LOCK_NOT_AVAILABLE;
    }
    return false;
}
