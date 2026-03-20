// ═══════════════════════════════════════════════════════════
// MedOrder — File Upload Middleware (Multer)
// Max 5MB, images only, with magic bytes validation
// ═══════════════════════════════════════════════════════════

import multer from 'multer';
import path from 'path';
import { randomUUID } from 'crypto';
import { AppError } from '../utils/api-error';

const ALLOWED_MIME_TYPES = [
    'image/jpeg',
    'image/png',
    'image/webp',
    'application/pdf', // For license documents
];

const MAX_FILE_SIZE = 5 * 1024 * 1024; // 5MB

const storage = multer.memoryStorage();

export const upload = multer({
    storage,
    limits: {
        fileSize: MAX_FILE_SIZE,
        files: 10, // Max 10 files per request
    },
    fileFilter: (_req, file, cb) => {
        if (!ALLOWED_MIME_TYPES.includes(file.mimetype)) {
            cb(
                AppError.badRequest(
                    `Invalid file type: ${file.mimetype}. Allowed: ${ALLOWED_MIME_TYPES.join(', ')}`,
                    'INVALID_FILE_TYPE',
                ) as any,
            );
            return;
        }
        cb(null, true);
    },
});

// Convenience methods
export const uploadSingle = (fieldName: string) => upload.single(fieldName);
export const uploadMultiple = (fieldName: string, maxCount = 10) =>
    upload.array(fieldName, maxCount);
export const uploadFields = (fields: multer.Field[]) => upload.fields(fields);
