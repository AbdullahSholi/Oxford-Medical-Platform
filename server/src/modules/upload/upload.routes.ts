// ═══════════════════════════════════════════════════════════
// MedOrder — Upload Routes
// Handles image uploads to S3/MinIO cloud storage
// ═══════════════════════════════════════════════════════════

import { Router } from 'express';
import { authenticate } from '../../shared/middleware/authenticate';
import { uploadSingle, uploadMultiple } from '../../shared/middleware/upload';
import { asyncHandler } from '../../shared/utils/async-handler';
import { ApiResponse } from '../../shared/utils/api-response';
import { StorageService } from '../../shared/services/storage.service';
import { AppError } from '../../shared/utils/api-error';

export const uploadRoutes = Router();

// All upload routes require authentication
uploadRoutes.use(authenticate);

// Upload single image (generic)
uploadRoutes.post('/image', uploadSingle('file'), asyncHandler(async (req, res) => {
    if (!req.file) throw AppError.badRequest('No file provided');
    const folder = (req.query.folder as string) || 'uploads';
    const result = await StorageService.upload(
        req.file.buffer,
        req.file.originalname,
        req.file.mimetype,
        folder,
    );
    ApiResponse.created(res, result);
}));

// Upload product image
uploadRoutes.post('/product-image', uploadSingle('file'), asyncHandler(async (req, res) => {
    if (!req.file) throw AppError.badRequest('No file provided');
    const result = await StorageService.uploadProductImage(
        req.file.buffer,
        req.file.originalname,
        req.file.mimetype,
    );
    ApiResponse.created(res, result);
}));

// Upload multiple images
uploadRoutes.post('/images', uploadMultiple('files', 5), asyncHandler(async (req, res) => {
    const files = req.files as Express.Multer.File[];
    if (!files || files.length === 0) throw AppError.badRequest('No files provided');

    const folder = (req.query.folder as string) || 'uploads';
    const results = await Promise.all(
        files.map(f => StorageService.upload(f.buffer, f.originalname, f.mimetype, folder)),
    );
    ApiResponse.created(res, results);
}));

// Upload avatar
uploadRoutes.post('/avatar', uploadSingle('file'), asyncHandler(async (req, res) => {
    if (!req.file) throw AppError.badRequest('No file provided');
    const result = await StorageService.uploadAvatar(
        req.file.buffer,
        req.file.originalname,
        req.file.mimetype,
    );
    ApiResponse.created(res, result);
}));

// Delete uploaded file (by key)
uploadRoutes.delete('/:key', asyncHandler(async (req, res) => {
    await StorageService.delete(req.params.key as string);
    ApiResponse.noContent(res);
}));
