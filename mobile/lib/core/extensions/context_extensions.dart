import 'package:flutter/material.dart';
import 'package:medorder/l10n/app_localizations.dart';

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

  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colorScheme.error : null,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<bool?> showConfirmDialog({
    required String title,
    required String message,
    String? confirmLabel,
    String? cancelLabel,
  }) {
    return showDialog<bool>(
      context: this,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelLabel ?? context.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel ?? context.l10n.confirm),
          ),
        ],
      ),
    );
  }
}
