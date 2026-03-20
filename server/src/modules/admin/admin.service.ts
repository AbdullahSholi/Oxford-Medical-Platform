import { AppError } from '../../shared/utils/api-error';
import { getPaginationMeta } from '../../shared/utils/pagination';
import { sendEmail, accountApprovedEmail, accountRejectedEmail } from '../../shared/services/email.service';
import { CacheService, CacheKeys, CacheTTL } from '../../shared/utils/cache';
import { logger } from '../../config/logger';
import { AdminRepository } from './admin.repository';
import { CreateDiscountInput, UpdateDiscountInput, CreateFlashSaleInput } from './admin.schema';

export class AdminService {
    constructor(private repo: AdminRepository) { }

    // ── Dashboard ───────────────────────────────────────
    async getDashboardStats() {
        return CacheService.getOrSet(CacheKeys.DASHBOARD_STATS, CacheTTL.DASHBOARD, async () => {
            const stats = await this.repo.getDashboardStats();
            const recentOrders = await this.repo.getRecentOrders(5);
            return { ...stats, recentOrders };
        });
    }

    // ── Doctor Management ───────────────────────────────
    async listDoctors(page = 1, limit = 20, status?: string) {
        const { data, total } = await this.repo.findDoctors(page, limit, status);
        return { data, meta: getPaginationMeta(total, page, limit) };
    }

    async getDoctorDetail(doctorId: string) {
        const doctor = await this.repo.findDoctorById(doctorId);
        if (!doctor) throw AppError.notFound('Doctor');
        return doctor;
    }

    async approveDoctor(doctorId: string, adminId: string) {
        const doctor = await this.repo.findDoctorById(doctorId);
        if (!doctor) throw AppError.notFound('Doctor');
        if (doctor.status !== 'pending') {
            throw AppError.badRequest(`Doctor is already ${doctor.status}`);
        }
        const result = await this.repo.approveDoctor(doctorId, adminId);

        // Send approval email (non-blocking)
        const emailData = accountApprovedEmail({ doctorName: doctor.fullName });
        sendEmail({ to: doctor.email, ...emailData }).catch((err) => logger.error({ err }, 'Failed to send email'));

        return result;
    }

    async rejectDoctor(doctorId: string, reason: string) {
        const doctor = await this.repo.findDoctorById(doctorId);
        if (!doctor) throw AppError.notFound('Doctor');
        if (doctor.status !== 'pending') {
            throw AppError.badRequest(`Doctor is already ${doctor.status}`);
        }
        const result = await this.repo.rejectDoctor(doctorId, reason);

        // Send rejection email (non-blocking)
        const emailData = accountRejectedEmail({ doctorName: doctor.fullName, reason });
        sendEmail({ to: doctor.email, ...emailData }).catch((err) => logger.error({ err }, 'Failed to send email'));

        return result;
    }

    async suspendDoctor(doctorId: string) {
        const doctor = await this.repo.findDoctorById(doctorId);
        if (!doctor) throw AppError.notFound('Doctor');
        if (doctor.status === 'suspended') {
            throw AppError.badRequest('Doctor is already suspended');
        }
        return this.repo.suspendDoctor(doctorId);
    }

    // ── Discount Management ─────────────────────────────
    async listDiscounts(page = 1, limit = 20) {
        const { data, total } = await this.repo.findDiscounts(page, limit);
        return { data, meta: getPaginationMeta(total, page, limit) };
    }

    async createDiscount(input: CreateDiscountInput) {
        return this.repo.createDiscount(input);
    }

    async updateDiscount(id: string, input: UpdateDiscountInput) {
        const existing = await this.repo.findDiscountById(id);
        if (!existing) throw AppError.notFound('Discount');
        return this.repo.updateDiscount(id, input);
    }

    // ── Flash Sale Management ───────────────────────────
    async listFlashSales(page = 1, limit = 20) {
        const { data, total } = await this.repo.findFlashSales(page, limit);
        return { data, meta: getPaginationMeta(total, page, limit) };
    }

    async createFlashSale(input: CreateFlashSaleInput) {
        if (input.endsAt <= input.startsAt) {
            throw AppError.badRequest('End date must be after start date');
        }
        return this.repo.createFlashSale(input);
    }

    // ── Reports ─────────────────────────────────────────
    async getRevenueReport(startDate?: string, endDate?: string) {
        const start = startDate
            ? new Date(startDate)
            : new Date(new Date().setMonth(new Date().getMonth() - 1));
        const end = endDate ? new Date(endDate) : new Date();
        return this.repo.getRevenueReport(start, end);
    }

    async getProductsReport() {
        return this.repo.getTopProducts(20);
    }

    async getDoctorsReport() {
        return this.repo.getDoctorStats();
    }
}
