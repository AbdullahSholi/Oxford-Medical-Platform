// ═══════════════════════════════════════════════════════════
// MedOrder — Admin Module Routes
// All admin routes require authentication + admin role
// Aggregates product, category, order, banner services
// ═══════════════════════════════════════════════════════════

import { Router } from 'express';
import { authenticate } from '../../shared/middleware/authenticate';
import { authorize } from '../../shared/middleware/authorize';
import { validate } from '../../shared/middleware/validate';
import { asyncHandler } from '../../shared/utils/async-handler';
import prisma from '../../config/database';

// Admin's own service
import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';
import { AdminRepository } from './admin.repository';
import {
    rejectDoctorSchema,
    updateOrderStatusSchema,
    createDiscountSchema,
    updateDiscountSchema,
    createFlashSaleSchema,
} from './admin.schema';

// Cross-module service imports
import { productService, productController } from '../product/product.routes';
import { categoryService, categoryController } from '../category/category.routes';
import { orderService } from '../order/order.routes';
import { bannerService, bannerController } from '../banner/banner.routes';
import { createProductSchema, updateProductSchema, getProductsQuerySchema } from '../product/product.schema';
import { createBannerSchema, updateBannerSchema } from '../banner/banner.schema';
import { ApiResponse } from '../../shared/utils/api-response';

// Admin-specific DI
const adminRepo = new AdminRepository(prisma);
const adminService = new AdminService(adminRepo);
const adminController = new AdminController(adminService);

export const adminRoutes = Router();

// All admin routes require auth + admin role
adminRoutes.use(authenticate);
adminRoutes.use(authorize('admin'));

// ── Dashboard ───────────────────────────────────────────
adminRoutes.get('/dashboard/stats', asyncHandler(adminController.getDashboard));

// ── Doctor Management ───────────────────────────────────
adminRoutes.get('/doctors', asyncHandler(adminController.listDoctors));
adminRoutes.get('/doctors/:id', asyncHandler(adminController.getDoctorDetail));
adminRoutes.patch('/doctors/:id/approve', asyncHandler(adminController.approveDoctor));
adminRoutes.patch('/doctors/:id/reject', validate(rejectDoctorSchema), asyncHandler(adminController.rejectDoctor));
adminRoutes.patch('/doctors/:id/suspend', asyncHandler(adminController.suspendDoctor));

// ── Product Management (via ProductService) ─────────────
adminRoutes.get('/products', validate(getProductsQuerySchema, 'query'), asyncHandler(productController.getAll));
adminRoutes.post('/products', validate(createProductSchema), asyncHandler(async (req, res) => {
    const product = await productService.createProduct(req.body);
    ApiResponse.created(res, product);
}));
adminRoutes.patch('/products/:id', validate(updateProductSchema), asyncHandler(async (req, res) => {
    const product = await productService.updateProduct(req.params.id as string, req.body);
    ApiResponse.success(res, { data: product, message: 'Product updated' });
}));
adminRoutes.delete('/products/:id', asyncHandler(async (req, res) => {
    await productService.deleteProduct(req.params.id as string);
    ApiResponse.noContent(res);
}));

// ── Order Management (via OrderService) ─────────────────
adminRoutes.get('/orders', asyncHandler(async (req, res) => {
    const page = Number(req.query.page) || 1;
    const limit = Number(req.query.limit) || 20;
    const status = req.query.status as string | undefined;
    const result = await orderService.getAllOrders(page, limit, status);
    ApiResponse.success(res, { data: result.data, meta: result.meta });
}));
adminRoutes.get('/orders/:id', asyncHandler(async (req, res) => {
    const order = await orderService.getOrderByIdAdmin(req.params.id as string);
    ApiResponse.success(res, { data: order });
}));
adminRoutes.patch('/orders/:id/status', validate(updateOrderStatusSchema), asyncHandler(async (req, res) => {
    const order = await orderService.updateOrderStatus(
        req.params.id as string,
        req.body.status,
        req.user!.id,
        req.body.notes,
    );
    ApiResponse.success(res, { data: order, message: 'Order status updated' });
}));

// ── Category Management (via CategoryService) ───────────
adminRoutes.post('/categories', asyncHandler(async (req, res) => {
    const category = await categoryService.create(req.body);
    ApiResponse.created(res, category);
}));
adminRoutes.patch('/categories/:id', asyncHandler(async (req, res) => {
    const category = await categoryService.update(req.params.id as string, req.body);
    ApiResponse.success(res, { data: category, message: 'Category updated' });
}));
adminRoutes.delete('/categories/:id', asyncHandler(async (req, res) => {
    await categoryService.delete(req.params.id as string);
    ApiResponse.noContent(res);
}));

// ── Discount Management ─────────────────────────────────
adminRoutes.get('/discounts', asyncHandler(adminController.listDiscounts));
adminRoutes.post('/discounts', validate(createDiscountSchema), asyncHandler(adminController.createDiscount));
adminRoutes.patch('/discounts/:id', validate(updateDiscountSchema), asyncHandler(adminController.updateDiscount));

// ── Flash Sale Management ───────────────────────────────
adminRoutes.get('/flash-sales', asyncHandler(adminController.listFlashSales));
adminRoutes.post('/flash-sales', validate(createFlashSaleSchema), asyncHandler(adminController.createFlashSale));

// ── Banner Management (via BannerService) ───────────────
adminRoutes.get('/banners', asyncHandler(bannerController.getAll));
adminRoutes.post('/banners', validate(createBannerSchema), asyncHandler(bannerController.create));
adminRoutes.patch('/banners/:id', validate(updateBannerSchema), asyncHandler(bannerController.update));
adminRoutes.patch('/banners/:id/toggle', asyncHandler(bannerController.toggle));
adminRoutes.delete('/banners/:id', asyncHandler(bannerController.remove));

// ── Reports ─────────────────────────────────────────────
adminRoutes.get('/reports/revenue', asyncHandler(adminController.revenueReport));
adminRoutes.get('/reports/products', asyncHandler(adminController.productsReport));
adminRoutes.get('/reports/doctors', asyncHandler(adminController.doctorsReport));
