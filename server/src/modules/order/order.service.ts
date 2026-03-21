import { PrismaClient, Prisma } from '@prisma/client';
import { AppError } from '../../shared/utils/api-error';
import { getPaginationMeta } from '../../shared/utils/pagination';
import { isValidTransition, CANCELLABLE_STATUSES, OrderStatusType } from '../../shared/constants/order-status';
import { OrderRepository } from './order.repository';
import { CreateOrderInput, GetOrdersQuery } from './order.schema';
import { notificationQueue, NotificationJobs } from '../../jobs/queues';
import { emitOrderUpdate } from '../../websocket/socket';
import { setLockTimeout } from '../../shared/utils/db-locks';
import { sendEmail, orderConfirmationEmail, orderStatusUpdateEmail } from '../../shared/services/email.service';
import { logger } from '../../config/logger';

interface CartRow { id: string; doctor_id: string }
interface ProductRow {
    id: string; name: string; sku: string; price: number;
    sale_price: number | null; stock: number; is_active: boolean;
    total_sold: number; images?: string;
}
interface CartItemRow { id: string; cart_id: string; product_id: string; quantity: number }
interface DiscountRow {
    id: string; code: string; type: string; value: number;
    min_order_amount: number | null; max_discount: number | null;
    usage_limit: number | null; per_user_limit: number;
    used_count: number; is_active: boolean;
}

export class OrderService {
    constructor(
        private repo: OrderRepository,
        private prisma: PrismaClient,
    ) { }

    async getDoctorOrders(doctorId: string, query: GetOrdersQuery) {
        const { data, total } = await this.repo.findByDoctor(doctorId, query.page, query.limit, query.status);
        return { data, meta: getPaginationMeta(total, query.page, query.limit) };
    }

    async getOrderById(doctorId: string, orderId: string) {
        const order = await this.repo.findById(orderId);
        if (!order || order.doctorId !== doctorId) throw AppError.notFound('Order');
        return order;
    }

    async getOrderByIdAdmin(orderId: string) {
        const order = await this.repo.findById(orderId);
        if (!order) throw AppError.notFound('Order');
        return order;
    }

    async getAllOrders(page: number, limit: number, status?: string) {
        const { data, total } = await this.repo.findAll(page, limit, status);
        return { data, meta: getPaginationMeta(total, page, limit) };
    }

