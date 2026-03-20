import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

enum AppButtonVariant { primary, secondary, text, danger }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final double? width;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 52,
      child: switch (variant) {
        AppButtonVariant.primary => ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            child: _buildChild(AppColors.textOnPrimary),
          ),
        AppButtonVariant.secondary => OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            child: _buildChild(AppColors.primary),
          ),
        AppButtonVariant.text => TextButton(
            onPressed: isLoading ? null : onPressed,
            child: _buildChild(AppColors.primary),
          ),
        AppButtonVariant.danger => ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: _buildChild(AppColors.textOnPrimary),
          ),
      },
    );
  }

  Widget _buildChild(Color color) {
    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: color,
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          AppSpacing.horizontalGapSm,
          Text(label),
        ],
      );
    }

    return Text(label);
  }
}
