# MedOrder — System Architecture & Code Design Guidelines

## Tech Stack: Flutter + Node.js + PostgreSQL

---

# PART 3: BACKEND (NODE.JS) CODE DESIGN GUIDELINES

---

## 3.1 Architecture: Layered with Dependency Injection

```
server/
├── package.json
├── tsconfig.json                         # TypeScript configuration
├── .env.example                          # Environment variable template
├── .env                                  # Local env (gitignored)
├── docker-compose.yml                    # PostgreSQL + Redis for local dev
├── Dockerfile
│
├── prisma/
│   ├── schema.prisma                     # Database schema definition
│   └── migrations/                       # Auto-generated migrations
│
├── src/
│   ├── index.ts                          # Entry point: start server
│   ├── app.ts                            # Express/Fastify app setup
│   ├── config/
│   │   ├── env.ts                        # Environment variable loader + validation (zod)
│   │   ├── database.ts                   # Prisma client singleton
│   │   ├── redis.ts                      # Redis client (ioredis)
│   │   ├── logger.ts                     # Pino logger configuration
│   │   └── container.ts                  # Dependency injection container (tsyringe/awilix)
│   │
│   ├── shared/
│   │   ├── middleware/
│   │   │   ├── authenticate.ts           # JWT verification middleware
│   │   │   ├── authorize.ts              # Role-based access (doctor, admin)
│   │   │   ├── validate.ts               # Zod schema validation middleware
│   │   │   ├── rate-limit.ts             # Rate limiting config
│   │   │   ├── error-handler.ts          # Global error handler
│   │   │   ├── request-logger.ts         # Request/response logging
│   │   │   └── upload.ts                 # Multer file upload config
│   │   ├── utils/
│   │   │   ├── api-response.ts           # Standardized { success, data, error, meta }
│   │   │   ├── api-error.ts              # Custom AppError class with status codes
│   │   │   ├── pagination.ts             # Pagination helper (offset + cursor)
│   │   │   ├── slug.ts                   # URL-safe slug generator
│   │   │   └── async-handler.ts          # Wraps async route handlers (try/catch)
│   │   ├── types/
│   │   │   ├── express.d.ts              # Extend Express Request with user
│   │   │   └── common.ts                 # Shared type definitions
│   │   └── constants/
│   │       ├── order-status.ts           # Order status enum
│   │       ├── doctor-status.ts          # Doctor approval status enum
│   │       └── roles.ts                  # User role enum
│   │
│   ├── modules/
│   │   ├── auth/
│   │   │   ├── auth.routes.ts            # Route definitions
│   │   │   ├── auth.controller.ts        # Request/response handling
│   │   │   ├── auth.service.ts           # Business logic
│   │   │   ├── auth.repository.ts        # Database queries (Prisma)
│   │   │   ├── auth.schema.ts            # Zod validation schemas
│   │   │   └── auth.types.ts             # Module-specific types
│   │   │
│   │   ├── doctor/
│   │   │   ├── doctor.routes.ts
│   │   │   ├── doctor.controller.ts
│   │   │   ├── doctor.service.ts
│   │   │   ├── doctor.repository.ts
│   │   │   ├── doctor.schema.ts
│   │   │   └── doctor.types.ts
│   │   │
│   │   ├── product/
│   │   │   ├── product.routes.ts
│   │   │   ├── product.controller.ts
│   │   │   ├── product.service.ts
│   │   │   ├── product.repository.ts
│   │   │   ├── product.schema.ts
│   │   │   └── product.types.ts
│   │   │
│   │   ├── category/   ...same pattern
│   │   ├── cart/        ...same pattern
│   │   ├── order/       ...same pattern
│   │   ├── review/      ...same pattern
│   │   ├── discount/    ...same pattern
│   │   ├── flash-sale/  ...same pattern
│   │   ├── notification/...same pattern
│   │   ├── banner/      ...same pattern
│   │   ├── upload/      ...same pattern
│   │   └── admin/
│   │       ├── admin.routes.ts
│   │       ├── dashboard/
│   │       │   ├── dashboard.controller.ts
│   │       │   └── dashboard.service.ts
│   │       ├── doctor-management/
│   │       │   ├── doctor-mgmt.controller.ts
│   │       │   └── doctor-mgmt.service.ts
│   │       └── ... (admin sub-modules)
│   │
│   ├── jobs/
│   │   ├── queues.ts                     # Queue definitions
│   │   ├── workers/
│   │   │   ├── notification.worker.ts
│   │   │   ├── order.worker.ts
│   │   │   ├── media.worker.ts
│   │   │   └── flash-sale.worker.ts
│   │   └── schedulers/
│   │       ├── flash-sale.scheduler.ts
│   │       └── order-cleanup.scheduler.ts
│   │
│   └── websocket/
│       ├── socket.ts                     # Socket.io server setup
│       ├── handlers/
│       │   ├── order-tracking.handler.ts
│       │   └── notification.handler.ts
│       └── middleware/
│           └── socket-auth.ts            # JWT auth for WebSocket
│
├── tests/
│   ├── unit/
│   │   ├── modules/
│   │   │   ├── auth/
│   │   │   │   ├── auth.service.test.ts
│   │   │   │   └── auth.controller.test.ts
│   │   │   └── order/
│   │   │       └── order.service.test.ts
│   │   └── shared/
│   │       └── pagination.test.ts
│   ├── integration/
│   │   ├── auth.test.ts
│   │   ├── products.test.ts
│   │   └── orders.test.ts
│   └── helpers/
│       ├── setup.ts                      # Test database setup/teardown
│       ├── factories.ts                  # Test data factories
│       └── auth.ts                       # Helper to get auth tokens in tests
│
└── scripts/
    ├── seed.ts                           # Database seeding script
    └── generate-admin.ts                 # Create initial admin user
```

