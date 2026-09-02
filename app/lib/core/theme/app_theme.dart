import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';
import 'app_radius.dart';

/// Centralized Material 3 Theme for Bhoomi v2.
///
/// Designed for high outdoor contrast, calm agricultural feel,
/// Rice Paper background, and large touch targets.
abstract final class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.forest,
      scaffoldBackgroundColor: AppColors.ricePaper,
      canvasColor: AppColors.ricePaper,
      
      // Color Scheme
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.forest,
        onPrimary: AppColors.pureWhite,
        primaryContainer: AppColors.primaryLight,
        onPrimaryContainer: AppColors.primaryDark,
        secondary: AppColors.paddyGreen,
        onSecondary: AppColors.pureWhite,
        secondaryContainer: AppColors.successBg,
        onSecondaryContainer: AppColors.primaryDark,
        tertiary: AppColors.turmeric,
        onTertiary: AppColors.soilCharcoal,
        error: AppColors.danger,
        onError: AppColors.pureWhite,
        errorContainer: AppColors.dangerBg,
        onErrorContainer: AppColors.danger,
        surface: AppColors.warmSurface,
        onSurface: AppColors.soilCharcoal,
        surfaceContainerHighest: AppColors.primaryLight,
        outline: AppColors.border,
        outlineVariant: AppColors.subtleDivider,
      ),

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.ricePaper,
        foregroundColor: AppColors.soilCharcoal,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: AppTypography.screenTitle,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),

      // Card Theme
      cardTheme: const CardThemeData(
        color: AppColors.warmSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: BorderSide(color: AppColors.border, width: 1.0),
        ),
        margin: EdgeInsets.zero,
      ),

      // Elevated Button Theme (Primary Action)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.forest,
          foregroundColor: AppColors.pureWhite,
          minimumSize: const Size.fromHeight(AppSpacing.primaryButtonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl24,
            vertical: AppSpacing.l16,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.button,
          ),
          textStyle: AppTypography.button,
          elevation: 0,
        ),
      ),

      // Outlined Button Theme (Secondary Action)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.forest,
          minimumSize: const Size.fromHeight(AppSpacing.secondaryButtonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl24,
            vertical: AppSpacing.l16,
          ),
          side: const BorderSide(color: AppColors.forest, width: 1.5),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.button,
          ),
          textStyle: AppTypography.button,
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.forest,
          minimumSize: const Size.fromHeight(AppSpacing.minTouchTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.l16,
            vertical: AppSpacing.s8,
          ),
          textStyle: AppTypography.button,
        ),
      ),

      // Input Decoration Theme (Forms & OTP)
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.warmSurface,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.l16,
          vertical: AppSpacing.l16,
        ),
        hintStyle: AppTypography.caption,
        labelStyle: AppTypography.body,
        border: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(color: AppColors.border, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(color: AppColors.border, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(color: AppColors.forest, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(color: AppColors.danger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(color: AppColors.danger, width: 2.0),
        ),
        errorStyle: TextStyle(color: AppColors.danger, fontSize: 13),
      ),

      // Chip Theme
      chipTheme: const ChipThemeData(
        backgroundColor: AppColors.pureWhite,
        selectedColor: AppColors.forestLight,
        disabledColor: AppColors.cardBackground,
        labelStyle: AppTypography.badge,
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.m12,
          vertical: AppSpacing.s8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.pill,
          side: BorderSide(color: AppColors.border, width: 1.0),
        ),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1.0,
        space: AppSpacing.xxl24,
      ),

      // Dialog Theme
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.warmSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.card),
        titleTextStyle: AppTypography.sectionTitle,
        contentTextStyle: AppTypography.body,
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.warmSurface,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.bottomSheet),
        showDragHandle: true,
        dragHandleColor: AppColors.fieldSlate,
      ),
    );
  }
}
