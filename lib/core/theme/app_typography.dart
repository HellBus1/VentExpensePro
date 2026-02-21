import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Text styles for the Stationery aesthetic.
///
/// - **Lora** (serif) for body, headers — evokes ink on paper.
/// - **JetBrainsMono** (monospace) for amounts — ledger numerals.
class AppTypography {
  AppTypography._();

  // — Font family names (must match pubspec.yaml declarations) —
  static const String _serifFamily = 'Lora';
  static const String _monoFamily = 'JetBrainsMono';

  // — Headers —

  static const TextStyle displayLarge = TextStyle(
    fontFamily: _serifFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.inkBlue,
    height: 1.3,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: _serifFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.inkBlue,
    height: 1.3,
  );

  static const TextStyle titleLarge = TextStyle(
    fontFamily: _serifFamily,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.inkDark,
    height: 1.4,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: _serifFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.inkDark,
    height: 1.4,
  );

  // — Body —

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _serifFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.inkDark,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _serifFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.inkDark,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: _serifFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.inkLight,
    height: 1.4,
  );

  // — Monospace (amounts / numbers) —

  static const TextStyle amountLarge = TextStyle(
    fontFamily: _monoFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.inkDark,
    height: 1.2,
  );

  static const TextStyle amountMedium = TextStyle(
    fontFamily: _monoFamily,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.inkDark,
    height: 1.3,
  );

  static const TextStyle amountSmall = TextStyle(
    fontFamily: _monoFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.inkDark,
    height: 1.3,
  );

  // — Labels / Captions —

  static const TextStyle label = TextStyle(
    fontFamily: _serifFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.inkLight,
    letterSpacing: 1.2,
    height: 1.4,
  );
}