## 3.2 Layer Responsibilities (Strict Separation)

```
Layer           │ Responsibility                              │ Knows About
────────────────┼─────────────────────────────────────────────┼────────────────
Routes          │ Define endpoints, attach middleware          │ Controller
Controller      │ Parse request, call service, send response  │ Service, Schema
Service         │ Business logic, orchestration, validation   │ Repository, other Services
Repository      │ Database queries via Prisma                 │ Prisma Client
Schema          │ Request validation (Zod)                    │ Nothing (pure data)
```

**Critical Rules:**
- Controllers NEVER contain business logic — they only parse, delegate, and respond
- Services NEVER access `req` or `res` objects — they receive typed parameters and return typed results
- Repositories NEVER throw business errors — they throw database errors; services interpret them
- Routes NEVER contain inline handler logic — always point to controller methods

## 3.3 Standardized API Response Format

Every API response follows this structure:

```typescript
// Success response
{
  "success": true,
  "data": { ... },
  "meta": {                          // Only for paginated responses
    "page": 1,
    "limit": 20,
    "total": 142,
    "totalPages": 8
  }
}

// Error response
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",      // Machine-readable error code
    "message": "Invalid input",      // Human-readable message
    "details": [                     // Optional: field-level errors
      {
        "field": "email",
        "message": "Invalid email format"
      }
    ]
  }
}

// Error codes enum:
VALIDATION_ERROR        → 400
UNAUTHORIZED            → 401
FORBIDDEN               → 403
NOT_FOUND               → 404
CONFLICT                → 409  (e.g., duplicate email)
ACCOUNT_PENDING         → 403  (doctor not yet approved)
ACCOUNT_REJECTED        → 403
RATE_LIMITED            → 429
INSUFFICIENT_STOCK      → 422
FLASH_SALE_ENDED        → 410
INTERNAL_ERROR          → 500
```

## 3.4 Request Validation with Zod

