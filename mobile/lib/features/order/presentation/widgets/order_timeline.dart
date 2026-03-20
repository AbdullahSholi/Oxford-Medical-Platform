import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/order.dart';

class OrderTimeline extends StatelessWidget {
  final OrderStatus currentStatus;

  const OrderTimeline({super.key, required this.currentStatus});

  static const _steps = [
    (OrderStatus.pending, 'Order Placed', Icons.receipt_long_rounded),
    (OrderStatus.confirmed, 'Confirmed', Icons.check_circle_rounded),
    (OrderStatus.processing, 'Processing', Icons.settings_rounded),
    (OrderStatus.shipped, 'Shipped', Icons.local_shipping_rounded),
    (OrderStatus.delivered, 'Delivered', Icons.done_all_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    if (currentStatus == OrderStatus.cancelled) {
      return const Center(
        child: Chip(
          avatar: Icon(Icons.cancel_rounded, color: AppColors.error, size: 18),
          label: Text('Order Cancelled'),
          backgroundColor: Color(0xFFFEE2E2),
        ),
      );
    }

    final currentIndex = _steps.indexWhere((s) => s.$1 == currentStatus);

    return Column(
      children: List.generate(_steps.length, (index) {
        final step = _steps[index];
        final isCompleted = index <= currentIndex;
        final isLast = index == _steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted ? AppColors.primary : AppColors.surfaceVariant,
                  ),
                  child: Icon(step.$3, size: 16, color: isCompleted ? Colors.white : AppColors.textHint),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 32,
                    color: isCompleted ? AppColors.primary : AppColors.divider,
                  ),
              ],
            ),
            AppSpacing.horizontalGapMd,
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                step.$2,
                style: TextStyle(
                  fontWeight: isCompleted ? FontWeight.w600 : FontWeight.w400,
                  color: isCompleted ? AppColors.textPrimary : AppColors.textHint,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
