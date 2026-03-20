// ═══════════════════════════════════════════════════════════
// MedOrder — Unit Tests: handleDatabaseError
// ═══════════════════════════════════════════════════════════

import { Prisma } from '@prisma/client';
import { handleDatabaseError, isDeadlockError, isLockTimeoutError } from '../../src/shared/utils/db-error-handler';
import { AppError } from '../../src/shared/utils/api-error';

// Mock logger
jest.mock('../../src/config/logger', () => ({
    logger: {
        warn: jest.fn(),
        error: jest.fn(),
        info: jest.fn(),
        debug: jest.fn(),
    },
}));

describe('handleDatabaseError', () => {
    it('should handle Prisma P2002 (unique constraint)', () => {
        const prismaError = new Prisma.PrismaClientKnownRequestError(
            'Unique constraint violated',
            { code: 'P2002', clientVersion: '5.0.0', meta: { target: ['email'] } },
        );

        const result = handleDatabaseError(prismaError);
        expect(result).toBeInstanceOf(AppError);
        expect(result?.code).toBe('DUPLICATE_ENTRY');
        expect(result?.statusCode).toBe(409);
    });

    it('should handle Prisma P2025 (record not found)', () => {
        const prismaError = new Prisma.PrismaClientKnownRequestError(
            'Record not found',
            { code: 'P2025', clientVersion: '5.0.0' },
        );

        const result = handleDatabaseError(prismaError);
        expect(result).toBeInstanceOf(AppError);
        expect(result?.code).toBe('NOT_FOUND');
        expect(result?.statusCode).toBe(404);
    });

    it('should handle PostgreSQL lock timeout (55P03)', () => {
        const prismaError = new Prisma.PrismaClientKnownRequestError(
            'Lock not available',
            { code: 'P2010', clientVersion: '5.0.0', meta: { code: '55P03' } },
        );

        const result = handleDatabaseError(prismaError);
        expect(result).toBeInstanceOf(AppError);
        expect(result?.code).toBe('LOCK_TIMEOUT');
        expect(result?.statusCode).toBe(409);
    });

    it('should handle PostgreSQL deadlock (40P01)', () => {
        const prismaError = new Prisma.PrismaClientKnownRequestError(
            'Deadlock detected',
            { code: 'P2010', clientVersion: '5.0.0', meta: { code: '40P01' } },
        );

        const result = handleDatabaseError(prismaError);
        expect(result).toBeInstanceOf(AppError);
        expect(result?.code).toBe('DEADLOCK_DETECTED');
        expect(result?.statusCode).toBe(409);
    });

    it('should handle PostgreSQL query cancelled (57014)', () => {
        const prismaError = new Prisma.PrismaClientKnownRequestError(
            'Query cancelled',
            { code: 'P2010', clientVersion: '5.0.0', meta: { code: '57014' } },
        );

        const result = handleDatabaseError(prismaError);
        expect(result).toBeInstanceOf(AppError);
        expect(result?.code).toBe('QUERY_TIMEOUT');
        expect(result?.statusCode).toBe(504);
    });

    it('should return null for unrecognized errors', () => {
        const result = handleDatabaseError(new Error('random error'));
        expect(result).toBeNull();
    });

    it('should handle raw PostgreSQL errors with code property', () => {
        const rawError = { code: '55P03', message: 'lock timeout' };
        const result = handleDatabaseError(rawError);
        expect(result).toBeInstanceOf(AppError);
        expect(result?.code).toBe('LOCK_TIMEOUT');
    });
});

describe('isDeadlockError', () => {
    it('should return true for deadlock Prisma error', () => {
        const prismaError = new Prisma.PrismaClientKnownRequestError(
            'deadlock',
            { code: 'P2010', clientVersion: '5.0.0', meta: { code: '40P01' } },
        );
        expect(isDeadlockError(prismaError)).toBe(true);
    });

    it('should return false for non-deadlock error', () => {
        expect(isDeadlockError(new Error('not a deadlock'))).toBe(false);
    });

    it('should handle raw error objects', () => {
        expect(isDeadlockError({ code: '40P01' })).toBe(true);
        expect(isDeadlockError({ code: '55P03' })).toBe(false);
    });
});

describe('isLockTimeoutError', () => {
    it('should return true for lock timeout error', () => {
        expect(isLockTimeoutError({ code: '55P03' })).toBe(true);
    });

    it('should return false for other errors', () => {
        expect(isLockTimeoutError({ code: '40P01' })).toBe(false);
        expect(isLockTimeoutError(new Error('nope'))).toBe(false);
    });
});
