import { PrismaClient } from '@prisma/client';
import { UpdateProfileInput, CreateAddressInput, UpdateAddressInput } from './doctor.schema';

export class DoctorRepository {
    constructor(private prisma: PrismaClient) {}

    async findById(id: string) {
        return this.prisma.doctor.findUnique({
            where: { id },
            select: {
                id: true,
                fullName: true,
                email: true,
                phone: true,
                avatarUrl: true,
                clinicName: true,
                specialty: true,
                city: true,
                clinicAddress: true,
                licenseUrl: true,
                status: true,
                createdAt: true,
                updatedAt: true,
            },
        });
    }

    async updateProfile(id: string, data: UpdateProfileInput) {
        return this.prisma.doctor.update({
            where: { id },
            data,
            select: {
                id: true,
                fullName: true,
                email: true,
                phone: true,
                avatarUrl: true,
                clinicName: true,
                specialty: true,
                city: true,
                clinicAddress: true,
                status: true,
                updatedAt: true,
            },
        });
    }

    async updateAvatar(id: string, avatarUrl: string) {
        return this.prisma.doctor.update({
            where: { id },
            data: { avatarUrl },
        });
    }

    async getAddresses(doctorId: string) {
        return this.prisma.doctorAddress.findMany({
            where: { doctorId },
            orderBy: [{ isDefault: 'desc' }, { createdAt: 'desc' }],
        });
    }

    async createAddress(doctorId: string, data: CreateAddressInput) {
        if (data.isDefault) {
            await this.prisma.doctorAddress.updateMany({
                where: { doctorId, isDefault: true },
                data: { isDefault: false },
            });
        }
        return this.prisma.doctorAddress.create({
            data: { ...data, doctorId },
        });
    }

    async updateAddress(id: string, doctorId: string, data: UpdateAddressInput) {
        if (data.isDefault) {
            await this.prisma.doctorAddress.updateMany({
                where: { doctorId, isDefault: true },
                data: { isDefault: false },
            });
        }
        return this.prisma.doctorAddress.update({
            where: { id },
            data,
        });
    }

    async deleteAddress(id: string, doctorId: string) {
        return this.prisma.doctorAddress.deleteMany({
            where: { id, doctorId },
        });
    }

    async findAddress(id: string, doctorId: string) {
        return this.prisma.doctorAddress.findFirst({
            where: { id, doctorId },
        });
    }
}