    async createOrder(doctorId: string, input: CreateOrderInput) {
        // Get delivery address
        const address = await this.prisma.doctorAddress.findFirst({
            where: { id: input.addressId, doctorId },
        });
        if (!address) throw AppError.notFound('Delivery address');

        const order = await this.prisma.$transaction(async (tx) => {
            // Set lock timeout for checkout operations (15s max)
            await setLockTimeout(tx, 'CHECKOUT');

            // Step 1: Lock cart
            const carts = await tx.$queryRaw<CartRow[]>`
                SELECT * FROM carts WHERE doctor_id = ${doctorId}::uuid FOR UPDATE
            `;
            const cart = carts[0];
            if (!cart) throw new AppError('EMPTY_CART', 'No cart found', 400);

            const cartItems = await tx.cartItem.findMany({
                where: { cartId: cart.id },
            });
            if (cartItems.length === 0) {
                throw new AppError('EMPTY_CART', 'Cannot create order with empty cart', 400);
            }

            // Step 2: Lock product rows (sorted to prevent deadlocks)
            const productIds = cartItems.map((ci) => ci.productId).sort();
            const lockedProducts = await tx.$queryRaw<ProductRow[]>`
                SELECT id, name, sku, price, sale_price, stock, is_active, total_sold FROM products
                WHERE id = ANY(${productIds}::uuid[])
                ORDER BY id ASC
                FOR UPDATE
            `;

            // Step 3: Verify stock
            const productMap = new Map(lockedProducts.map((p) => [p.id, p]));
            for (const item of cartItems) {
                const product = productMap.get(item.productId);
                if (!product || !product.is_active) {
                    throw AppError.notFound(`Product ${item.productId}`);
                }
                if (product.stock < item.quantity) {
                    throw AppError.insufficientStock(product.name, product.stock, item.quantity);
                }
            }

            // Step 4: Lock & validate discount
            let discountRecord: DiscountRow | null = null;
            if (input.discountCode) {
                const discountCode = input.discountCode.toUpperCase().trim();
                const discounts = await tx.$queryRaw<DiscountRow[]>`
                    SELECT * FROM discounts
                    WHERE code = ${discountCode}
                    AND is_active = true
                    AND starts_at <= NOW()
                    AND ends_at > NOW()
                    FOR UPDATE
                `;
                discountRecord = discounts[0] ?? null;
                if (!discountRecord) {
                    throw new AppError('INVALID_DISCOUNT', 'Discount code is invalid or expired', 400);
                }
                if (discountRecord.usage_limit && discountRecord.used_count >= discountRecord.usage_limit) {
                    throw new AppError('DISCOUNT_EXHAUSTED', 'Discount usage limit reached', 410);
                }
                const userUsage = await tx.discountUsage.count({
                    where: { discountId: discountRecord.id, doctorId },
                });
                if (userUsage >= discountRecord.per_user_limit) {
                    throw new AppError('DISCOUNT_ALREADY_USED', 'You have already used this discount', 400);
                }
            }

            // Step 5: Calculate totals
            const totals = this.calculateTotals(cartItems, productMap, discountRecord);

            // Step 6: Deduct stock
            for (const item of cartItems) {
                await tx.$executeRaw`
                    UPDATE products
                    SET stock = stock - ${item.quantity},
                        total_sold = total_sold + ${item.quantity}
                    WHERE id = ${item.productId}::uuid
                `;
            }

            // Step 7: Create order
            const orderNumber = await this.generateOrderNumber(tx);
            const deliverySnapshot = {
                label: address.label,
                recipientName: address.recipientName,
                phone: address.phone,
                city: address.city,
                streetAddress: address.streetAddress,
                buildingInfo: address.buildingInfo,
                landmark: address.landmark,
            };

            const newOrder = await tx.order.create({
                data: {
                    orderNumber,
                    doctorId,
                    deliveryAddress: deliverySnapshot as unknown as Prisma.InputJsonValue,
                    subtotal: totals.subtotal,
                    discountAmount: totals.discount,
                    deliveryFee: totals.deliveryFee,
                    total: totals.total,
                    paymentMethod: 'cod',
                    discountId: discountRecord?.id,
                    notes: input.notes,
                    items: {
                        create: cartItems.map((item) => {
                            const product = productMap.get(item.productId)!;
                            const unitPrice = product.sale_price ?? product.price;
                            return {
                                productId: item.productId,
                                productName: product.name,
                                productSku: product.sku,
                                productImage: null,
                                unitPrice,
                                quantity: item.quantity,
                                totalPrice: unitPrice * item.quantity,
                            };
                        }),
                    },
                    statusHistory: {
                        create: { status: 'pending', notes: 'Order placed' },
                    },
                },
                include: { items: true },
            });

            // Step 8: Update discount usage
            if (discountRecord) {
                await tx.$executeRaw`
                    UPDATE discounts SET used_count = used_count + 1
                    WHERE id = ${discountRecord.id}::uuid
                `;
                await tx.discountUsage.create({
                    data: { discountId: discountRecord.id, doctorId, orderId: newOrder.id },
                });
            }

            // Step 9: Clear cart
            await tx.cartItem.deleteMany({ where: { cartId: cart.id } });

            return newOrder;
        }, { timeout: 15000 });

        // Post-commit: queue notification
        await notificationQueue.add(NotificationJobs.SEND_PUSH, {
            userId: doctorId,
            title: 'Order Confirmed',
            body: `Order #${order.orderNumber} has been placed successfully`,
            data: { orderId: order.id },
        });

        // Send order confirmation email
        const doctor = await this.prisma.doctor.findUnique({ where: { id: doctorId }, select: { fullName: true, email: true } });
        if (doctor) {
            const emailData = orderConfirmationEmail({
                doctorName: doctor.fullName,
                orderNumber: order.orderNumber,
                items: order.items.map((item: any) => ({ name: item.productName, quantity: item.quantity, price: Number(item.unitPrice) })),
                subtotal: Number(order.subtotal),
                deliveryFee: Number(order.deliveryFee),
                discount: Number(order.discountAmount),
                total: Number(order.total),
            });
            sendEmail({ to: doctor.email, ...emailData }).catch((err) => logger.error({ err }, 'Failed to send order email'));
        }

        return order;
    }

    async cancelOrder(doctorId: string, orderId: string, reason?: string) {
        const cancelled = await this.prisma.$transaction(async (tx) => {
            // Set lock timeout for cancel operations (10s max)
            await setLockTimeout(tx, 'ADMIN');

            // Lock order row
            const orders = await tx.$queryRaw<Array<{ id: string; doctor_id: string; status: string }>>`
                SELECT id, doctor_id, status, order_number FROM orders
                WHERE id = ${orderId}::uuid AND doctor_id = ${doctorId}::uuid
                FOR UPDATE
            `;
            const order = orders[0];
            if (!order) throw AppError.notFound('Order');

            if (!CANCELLABLE_STATUSES.includes(order.status as OrderStatusType)) {
                throw new AppError('INVALID_STATUS', `Cannot cancel order in "${order.status}" status`, 400);
            }

            // Get order items to restore stock
            const orderItems = await tx.orderItem.findMany({ where: { orderId } });

            // Lock product rows (sorted)
            const productIds = orderItems.map((oi) => oi.productId).sort();
            if (productIds.length > 0) {
                await tx.$queryRaw`
                    SELECT id FROM products
                    WHERE id = ANY(${productIds}::uuid[])
                    ORDER BY id ASC
                    FOR UPDATE
                `;

                // Restore stock in batch
                await tx.$executeRaw`
                    UPDATE products p
                    SET stock = p.stock + oi.quantity,
                        total_sold = p.total_sold - oi.quantity
                    FROM order_items oi
                    WHERE oi.order_id = ${orderId}::uuid
                      AND p.id = oi.product_id
                `;
            }

            // Update order
            return tx.order.update({
                where: { id: orderId },
                data: {
                    status: 'cancelled',
                    cancelReason: reason,
                    cancelledAt: new Date(),
                    statusHistory: {
                        create: { status: 'cancelled', notes: reason || 'Cancelled by doctor' },
                    },
                },
                include: { items: true },
            });
        }, { timeout: 10000 });

        emitOrderUpdate(orderId, { status: 'cancelled', orderId });
        return cancelled;
    }

