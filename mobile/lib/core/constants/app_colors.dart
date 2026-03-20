import 'package:flutter/material.dart';

abstract final class AppColors {
  // Primary palette - Medical professional blue
  static const primary = Color(0xFF1565C0);
  static const primaryLight = Color(0xFF42A5F5);
  static const primaryDark = Color(0xFF0D47A1);

  // Secondary palette - Teal accent
  static const secondary = Color(0xFF00897B);
  static const secondaryLight = Color(0xFF4DB6AC);
  static const secondaryDark = Color(0xFF00695C);

  // Neutral palette
  static const background = Color(0xFFF5F7FA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF0F2F5);
  static const onSurface = Color(0xFF1A1A2E);
  static const onSurfaceVariant = Color(0xFF6B7280);

  // Text
  static const textPrimary = Color(0xFF1A1A2E);
  static const textSecondary = Color(0xFF6B7280);
  static const textHint = Color(0xFF9CA3AF);
  static const textOnPrimary = Color(0xFFFFFFFF);

  // Status
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);

  // Order status
  static const statusPending = Color(0xFFF59E0B);
  static const statusConfirmed = Color(0xFF3B82F6);
  static const statusShipped = Color(0xFF8B5CF6);
  static const statusDelivered = Color(0xFF10B981);
  static const statusCancelled = Color(0xFFEF4444);

  // Misc
  static const divider = Color(0xFFE5E7EB);
  static const shimmerBase = Color(0xFFE0E0E0);
  static const shimmerHighlight = Color(0xFFF5F5F5);
  static const shadow = Color(0x1A000000);
  static const overlay = Color(0x80000000);
  static const flashSale = Color(0xFFFF6B35);
}
