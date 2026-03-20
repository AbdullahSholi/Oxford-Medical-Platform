import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

class AppEmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? imagePath;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.imagePath,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (imagePath != null)
              Image.asset(imagePath!, height: 160)
            else if (icon != null)
              Icon(icon, size: 80, color: AppColors.textHint),
            AppSpacing.verticalGapXl,
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (subtitle != null) ...[
              AppSpacing.verticalGapSm,
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              AppSpacing.verticalGapXl,
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
