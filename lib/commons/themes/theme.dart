import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vent_expense_pro/commons/themes/color_scheme_choice.dart';

ThemeData buildLightTheme(String colorPalette) {
  ColorScheme colorScheme =
      ColorSchemeChoice.getColorScheme(false, colorPalette);

  return _getThemeData(colorScheme);
}

ThemeData buildDarkTheme(String colorPalette) {
  ColorScheme colorScheme =
      ColorSchemeChoice.getColorScheme(true, colorPalette);

  return _getThemeData(colorScheme);
}

ThemeData _getThemeData(ColorScheme colorScheme) {
  return ThemeData(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
    cardColor: colorScheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.primary,
      elevation: 1,
      iconTheme: IconThemeData(color: colorScheme.onPrimary),
      actionsIconTheme: IconThemeData(color: colorScheme.onPrimary),
      titleTextStyle: TextStyle(
        color: colorScheme.onPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: colorScheme.primary,
        statusBarIconBrightness: Brightness.light,
      ),
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: colorScheme.onSurface),
      bodyMedium: TextStyle(color: colorScheme.onSurface),
      bodySmall: TextStyle(color: colorScheme.onSurface),
      titleLarge: TextStyle(color: colorScheme.onSurface),
      titleMedium: TextStyle(color: colorScheme.onSurface),
      titleSmall: TextStyle(color: colorScheme.onSurface),
    ),
    inputDecorationTheme: InputDecorationTheme(
      hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
      labelStyle: TextStyle(color: colorScheme.onSurface),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: colorScheme.primary),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: colorScheme.onSurface),
      ),
      prefixIconColor: colorScheme.primary,
    ),
    tabBarTheme: TabBarTheme(
      labelColor: colorScheme.primary,
      unselectedLabelColor: colorScheme.onSurface.withOpacity(0.6),
    ),
  );
}
