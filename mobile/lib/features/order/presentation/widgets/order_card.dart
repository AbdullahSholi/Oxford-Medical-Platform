import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/entities/order.dart';
import '../bloc/order_list_bloc.dart';

class OrderCard extends StatelessWidget {
  final Order order;

  const OrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/orders/${order.id}').then((_) {
        if (context.mounted) context.read<OrderListBloc>().add(const OrderListFetched());
      }),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  Formatters.orderNumber(order.id),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                StatusBadge.orderStatus(order.status.name),
              ],
            ),
            AppSpacing.verticalGapSm,
            Text(
              Formatters.dateTime(order.createdAt),
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            AppSpacing.verticalGapMd,
            Text(
              '${order.itemCount} item${order.itemCount > 1 ? 's' : ''}',
              style: const TextStyle(fontSize: 13),
            ),
            AppSpacing.verticalGapSm,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  Formatters.price(order.total),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.primary),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
