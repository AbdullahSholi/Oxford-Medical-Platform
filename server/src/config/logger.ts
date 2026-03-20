// ═══════════════════════════════════════════════════════════
// MedOrder — Pino Logger Configuration
// Structured JSON logging in production, pretty in development
// ═══════════════════════════════════════════════════════════

import pino from 'pino';
import { env, isDevelopment } from './env';

export const logger = pino({
    level: isDevelopment ? 'debug' : 'info',
    transport: isDevelopment
        ? {
            target: 'pino-pretty',
            options: {
                colorize: true,
                translateTime: 'SYS:HH:MM:ss',
                ignore: 'pid,hostname',
            },
        }
        : undefined,
    base: {
        env: env.NODE_ENV,
    },
    serializers: {
        err: pino.stdSerializers.err,
        req: pino.stdSerializers.req,
        res: pino.stdSerializers.res,
    },
    redact: {
        paths: ['req.headers.authorization', 'req.body.password', 'req.body.otp'],
        censor: '[REDACTED]',
    },
});

export default logger;
