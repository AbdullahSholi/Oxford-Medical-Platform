// ═══════════════════════════════════════════════════════════
// MedOrder — Deadlock Retry Utility
// Auto-retries operations that fail due to PostgreSQL deadlocks
// with exponential backoff.
// ═══════════════════════════════════════════════════════════

import { isDeadlockError } from './db-error-handler';
import { logger } from '../../config/logger';

/**
 * Wraps an async operation with automatic deadlock retry.
 *
 * When a PostgreSQL deadlock (40P01) is detected, the operation
 * is retried up to `maxRetries` times with exponential backoff
 * (50ms → 100ms → 200ms).
 *
 * @param operation - The async function to run (typically a Prisma transaction)
 * @param maxRetries - Maximum number of retry attempts (default: 3)
 * @returns The result of the operation
 * @throws The last error if all retries are exhausted
 *
 * @example
 * ```typescript
 * const order = await withDeadlockRetry(async () => {
 *     return prisma.$transaction(async (tx) => {
 *         // ... lock rows and perform updates ...
 *     });
 * });
 * ```
 */
export async function withDeadlockRetry<T>(
    operation: () => Promise<T>,
    maxRetries = 3,
): Promise<T> {
    for (let attempt = 1; attempt <= maxRetries; attempt++) {
        try {
            return await operation();
        } catch (error) {
            if (isDeadlockError(error) && attempt < maxRetries) {
                // Exponential backoff: 50ms, 100ms, 200ms
                const delay = 50 * Math.pow(2, attempt - 1);
                logger.warn(
                    { attempt, maxRetries, delayMs: delay },
                    `Deadlock detected — retrying (attempt ${attempt}/${maxRetries})`,
                );
                await sleep(delay);
                continue;
            }
            throw error;
        }
    }
    // This is unreachable because the loop either returns or throws,
    // but TypeScript needs it for exhaustiveness
    throw new Error('Unreachable: withDeadlockRetry exhausted all attempts');
}

/**
 * Wraps an async operation with a general retry mechanism.
 * Retries on any error matching the predicate.
 *
 * @param operation - The async function to run
 * @param shouldRetry - Predicate testing if the error is retryable
 * @param maxRetries - Maximum retry attempts
 * @param baseDelayMs - Base delay for exponential backoff
 */
export async function withRetry<T>(
    operation: () => Promise<T>,
    shouldRetry: (error: unknown) => boolean,
    maxRetries = 3,
    baseDelayMs = 50,
): Promise<T> {
    for (let attempt = 1; attempt <= maxRetries; attempt++) {
        try {
            return await operation();
        } catch (error) {
            if (shouldRetry(error) && attempt < maxRetries) {
                const delay = baseDelayMs * Math.pow(2, attempt - 1);
                const jitter = Math.random() * delay * 0.3; // Add 0-30% jitter
                await sleep(delay + jitter);
                continue;
            }
            throw error;
        }
    }
    throw new Error('Unreachable: withRetry exhausted all attempts');
}

/**
 * Promise-based sleep utility.
 */
function sleep(ms: number): Promise<void> {
    return new Promise((resolve) => setTimeout(resolve, ms));
}
