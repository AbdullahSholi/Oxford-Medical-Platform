// ═══════════════════════════════════════════════════════════
// MedOrder — Order Status Constants & State Machine
// ═══════════════════════════════════════════════════════════

export const OrderStatus = {
    PENDING: 'pending',
    CONFIRMED: 'confirmed',
    PROCESSING: 'processing',
    SHIPPED: 'shipped',
    OUT_FOR_DELIVERY: 'out_for_delivery',
    DELIVERED: 'delivered',
    CANCELLED: 'cancelled',
} as const;

export type OrderStatusType = (typeof OrderStatus)[keyof typeof OrderStatus];

// Valid status transitions — enforced at application level
export const VALID_STATUS_TRANSITIONS: Record<OrderStatusType, OrderStatusType[]> = {
    [OrderStatus.PENDING]: [OrderStatus.CONFIRMED, OrderStatus.CANCELLED],
    [OrderStatus.CONFIRMED]: [OrderStatus.PROCESSING, OrderStatus.CANCELLED],
    [OrderStatus.PROCESSING]: [OrderStatus.SHIPPED, OrderStatus.CANCELLED],
    [OrderStatus.SHIPPED]: [OrderStatus.OUT_FOR_DELIVERY],
    [OrderStatus.OUT_FOR_DELIVERY]: [OrderStatus.DELIVERED],
    [OrderStatus.DELIVERED]: [],     // Terminal state
    [OrderStatus.CANCELLED]: [],     // Terminal state
};

export const CANCELLABLE_STATUSES: OrderStatusType[] = [
    OrderStatus.PENDING,
    OrderStatus.CONFIRMED,
    OrderStatus.PROCESSING,
];

export function isValidTransition(from: OrderStatusType, to: OrderStatusType): boolean {
    return VALID_STATUS_TRANSITIONS[from]?.includes(to) ?? false;
}
