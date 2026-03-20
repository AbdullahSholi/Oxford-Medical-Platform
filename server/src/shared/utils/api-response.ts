// ═══════════════════════════════════════════════════════════
// MedOrder — Standardized API Response Helper
// { success, data, error, meta }
// ═══════════════════════════════════════════════════════════

import { Response } from 'express';

interface PaginationMeta {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
    hasNext: boolean;
    hasPrev: boolean;
}

interface ApiResponseOptions<T> {
    data?: T;
    message?: string;
    meta?: PaginationMeta | Record<string, unknown>;
    statusCode?: number;
}

export class ApiResponse {
    static success<T>(res: Response, options: ApiResponseOptions<T> = {}): Response {
        const { data = null, message = 'Success', meta, statusCode = 200 } = options;
        const body: Record<string, any> = {
            success: true,
            message,
            data,
        };
        if (meta) {
            body.meta = meta;
        }
        return res.status(statusCode).json(body);
    }

    static created<T>(res: Response, data: T, message = 'Created successfully'): Response {
        return res.status(201).json({
            success: true,
            message,
            data,
        });
    }

    static noContent(res: Response): Response {
        return res.status(204).send();
    }

    static error(
        res: Response,
        statusCode: number,
        code: string,
        message: string,
        details?: unknown,
    ): Response {
        const body: Record<string, any> = {
            success: false,
            error: {
                code,
                message,
            },
        };
        if (details) {
            body.error.details = details;
        }
        return res.status(statusCode).json(body);
    }

    static paginated<T>(
        res: Response,
        data: T[],
        total: number,
        page: number,
        limit: number,
    ): Response {
        const totalPages = Math.ceil(total / limit);
        return res.status(200).json({
            success: true,
            data,
            meta: {
                page,
                limit,
                total,
                totalPages,
                hasNext: page < totalPages,
                hasPrev: page > 1,
            },
        });
    }
}
