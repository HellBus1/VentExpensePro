import 'package:flutter/material.dart';
import '../constants/constants.dart' as Constants;

import 'color.dart';

class ColorSchemeChoice {
  static ColorScheme getColorScheme(bool isDarkMode, String colorPalette) {
    if (isDarkMode) {
      return _getDarkScheme(colorPalette);
    } else {
      return _getLightScheme(colorPalette);
    }
  }

  // Dark Schemes
  static ColorScheme _getDarkScheme(String colorPalette) {
    switch (colorPalette) {
      case Constants.CRIMSON:
        return ColorScheme.dark(
          primary: crimsonDarkPrimary,
          secondary: crimsonDarkSecondary,
          tertiary: darkTertiary,
          surface: darkBackground,
          onPrimary: darkTertiary,
          onSurface: darkOnSurface,
        );
      case Constants.CADMIUM_GREEN:
        return ColorScheme.dark(
          primary: cadmiumGreenDarkPrimary,
          secondary: cadmiumGreenDarkSecondary,
          tertiary: darkTertiary,
          surface: darkTertiary,
          onPrimary: darkTertiary,
          onSurface: darkOnSurface,
        );
      case Constants.COBALT_BLUE:
        return ColorScheme.dark(
          primary: cobaltBlueDarkPrimary,
          secondary: cobaltBlueDarkSecondary,
          tertiary: darkTertiary,
          surface: darkTertiary,
          onPrimary: darkTertiary,
          onSurface: darkOnSurface,
        );
      default:
        return ColorScheme.dark(
          primary: crimsonDarkPrimary,
          secondary: crimsonDarkSecondary,
          tertiary: darkTertiary,
          surface: darkTertiary,
          onPrimary: darkTertiary,
          onSurface: darkOnSurface,
        );
    }
  }

  // Light Schemes
  static ColorScheme _getLightScheme(String colorPalette) {
    switch (colorPalette) {
      case Constants.CRIMSON:
        return ColorScheme.light(
          primary: crimsonLightPrimary,
          secondary: crimsonLightSecondary,
          tertiary: lightTertiary,
          surface: lightTertiary,
          onPrimary: lightTertiary,
          onSurface: lightOnSurface,
        );
      case Constants.CADMIUM_GREEN:
        return ColorScheme.light(
          primary: cadmiumGreenLightPrimary,
          secondary: cadmiumGreenLightSecondary,
          tertiary: lightTertiary,
          surface: lightTertiary,
          onPrimary: lightTertiary,
          onSurface: lightOnSurface,
        );
      case Constants.COBALT_BLUE:
        return ColorScheme.light(
          primary: cobaltBlueLightPrimary,
          secondary: cobaltBlueLightSecondary,
          tertiary: lightTertiary,
          surface: lightTertiary,
          onPrimary: lightTertiary,
          onSurface: lightOnSurface,
        );
      default:
        return ColorScheme.light(
          primary: crimsonLightPrimary,
          secondary: crimsonLightSecondary,
          tertiary: lightTertiary,
          surface: lightTertiary,
          onPrimary: lightTertiary,
          onSurface: lightOnSurface,
        );
    }
  }
}
