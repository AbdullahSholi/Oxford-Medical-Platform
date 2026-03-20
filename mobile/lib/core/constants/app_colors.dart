import 'package:flutter/material.dart';

abstract final class AppColors {
  // Primary palette — refined medical blue with depth
  static const primary = Color(0xFF1565C0);
  static const primaryLight = Color(0xFF42A5F5);
  static const primaryDark = Color(0xFF0D47A1);
  static const primarySurface = Color(0xFFE3F2FD);

  // Secondary palette — warm coral accent
  static const secondary = Color(0xFFFF6B35);
  static const secondaryLight = Color(0xFFFF9A76);
  static const secondaryDark = Color(0xFFE85D26);
  static const secondarySurface = Color(0xFFFFF3E0);

  // Neutral palette
  static const background = Color(0xFFF7F8FC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF1F3F8);
  static const surfaceElevated = Color(0xFFFFFFFF);
  static const onSurface = Color(0xFF1A1D29);
  static const onSurfaceVariant = Color(0xFF6B7280);

  // Text
  static const textPrimary = Color(0xFF1A1D29);
  static const textSecondary = Color(0xFF6B7280);
  static const textTertiary = Color(0xFF9CA3AF);
  static const textHint = Color(0xFFB0B7C3);
  static const textOnPrimary = Color(0xFFFFFFFF);

  // Status — softer modern tones
  static const success = Color(0xFF22C55E);
  static const successLight = Color(0xFFDCFCE7);
  static const warning = Color(0xFFF59E0B);
  static const warningLight = Color(0xFFFEF3C7);
  static const error = Color(0xFFEF4444);
  static const errorLight = Color(0xFFFEE2E2);
  static const info = Color(0xFF3B82F6);
  static const infoLight = Color(0xFFDBEAFE);

  // Order status
  static const statusPending = Color(0xFFF59E0B);
  static const statusConfirmed = Color(0xFF3B82F6);
  static const statusShipped = Color(0xFF8B5CF6);
  static const statusDelivered = Color(0xFF22C55E);
  static const statusCancelled = Color(0xFFEF4444);

  // Misc
  static const divider = Color(0xFFE8ECF2);
  static const shimmerBase = Color(0xFFE8ECF2);
  static const shimmerHighlight = Color(0xFFF7F8FC);
  static const shadow = Color(0x0A000000);
  static const shadowMedium = Color(0x14000000);
  static const overlay = Color(0x66000000);
  static const flashSale = Color(0xFFFF6B35);

  // Gradients
  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
  );

  static const primaryDarkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
  );

  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF6B35), Color(0xFFFF9A76)],
  );

  static const surfaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF7F8FC), Color(0xFFFFFFFF)],
  );
}
