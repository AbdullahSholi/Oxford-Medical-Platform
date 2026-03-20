// ═══════════════════════════════════════════════════════════
// MedOrder — Order Concurrency Integration Tests
// Tests race conditions in checkout, cancel, and stock operations
//
// Run: npm run test:integration -- --testPathPattern=order-concurrency
// ═══════════════════════════════════════════════════════════

import { PrismaClient } from '@prisma/client';
import { OrderService } from '../../src/modules/order/order.service';
import { OrderRepository } from '../../src/modules/order/order.repository';
import {
    createTestPrisma,
    runConcurrent,
    nTimes,
    cleanTables,
    seedOrderTestData,
} from '../helpers/concurrency';

describe('Order Concurrency Tests', () => {
    let prisma: PrismaClient;
    let orderService: OrderService;

    beforeAll(() => {
        prisma = createTestPrisma();
        const orderRepo = new OrderRepository(prisma);
        orderService = new OrderService(orderRepo, prisma);
    });

    afterAll(async () => {
        await prisma.$disconnect();
    });

    beforeEach(async () => {
        await cleanTables(prisma, [
            'order_status_history',
            'order_items',
            'orders',
            'discount_usage',
            'cart_items',
            'carts',
            'products',
            'categories',
            'doctors',
        ]);
    });

    describe('Checkout Race Condition', () => {
        it('should allow only one checkout when stock is limited', async () => {
            // Arrange: Create product with stock=1 and two doctors with carts
            const category = await prisma.category.create({
                data: { name: 'Race Test Cat', slug: `race-cat-${Date.now()}` },
            });

            const product = await prisma.product.create({
                data: {
                    name: 'Limited Item',
                    slug: `limited-${Date.now()}`,
                    description: 'Only 1 in stock',
                    sku: `SKU-LTD-${Date.now()}`,
                    price: 100,
                    stock: 1,
                    categoryId: category.id,
                },
            });

            // Create two doctors with carts both containing the same product
            const [doctor1, doctor2] = await Promise.all([
                prisma.doctor.create({
                    data: {
                        email: `dr1-${Date.now()}@test.com`,
                        passwordHash: '$2b$12$placeholder',
                        fullName: 'Doctor One',
                        phone: '+1111111111',
                        licenseNumber: `LIC-1-${Date.now()}`,
                        specialization: 'General',
                        clinicName: 'Clinic 1',
                        city: 'City A',
                        status: 'approved',
                    },
                }),
                prisma.doctor.create({
                    data: {
                        email: `dr2-${Date.now()}@test.com`,
                        passwordHash: '$2b$12$placeholder',
                        fullName: 'Doctor Two',
                        phone: '+2222222222',
                        licenseNumber: `LIC-2-${Date.now()}`,
                        specialization: 'General',
                        clinicName: 'Clinic 2',
                        city: 'City B',
                        status: 'approved',
                    },
                }),
            ]);

            // Create addresses for both doctors
            const [addr1, addr2] = await Promise.all([
                prisma.doctorAddress.create({
                    data: {
                        doctorId: doctor1.id,
                        label: 'Office',
                        recipientName: 'Dr One',
                        phone: '+1111111111',
                        city: 'City A',
                        streetAddress: '123 Main St',
                    },
                }),
                prisma.doctorAddress.create({
                    data: {
                        doctorId: doctor2.id,
                        label: 'Office',
                        recipientName: 'Dr Two',
                        phone: '+2222222222',
                        city: 'City B',
                        streetAddress: '456 Oak Ave',
                    },
                }),
            ]);

            // Create carts with the limited-stock product
            await Promise.all([
                prisma.cart.create({
                    data: {
                        doctorId: doctor1.id,
                        items: { create: [{ productId: product.id, quantity: 1 }] },
                    },
                }),
                prisma.cart.create({
                    data: {
                        doctorId: doctor2.id,
                        items: { create: [{ productId: product.id, quantity: 1 }] },
                    },
                }),
            ]);

            // Act: Both doctors checkout simultaneously
            const { succeeded, failed } = await runConcurrent([
                () => orderService.createOrder(doctor1.id, { addressId: addr1.id }),
                () => orderService.createOrder(doctor2.id, { addressId: addr2.id }),
            ]);

            // Assert: Exactly one succeeds, one fails with INSUFFICIENT_STOCK
            expect(succeeded).toHaveLength(1);
            expect(failed).toHaveLength(1);
            expect(failed[0].code).toBe('INSUFFICIENT_STOCK');

            // Verify stock is exactly 0
            const updatedProduct = await prisma.product.findUnique({
                where: { id: product.id },
            });
            expect(updatedProduct?.stock).toBe(0);
        });
    });

    describe('Double Cancel Race Condition', () => {
        it('should only cancel once when two cancel requests arrive simultaneously', async () => {
            // Arrange: Create an order
            const testData = await seedOrderTestData(prisma);
            const addr = await prisma.doctorAddress.create({
                data: {
                    doctorId: testData.doctorId,
                    label: 'Office',
                    recipientName: 'Test Doctor',
                    phone: '+1234567890',
                    city: 'Test City',
                    streetAddress: '123 Test St',
                },
            });

            const order = await orderService.createOrder(testData.doctorId, {
                addressId: addr.id,
            });

            // Act: Two concurrent cancel requests
            const { succeeded, failed } = await runConcurrent([
                () => orderService.cancelOrder(testData.doctorId, order.id, 'Changed mind'),
                () => orderService.cancelOrder(testData.doctorId, order.id, 'Changed mind'),
            ]);

            // Assert: Exactly one succeeds, one fails with INVALID_STATUS
            expect(succeeded).toHaveLength(1);
            expect(failed).toHaveLength(1);
            expect(failed[0].code).toBe('INVALID_STATUS');
        });
    });

    describe('Discount Race Condition', () => {
        it('should enforce usage limit when concurrent orders use same discount', async () => {
            // Arrange: Create a discount with usage_limit=1
            const category = await prisma.category.create({
                data: { name: 'Discount Cat', slug: `disc-cat-${Date.now()}` },
            });

            const product = await prisma.product.create({
                data: {
                    name: 'Discount Product',
                    slug: `disc-prod-${Date.now()}`,
                    description: 'Product for discount testing',
                    sku: `SKU-DISC-${Date.now()}`,
                    price: 200,
                    stock: 100, // Plenty of stock
                    categoryId: category.id,
                },
            });

            const discount = await prisma.discount.create({
                data: {
                    code: `TEST-UNI-${Date.now()}`,
                    type: 'percentage',
                    value: 10,
                    usageLimit: 1,
                    perUserLimit: 1,
                    isActive: true,
                    startsAt: new Date(Date.now() - 86400000),
                    endsAt: new Date(Date.now() + 86400000),
                },
            });

            // Create 3 doctors with carts
            const doctors = await Promise.all(
                [1, 2, 3].map((i) =>
                    prisma.doctor.create({
                        data: {
                            email: `disc-dr${i}-${Date.now()}@test.com`,
                            passwordHash: '$2b$12$placeholder',
                            fullName: `Discount Doctor ${i}`,
                            phone: `+${i}${i}${i}${i}${i}${i}${i}${i}${i}${i}`,
                            licenseNumber: `LIC-D${i}-${Date.now()}`,
                            specialization: 'General',
                            clinicName: `Clinic ${i}`,
                            city: 'Test City',
                            status: 'approved',
                        },
                    }),
                ),
            );

            const addresses = await Promise.all(
                doctors.map((d) =>
                    prisma.doctorAddress.create({
                        data: {
                            doctorId: d.id,
                            label: 'Office',
                            recipientName: d.fullName,
                            phone: d.phone,
                            city: 'Test City',
                            streetAddress: '123 Test St',
                        },
                    }),
                ),
            );

            await Promise.all(
                doctors.map((d) =>
                    prisma.cart.create({
                        data: {
                            doctorId: d.id,
                            items: { create: [{ productId: product.id, quantity: 1 }] },
                        },
                    }),
                ),
            );

            // Act: 3 doctors try to use the same discount simultaneously
            const { succeeded, failed } = await runConcurrent(
                doctors.map((d, i) => () =>
                    orderService.createOrder(d.id, {
                        addressId: addresses[i].id,
                        discountCode: discount.code,
                    }),
                ),
            );

            // Assert: Only 1 succeeds with the discount
            expect(succeeded).toHaveLength(1);
            expect(failed).toHaveLength(2);
            // Failed orders should get DISCOUNT_EXHAUSTED or DISCOUNT_ALREADY_USED
            for (const f of failed) {
                expect(['DISCOUNT_EXHAUSTED', 'DISCOUNT_ALREADY_USED']).toContain(f.code);
            }
        });
    });
});
