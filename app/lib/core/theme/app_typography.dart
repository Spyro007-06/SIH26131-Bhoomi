import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Centralized Typography tokens for Bhoomi v2.
///
/// Supports Marathi (mr-IN), Hindi (hi-IN), and Indian English (en-IN).
/// All primary farmer-facing text remains >= 16px for readability in bright outdoor sunlight.
abstract final class AppTypography {
  // Font Family names with Devanagari fallbacks
  static const String primaryFontFamily = 'Noto Sans';
  static const List<String> fontFallbacks = [
    'Noto Sans Devanagari',
    'Yantramanav',
    'Mukta',
    'sans-serif',
  ];

  /// Display text (32px, bold) - Used for prominent hero numbers / statements
  static const TextStyle display = TextStyle(
    fontFamily: primaryFontFamily,
    fontFamilyFallback: fontFallbacks,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.5,
    color: AppColors.soilCharcoal,
  );

  /// Screen title (26px, bold) - Top-level screen headings
  static const TextStyle screenTitle = TextStyle(
    fontFamily: primaryFontFamily,
    fontFamilyFallback: fontFallbacks,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: -0.3,
    color: AppColors.soilCharcoal,
  );

  /// Section title (20px, semi-bold) - Card & group headers
  static const TextStyle sectionTitle = TextStyle(
    fontFamily: primaryFontFamily,
    fontFamilyFallback: fontFallbacks,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.35,
    letterSpacing: -0.2,
    color: AppColors.soilCharcoal,
  );

  /// Subheading (18px, semi-bold) - Secondary subsection titles
  static const TextStyle subhead = TextStyle(
    fontFamily: primaryFontFamily,
    fontFamilyFallback: fontFallbacks,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.soilCharcoal,
  );

  /// Body Large (18px, regular) - Prominent farmer instructions
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: primaryFontFamily,
    fontFamilyFallback: fontFallbacks,
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.soilCharcoal,
  );

  /// Body Standard (16px, regular) - Standard readable body text (>= 16px invariant)
  static const TextStyle body = TextStyle(
    fontFamily: primaryFontFamily,
    fontFamilyFallback: fontFallbacks,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.soilCharcoal,
  );

  /// Body Medium (16px, medium) - Emphasized body text / labels
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: primaryFontFamily,
    fontFamilyFallback: fontFallbacks,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.45,
    color: AppColors.soilCharcoal,
  );

  /// Button Label (17px, semi-bold) - Large tactile button text
  static const TextStyle button = TextStyle(
    fontFamily: primaryFontFamily,
    fontFamilyFallback: fontFallbacks,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.25,
    letterSpacing: 0.2,
  );

  /// Small Button Label (15px, semi-bold) - Compact secondary action buttons
  static const TextStyle buttonSmall = TextStyle(
    fontFamily: primaryFontFamily,
    fontFamilyFallback: fontFallbacks,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.25,
  );

  /// Badge / Status Label (14px, semi-bold) - Semantic chips and badges
  static const TextStyle badge = TextStyle(
    fontFamily: primaryFontFamily,
    fontFamilyFallback: fontFallbacks,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.3,
  );

  /// Caption (14px, regular) - Secondary metadata, timestamps, citations
  static const TextStyle caption = TextStyle(
    fontFamily: primaryFontFamily,
    fontFamilyFallback: fontFallbacks,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.fieldSlate,
  );

  /// Micro-caption (12px, medium) - Small tag details
  static const TextStyle captionSmall = TextStyle(
    fontFamily: primaryFontFamily,
    fontFamilyFallback: fontFallbacks,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: AppColors.fieldSlate,
  );

  // Ergonomic Aliases
  static const TextStyle subheading = subhead;
  static const TextStyle title = sectionTitle;
  static const TextStyle bodySmall = caption;
}

