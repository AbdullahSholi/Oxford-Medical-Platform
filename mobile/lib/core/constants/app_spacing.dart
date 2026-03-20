import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  // Padding presets
  static const pagePadding = EdgeInsets.symmetric(horizontal: 20);
  static const cardPadding = EdgeInsets.all(lg);
  static const listItemPadding = EdgeInsets.symmetric(horizontal: lg, vertical: md);
  static const sectionPadding = EdgeInsets.symmetric(vertical: xl);

  // Radius — rounder, more modern
  static const double radiusXs = 4;
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusXxl = 32;
  static const double radiusFull = 9999;

  // Gaps (SizedBox shortcuts)
  static const verticalGapXs = SizedBox(height: xs);
  static const verticalGapSm = SizedBox(height: sm);
  static const verticalGapMd = SizedBox(height: md);
  static const verticalGapLg = SizedBox(height: lg);
  static const verticalGapXl = SizedBox(height: xl);
  static const verticalGapXxl = SizedBox(height: xxl);

  static const horizontalGapXs = SizedBox(width: xs);
  static const horizontalGapSm = SizedBox(width: sm);
  static const horizontalGapMd = SizedBox(width: md);
  static const horizontalGapLg = SizedBox(width: lg);
  static const horizontalGapXl = SizedBox(width: xl);

  // Modern shadow presets
  static final shadowSm = [
    BoxShadow(
      color: AppColors.shadow,
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static final shadowMd = [
    BoxShadow(
      color: AppColors.shadow,
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: AppColors.shadow,
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  static final shadowLg = [
    BoxShadow(
      color: AppColors.shadowMedium,
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: AppColors.shadow,
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static final shadowPrimary = [
    BoxShadow(
      color: AppColors.primary.withOpacity(0.3),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];
}