```typescript
// product.schema.ts
import { z } from 'zod';

export const createProductSchema = z.object({
  body: z.object({
    name: z.string().min(3).max(200),
    description: z.string().min(10).max(5000),
    categoryId: z.string().uuid(),
    brandId: z.string().uuid().optional(),
    sku: z.string().regex(/^[A-Z0-9-]+$/),
    price: z.number().positive().multipleOf(0.01),
    salePrice: z.number().positive().multipleOf(0.01).optional(),
    stock: z.number().int().min(0),
    lowStockThreshold: z.number().int().min(0).default(10),
    medicalDetails: z.object({
      intendedUse: z.string().optional(),
      material: z.string().optional(),
      sterile: z.boolean().default(false),
      latexFree: z.boolean().default(true),
      manufacturer: z.string(),
      countryOfOrigin: z.string(),
      expiryDate: z.string().datetime().optional(),
      certifications: z.array(z.enum(['CE', 'FDA', 'ISO'])).default([]),
      storageInstructions: z.string().optional(),
    }),
    bulkPricing: z.array(z.object({
      minQuantity: z.number().int().positive(),
      maxQuantity: z.number().int().positive().nullable(),
      unitPrice: z.number().positive().multipleOf(0.01),
    })).optional(),
    isActive: z.boolean().default(true),
  }),
});

export const getProductsQuerySchema = z.object({
  query: z.object({
    page: z.coerce.number().int().positive().default(1),
    limit: z.coerce.number().int().min(1).max(50).default(20),
    categoryId: z.string().uuid().optional(),
    brandId: z.string().uuid().optional(),
    minPrice: z.coerce.number().positive().optional(),
    maxPrice: z.coerce.number().positive().optional(),
    inStock: z.coerce.boolean().optional(),
    sort: z.enum(['price_asc', 'price_desc', 'newest', 'rating', 'best_selling']).default('newest'),
    search: z.string().max(100).optional(),
  }),
});

export type CreateProductInput = z.infer<typeof createProductSchema>['body'];
export type GetProductsQuery = z.infer<typeof getProductsQuerySchema>['query'];
```

## 3.5 Example Module Implementation (Order)

