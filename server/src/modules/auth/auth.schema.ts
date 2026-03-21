import { z } from 'zod';

export const registerSchema = z.object({
    fullName: z.string().trim().min(3).max(200),
    email: z.string().trim().email().max(255),
    phone: z.string().trim().regex(/^\+?[1-9]\d{7,14}$/, 'Invalid phone number'),
    password: z.string().min(8).max(128),
    clinicName: z.string().trim().min(2).max(300).optional(),
    specialty: z.string().trim().min(2).max(100).optional(),
    city: z.string().trim().min(2).max(100).optional(),
    clinicAddress: z.string().trim().min(5).optional(),
    licenseNumber: z.string().trim().min(2).max(50).optional(),
});

export const loginSchema = z.object({
    email: z.string().trim().email(),
    password: z.string().min(1).max(128),
});

export const sendOtpSchema = z.object({
    email: z.string().trim().email(),
});

export const verifyOtpSchema = z.object({
    email: z.string().trim().email(),
    otp: z.string().trim().length(6),
});

export const resetPasswordSchema = z.object({
    email: z.string().trim().email(),
    otp: z.string().trim().length(6),
    newPassword: z.string().min(8).max(128),
});

export const refreshTokenSchema = z.object({
    refreshToken: z.string().min(1),
});

export type RegisterInput = z.infer<typeof registerSchema>;
export type LoginInput = z.infer<typeof loginSchema>;
export type SendOtpInput = z.infer<typeof sendOtpSchema>;
export type VerifyOtpInput = z.infer<typeof verifyOtpSchema>;
export type ResetPasswordInput = z.infer<typeof resetPasswordSchema>;
export const changePasswordSchema = z.object({
    currentPassword: z.string().min(1).max(128),
    newPassword: z.string().min(8).max(128),
});

export type RefreshTokenInput = z.infer<typeof refreshTokenSchema>;
export type ChangePasswordInput = z.infer<typeof changePasswordSchema>;
