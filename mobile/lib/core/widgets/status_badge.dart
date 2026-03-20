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
      'pending' => (AppColors.warningLight, AppColors.statusPending),
      'confirmed' => (AppColors.infoLight, AppColors.statusConfirmed),
      'processing' => (AppColors.infoLight, AppColors.info),
      'shipped' => (const Color(0xFFF3E8FF), AppColors.statusShipped),
      'delivered' => (AppColors.successLight, AppColors.statusDelivered),
      'cancelled' => (AppColors.errorLight, AppColors.statusCancelled),
      _ => (AppColors.surfaceVariant, AppColors.textSecondary),
    };
    return StatusBadge(label: status, color: bgColor, textColor: fgColor);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color ?? AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor ?? AppColors.primary,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