```typescript
// ─── order.routes.ts ─────────────────────────────────
import { Router } from 'express';
import { authenticate } from '@/shared/middleware/authenticate';
import { authorize } from '@/shared/middleware/authorize';
import { validate } from '@/shared/middleware/validate';
import { OrderController } from './order.controller';
import { createOrderSchema, getOrdersQuerySchema } from './order.schema';

export function orderRoutes(controller: OrderController): Router {
  const router = Router();

  router.use(authenticate);
  router.use(authorize('doctor'));

  router.post('/', validate(createOrderSchema), controller.create);
  router.get('/', validate(getOrdersQuerySchema), controller.getAll);
  router.get('/:id', controller.getById);
  router.post('/:id/cancel', controller.cancel);
  router.post('/:id/reorder', controller.reorder);

  return router;
}


// ─── order.controller.ts ─────────────────────────────
import { Request, Response } from 'express';
import { asyncHandler } from '@/shared/utils/async-handler';
import { ApiResponse } from '@/shared/utils/api-response';
import { OrderService } from './order.service';

export class OrderController {
  constructor(private orderService: OrderService) {}

  create = asyncHandler(async (req: Request, res: Response) => {
    const order = await this.orderService.createOrder(
      req.user.id,
      req.body,
    );
    res.status(201).json(ApiResponse.success(order));
  });

  getAll = asyncHandler(async (req: Request, res: Response) => {
    const result = await this.orderService.getDoctorOrders(
      req.user.id,
      req.query,
    );
    res.json(ApiResponse.paginated(result.data, result.meta));
  });

  getById = asyncHandler(async (req: Request, res: Response) => {
    const order = await this.orderService.getOrderById(
      req.user.id,
      req.params.id,
    );
    res.json(ApiResponse.success(order));
  });

  cancel = asyncHandler(async (req: Request, res: Response) => {
    const order = await this.orderService.cancelOrder(
      req.user.id,
      req.params.id,
      req.body.reason,
    );
    res.json(ApiResponse.success(order));
  });
}


// ─── order.service.ts ────────────────────────────────
// ⚠️  PESSIMISTIC LOCKING — This is the most critical service in the system.
// All checkout and cancellation logic runs inside a serialized transaction
// using SELECT ... FOR UPDATE to prevent race conditions on stock,
// discounts, and cart data.

import { PrismaClient } from '@prisma/client';
import { AppError } from '@/shared/utils/api-error';
import { NotificationService } from '../notification/notification.service';

export class OrderService {
  constructor(
    private prisma: PrismaClient,
    private notificationService: NotificationService,
  ) {}

  async createOrder(doctorId: string, input: CreateOrderInput) {
    // ══════════════════════════════════════════════════════════════
    // ENTIRE CHECKOUT runs inside a Prisma interactive transaction.
    // All SELECT ... FOR UPDATE locks are held until COMMIT/ROLLBACK.
    // External calls (notifications, cache) happen AFTER commit.
    // ══════════════════════════════════════════════════════════════
    const order = await this.prisma.$transaction(async (tx) => {
      // ── Step 1: Lock the doctor's cart row ────────────────────
      // Prevents: concurrent checkout by the same doctor
      const [cart] = await tx.$queryRaw<Cart[]>`
        SELECT * FROM carts
        WHERE doctor_id = ${doctorId}
        FOR UPDATE
      `;
      if (!cart) {
        throw new AppError('EMPTY_CART', 'No cart found', 400);
      }

      const cartItems = await tx.cartItem.findMany({
        where: { cartId: cart.id },
        include: { product: true },
      });
      if (cartItems.length === 0) {
        throw new AppError('EMPTY_CART', 'Cannot create order with empty cart', 400);
      }

      // ── Step 2: Lock ALL product rows being purchased ────────
      // Sort by ID ascending to prevent deadlocks when two
      // concurrent transactions lock the same products.
      const productIds = cartItems
        .map((ci) => ci.productId)
        .sort();

      const lockedProducts = await tx.$queryRaw<Product[]>`
        SELECT * FROM products
        WHERE id = ANY(${productIds}::uuid[])
        ORDER BY id ASC
        FOR UPDATE
      `;

      // ── Step 3: Verify stock under the lock ──────────────────
      // This check is now race-condition-proof because the rows
      // are locked — no other transaction can modify stock.
      const productMap = new Map(lockedProducts.map((p) => [p.id, p]));
      for (const item of cartItems) {
        const product = productMap.get(item.productId);
        if (!product || !product.is_active) {
          throw new AppError('NOT_FOUND', `Product ${item.productId} not found or inactive`, 404);
        }
        if (product.stock < item.quantity) {
          throw new AppError(
            'INSUFFICIENT_STOCK',
            `Insufficient stock for "${product.name}" (available: ${product.stock}, requested: ${item.quantity})`,
            422,
          );
        }
      }

      // ── Step 4: Lock & validate discount (if coupon applied) ─
      let discountRecord = null;
      if (input.discountCode) {
        [discountRecord] = await tx.$queryRaw<Discount[]>`
          SELECT * FROM discounts
          WHERE code = ${input.discountCode}
          AND is_active = true
          AND starts_at <= NOW()
          AND ends_at > NOW()
          FOR UPDATE
        `;
        if (!discountRecord) {
          throw new AppError('INVALID_DISCOUNT', 'Discount code is invalid or expired', 400);
        }
        if (discountRecord.usage_limit && discountRecord.used_count >= discountRecord.usage_limit) {
          throw new AppError('DISCOUNT_EXHAUSTED', 'Discount usage limit reached', 410);
        }
        // Check per-user limit
        const userUsage = await tx.discountUsage.count({
          where: { discountId: discountRecord.id, doctorId },
        });
        if (userUsage >= discountRecord.per_user_limit) {
          throw new AppError('DISCOUNT_ALREADY_USED', 'You have already used this discount', 400);
        }
      }

      // ── Step 5: Calculate totals ─────────────────────────────
      const totals = this.calculateOrderTotals(cartItems, lockedProducts, discountRecord);

      // ── Step 6: Deduct stock (rows are already locked) ───────
      for (const item of cartItems) {
        await tx.$executeRaw`
          UPDATE products
          SET stock = stock - ${item.quantity},
              total_sold = total_sold + ${item.quantity}
          WHERE id = ${item.productId}
        `;
      }

      // ── Step 7: Create order + order_items + status history ──
      const orderNumber = await this.generateOrderNumber(tx);
      const newOrder = await tx.order.create({
        data: {
          orderNumber,
          doctorId,
          deliveryAddress: input.deliveryAddress,
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
              return {
                productId: item.productId,
                productName: product.name,
                productSku: product.sku,
                productImage: product.images?.[0]?.url,
                unitPrice: product.sale_price ?? product.price,
                quantity: item.quantity,
                totalPrice: (product.sale_price ?? product.price) * item.quantity,
              };
            }),
          },
          statusHistory: {
            create: { status: 'pending', notes: 'Order placed by doctor' },
          },
        },
        include: { items: true },
      });

      // ── Step 8: Update discount used_count (if applied) ──────
      if (discountRecord) {
        await tx.$executeRaw`
          UPDATE discounts
          SET used_count = used_count + 1
          WHERE id = ${discountRecord.id}
        `;
        await tx.discountUsage.create({
          data: {
            discountId: discountRecord.id,
            doctorId,
            orderId: newOrder.id,
          },
        });
      }

      // ── Step 9: Clear cart (inside the same transaction) ─────
      await tx.cartItem.deleteMany({ where: { cartId: cart.id } });

      return newOrder;
    }, {
      // Transaction options:
      timeout: 15000,           // 15s max — fail fast if locks are contended
      isolationLevel: 'ReadCommitted',  // Default for PostgreSQL
    });

    // ── Post-commit actions (NO locks held) ─────────────────────
    // These run after the transaction has committed successfully.
    // If they fail, the order is still valid — just retry the side-effects.
    await this.notificationService.queueOrderConfirmation(order);

    return order;
  }

  async cancelOrder(doctorId: string, orderId: string, reason?: string) {
    // ══════════════════════════════════════════════════════════════
    // Cancellation also uses pessimistic locking to prevent:
    //  - Double-cancel (two clicks, two API calls)
    //  - Race between cancel and admin status update
    //  - Double stock restoration
    // ══════════════════════════════════════════════════════════════
    const cancelled = await this.prisma.$transaction(async (tx) => {
      // Lock the order row — prevent concurrent status changes
      const [order] = await tx.$queryRaw<Order[]>`
        SELECT * FROM orders
        WHERE id = ${orderId} AND doctor_id = ${doctorId}
        FOR UPDATE
      `;

      if (!order) {
        throw new AppError('NOT_FOUND', 'Order not found', 404);
      }

      if (!['pending', 'processing'].includes(order.status)) {
        throw new AppError(
          'INVALID_STATUS',
          `Cannot cancel order in "${order.status}" status`,
          400,
        );
      }

      // Get order items to restore stock
      const orderItems = await tx.orderItem.findMany({
        where: { orderId },
      });

      // Lock product rows before restoring stock (sorted to prevent deadlocks)
      const productIds = orderItems.map((oi) => oi.productId).sort();
      await tx.$queryRaw`
        SELECT id FROM products
        WHERE id = ANY(${productIds}::uuid[])
        ORDER BY id ASC
        FOR UPDATE
      `;

      // Restore stock atomically
      for (const item of orderItems) {
        await tx.$executeRaw`
          UPDATE products
          SET stock = stock + ${item.quantity},
              total_sold = total_sold - ${item.quantity}
          WHERE id = ${item.productId}
        `;
      }

      // Update order status
      const updated = await tx.order.update({
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

      return updated;
    }, {
      timeout: 10000,
    });

    // Post-commit: queue notification (outside the locked transaction)
    await this.notificationService.queueOrderCancellation(cancelled);

    return cancelled;
  }
}
```