    async updateOrderStatus(orderId: string, newStatus: string, adminId: string, notes?: string) {
        const updated = await this.prisma.$transaction(async (tx) => {
            // Set lock timeout for admin status update (10s max)
            await setLockTimeout(tx, 'ADMIN');

            const orders = await tx.$queryRaw<Array<{ id: string; status: string; doctor_id: string }>>`
                SELECT id, doctor_id, status, order_number FROM orders WHERE id = ${orderId}::uuid FOR UPDATE
            `;
            const order = orders[0];
            if (!order) throw AppError.notFound('Order');

            if (!isValidTransition(order.status as OrderStatusType, newStatus as OrderStatusType)) {
                throw new AppError('INVALID_TRANSITION', `Cannot transition from "${order.status}" to "${newStatus}"`, 400);
            }

            // If cancelling from admin, restore stock in batch
            if (newStatus === 'cancelled') {
                await tx.$executeRaw`
                    UPDATE products p
                    SET stock = p.stock + oi.quantity,
                        total_sold = p.total_sold - oi.quantity
                    FROM order_items oi
                    WHERE oi.order_id = ${orderId}::uuid
                      AND p.id = oi.product_id
                `;
            }

            return tx.order.update({
                where: { id: orderId },
                data: {
                    status: newStatus as any,
                    ...(newStatus === 'cancelled' && { cancelledAt: new Date() }),
                    statusHistory: {
                        create: { status: newStatus as any, changedBy: adminId, notes },
                    },
                },
                include: { items: true },
            });
        });

        emitOrderUpdate(orderId, { status: newStatus, orderId });

        await notificationQueue.add(NotificationJobs.SEND_PUSH, {
            userId: updated.doctorId,
            title: 'Order Update',
            body: `Your order #${updated.orderNumber} is now ${newStatus.replaceAll('_', ' ')}`,
            data: { orderId },
        });

        // Send status update email
        const statusMessages: Record<string, string> = {
            confirmed: 'Your order has been confirmed',
            processing: 'Your order is being prepared',
            shipped: 'Your order has been shipped',
            delivered: 'Your order has been delivered',
            cancelled: 'Your order has been cancelled',
        };
        const doctor = await this.prisma.doctor.findUnique({ where: { id: updated.doctorId }, select: { fullName: true, email: true } });
        if (doctor && statusMessages[newStatus]) {
            const emailData = orderStatusUpdateEmail({
                doctorName: doctor.fullName,
                orderNumber: updated.orderNumber,
                status: newStatus,
                statusMessage: statusMessages[newStatus],
            });
            sendEmail({ to: doctor.email, ...emailData }).catch((err) => logger.error({ err }, 'Failed to send order email'));
        }

        return updated;
    }

    private calculateTotals(
        cartItems: Array<{ productId: string; quantity: number }>,
        productMap: Map<string, ProductRow>,
        discount: DiscountRow | null,
    ): { subtotal: number; discount: number; deliveryFee: number; total: number } {
        let subtotal = 0;
        for (const item of cartItems) {
            const product = productMap.get(item.productId)!;
            const unitPrice = product.sale_price ?? product.price;
            subtotal += unitPrice * item.quantity;
        }

        let discountAmount = 0;
        if (discount) {
            if (discount.min_order_amount && subtotal < discount.min_order_amount) {
                // Don't apply discount
            } else if (discount.type === 'percentage') {
                discountAmount = subtotal * (discount.value / 100);
                if (discount.max_discount) {
                    discountAmount = Math.min(discountAmount, discount.max_discount);
                }
            } else {
                discountAmount = discount.value;
            }
        }

        const deliveryFee = subtotal >= 500 ? 0 : 25; // Free delivery over 500
        const total = subtotal - discountAmount + deliveryFee;

        return { subtotal, discount: discountAmount, deliveryFee, total: Math.max(total, 0) };
    }

    private async generateOrderNumber(tx: any): Promise<string> {
        const date = new Date();
        const prefix = `MO${date.getFullYear().toString().slice(-2)}${String(date.getMonth() + 1).padStart(2, '0')}`;
        const last = await tx.order.findFirst({
            where: { orderNumber: { startsWith: prefix } },
            orderBy: { orderNumber: 'desc' },
            select: { orderNumber: true },
        });
        const seq = last ? parseInt(last.orderNumber.slice(-5), 10) + 1 : 1;
        return `${prefix}${String(seq).padStart(5, '0')}`;
    }
}
