import { Request, Response } from 'express';
import { CartService } from './cart.service';
import { ApiResponse } from '../../shared/utils/api-response';

export class CartController {
    constructor(private service: CartService) { }

    getCart = async (req: Request, res: Response): Promise<void> => {
        const cart = await this.service.getCart(req.user!.id);
        ApiResponse.success(res, { data: cart });
    };

    addItem = async (req: Request, res: Response): Promise<void> => {
        const cart = await this.service.addToCart(req.user!.id, req.body);
        ApiResponse.created(res, cart);
    };

    updateItem = async (req: Request, res: Response): Promise<void> => {
        await this.service.updateCartItem(req.user!.id, req.params.productId as string, req.body.quantity);
        ApiResponse.success(res, { message: 'Cart item updated' });
    };

    removeItem = async (req: Request, res: Response): Promise<void> => {
        await this.service.removeCartItem(req.user!.id, req.params.productId as string);
        const cart = await this.service.getCart(req.user!.id);
        ApiResponse.success(res, { data: cart });
    };

    applyCoupon = async (req: Request, res: Response): Promise<void> => {
        const cart = await this.service.applyCoupon(req.user!.id, req.body.code);
        ApiResponse.success(res, { data: cart, message: 'Coupon applied successfully' });
    };

    removeCoupon = async (_req: Request, res: Response): Promise<void> => {
        ApiResponse.success(res, { data: null, message: 'Coupon removed' });
    };

    clearCart = async (req: Request, res: Response): Promise<void> => {
        await this.service.clearCart(req.user!.id);
        ApiResponse.noContent(res);
    };
}
