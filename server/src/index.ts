// ═══════════════════════════════════════════════════════════
// MedOrder — Server Entry Point
// Starts HTTP + WebSocket servers, connects to DB + Redis
// ═══════════════════════════════════════════════════════════

import http from 'http';
import app from './app';
import { env } from './config/env';
import { logger } from './config/logger';
import prisma from './config/database';
import redis from './config/redis';
import { initializeSocketServer } from './websocket/socket';
import './jobs/workers';

async function bootstrap(): Promise<void> {
    try {
        // 1. Verify database connection
        await prisma.$connect();
        logger.info('✅ PostgreSQL connected');

        // 2. Verify Redis connection
        await redis.ping();
        logger.info('✅ Redis connected');

        // 3. Create HTTP server
        const server = http.createServer(app);

        // 4. Initialize Socket.io on the same HTTP server
        initializeSocketServer(server);

        // 5. Start listening
        server.listen(env.PORT, () => {
            logger.info(`🚀 MedOrder API server running on port ${env.PORT}`);
            logger.info(`📍 Environment: ${env.NODE_ENV}`);
            logger.info(`📍 API prefix: ${env.API_PREFIX}`);
            logger.info(`📍 Health check: http://localhost:${env.PORT}/health`);
        });

        // ── Graceful shutdown ─────────────────────────────────
        const shutdown = async (signal: string) => {
            logger.info(`${signal} received — shutting down gracefully...`);

            server.close(async () => {
                await prisma.$disconnect();
                redis.disconnect();
                logger.info('👋 Server shut down cleanly');
                process.exit(0);
            });

            // Force kill after 10 seconds
            setTimeout(() => {
                logger.error('Forced shutdown after 10s timeout');
                process.exit(1);
            }, 10000);
        };

        process.on('SIGTERM', () => shutdown('SIGTERM'));
        process.on('SIGINT', () => shutdown('SIGINT'));

        // ── Unhandled errors ──────────────────────────────────
        process.on('unhandledRejection', (reason) => {
            logger.error({ reason }, 'Unhandled Promise Rejection');
        });

        process.on('uncaughtException', (error) => {
            logger.fatal({ error }, 'Uncaught Exception — shutting down');
            process.exit(1);
        });
    } catch (error) {
        logger.fatal({ error }, '❌ Failed to start server');
        process.exit(1);
    }
}

bootstrap();
