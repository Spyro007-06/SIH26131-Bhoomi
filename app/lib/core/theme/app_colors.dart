import 'package:flutter/material.dart';

/// Centralized Design System Colors for Bhoomi v2.
///
/// Principles:
/// - Rice Paper background + Warm White cards + Forest Green primary actions
/// - Never use pure black as primary text color
/// - Never use bright green as dominant screen color
abstract final class AppColors {
  // Primary Palette
  static const Color forest = Color(0xFF245C45);        // Primary Forest Green
  static const Color primaryDark = Color(0xFF174432);   // Primary Dark
  static const Color primaryLight = Color(0xFFDDEBE2);  // Primary Light Tint
  static const Color forestLight = primaryLight;

  // Secondary Palette
  static const Color paddyGreen = Color(0xFF5F8F45);    // Secondary Paddy Green

  // Backgrounds & Surfaces
  static const Color ricePaper = Color(0xFFF7F5EE);     // Scaffold Background
  static const Color warmSurface = Color(0xFFFFFDF8);   // Card & Dialog Surface
  static const Color cardBackground = warmSurface;
  static const Color pureWhite = Color(0xFFFFFFFF);     // Pure White overlay

  // Text & Neutrals (Soil & Field tones)
  static const Color soilCharcoal = Color(0xFF202A25);  // High-contrast primary text
  static const Color fieldSlate = Color(0xFF66736B);    // Secondary slate text
  static const Color border = Color(0xFFD8DED8);        // Subtle card & input border
  static const Color subtleDivider = Color(0xFFE5ECE5); // Divider line

  // Accent & Attention
  static const Color turmeric = Color(0xFFD69A2D);      // Accent Turmeric (clarify, caution)

  // Status: Warning
  static const Color warning = Color(0xFFC98224);       // Warning Amber
  static const Color warningBg = Color(0xFFFFF1D6);     // Warning Background

  // Status: Danger / Safety Veto / Escalation
  static const Color danger = Color(0xFFB94A48);        // Muted Red
  static const Color dangerBg = Color(0xFFFCE8E6);      // Danger Background

  // Status: Success / Resolution
  static const Color success = Color(0xFF3F7D4A);       // Success Green
  static const Color successBg = Color(0xFFE6F2E8);     // Success Background

  // Status: Info / Guidance
  static const Color info = Color(0xFF3F7180);          // Info Cyan/Teal
  static const Color infoBg = Color(0xFFE6F1F4);        // Info Background
}
