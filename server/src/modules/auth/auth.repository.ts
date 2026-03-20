import { PrismaClient } from '@prisma/client';

export class AuthRepository {
    constructor(private prisma: PrismaClient) {}

    async findDoctorByEmail(email: string) {
        return this.prisma.doctor.findUnique({ where: { email } });
    }

    async findDoctorByPhone(phone: string) {
        return this.prisma.doctor.findUnique({ where: { phone } });
    }

    async findDoctorById(id: string) {
        return this.prisma.doctor.findUnique({ where: { id } });
    }

    async createDoctor(data: {
        fullName: string;
        email: string;
        phone: string;
        passwordHash: string;
        clinicName: string;
        specialty: string;
        city: string;
        clinicAddress: string;
        licenseUrl: string;
    }) {
        return this.prisma.doctor.create({
            data,
            select: {
                id: true,
                fullName: true,
                email: true,
                phone: true,
                clinicName: true,
                specialty: true,
                city: true,
                status: true,
                createdAt: true,
            },
        });
    }

    async updateDoctorLogin(id: string) {
        return this.prisma.doctor.update({
            where: { id },
            data: { lastLoginAt: new Date() },
        });
    }

    async updateDoctorPassword(id: string, passwordHash: string) {
        return this.prisma.doctor.update({
            where: { id },
            data: { passwordHash },
        });
    }

    async updateFcmToken(doctorId: string, fcmToken: string) {
        return this.prisma.doctor.update({
            where: { id: doctorId },
            data: { fcmToken },
        });
    }

    async createRefreshToken(data: {
        doctorId?: string;
        adminId?: string;
        tokenHash: string;
        familyId: string;
        expiresAt: Date;
    }) {
        return this.prisma.refreshToken.create({ data });
    }

    async findRefreshToken(tokenHash: string) {
        return this.prisma.refreshToken.findFirst({
            where: { tokenHash, isRevoked: false },
        });
    }

    async revokeRefreshToken(id: string) {
        return this.prisma.refreshToken.update({
            where: { id },
            data: { isRevoked: true },
        });
    }

    async revokeTokenFamily(familyId: string) {
        return this.prisma.refreshToken.updateMany({
            where: { familyId },
            data: { isRevoked: true },
        });
    }

    async findAdminByEmail(email: string) {
        return this.prisma.admin.findUnique({ where: { email } });
    }

    async updateAdminLogin(id: string) {
        return this.prisma.admin.update({
            where: { id },
            data: { lastLoginAt: new Date() },
        });
    }

    async ensureCart(doctorId: string) {
        return this.prisma.cart.upsert({
            where: { doctorId },
            create: { doctorId },
            update: {},
        });
    }
}
