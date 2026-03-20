// ═══════════════════════════════════════════════════════════
// MedOrder — Integration Test: Global Setup
// Runs ONCE before all integration tests
// ═══════════════════════════════════════════════════════════

import { execSync } from 'child_process';

export default async function globalSetup(): Promise<void> {
    // Ensure test database is up-to-date
    console.log('🔧 Setting up test database...');

    // Push schema to test DB (faster than migrate for tests)
    execSync('npx prisma db push --force-reset --skip-generate', {
        stdio: 'inherit',
        env: {
            ...process.env,
            DATABASE_URL: process.env.DATABASE_URL || 'postgresql://test:test@localhost:5432/medorder_test',
        },
    });

    console.log('✅ Test database ready');
}
