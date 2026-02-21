import 'package:flutter/material.dart';

/// The Stationery color palette — ink on cream paper.
class AppColors {
  AppColors._();

  // — Backgrounds —
  /// Cream paper background.
  static const Color paper = Color(0xFFFFF8F0);

  /// Slightly darker cream for cards / elevated surfaces.
  static const Color paperElevated = Color(0xFFF5EDE0);

  /// Warm grey for subtle separators.
  static const Color divider = Color(0xFFD6CFC4);

  // — Ink / Text —
  /// Deep ink blue — primary brand color.
  static const Color inkBlue = Color(0xFF1B3A5C);

  /// Dark charcoal for body text.
  static const Color inkDark = Color(0xFF2C2C2C);

  /// Muted grey for secondary text.
  static const Color inkLight = Color(0xFF7A7570);

  // — Accents —
  /// Stamp red — used for debts, liabilities, expenses.
  static const Color stampRed = Color(0xFFC0392B);

  /// Faded stamp red for backgrounds.
  static const Color stampRedLight = Color(0xFFFDECEA);

  /// Green ink — used for income, assets, positive values.
  static const Color inkGreen = Color(0xFF27774E);

  /// Faded green for backgrounds.
  static const Color inkGreenLight = Color(0xFFE8F5EE);

  // — Functional —
  /// Settlement / transfer accent.
  static const Color transferAmber = Color(0xFFD4A017);

  /// Error / invalid state.
  static const Color error = Color(0xFFB71C1C);

  /// Disabled / inactive elements.
  static const Color disabled = Color(0xFFBDB5AA);
}
