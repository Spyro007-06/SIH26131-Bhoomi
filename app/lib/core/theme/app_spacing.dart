import 'package:flutter/material.dart';

/// Centralized Spacing tokens and touch-target dimensions for Bhoomi v2.
///
/// Scale: 4, 8, 12, 16, 20, 24, 32, 40 px.
/// Minimum touch targets: 44x44 (prefer 48-56px for primary farmer interactions).
abstract final class AppSpacing {
  // Spacing Scale
  static const double xs4 = 4.0;
  static const double s4 = 4.0;
  static const double s6 = 6.0;
  static const double s8 = 8.0;
  static const double s10 = 10.0;
  static const double m12 = 12.0;
  static const double m16 = 16.0;
  static const double l16 = 16.0;
  static const double l20 = 20.0;
  static const double xl20 = 20.0;
  static const double l24 = 24.0;
  static const double xxl24 = 24.0;
  static const double xl28 = 28.0;
  static const double xl32 = 32.0;
  static const double xxxl32 = 32.0;
  static const double huge40 = 40.0;
  static const double xxl48 = 48.0;

  // Page Padding
  static const double pageHorizontal = 20.0;
  static const double pageVertical = 16.0;
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: pageHorizontal,
    vertical: pageVertical,
  );

  // Card Padding
  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);
  static const EdgeInsets cardPaddingLarge = EdgeInsets.all(20.0);
  static const EdgeInsets cardPaddingCompact = EdgeInsets.all(12.0);

  // Touch Target Dimensions
  static const double minTouchTarget = 44.0;
  static const double primaryButtonHeight = 52.0;
  static const double secondaryButtonHeight = 48.0;
  static const double largeActionButtonHeight = 56.0;
  static const double iconButtonSize = 48.0;
}
