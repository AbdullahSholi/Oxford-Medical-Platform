// ═══════════════════════════════════════════════════════════
// MedOrder — Unit Tests: withDeadlockRetry & withRetry
// ═══════════════════════════════════════════════════════════

import { withDeadlockRetry, withRetry } from '../../src/shared/utils/retry';

// Mock the db-error-handler module
jest.mock('../../src/shared/utils/db-error-handler', () => ({
    isDeadlockError: (error: any) => error?.meta?.code === '40P01',
}));

// Mock logger
jest.mock('../../src/config/logger', () => ({
    logger: {
        warn: jest.fn(),
        error: jest.fn(),
        info: jest.fn(),
        debug: jest.fn(),
    },
}));

describe('withDeadlockRetry', () => {
    it('should return result on first try when no deadlock', async () => {
        const result = await withDeadlockRetry(async () => 'success');
        expect(result).toBe('success');
    });

    it('should retry on deadlock and succeed on second attempt', async () => {
        let attempt = 0;
        const result = await withDeadlockRetry(async () => {
            attempt++;
            if (attempt === 1) {
                const error: any = new Error('deadlock');
                error.meta = { code: '40P01' };
                throw error;
            }
            return 'recovered';
        });

        expect(result).toBe('recovered');
        expect(attempt).toBe(2);
    });

    it('should throw after exhausting retries on persistent deadlock', async () => {
        const operation = async () => {
            const error: any = new Error('deadlock');
            error.meta = { code: '40P01' };
            throw error;
        };

        await expect(withDeadlockRetry(operation, 3)).rejects.toThrow('deadlock');
    });

    it('should NOT retry on non-deadlock errors', async () => {
        let attempt = 0;
        const operation = async () => {
            attempt++;
            throw new Error('some other error');
        };

        await expect(withDeadlockRetry(operation)).rejects.toThrow('some other error');
        expect(attempt).toBe(1); // No retry
    });

    it('should respect custom maxRetries', async () => {
        let attempt = 0;
        const operation = async () => {
            attempt++;
            const error: any = new Error('deadlock');
            error.meta = { code: '40P01' };
            throw error;
        };

        await expect(withDeadlockRetry(operation, 5)).rejects.toThrow();
        expect(attempt).toBe(5);
    });
});

describe('withRetry', () => {
    it('should retry based on custom predicate', async () => {
        let attempt = 0;
        const result = await withRetry(
            async () => {
                attempt++;
                if (attempt < 3) throw new Error('temp');
                return 'done';
            },
            (err) => (err as Error).message === 'temp',
            5,
            10,
        );

        expect(result).toBe('done');
        expect(attempt).toBe(3);
    });

    it('should not retry when predicate returns false', async () => {
        let attempt = 0;
        await expect(
            withRetry(
                async () => {
                    attempt++;
                    throw new Error('permanent');
                },
                () => false, // Never retry
                5,
            ),
        ).rejects.toThrow('permanent');
        expect(attempt).toBe(1);
    });
});
