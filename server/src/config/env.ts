// ═══════════════════════════════════════════════════════════
// MedOrder — Environment Configuration (Validated with Zod)
// Fail-fast on missing/invalid variables at startup
// ═══════════════════════════════════════════════════════════

import { z } from 'zod';
import dotenv from 'dotenv';
import path from 'path';

dotenv.config({ path: path.resolve(__dirname, '../../.env') });

const envSchema = z.object({
    // ── Server
    NODE_ENV: z.enum(['development', 'staging', 'production']).default('development'),
    PORT: z.coerce.number().default(3000),
    API_PREFIX: z.string().default('/api/v1'),
    CORS_ORIGINS: z.string().default('http://localhost:3000'),

    // ── Database
    DATABASE_URL: z.string().url(),
    DATABASE_POOL_MIN: z.coerce.number().default(2),
    DATABASE_POOL_MAX: z.coerce.number().default(10),

    // ── Redis
    REDIS_URL: z.string().default('redis://localhost:6379'),

    // ── Auth
    JWT_ACCESS_SECRET: z.string().min(16),
    JWT_REFRESH_SECRET: z.string().min(16),
    JWT_ACCESS_EXPIRY: z.string().default('15m'),
    JWT_REFRESH_EXPIRY: z.string().default('7d'),
    BCRYPT_ROUNDS: z.coerce.number().min(10).max(14).default(12),
    OTP_EXPIRY_SECONDS: z.coerce.number().default(300),

    // ── Storage (S3 / MinIO)
    S3_BUCKET: z.string().default('medorder-uploads'),
    S3_REGION: z.string().default('eu-central-1'),
    S3_ACCESS_KEY: z.string().optional().default(''),
    S3_SECRET_KEY: z.string().optional().default(''),
    S3_ENDPOINT: z.string().optional().default(''),
    CDN_BASE_URL: z.string().optional().default(''),

    // ── Notifications
    FIREBASE_PROJECT_ID: z.string().optional().default(''),
    FIREBASE_CREDENTIALS_PATH: z.string().optional().default(''),
    TWILIO_SID: z.string().optional().default(''),
    TWILIO_AUTH_TOKEN: z.string().optional().default(''),
    TWILIO_PHONE: z.string().optional().default(''),
    SENDGRID_API_KEY: z.string().optional().default(''),
    SMTP_HOST: z.string().optional().default(''),
    SMTP_PORT: z.coerce.number().optional().default(587),
    SMTP_USER: z.string().optional().default(''),
    SMTP_PASS: z.string().optional().default(''),
    EMAIL_FROM: z.string().email().default('noreply@medorder.com'),

    // ── Rate Limiting
    RATE_LIMIT_WINDOW_MS: z.coerce.number().default(60000),
    RATE_LIMIT_MAX: z.coerce.number().default(100),
    LOGIN_RATE_LIMIT_MAX: z.coerce.number().default(5),
    LOGIN_RATE_LIMIT_WINDOW_MS: z.coerce.number().default(900000),

    // ── Monitoring
    SENTRY_DSN: z.string().optional().default(''),
});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
    console.error('❌ Invalid environment variables:');
    console.error(parsed.error.flatten().fieldErrors);
    process.exit(1);
}

export const env = parsed.data;

export const isProduction = env.NODE_ENV === 'production';
export const isDevelopment = env.NODE_ENV === 'development';
