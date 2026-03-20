// ═══════════════════════════════════════════════════════════
// MedOrder — Prisma Client Singleton
// Prisma v7: uses driver adapter pattern with @prisma/adapter-pg
// ═══════════════════════════════════════════════════════════

import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { env, isDevelopment } from './env';

const globalForPrisma = globalThis as unknown as {
    prisma: PrismaClient | undefined;
};

function createPrismaClient(): PrismaClient {
    const adapter = new PrismaPg({
        connectionString: env.DATABASE_URL,
        min: env.DATABASE_POOL_MIN,
        max: env.DATABASE_POOL_MAX,
    });
    return new PrismaClient({ adapter });
}

export const prisma =
    globalForPrisma.prisma ?? createPrismaClient();

if (isDevelopment) {
    globalForPrisma.prisma = prisma;
}

export default prisma;
