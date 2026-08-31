import 'package:flutter/material.dart';

/// Centralized Border Radius tokens for Bhoomi v2.
///
/// Principles:
/// - Cards: 16px
/// - Buttons: 14px
/// - Inputs: 14px
/// - Bottom sheets: 24px top
/// - Chips / Small elements: 10px
abstract final class AppRadius {
  // Numeric Radius Values
  static const double cardValue = 16.0;
  static const double buttonValue = 14.0;
  static const double inputValue = 14.0;
  static const double sheetValue = 24.0;
  static const double chipValue = 10.0;
  static const double pillValue = 999.0;

  // BorderRadius Constants
  static const BorderRadius card = BorderRadius.all(Radius.circular(cardValue));
  static const BorderRadius button = BorderRadius.all(Radius.circular(buttonValue));
  static const BorderRadius input = BorderRadius.all(Radius.circular(inputValue));
  static const BorderRadius chip = BorderRadius.all(Radius.circular(chipValue));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(pillValue));

  // Bottom Sheet Radius
  static const BorderRadius bottomSheet = BorderRadius.only(
    topLeft: Radius.circular(sheetValue),
    topRight: Radius.circular(sheetValue),
  );

  // Rounded Shapes for Material Components
  static const RoundedRectangleBorder cardShape = RoundedRectangleBorder(
    borderRadius: card,
  );

  static const RoundedRectangleBorder buttonShape = RoundedRectangleBorder(
    borderRadius: button,
  );

  static const RoundedRectangleBorder inputShape = RoundedRectangleBorder(
    borderRadius: input,
  );
}
