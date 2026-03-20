import { PrismaClient } from '@prisma/client';
import { AppError } from '../../shared/utils/api-error';
import { CartRepository } from './cart.repository';
import { AddToCartInput } from './cart.schema';

interface CartRow { id: string; doctor_id: string }
interface ProductRow { id: string; is_active: boolean; stock: number; name: string }

export class CartService {
    constructor(
        private repo: CartRepository,
        private prisma: PrismaClient,
    ) {}

    async getCart(doctorId: string) {
        await this.repo.ensureCart(doctorId);
        return this.repo.getCart(doctorId);
    }

    async addToCart(doctorId: string, input: AddToCartInput) {
        return this.prisma.$transaction(async (tx) => {
            // Lock cart row - prevents race with concurrent checkout
            const carts = await tx.$queryRaw<CartRow[]>`
                SELECT * FROM carts WHERE doctor_id = ${doctorId}::uuid FOR UPDATE
            `;
            let cart = carts[0];
            if (!cart) {
                const created = await tx.cart.create({ data: { doctorId } });
                cart = { id: created.id, doctor_id: doctorId };
            }

            // Lock product row to get fresh stock
            const products = await tx.$queryRaw<ProductRow[]>`
                SELECT id, is_active, stock, name FROM products WHERE id = ${input.productId}::uuid FOR UPDATE
            `;
            const product = products[0];

            if (!product || !product.is_active) {
                throw AppError.notFound('Product');
            }
            if (product.stock < input.quantity) {
                throw AppError.insufficientStock(product.name, product.stock, input.quantity);
            }

            // Upsert cart item
            await tx.cartItem.upsert({
                where: { cartId_productId: { cartId: cart.id, productId: input.productId } },
                create: { cartId: cart.id, productId: input.productId, quantity: input.quantity },
                update: { quantity: input.quantity },
            });

            return tx.cart.findUnique({
                where: { id: cart.id },
                include: {
                    items: {
                        include: {
                            product: {
                                select: {
                                    id: true,
                                    name: true,
                                    slug: true,
                                    price: true,
                                    salePrice: true,
                                    stock: true,
                                    isActive: true,
                                    images: { take: 1, orderBy: { sortOrder: 'asc' }, select: { url: true } },
                                },
                            },
                        },
                    },
                },
            });
        }, { timeout: 10000 });
    }

    async updateCartItem(doctorId: string, productId: string, quantity: number) {
        return this.prisma.$transaction(async (tx) => {
            const carts = await tx.$queryRaw<CartRow[]>`
                SELECT * FROM carts WHERE doctor_id = ${doctorId}::uuid FOR UPDATE
            `;
            const cart = carts[0];
            if (!cart) throw AppError.notFound('Cart');

            const products = await tx.$queryRaw<ProductRow[]>`
                SELECT id, is_active, stock, name FROM products WHERE id = ${productId}::uuid FOR UPDATE
            `;
            const product = products[0];
            if (!product || !product.is_active) throw AppError.notFound('Product');
            if (product.stock < quantity) {
                throw AppError.insufficientStock(product.name, product.stock, quantity);
            }

            await tx.cartItem.update({
                where: { cartId_productId: { cartId: cart.id, productId } },
                data: { quantity },
            });
        }, { timeout: 10000 });
    }

    async removeCartItem(doctorId: string, productId: string) {
        const cart = await this.prisma.cart.findUnique({ where: { doctorId } });
        if (!cart) return;
        await this.prisma.cartItem.deleteMany({
            where: { cartId: cart.id, productId },
        });
    }

    async validateCoupon(doctorId: string, code: string) {
        const discount = await this.prisma.discount.findUnique({ where: { code: code.toUpperCase().trim() } });
        if (!discount || !discount.isActive) {
            throw new AppError('INVALID_COUPON', 'Invalid or expired coupon code', 400);
        }
        const now = new Date();
        if (now < discount.startsAt || now >= discount.endsAt) {
            throw new AppError('INVALID_COUPON', 'This coupon has expired', 400);
        }
        if (discount.usageLimit && discount.usedCount >= discount.usageLimit) {
            throw new AppError('INVALID_COUPON', 'This coupon has reached its usage limit', 400);
        }
        const userUsage = await this.prisma.discountUsage.count({
            where: { discountId: discount.id, doctorId },
        });
        if (userUsage >= discount.perUserLimit) {
            throw new AppError('INVALID_COUPON', 'You have already used this coupon', 400);
        }
        return {
            code: discount.code,
            type: discount.type,
            value: discount.value,
            description: discount.description,
            minOrderAmount: discount.minOrderAmount,
            maxDiscount: discount.maxDiscount,
        };
    }

    async clearCart(doctorId: string) {
        await this.repo.clearCart(doctorId);
    }
}