## 3.6 Backend Code Style Rules

**TypeScript is mandatory** — never use plain JavaScript. Strict mode enabled.

```json
// tsconfig.json critical settings
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "forceConsistentCasingInFileNames": true,
    "paths": {
      "@/*": ["./src/*"]
    }
  }
}
```

**Rules:**
- Every function must have explicit return types
- Every function parameter must be typed (no `any`)
- Use `interface` for object shapes, `type` for unions/intersections
- All environment variables validated at startup with Zod (fail fast)
- All database operations that modify multiple tables must use transactions
- Never expose internal error details to clients in production
- Use structured logging (Pino) with request ID correlation
- Every endpoint must have request validation (Zod middleware)
- File uploads: validate MIME type, file size, and magic bytes
- SQL: Never concatenate user input — always use parameterized queries (Prisma handles this)

**Pessimistic Locking Rules:**
- Any operation that reads-then-writes shared mutable state (stock, counters, status) MUST use `SELECT ... FOR UPDATE` inside a transaction
- Always lock rows in a **consistent order** (sort IDs ascending) to prevent deadlocks
- Keep the locked transaction scope **minimal** — no external API calls (S3, FCM, Redis cache invalidation) inside the transaction; queue them AFTER commit
- Use `$transaction()` with an explicit `timeout` (10–15s) to fail fast on lock contention
- Use `FOR UPDATE NOWAIT` for flash sale purchases — fail immediately rather than queueing
- Log and monitor lock wait durations via `pg_stat_activity` and application-level metrics
- Never use `SELECT ... FOR UPDATE` in read-only endpoints (GET requests)
- All stock modifications must use atomic SQL expressions: `SET stock = stock - $qty` (never `SET stock = $computedValue`)

