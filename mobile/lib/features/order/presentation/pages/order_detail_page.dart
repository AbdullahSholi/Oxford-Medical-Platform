import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/cached_image.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../domain/entities/order.dart';
import '../bloc/order_detail_bloc.dart';
import '../widgets/order_timeline.dart';

class OrderDetailPage extends StatelessWidget {
  final String id;
  const OrderDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n.orderDetails,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
      ),
      body: BlocBuilder<OrderDetailBloc, OrderDetailState>(
        builder: (context, state) {
          if (state is OrderDetailLoading) return const AppLoading();
          if (state is OrderDetailError) {
            return AppErrorWidget(message: state.message, onRetry: () => context.read<OrderDetailBloc>().add(OrderDetailFetched(id)));
          }
          if (state is OrderDetailLoaded) {
            final order = state.order;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order header card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      boxShadow: AppSpacing.shadowSm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              Formatters.orderNumber(order.id),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                letterSpacing: -0.2,
                              ),
                            ),
                            StatusBadge.orderStatus(order.status.name),
                          ],
                        ),
                        AppSpacing.verticalGapSm,
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textTertiary),
                            const SizedBox(width: 6),
                            Text(
                              Formatters.dateTime(order.createdAt),
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.verticalGapLg,

                  // Timeline
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      boxShadow: AppSpacing.shadowSm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.timeline_rounded, size: 18, color: AppColors.primary),
                            SizedBox(width: 8),
                            Text('Order Status', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        OrderTimeline(currentStatus: order.status),
                      ],
                    ),
                  ),
                  AppSpacing.verticalGapLg,

                  // Items
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      boxShadow: AppSpacing.shadowSm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.shopping_bag_outlined, size: 18, color: AppColors.primary),
                            SizedBox(width: 8),
                            Text('Items', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ...order.items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                child: AppCachedImage(
                                  imageUrl: item.productImage,
                                  width: 52,
                                  height: 52,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.productName,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${item.quantity} x ${Formatters.price(item.price)}',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                Formatters.price(item.total),
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                            ],
                          ),
                        )),
                        const Divider(color: AppColors.divider),
                        const SizedBox(height: 8),
                        _Row(label: 'Subtotal', value: Formatters.price(order.subtotal)),
                        if (order.discount > 0)
                          _Row(label: 'Discount', value: '-${Formatters.price(order.discount)}', valueColor: AppColors.success),
                        _Row(
                          label: 'Delivery',
                          value: order.deliveryFee > 0 ? Formatters.price(order.deliveryFee) : 'Free',
                          valueColor: order.deliveryFee == 0 ? AppColors.success : null,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(height: 1, color: AppColors.divider),
                        ),
                        _Row(label: 'Total', value: Formatters.price(order.total), isBold: true),
                      ],
                    ),
                  ),
                  AppSpacing.verticalGapXl,

                  // Actions
                  if (order.status != OrderStatus.delivered && order.status != OrderStatus.cancelled) ...[
                    AppButton(
                      label: 'Track Order',
                      icon: Icons.location_on_outlined,
                      variant: AppButtonVariant.gradient,
                      onPressed: () => context.push('/orders/${order.id}/tracking'),
                    ),
                    AppSpacing.verticalGapMd,
                  ],
                  AppButton(
                    label: 'Re-Order',
                    variant: AppButtonVariant.secondary,
                    icon: Icons.refresh_rounded,
                    onPressed: () => _reorder(context, order),
                  ),
                  if (order.status == OrderStatus.pending) ...[
                    AppSpacing.verticalGapMd,
                    AppButton(
                      label: 'Cancel Order',
                      variant: AppButtonVariant.danger,
                      icon: Icons.cancel_outlined,
                      onPressed: () async {
                        final confirmed = await context.showConfirmDialog(title: 'Cancel Order', message: 'Are you sure you want to cancel this order?');
                        if (confirmed == true && context.mounted) {
                          context.read<OrderDetailBloc>().add(OrderCancelRequested(order.id));
                        }
                      },
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _reorder(BuildContext context, Order order) {
    final cartBloc = context.read<CartBloc>();
    for (final item in order.items) {
      cartBloc.add(CartItemAdded(productId: item.productId, quantity: item.quantity));
    }
    context.showSnackBar('${order.items.length} item(s) added to cart');
    context.go('/cart');
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  final bool isBold;
  final Color? valueColor;
  const _Row({required this.label, required this.value, this.isBold = false, this.valueColor});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
          fontSize: isBold ? 16 : 14,
          color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
        )),
        Text(value, style: TextStyle(
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          fontSize: isBold ? 18 : 14,
          color: valueColor ?? (isBold ? AppColors.primary : AppColors.textPrimary),
        )),
      ]),
    );
  }
}
