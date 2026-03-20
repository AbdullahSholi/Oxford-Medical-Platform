// ═══════════════════════════════════════════════════════════
// MedOrder — Cloud Storage Service (S3 / MinIO)
// Handles file uploads, deletions, and presigned URL generation
// ═══════════════════════════════════════════════════════════

import {
    S3Client,
    PutObjectCommand,
    DeleteObjectCommand,
    GetObjectCommand,
    HeadBucketCommand,
} from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { randomUUID } from 'crypto';
import path from 'path';
import { env } from '../../config/env';

const s3 = new S3Client({
    region: env.S3_REGION,
    ...(env.S3_ENDPOINT && {
        endpoint: env.S3_ENDPOINT,
        forcePathStyle: true, // Required for MinIO
    }),
    ...(env.S3_ACCESS_KEY && env.S3_SECRET_KEY && {
        credentials: {
            accessKeyId: env.S3_ACCESS_KEY,
            secretAccessKey: env.S3_SECRET_KEY,
        },
    }),
});

const BUCKET = env.S3_BUCKET;

export interface UploadResult {
    key: string;
    url: string;
    contentType: string;
    size: number;
}

export class StorageService {
    private static initialized = false;

    static async ensureBucket(): Promise<void> {
        if (this.initialized) return;
        try {
            await s3.send(new HeadBucketCommand({ Bucket: BUCKET }));
            console.log(`📦 Bucket "${BUCKET}" is accessible`);
        } catch (e) {
            // R2 buckets must be created via Cloudflare dashboard.
            // Log warning but don't fail — PutObject may still work.
            console.warn(`⚠️ HeadBucket check failed for "${BUCKET}":`, (e as Error).message);
        }
        this.initialized = true;
    }

    /**
     * Upload a file buffer to S3/MinIO
     */
    static async upload(
        buffer: Buffer,
        originalName: string,
        contentType: string,
        folder: string = 'uploads',
    ): Promise<UploadResult> {
        await this.ensureBucket();

        const ext = path.extname(originalName);
        const key = `${folder}/${randomUUID()}${ext}`;

        await s3.send(new PutObjectCommand({
            Bucket: BUCKET,
            Key: key,
            Body: buffer,
            ContentType: contentType,
            CacheControl: 'max-age=31536000', // 1 year cache for immutable assets
        }));

        // Use CDN_BASE_URL if configured (Cloudflare R2 + custom domain)
        // Otherwise fall back to endpoint URL or standard S3 URL
        const url = env.CDN_BASE_URL
            ? `${env.CDN_BASE_URL}/${key}`
            : env.S3_ENDPOINT
                ? `${env.S3_ENDPOINT}/${BUCKET}/${key}`
                : `https://${BUCKET}.s3.${env.S3_REGION}.amazonaws.com/${key}`;

        return { key, url, contentType, size: buffer.length };
    }

    /**
     * Delete a file from S3/MinIO
     */
    static async delete(key: string): Promise<void> {
        await s3.send(new DeleteObjectCommand({
            Bucket: BUCKET,
            Key: key,
        }));
    }

    /**
     * Generate a presigned URL for temporary access (default 1 hour)
     */
    static async getPresignedUrl(key: string, expiresIn = 3600): Promise<string> {
        return getSignedUrl(s3, new GetObjectCommand({
            Bucket: BUCKET,
            Key: key,
        }), { expiresIn });
    }

    /**
     * Upload a product image
     */
    static async uploadProductImage(buffer: Buffer, originalName: string, contentType: string): Promise<UploadResult> {
        return this.upload(buffer, originalName, contentType, 'products');
    }

    /**
     * Upload a doctor's license document
     */
    static async uploadLicense(buffer: Buffer, originalName: string, contentType: string): Promise<UploadResult> {
        return this.upload(buffer, originalName, contentType, 'licenses');
    }

    /**
     * Upload a doctor's avatar
     */
    static async uploadAvatar(buffer: Buffer, originalName: string, contentType: string): Promise<UploadResult> {
        return this.upload(buffer, originalName, contentType, 'avatars');
    }

    /**
     * Upload a banner image
     */
    static async uploadBanner(buffer: Buffer, originalName: string, contentType: string): Promise<UploadResult> {
        return this.upload(buffer, originalName, contentType, 'banners');
    }
}
