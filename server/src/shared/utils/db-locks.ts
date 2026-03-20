// ═══════════════════════════════════════════════════════════
// MedOrder — Pessimistic Locking Utilities
// Provides helpers for row-level locking, lock timeouts,
// and consistent lock ordering to prevent deadlocks.
// ═══════════════════════════════════════════════════════════

import { PrismaClient, Prisma } from '@prisma/client';

/**
 * Lock timeout presets (matches Part 4 spec §4.3)
 */
export const LOCK_TIMEOUTS = {
    /** Standard checkout (max 15s wait for lock) */
    CHECKOUT: '15s',
    /** Flash sale purchase (fail-fast, 2s max) */
    FLASH_SALE: '2s',
    /** Background worker processing (5s max) */
    BACKGROUND: '5s',
    /** Admin operations (10s max) */
    ADMIN: '10s',
    /** Default fallback (30s) */
    DEFAULT: '30s',
} as const;

/**
 * Lock ordering constants.
 * When locking rows from multiple tables in a single transaction,
 * ALWAYS acquire locks in this order to prevent deadlocks.
 *
 *   1. carts
 *   2. products        (sorted by id ASC)
 *   3. flash_sale_products (sorted by id ASC)
 *   4. discounts
 *   5. orders
 */
export const LOCK_ORDER = {
    CARTS: 1,
    PRODUCTS: 2,
    FLASH_SALE_PRODUCTS: 3,
    DISCOUNTS: 4,
    ORDERS: 5,
} as const;

/**
 * Sets the lock timeout for the CURRENT transaction.
 * Must be called inside a `prisma.$transaction()` block.
 *
 * @example
 * await prisma.$transaction(async (tx) => {
 *   await setLockTimeout(tx, 'CHECKOUT');
 *   // ... rest of transaction
 * });
 */
export async function setLockTimeout(
    tx: Prisma.TransactionClient,
    preset: keyof typeof LOCK_TIMEOUTS,
): Promise<void> {
    const timeout = LOCK_TIMEOUTS[preset];
    await tx.$executeRawUnsafe(`SET LOCAL lock_timeout = '${timeout}'`);
}

/**
 * Locks a single row by ID using FOR UPDATE.
 *
 * @returns The locked row (raw SQL result)
 */
export async function lockRowById<T>(
    tx: Prisma.TransactionClient,
    table: string,
    id: string,
): Promise<T | null> {
    const rows = await tx.$queryRawUnsafe<T[]>(
        `SELECT * FROM "${table}" WHERE id = $1::uuid FOR UPDATE`,
        id,
    );
    return rows[0] ?? null;
}

/**
 * Locks multiple rows by ID using FOR UPDATE, sorted by id ASC
 * to prevent deadlocks.
 *
 * @param ids - Row IDs (will be sorted ascending before locking)
 * @returns The locked rows in ascending ID order
 */
export async function lockRowsByIds<T>(
    tx: Prisma.TransactionClient,
    table: string,
    ids: string[],
): Promise<T[]> {
    if (ids.length === 0) return [];

    // Sort IDs to guarantee consistent lock ordering
    const sorted = [...ids].sort();
    return tx.$queryRawUnsafe<T[]>(
        `SELECT * FROM "${table}" WHERE id = ANY($1::uuid[]) ORDER BY id ASC FOR UPDATE`,
        sorted,
    );
}

/**
 * Locks a single row using FOR UPDATE NOWAIT.
 * Throws immediately if the row is already locked — used for
 * high-contention scenarios like flash sale purchases.
 *
 * @throws Error with code 55P03 (lock_not_available) if lock is held
 */
export async function lockRowNowait<T>(
    tx: Prisma.TransactionClient,
    table: string,
    id: string,
): Promise<T | null> {
    const rows = await tx.$queryRawUnsafe<T[]>(
        `SELECT * FROM "${table}" WHERE id = $1::uuid FOR UPDATE NOWAIT`,
        id,
    );
    return rows[0] ?? null;
}

/**
 * Locks rows using FOR UPDATE SKIP LOCKED.
 * Skips any rows held by other transactions — used for
 * background job workers to pick the next unlocked batch.
 *
 * @param where  - SQL WHERE clause fragment (e.g. "status = 'pending'")
 * @param orderBy - SQL ORDER BY clause (e.g. "created_at ASC")
 * @param limit  - Max rows to lock
 */
export async function lockRowsSkipLocked<T>(
    tx: Prisma.TransactionClient,
    table: string,
    where: string,
    orderBy: string,
    limit: number,
): Promise<T[]> {
    return tx.$queryRawUnsafe<T[]>(
        `SELECT * FROM "${table}" WHERE ${where} ORDER BY ${orderBy} LIMIT ${limit} FOR UPDATE SKIP LOCKED`,
    );
}

/**
 * Wraps a function in a Prisma interactive transaction with
 * a preset lock timeout and transaction timeout.
 *
 * @example
 * const order = await withLock(prisma, 'CHECKOUT', async (tx) => {
 *   await lockRowById(tx, 'carts', doctorId);
 *   // ...
 *   return newOrder;
 * });
 */
export async function withLock<T>(
    prisma: PrismaClient,
    preset: keyof typeof LOCK_TIMEOUTS,
    fn: (tx: Prisma.TransactionClient) => Promise<T>,
    txTimeout?: number,
): Promise<T> {
    const timeoutMs = txTimeout ?? parseTimeoutMs(LOCK_TIMEOUTS[preset]) * 2; // tx timeout = 2× lock timeout

    return prisma.$transaction(async (tx) => {
        await setLockTimeout(tx, preset);
        return fn(tx);
    }, { timeout: timeoutMs });
}

/**
 * Parse a PostgreSQL timeout string (e.g. '15s', '2s') to milliseconds.
 */
function parseTimeoutMs(timeout: string): number {
    const match = timeout.match(/^(\d+)(s|ms)$/);
    if (!match) return 30000;
    const [, value, unit] = match;
    return unit === 's' ? Number(value) * 1000 : Number(value);
}
