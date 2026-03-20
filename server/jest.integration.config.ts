// ═══════════════════════════════════════════════════════════
// MedOrder — Jest Configuration (Integration Tests)
// Uses real PostgreSQL test database for end-to-end testing
// ═══════════════════════════════════════════════════════════

import type { Config } from 'jest';

const config: Config = {
    preset: 'ts-jest',
    testEnvironment: 'node',
    roots: ['<rootDir>/tests'],
    testMatch: [
        '**/tests/integration/**/*.test.ts',
        '**/tests/integration/**/*.spec.ts',
    ],
    moduleNameMapper: {
        '^@/(.*)$': '<rootDir>/src/$1',
        '^@config/(.*)$': '<rootDir>/src/config/$1',
        '^@shared/(.*)$': '<rootDir>/src/shared/$1',
        '^@modules/(.*)$': '<rootDir>/src/modules/$1',
        '^@jobs/(.*)$': '<rootDir>/src/jobs/$1',
    },
    // Integration tests need more time (database operations)
    testTimeout: 30000,
    // Run sequentially to avoid DB conflicts
    maxWorkers: 1,
    // Global setup: reset DB before test suite
    globalSetup: '<rootDir>/tests/integration/global-setup.ts',
    globalTeardown: '<rootDir>/tests/integration/global-teardown.ts',
    setupFilesAfterSetup: ['<rootDir>/tests/setup.ts'],
    clearMocks: true,
    verbose: true,
};

export default config;
