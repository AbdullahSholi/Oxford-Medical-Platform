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
      appBar: AppBar(title: Text(context.l10n.orderDetails)),
      body: BlocBuilder<OrderDetailBloc, OrderDetailState>(
        builder: (context, state) {
          if (state is OrderDetailLoading) return const AppLoading();
          if (state is OrderDetailError) {
            return AppErrorWidget(message: state.message, onRetry: () => context.read<OrderDetailBloc>().add(OrderDetailFetched(id)));
          }
          if (state is OrderDetailLoaded) {
            final order = state.order;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(Formatters.orderNumber(order.id), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      StatusBadge.orderStatus(order.status.name),
                    ],
                  ),
                  AppSpacing.verticalGapSm,
                  Text(Formatters.dateTime(order.createdAt), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  AppSpacing.verticalGapXl,
                  OrderTimeline(currentStatus: order.status),
                  AppSpacing.verticalGapXl,
                  Text('Items', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  AppSpacing.verticalGapMd,
                  ...order.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Row(children: [
                      AppCachedImage(imageUrl: item.productImage, width: 50, height: 50, borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                      AppSpacing.horizontalGapMd,
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(item.productName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        Text('${item.quantity} x ${Formatters.price(item.price)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ])),
                      Text(Formatters.price(item.total), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ]),
                  )),
                  const Divider(),
                  AppSpacing.verticalGapMd,
                  _Row(label: 'Subtotal', value: Formatters.price(order.subtotal)),
                  if (order.discount > 0) _Row(label: 'Discount', value: '-${Formatters.price(order.discount)}'),
                  _Row(label: 'Delivery', value: order.deliveryFee > 0 ? Formatters.price(order.deliveryFee) : 'Free'),
                  const Divider(),
                  _Row(label: 'Total', value: Formatters.price(order.total), isBold: true),
                  AppSpacing.verticalGapXl,
                  if (order.status != OrderStatus.delivered && order.status != OrderStatus.cancelled) ...[
                    AppButton(
                      label: 'Track Order',
                      icon: Icons.location_on_outlined,
                      onPressed: () => context.push('/orders/${order.id}/tracking'),
                    ),
                    AppSpacing.verticalGapMd,
                  ],
                  AppButton(
                    label: 'Re-Order',
                    variant: AppButtonVariant.secondary,
                    onPressed: () => _reorder(context, order),
                  ),
                  if (order.status == OrderStatus.pending) ...[
                    AppSpacing.verticalGapMd,
                    AppButton(
                      label: 'Cancel Order',
                      variant: AppButtonVariant.danger,
                      onPressed: () async {
                        final confirmed = await context.showConfirmDialog(title: 'Cancel Order', message: 'Are you sure you want to cancel this order?');
                        if (confirmed == true && context.mounted) {
                          context.read<OrderDetailBloc>().add(OrderCancelRequested(order.id));
                        }
                      },
                    ),
                  ],
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
  const _Row({required this.label, required this.value, this.isBold = false});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.w700 : FontWeight.w400)),
        Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.w700 : FontWeight.w500)),
      ]),
    );
  }
}
