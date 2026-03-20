import { PrismaClient } from '@prisma/client';

export class CartRepository {
    constructor(private prisma: PrismaClient) {}

    async getCart(doctorId: string) {
        const cart = await this.prisma.cart.findUnique({
            where: { doctorId },
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
                    orderBy: { createdAt: 'desc' },
                },
            },
        });
        return cart;
    }

    async ensureCart(doctorId: string) {
        return this.prisma.cart.upsert({
            where: { doctorId },
            create: { doctorId },
            update: {},
        });
    }

    async clearCart(doctorId: string) {
        const cart = await this.prisma.cart.findUnique({ where: { doctorId } });
        if (cart) {
            await this.prisma.cartItem.deleteMany({ where: { cartId: cart.id } });
        }
    }
}
