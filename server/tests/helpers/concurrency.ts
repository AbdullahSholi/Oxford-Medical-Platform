// ═══════════════════════════════════════════════════════════
// MedOrder — Concurrency Test Utilities
// Helpers for testing race conditions, deadlocks, and
// pessimistic locking in integration tests.
// ═══════════════════════════════════════════════════════════

import { PrismaClient } from '@prisma/client';

/**
 * Creates a Prisma client configured for the test database.
 * Each test should create its own client for isolation.
 */
export function createTestPrisma(): PrismaClient {
    return new PrismaClient({
        datasources: {
            db: {
                url: process.env.DATABASE_URL || 'postgresql://test:test@localhost:5432/medorder_test',
            },
        },
    });
}

/**
 * Runs N concurrent operations and collects their results.
 * This is the core helper for race condition testing.
 *
 * @param operations - Array of async functions to run concurrently
 * @returns Object with succeeded results and failed errors
 *
 * @example
 * ```typescript
 * const { succeeded, failed } = await runConcurrent([
 *     () => orderService.createOrder(doctor1, input),
 *     () => orderService.createOrder(doctor2, input),
 * ]);
 * expect(succeeded).toHaveLength(1);
 * expect(failed).toHaveLength(1);
 * expect(failed[0].code).toBe('INSUFFICIENT_STOCK');
 * ```
 */
export async function runConcurrent<T>(
    operations: Array<() => Promise<T>>,
): Promise<{
    succeeded: T[];
    failed: Array<{ error: unknown; code?: string; message?: string }>;
    results: Array<PromiseSettledResult<T>>;
}> {
    const results = await Promise.allSettled(operations.map((op) => op()));

    const succeeded: T[] = [];
    const failed: Array<{ error: unknown; code?: string; message?: string }> = [];

    for (const result of results) {
        if (result.status === 'fulfilled') {
            succeeded.push(result.value);
        } else {
            const err = result.reason;
            failed.push({
                error: err,
                code: err?.code ?? err?.constructor?.name,
                message: err?.message,
            });
        }
    }

    return { succeeded, failed, results };
}

/**
 * Creates N identical operations from a factory function.
 * Useful for fire-then-check concurrency tests.
 *
 * @example
 * ```typescript
 * const ops = nTimes(50, () => flashSaleService.purchase(doctorId, productId, 1));
 * const { succeeded, failed } = await runConcurrent(ops);
 * expect(succeeded).toHaveLength(10); // only 10 units available
 * ```
 */
export function nTimes<T>(n: number, factory: () => Promise<T>): Array<() => Promise<T>> {
    return Array.from({ length: n }, () => factory);
}

/**
 * Delays execution for the specified milliseconds.
 */
export function delay(ms: number): Promise<void> {
    return new Promise((resolve) => setTimeout(resolve, ms));
}

/**
 * Cleans up all rows from the specified tables in reverse FK order.
 * Use between test cases to ensure isolation.
 *
 * @param prisma - Prisma client instance
 * @param tables - Table names to truncate (in order)
 */
export async function cleanTables(prisma: PrismaClient, tables: string[]): Promise<void> {
    // Truncate in reverse order to avoid FK violations
    const reversed = [...tables].reverse();
    for (const table of reversed) {
        await prisma.$executeRawUnsafe(`TRUNCATE TABLE "${table}" CASCADE`);
    }
}

/**
 * Seeds a minimal set of test data for order flow testing.
 * Returns the IDs of created entities.
 */
export async function seedOrderTestData(prisma: PrismaClient): Promise<{
    doctorId: string;
    categoryId: string;
    productIds: string[];
    cartId: string;
}> {
    // Create doctor
    const doctor = await prisma.doctor.create({
        data: {
            email: `test-${Date.now()}@medorder.com`,
            passwordHash: '$2b$12$placeholder',
            fullName: 'Test Doctor',
            phone: '+1234567890',
            licenseNumber: `LIC-${Date.now()}`,
            specialization: 'General',
            clinicName: 'Test Clinic',
            city: 'Test City',
            status: 'approved',
        },
    });

    // Create category
    const category = await prisma.category.create({
        data: {
            name: `Test Category ${Date.now()}`,
            slug: `test-cat-${Date.now()}`,
        },
    });

    // Create products with limited stock
    const product1 = await prisma.product.create({
        data: {
            name: 'Test Product 1',
            slug: `test-prod-1-${Date.now()}`,
            description: 'Test product for concurrency testing',
            sku: `SKU-${Date.now()}-1`,
            price: 100,
            stock: 5,
            categoryId: category.id,
        },
    });

    const product2 = await prisma.product.create({
        data: {
            name: 'Test Product 2',
            slug: `test-prod-2-${Date.now()}`,
            description: 'Test product for concurrency testing',
            sku: `SKU-${Date.now()}-2`,
            price: 50,
            stock: 3,
            categoryId: category.id,
        },
    });

    // Create cart with items
    const cart = await prisma.cart.create({
        data: {
            doctorId: doctor.id,
            items: {
                create: [
                    { productId: product1.id, quantity: 2 },
                    { productId: product2.id, quantity: 1 },
                ],
            },
        },
    });

    return {
        doctorId: doctor.id,
        categoryId: category.id,
        productIds: [product1.id, product2.id],
        cartId: cart.id,
    };
}
