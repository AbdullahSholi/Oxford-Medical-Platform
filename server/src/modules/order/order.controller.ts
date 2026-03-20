import { Request, Response } from 'express';
import { OrderService } from './order.service';
import { ApiResponse } from '../../shared/utils/api-response';

export class OrderController {
    constructor(private service: OrderService) { }

    create = async (req: Request, res: Response): Promise<void> => {
        const order = await this.service.createOrder(req.user!.id, req.body);
        ApiResponse.created(res, order);
    };

    getAll = async (req: Request, res: Response): Promise<void> => {
        const result = await this.service.getDoctorOrders(req.user!.id, req.query as any);
        ApiResponse.paginated(res, result.data, result.meta.total, result.meta.page, result.meta.limit);
    };

    getById = async (req: Request, res: Response): Promise<void> => {
        const order = await this.service.getOrderById(req.user!.id, req.params.id as string);
        ApiResponse.success(res, { data: order });
    };

    cancel = async (req: Request, res: Response): Promise<void> => {
        const order = await this.service.cancelOrder(req.user!.id, req.params.id as string, req.body?.reason);
        ApiResponse.success(res, { data: order, message: 'Order cancelled' });
    };

    getTracking = async (req: Request, res: Response): Promise<void> => {
        const order = await this.service.getOrderById(req.user!.id, req.params.id as string);
        ApiResponse.success(res, { data: { status: order.status, history: order.statusHistory } });
    };
}
