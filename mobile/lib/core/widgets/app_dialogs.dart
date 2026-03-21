import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

enum AppDialogType { success, error, warning, info }

class AppDialogs {
  AppDialogs._();

  /// Shows a styled dialog with icon, title, message, and action buttons.
  static Future<bool?> show(
    BuildContext context, {
    required AppDialogType type,
    required String title,
    required String message,
    String? confirmLabel,
    String? cancelLabel,
    bool showCancel = false,
    VoidCallback? onConfirm,
  }) {
    final config = _DialogConfig.fromType(type);

    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, _, __) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: curved,
          child: FadeTransition(
            opacity: anim,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              ),
              contentPadding: EdgeInsets.zero,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 28),
                  // Icon circle
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: config.lightColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(config.icon, color: config.color, size: 32),
                  ),
                  const SizedBox(height: 20),
                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Message
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Action buttons
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: showCancel
                        ? Row(
                            children: [
                              Expanded(
                                child: _DialogButton(
                                  label: cancelLabel ?? 'Cancel',
                                  onTap: () => Navigator.pop(ctx, false),
                                  isPrimary: false,
                                  color: config.color,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _DialogButton(
                                  label: confirmLabel ?? 'Confirm',
                                  onTap: () {
                                    Navigator.pop(ctx, true);
                                    onConfirm?.call();
                                  },
                                  isPrimary: true,
                                  color: config.color,
                                ),
                              ),
                            ],
                          )
                        : SizedBox(
                            width: double.infinity,
                            child: _DialogButton(
                              label: confirmLabel ?? 'OK',
                              onTap: () {
                                Navigator.pop(ctx, true);
                                onConfirm?.call();
                              },
                              isPrimary: true,
                              color: config.color,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Convenience methods

  static Future<bool?> success(
    BuildContext context, {
    required String title,
    required String message,
    String? confirmLabel,
  }) =>
      show(context,
          type: AppDialogType.success,
          title: title,
          message: message,
          confirmLabel: confirmLabel);

  static Future<bool?> error(
    BuildContext context, {
    required String title,
    required String message,
    String? confirmLabel,
  }) =>
      show(context,
          type: AppDialogType.error,
          title: title,
          message: message,
          confirmLabel: confirmLabel);

  static Future<bool?> warning(
    BuildContext context, {
    required String title,
    required String message,
    String? confirmLabel,
  }) =>
      show(context,
          type: AppDialogType.warning,
          title: title,
          message: message,
          confirmLabel: confirmLabel);

  static Future<bool?> info(
    BuildContext context, {
    required String title,
    required String message,
    String? confirmLabel,
  }) =>
      show(context,
          type: AppDialogType.info,
          title: title,
          message: message,
          confirmLabel: confirmLabel);

  static Future<bool?> confirm(
    BuildContext context, {
    required String title,
    required String message,
    AppDialogType type = AppDialogType.warning,
    String? confirmLabel,
    String? cancelLabel,
  }) =>
      show(context,
          type: type,
          title: title,
          message: message,
          showCancel: true,
          confirmLabel: confirmLabel,
          cancelLabel: cancelLabel);
}

class _DialogConfig {
  final Color color;
  final Color lightColor;
  final IconData icon;

  const _DialogConfig({
    required this.color,
    required this.lightColor,
    required this.icon,
  });

  factory _DialogConfig.fromType(AppDialogType type) => switch (type) {
        AppDialogType.success => const _DialogConfig(
            color: AppColors.success,
            lightColor: AppColors.successLight,
            icon: Icons.check_circle_rounded,
          ),
        AppDialogType.error => const _DialogConfig(
            color: AppColors.error,
            lightColor: AppColors.errorLight,
            icon: Icons.error_rounded,
          ),
        AppDialogType.warning => const _DialogConfig(
            color: AppColors.warning,
            lightColor: AppColors.warningLight,
            icon: Icons.warning_rounded,
          ),
        AppDialogType.info => const _DialogConfig(
            color: AppColors.info,
            lightColor: AppColors.infoLight,
            icon: Icons.info_rounded,
          ),
      };
}

class _DialogButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;
  final Color color;

  const _DialogButton({
    required this.label,
    required this.onTap,
    required this.isPrimary,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isPrimary ? color : Colors.transparent,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: isPrimary ? null : Border.all(color: AppColors.divider),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isPrimary ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
