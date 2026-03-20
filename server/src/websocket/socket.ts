// ═══════════════════════════════════════════════════════════
// MedOrder — Socket.io Server Setup
// Real-time: order tracking, live notifications
// ═══════════════════════════════════════════════════════════

import { Server as HttpServer } from 'http';
import { Server, Socket } from 'socket.io';
import jwt from 'jsonwebtoken';
import { env } from '../config/env';
import { logger } from '../config/logger';

let io: Server;

export function initializeSocketServer(httpServer: HttpServer): Server {
    io = new Server(httpServer, {
        cors: {
            origin: env.CORS_ORIGINS.split(',').map((o) => o.trim()),
            credentials: true,
        },
        pingInterval: 25000,
        pingTimeout: 10000,
    });

    // ── Authentication middleware ─────────────────────────
    io.use((socket, next) => {
        const token = socket.handshake.auth.token;
        if (!token) {
            return next(new Error('Authentication required'));
        }

        try {
            const decoded = jwt.verify(token, env.JWT_ACCESS_SECRET) as any;
            (socket as any).userId = decoded.sub;
            (socket as any).userRole = decoded.role;
            next();
        } catch {
            next(new Error('Invalid token'));
        }
    });

    // ── Connection handler ────────────────────────────────
    io.on('connection', (socket: Socket) => {
        const userId = (socket as any).userId;
        logger.info({ userId, socketId: socket.id }, 'WebSocket client connected');

        // Join user-specific room for targeted notifications
        socket.join(`user:${userId}`);

        // ── Order tracking ────────────────────────────────
        socket.on('track:order', (orderId: string) => {
            socket.join(`order:${orderId}`);
            logger.debug({ userId, orderId }, 'Joined order tracking room');
        });

        socket.on('untrack:order', (orderId: string) => {
            socket.leave(`order:${orderId}`);
        });

        socket.on('disconnect', (reason) => {
            logger.debug({ userId, socketId: socket.id, reason }, 'WebSocket client disconnected');
        });
    });

    logger.info('🔌 Socket.io server initialized');
    return io;
}

// ── Emit helpers (used from services) ───────────────────
export function emitToUser(userId: string, event: string, data: unknown): void {
    io?.to(`user:${userId}`).emit(event, data);
}

export function emitOrderUpdate(orderId: string, data: unknown): void {
    io?.to(`order:${orderId}`).emit('order:status-updated', data);
}

export function getIO(): Server {
    if (!io) throw new Error('Socket.io not initialized');
    return io;
}
