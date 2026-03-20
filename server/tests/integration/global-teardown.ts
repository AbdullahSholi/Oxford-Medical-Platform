// ═══════════════════════════════════════════════════════════
// MedOrder — Integration Test: Global Teardown
// Runs ONCE after all integration tests
// ═══════════════════════════════════════════════════════════

import { PrismaClient } from '@prisma/client';

export default async function globalTeardown(): Promise<void> {
    console.log('🧹 Cleaning up test database...');

    const prisma = new PrismaClient();
    await prisma.$disconnect();

    console.log('✅ Test teardown complete');
}
