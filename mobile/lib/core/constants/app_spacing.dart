import 'package:flutter/material.dart';

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  // Padding presets
  static const pagePadding = EdgeInsets.symmetric(horizontal: lg);
  static const cardPadding = EdgeInsets.all(lg);
  static const listItemPadding = EdgeInsets.symmetric(horizontal: lg, vertical: md);
  static const sectionPadding = EdgeInsets.symmetric(vertical: xl);

  // Radius
  static const double radiusSm = 6;
  static const double radiusMd = 10;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusFull = 999;

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
}
