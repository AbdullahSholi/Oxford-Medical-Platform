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
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.errorLight,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cancel_rounded, color: AppColors.error, size: 20),
            SizedBox(width: 8),
            Text(
              'Order Cancelled',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    final currentIndex = _steps.indexWhere((s) => s.$1 == currentStatus);

    return Column(
      children: List.generate(_steps.length, (index) {
        final step = _steps[index];
        final isCompleted = index <= currentIndex;
        final isCurrent = index == currentIndex;
        final isLast = index == _steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted ? AppColors.primary : AppColors.surfaceVariant,
                    border: isCurrent
                        ? Border.all(color: AppColors.primary.withOpacity(0.3), width: 3)
                        : null,
                    boxShadow: isCurrent
                        ? [BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 8)]
                        : null,
                  ),
                  child: Icon(
                    step.$3,
                    size: 16,
                    color: isCompleted ? Colors.white : AppColors.textHint,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 28,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    decoration: BoxDecoration(
                      color: isCompleted && index < currentIndex
                          ? AppColors.primary
                          : AppColors.divider,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.$2,
                    style: TextStyle(
                      fontWeight: isCompleted ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 14,
                      color: isCompleted ? AppColors.textPrimary : AppColors.textHint,
                    ),
                  ),
                  if (isCurrent)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Current status',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}
