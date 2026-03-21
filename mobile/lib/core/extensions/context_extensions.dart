import 'package:flutter/material.dart';
import 'package:medorder/l10n/app_localizations.dart';
import '../constants/app_colors.dart';
import '../widgets/app_dialogs.dart';

extension ContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;

  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => mediaQuery.size;
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;
  EdgeInsets get padding => mediaQuery.padding;
  double get bottomInset => mediaQuery.viewInsets.bottom;

  AppLocalizations get l10n => AppLocalizations.of(this)!;

  bool get isKeyboardOpen => bottomInset > 0;
  bool get isTablet => screenWidth > 600;

  // ── Snackbars ──────────────────────────────────────────────

  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).clearSnackBars();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colorScheme.error : null,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(this).clearSnackBars();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void showErrorSnackBar(String message) {
    ScaffoldMessenger.of(this).clearSnackBars();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void showWarningSnackBar(String message) {
    ScaffoldMessenger.of(this).clearSnackBars();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void showInfoSnackBar(String message) {
    ScaffoldMessenger.of(this).clearSnackBars();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: AppColors.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // ── Dialogs ────────────────────────────────────────────────

  Future<bool?> showConfirmDialog({
    required String title,
    required String message,
    String? confirmLabel,
    String? cancelLabel,
  }) {
    return AppDialogs.confirm(
      this,
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
    );
  }

  Future<bool?> showSuccessDialog({
    required String title,
    required String message,
    String? confirmLabel,
  }) {
    return AppDialogs.success(this, title: title, message: message, confirmLabel: confirmLabel);
  }

  Future<bool?> showErrorDialog({
    required String title,
    required String message,
    String? confirmLabel,
  }) {
    return AppDialogs.error(this, title: title, message: message, confirmLabel: confirmLabel);
  }

  Future<bool?> showWarningDialog({
    required String title,
    required String message,
    String? confirmLabel,
  }) {
    return AppDialogs.warning(this, title: title, message: message, confirmLabel: confirmLabel);
  }

  Future<bool?> showInfoDialog({
    required String title,
    required String message,
    String? confirmLabel,
  }) {
    return AppDialogs.info(this, title: title, message: message, confirmLabel: confirmLabel);
  }
}
