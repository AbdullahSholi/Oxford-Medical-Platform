// ═══════════════════════════════════════════════════════════
// MedOrder — Test Setup
// Common setup for all test suites
// ═══════════════════════════════════════════════════════════

// Set test environment variables before anything else
process.env.NODE_ENV = 'test';
process.env.JWT_ACCESS_SECRET = 'test-access-secret-min16chars';
process.env.JWT_REFRESH_SECRET = 'test-refresh-secret-min16chars';
process.env.DATABASE_URL = process.env.DATABASE_URL || 'postgresql://test:test@localhost:5432/medorder_test';
process.env.REDIS_URL = process.env.REDIS_URL || 'redis://localhost:6379/1';
