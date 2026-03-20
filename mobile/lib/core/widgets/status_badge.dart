import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color? color;
  final Color? textColor;

  const StatusBadge({
    super.key,
    required this.label,
    this.color,
    this.textColor,
  });

  factory StatusBadge.orderStatus(String status) {
    final (bgColor, fgColor) = switch (status.toLowerCase()) {
      'pending' => (AppColors.statusPending.withOpacity(0.15), AppColors.statusPending),
      'confirmed' => (AppColors.statusConfirmed.withOpacity(0.15), AppColors.statusConfirmed),
      'processing' => (AppColors.info.withOpacity(0.15), AppColors.info),
      'shipped' => (AppColors.statusShipped.withOpacity(0.15), AppColors.statusShipped),
      'delivered' => (AppColors.statusDelivered.withOpacity(0.15), AppColors.statusDelivered),
      'cancelled' => (AppColors.statusCancelled.withOpacity(0.15), AppColors.statusCancelled),
      _ => (AppColors.surfaceVariant, AppColors.textSecondary),
    };
    return StatusBadge(label: status, color: bgColor, textColor: fgColor);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color ?? AppColors.primaryLight.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor ?? AppColors.primary,
        ),
      ),
    );
  }
}
