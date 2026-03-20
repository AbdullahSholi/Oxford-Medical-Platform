// ═══════════════════════════════════════════════════════════
// MedOrder — Jest Configuration (Unit Tests)
// ═══════════════════════════════════════════════════════════

import type { Config } from 'jest';

const config: Config = {
    preset: 'ts-jest',
    testEnvironment: 'node',
    roots: ['<rootDir>/tests'],
    testMatch: [
        '**/tests/unit/**/*.test.ts',
        '**/tests/unit/**/*.spec.ts',
    ],
    moduleNameMapper: {
        '^@/(.*)$': '<rootDir>/src/$1',
        '^@config/(.*)$': '<rootDir>/src/config/$1',
        '^@shared/(.*)$': '<rootDir>/src/shared/$1',
        '^@modules/(.*)$': '<rootDir>/src/modules/$1',
        '^@jobs/(.*)$': '<rootDir>/src/jobs/$1',
    },
    collectCoverageFrom: [
        'src/**/*.ts',
        '!src/**/*.d.ts',
        '!src/index.ts',
        '!src/config/**',
    ],
    coverageThresholds: {
        global: {
            branches: 70,
            functions: 80,
            lines: 80,
            statements: 80,
        },
    },
    setupFilesAfterSetup: ['<rootDir>/tests/setup.ts'],
    clearMocks: true,
    verbose: true,
};

export default config;
