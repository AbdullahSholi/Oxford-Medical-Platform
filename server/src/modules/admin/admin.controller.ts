import { Request, Response } from 'express';
import { AdminService } from './admin.service';
import { ApiResponse } from '../../shared/utils/api-response';

export class AdminController {
    constructor(private service: AdminService) { }

    // ── Dashboard ───────────────────────────────────────
    getDashboard = async (_req: Request, res: Response): Promise<void> => {
        const stats = await this.service.getDashboardStats();
        ApiResponse.success(res, { data: stats });
    };

    // ── Doctor Management ───────────────────────────────
    listDoctors = async (req: Request, res: Response): Promise<void> => {
        const page = Number(req.query.page) || 1;
        const limit = Number(req.query.limit) || 20;
        const status = req.query.status as string | undefined;
        const result = await this.service.listDoctors(page, limit, status);
        ApiResponse.success(res, { data: result.data, meta: result.meta });
    };

    getDoctorDetail = async (req: Request, res: Response): Promise<void> => {
        const doctor = await this.service.getDoctorDetail(req.params.id as string);
        ApiResponse.success(res, { data: doctor });
    };

    approveDoctor = async (req: Request, res: Response): Promise<void> => {
        const doctor = await this.service.approveDoctor(req.params.id as string, req.user!.id);
        ApiResponse.success(res, { data: doctor, message: 'Doctor approved' });
    };

    rejectDoctor = async (req: Request, res: Response): Promise<void> => {
        const doctor = await this.service.rejectDoctor(req.params.id as string, req.body.reason);
        ApiResponse.success(res, { data: doctor, message: 'Doctor rejected' });
    };

    suspendDoctor = async (req: Request, res: Response): Promise<void> => {
        const doctor = await this.service.suspendDoctor(req.params.id as string);
        ApiResponse.success(res, { data: doctor, message: 'Doctor suspended' });
    };

    // ── Discount Management ─────────────────────────────
    listDiscounts = async (req: Request, res: Response): Promise<void> => {
        const page = Number(req.query.page) || 1;
        const limit = Number(req.query.limit) || 20;
        const result = await this.service.listDiscounts(page, limit);
        ApiResponse.success(res, { data: result.data, meta: result.meta });
    };

    createDiscount = async (req: Request, res: Response): Promise<void> => {
        const discount = await this.service.createDiscount(req.body);
        ApiResponse.created(res, discount);
    };

    updateDiscount = async (req: Request, res: Response): Promise<void> => {
        const discount = await this.service.updateDiscount(req.params.id as string, req.body);
        ApiResponse.success(res, { data: discount, message: 'Discount updated' });
    };

    // ── Flash Sale Management ───────────────────────────
    listFlashSales = async (req: Request, res: Response): Promise<void> => {
        const page = Number(req.query.page) || 1;
        const limit = Number(req.query.limit) || 20;
        const result = await this.service.listFlashSales(page, limit);
        ApiResponse.success(res, { data: result.data, meta: result.meta });
    };

    createFlashSale = async (req: Request, res: Response): Promise<void> => {
        const sale = await this.service.createFlashSale(req.body);
        ApiResponse.created(res, sale);
    };

    // ── Reports ─────────────────────────────────────────
    revenueReport = async (req: Request, res: Response): Promise<void> => {
        const report = await this.service.getRevenueReport(
            req.query.startDate as string,
            req.query.endDate as string,
        );
        ApiResponse.success(res, { data: report });
    };

    productsReport = async (_req: Request, res: Response): Promise<void> => {
        const report = await this.service.getProductsReport();
        ApiResponse.success(res, { data: report });
    };

    doctorsReport = async (_req: Request, res: Response): Promise<void> => {
        const report = await this.service.getDoctorsReport();
        ApiResponse.success(res, { data: report });
    };
}
