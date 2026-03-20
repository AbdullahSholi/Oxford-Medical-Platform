// ═══════════════════════════════════════════════════════════
// MedOrder — Input Sanitization Middleware
// Strips potential XSS payloads from request body/query/params
// ═══════════════════════════════════════════════════════════

import { Request, Response, NextFunction } from 'express';

/**
 * Recursively sanitize all string values in an object.
 * Strips HTML tags and dangerous characters to prevent stored XSS.
 */
function sanitizeValue(value: unknown): unknown {
    if (typeof value === 'string') {
        return value
            .replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '') // Remove script tags
            .replace(/<[^>]*>/g, '')  // Remove HTML tags
            .replace(/javascript:/gi, '') // Remove javascript: protocol
            .replace(/on\w+\s*=/gi, '') // Remove inline event handlers (onclick=, onerror=, etc.)
            .trim();
    }
    if (Array.isArray(value)) {
        return value.map(sanitizeValue);
    }
    if (value && typeof value === 'object') {
        const sanitized: Record<string, unknown> = {};
        for (const [key, val] of Object.entries(value)) {
            sanitized[key] = sanitizeValue(val);
        }
        return sanitized;
    }
    return value;
}

/**
 * Express middleware that sanitizes req.body, req.query, and req.params.
 * Should be applied after body parsing and before route handlers.
 */
export function sanitizeInput(req: Request, _res: Response, next: NextFunction): void {
    if (req.body && typeof req.body === 'object') {
        req.body = sanitizeValue(req.body);
    }
    if (req.query && typeof req.query === 'object') {
        try {
            req.query = sanitizeValue(req.query) as any;
        } catch {
            // Express 5: req.query is a read-only getter; skip sanitization
            (req as any).sanitizedQuery = sanitizeValue(req.query);
        }
    }
    if (req.params && typeof req.params === 'object') {
        try {
            req.params = sanitizeValue(req.params) as any;
        } catch {
            // Express 5: req.params may be read-only
        }
    }
    next();
}
