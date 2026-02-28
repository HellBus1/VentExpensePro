import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Builds the full [ThemeData] for the Stationery aesthetic.
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // — Colors —
      scaffoldBackgroundColor: AppColors.paper,
      colorScheme: const ColorScheme.light(
        primary: AppColors.inkBlue,
        onPrimary: AppColors.paper,
        secondary: AppColors.stampRed,
        onSecondary: Colors.white,
        surface: AppColors.paperElevated,
        onSurface: AppColors.inkDark,
        error: AppColors.error,
        onError: Colors.white,
      ),

      // — App Bar —
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.paper,
        foregroundColor: AppColors.inkBlue,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.titleLarge,
      ),

      // — Bottom Navigation —
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.paperElevated,
        selectedItemColor: AppColors.inkBlue,
        unselectedItemColor: AppColors.disabled,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: AppTypography.label,
        unselectedLabelStyle: AppTypography.label,
      ),

      // — Cards —
      cardTheme: CardThemeData(
        color: AppColors.paperElevated,
        elevation: 1,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),

      // — FAB —
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.inkBlue,
        foregroundColor: AppColors.paper,
        elevation: 4,
      ),

      // — Text —
      textTheme: const TextTheme(
        displayLarge: AppTypography.displayLarge,
        displayMedium: AppTypography.displayMedium,
        titleLarge: AppTypography.titleLarge,
        titleMedium: AppTypography.titleMedium,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
        bodySmall: AppTypography.bodySmall,
        labelSmall: AppTypography.label,
      ),

      // — Divider —
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 0.5,
        space: 1,
      ),

      // — Input —
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.paper,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.inkBlue, width: 1.5),
        ),
        labelStyle: AppTypography.bodyMedium,
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.disabled),
      ),
    );
  }
}
