import { AppError } from '../../shared/utils/api-error';
import { DoctorRepository } from './doctor.repository';
import { UpdateProfileInput, CreateAddressInput, UpdateAddressInput } from './doctor.schema';

export class DoctorService {
    constructor(private repo: DoctorRepository) {}

    async getProfile(doctorId: string) {
        const doctor = await this.repo.findById(doctorId);
        if (!doctor) throw AppError.notFound('Doctor');
        return doctor;
    }

    async updateProfile(doctorId: string, data: UpdateProfileInput) {
        return this.repo.updateProfile(doctorId, data);
    }

    async getAddresses(doctorId: string) {
        return this.repo.getAddresses(doctorId);
    }

    async createAddress(doctorId: string, data: CreateAddressInput) {
        return this.repo.createAddress(doctorId, data);
    }

    async updateAddress(addressId: string, doctorId: string, data: UpdateAddressInput) {
        const existing = await this.repo.findAddress(addressId, doctorId);
        if (!existing) throw AppError.notFound('Address');
        return this.repo.updateAddress(addressId, doctorId, data);
    }

    async deleteAddress(addressId: string, doctorId: string) {
        const existing = await this.repo.findAddress(addressId, doctorId);
        if (!existing) throw AppError.notFound('Address');
        await this.repo.deleteAddress(addressId, doctorId);
    }
}
