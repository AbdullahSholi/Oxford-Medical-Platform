import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { randomUUID, createHash } from 'crypto';
import { env } from '../../config/env';
import redis from '../../config/redis';
import { AppError } from '../../shared/utils/api-error';
import { AuthRepository } from './auth.repository';
import { RegisterInput, LoginInput, ResetPasswordInput } from './auth.schema';
import { TokenPair, JwtPayload } from '../../shared/types/common';

export class AuthService {
    constructor(private repo: AuthRepository) { }

    async register(input: RegisterInput, licenseUrl: string): Promise<{ doctor: Record<string, unknown> }> {
        const existingEmail = await this.repo.findDoctorByEmail(input.email);
        if (existingEmail) throw AppError.conflict('Email already registered', 'DUPLICATE_EMAIL');

        const existingPhone = await this.repo.findDoctorByPhone(input.phone);
        if (existingPhone) throw AppError.conflict('Phone number already registered', 'DUPLICATE_PHONE');

        const passwordHash = await bcrypt.hash(input.password, env.BCRYPT_ROUNDS);

        const doctor = await this.repo.createDoctor({
            fullName: input.fullName,
            email: input.email,
            phone: input.phone,
            passwordHash,
            clinicName: input.clinicName ?? '',
            specialty: input.specialty ?? '',
            city: input.city ?? '',
            clinicAddress: input.clinicAddress ?? '',
            licenseUrl,
        });

        // Send welcome email (non-blocking)
        import('../../shared/services/email.service').then(({ sendEmail, welcomeEmail }) => {
            const emailData = welcomeEmail({ doctorName: input.fullName });
            sendEmail({ to: input.email, ...emailData }).catch((err) => {
                import('../../config/logger').then(({ logger }) => logger.error({ err }, 'Failed to send welcome email'));
            });
        });

        return { doctor };
    }

    async login(input: LoginInput): Promise<{ doctor: Record<string, unknown>; tokens: TokenPair }> {
        const doctor = await this.repo.findDoctorByEmail(input.email);
        if (!doctor) throw AppError.unauthorized('Invalid email or password', 'INVALID_CREDENTIALS');

        const passwordValid = await bcrypt.compare(input.password, doctor.passwordHash);
        if (!passwordValid) throw AppError.unauthorized('Invalid email or password', 'INVALID_CREDENTIALS');

        if (doctor.status === 'pending') {
            throw new AppError('ACCOUNT_PENDING', 'Your account is pending approval', 403);
        }
        if (doctor.status === 'rejected') {
            throw new AppError('ACCOUNT_REJECTED', 'Your account has been rejected', 403);
        }
        if (doctor.status === 'suspended') {
            throw new AppError('ACCOUNT_SUSPENDED', 'Your account has been suspended', 403);
        }

        const tokens = await this.generateTokens(doctor.id, 'doctor');
        await this.repo.updateDoctorLogin(doctor.id);
        await this.repo.ensureCart(doctor.id);

        const { passwordHash: _, refreshTokenHash: __, ...safeDoctor } = doctor;
        return { doctor: safeDoctor, tokens };
    }

    async adminLogin(email: string, password: string): Promise<{ admin: Record<string, unknown>; tokens: TokenPair }> {
        const admin = await this.repo.findAdminByEmail(email);
        if (!admin) throw AppError.unauthorized('Invalid credentials', 'INVALID_CREDENTIALS');
        if (!admin.isActive) throw AppError.forbidden('Account disabled');

        const valid = await bcrypt.compare(password, admin.passwordHash);
        if (!valid) throw AppError.unauthorized('Invalid credentials', 'INVALID_CREDENTIALS');

        const tokens = await this.generateTokens(admin.id, 'admin');
        await this.repo.updateAdminLogin(admin.id);

        const { passwordHash: _, ...safeAdmin } = admin;
        return { admin: safeAdmin, tokens };
    }

    async refreshToken(refreshToken: string): Promise<TokenPair> {
        const tokenHash = this.hashToken(refreshToken);
        const stored = await this.repo.findRefreshToken(tokenHash);

        if (!stored) throw AppError.unauthorized('Invalid refresh token');
        if (stored.expiresAt < new Date()) {
            await this.repo.revokeTokenFamily(stored.familyId);
            throw AppError.unauthorized('Refresh token expired');
        }

        // Rotate: revoke old, issue new
        await this.repo.revokeRefreshToken(stored.id);

        const userId = stored.doctorId || stored.adminId;
        const role = stored.doctorId ? 'doctor' : 'admin';
        if (!userId) throw AppError.unauthorized('Invalid refresh token');

        return this.generateTokens(userId, role, stored.familyId);
    }

    async sendOtp(email: string): Promise<void> {
        const doctor = await this.repo.findDoctorByEmail(email);
        if (!doctor) return; // Don't reveal whether email exists

        const otp = Math.floor(100000 + Math.random() * 900000).toString();
        await redis.setex(`otp:${email}`, env.OTP_EXPIRY_SECONDS, otp);
        if (env.NODE_ENV !== 'production') {
            console.log(`[DEV] OTP for ${email}: ${otp}`);
        }
        // TODO: Send OTP via email/SMS in production
    }

    async verifyOtp(email: string, otp: string): Promise<boolean> {
        const stored = await redis.get(`otp:${email}`);
        if (!stored || stored !== otp) return false;
        await redis.del(`otp:${email}`);
        return true;
    }

    async resetPassword(input: ResetPasswordInput): Promise<void> {
        const valid = await this.verifyOtp(input.email, input.otp);
        if (!valid) throw AppError.badRequest('Invalid or expired OTP', 'INVALID_OTP');

        const doctor = await this.repo.findDoctorByEmail(input.email);
        if (!doctor) throw AppError.notFound('Doctor');

        const passwordHash = await bcrypt.hash(input.newPassword, env.BCRYPT_ROUNDS);
        await this.repo.updateDoctorPassword(doctor.id, passwordHash);
    }

    async logout(tokenJti: string, userId: string): Promise<void> {
        // Blacklist current access token
        await redis.setex(`blacklist:${tokenJti}`, 900, '1'); // 15min TTL
    }

    private async generateTokens(userId: string, role: string, familyId?: string): Promise<TokenPair> {
        const jti = randomUUID();
        const family = familyId || randomUUID();

        const accessToken = jwt.sign(
            { sub: userId, role, jti } as Omit<JwtPayload, 'iat' | 'exp'>,
            env.JWT_ACCESS_SECRET,
            { expiresIn: env.JWT_ACCESS_EXPIRY as jwt.SignOptions['expiresIn'] },
        );

        const refreshTokenValue = randomUUID();
        const tokenHash = this.hashToken(refreshTokenValue);

        const expiresAt = new Date();
        expiresAt.setDate(expiresAt.getDate() + 7);

        await this.repo.createRefreshToken({
            ...(role === 'doctor' ? { doctorId: userId } : { adminId: userId }),
            tokenHash,
            familyId: family,
            expiresAt,
        });

        return { accessToken, refreshToken: refreshTokenValue };
    }

    private hashToken(token: string): string {
        return createHash('sha256').update(token).digest('hex');
    }
}