## 3.7 Pessimistic Locking Patterns (Reference)

Below are the locking patterns for all critical operations. Every pattern uses Prisma's `$transaction()` with raw SQL `FOR UPDATE` queries.

### Pattern 1: Flash Sale Purchase (with NOWAIT)

```typescript
async purchaseFlashSaleItem(doctorId: string, flashSaleProductId: string, quantity: number) {
  return this.prisma.$transaction(async (tx) => {
    // Lock flash sale product row — NOWAIT = fail immediately if contested
    const [fsp] = await tx.$queryRaw<FlashSaleProduct[]>`
      SELECT fsp.*, fs.starts_at, fs.ends_at, fs.is_active
      FROM flash_sale_products fsp
      JOIN flash_sales fs ON fs.id = fsp.flash_sale_id
      WHERE fsp.id = ${flashSaleProductId}
      FOR UPDATE OF fsp NOWAIT
    `;

    if (!fsp || !fsp.is_active || fsp.ends_at < new Date()) {
      throw new AppError('FLASH_SALE_ENDED', 'Flash sale is no longer active', 410);
    }

    const remaining = fsp.flash_stock - fsp.sold_count;
    if (remaining < quantity) {
      throw new AppError('INSUFFICIENT_STOCK', `Only ${remaining} units left in flash sale`, 422);
    }

    // Lock the main product row too (stock deduction)
    await tx.$queryRaw`
      SELECT id FROM products WHERE id = ${fsp.product_id} FOR UPDATE
    `;

    // Deduct flash sale stock
    await tx.$executeRaw`
      UPDATE flash_sale_products
      SET sold_count = sold_count + ${quantity}
      WHERE id = ${flashSaleProductId}
    `;

    // Deduct main product stock
    await tx.$executeRaw`
      UPDATE products
      SET stock = stock - ${quantity}, total_sold = total_sold + ${quantity}
      WHERE id = ${fsp.product_id}
    `;

    // ... create order items at flash_price ...
  }, { timeout: 5000 }); // Short timeout for flash sales
}
```

### Pattern 2: Discount Validation & Redemption

```typescript
async validateAndRedeemDiscount(tx: PrismaTransaction, discountCode: string, doctorId: string) {
  // Lock the discount row to prevent concurrent usage_count increments
  const [discount] = await tx.$queryRaw<Discount[]>`
    SELECT * FROM discounts
    WHERE code = ${discountCode}
    AND is_active = true
    AND starts_at <= NOW()
    AND ends_at > NOW()
    FOR UPDATE
  `;

  if (!discount) throw new AppError('INVALID_DISCOUNT', 'Invalid or expired discount', 400);

  // Check global usage limit
  if (discount.usage_limit !== null && discount.used_count >= discount.usage_limit) {
    throw new AppError('DISCOUNT_EXHAUSTED', 'Discount has been fully redeemed', 410);
  }

  // Check per-user limit (no lock needed — INSERT will enforce uniqueness)
  const userUsageCount = await tx.discountUsage.count({
    where: { discountId: discount.id, doctorId },
  });
  if (userUsageCount >= discount.per_user_limit) {
    throw new AppError('DISCOUNT_ALREADY_USED', 'You have already used this discount', 409);
  }

  return discount;
}
```

### Pattern 3: Order Status Transition (State Machine)

```typescript
// Valid status transitions — enforced at application level
const VALID_TRANSITIONS: Record<string, string[]> = {
  pending:          ['confirmed', 'cancelled'],
  confirmed:        ['processing', 'cancelled'],
  processing:       ['shipped', 'cancelled'],
  shipped:          ['out_for_delivery'],
  out_for_delivery: ['delivered'],
  delivered:        [],              // Terminal state
  cancelled:        [],              // Terminal state
};

async updateOrderStatus(orderId: string, newStatus: string, adminId: string) {
  return this.prisma.$transaction(async (tx) => {
    // Lock order row — prevent concurrent status updates from
    // admin dashboard and background workers
    const [order] = await tx.$queryRaw<Order[]>`
      SELECT * FROM orders WHERE id = ${orderId} FOR UPDATE
    `;

    if (!order) throw new AppError('NOT_FOUND', 'Order not found', 404);

    const allowed = VALID_TRANSITIONS[order.status] || [];
    if (!allowed.includes(newStatus)) {
      throw new AppError(
        'INVALID_TRANSITION',
        `Cannot transition from "${order.status}" to "${newStatus}"`,
        400,
      );
    }

    const updated = await tx.order.update({
      where: { id: orderId },
      data: {
        status: newStatus,
        statusHistory: {
          create: { status: newStatus, changedBy: adminId },
        },
      },
    });

    return updated;
  });
}
```

### Pattern 4: Cart Modification (Guarding Against Checkout Race)

```typescript
async addToCart(doctorId: string, productId: string, quantity: number) {
  return this.prisma.$transaction(async (tx) => {
    // Lock the cart row — if a checkout is in-flight for this doctor,
    // this call will WAIT until the checkout commits or rolls back.
    const [cart] = await tx.$queryRaw<Cart[]>`
      SELECT * FROM carts WHERE doctor_id = ${doctorId} FOR UPDATE
    `;

    // Lock the product row to get a fresh stock count
    const [product] = await tx.$queryRaw<Product[]>`
      SELECT * FROM products WHERE id = ${productId} FOR UPDATE
    `;

    if (!product || !product.is_active) {
      throw new AppError('NOT_FOUND', 'Product not available', 404);
    }
    if (product.stock < quantity) {
      throw new AppError('INSUFFICIENT_STOCK', 'Not enough stock', 422);
    }

    // Upsert cart item
    await tx.cartItem.upsert({
      where: { cartId_productId: { cartId: cart.id, productId } },
      create: { cartId: cart.id, productId, quantity },
      update: { quantity },
    });
  });
}
```

### Pattern 5: Admin Stock Adjustment

```typescript
async adjustStock(productId: string, adjustment: number, adminId: string) {
  return this.prisma.$transaction(async (tx) => {
    // Lock the product row to prevent race with ongoing checkouts
    const [product] = await tx.$queryRaw<Product[]>`
      SELECT * FROM products WHERE id = ${productId} FOR UPDATE
    `;

    if (!product) throw new AppError('NOT_FOUND', 'Product not found', 404);

    const newStock = product.stock + adjustment;
    if (newStock < 0) {
      throw new AppError('INVALID_STOCK', 'Stock cannot go below zero', 400);
    }

    await tx.product.update({
      where: { id: productId },
      data: { stock: newStock },
    });

    // Log the adjustment for audit trail
    await tx.$executeRaw`
      INSERT INTO stock_adjustments (product_id, previous_stock, adjustment, new_stock, adjusted_by)
      VALUES (${productId}, ${product.stock}, ${adjustment}, ${newStock}, ${adminId})
    `;
  });
}
```
