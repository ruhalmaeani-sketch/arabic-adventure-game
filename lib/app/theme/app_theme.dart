import 'package:flutter/material.dart';

import 'app_palette.dart';

/// سِمَةُ التطبيق: خطٌّ عربيٌّ واضح، وأحجامٌ كبيرةٌ تكفي القراءةَ على الهاتف.
class AppTheme {
  const AppTheme._();

  static const String uiFont = 'Cairo';
  static const String displayFont = 'Amiri';

  static ThemeData build() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppPalette.wood,
        primary: AppPalette.wood,
        surface: AppPalette.parchment,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppPalette.parchment,
      fontFamily: uiFont,
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        displayLarge: const TextStyle(
          fontFamily: displayFont,
          fontSize: 44,
          height: 1.4,
          fontWeight: FontWeight.w700,
          color: AppPalette.ink,
        ),
        titleLarge: const TextStyle(
          fontFamily: displayFont,
          fontSize: 26,
          height: 1.5,
          color: AppPalette.ink,
        ),
        bodyLarge: const TextStyle(
          fontFamily: uiFont,
          fontSize: 18,
          height: 1.7,
          color: AppPalette.inkSoft,
        ),
        bodyMedium: const TextStyle(
          fontFamily: uiFont,
          fontSize: 16,
          height: 1.7,
          color: AppPalette.inkSoft,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppPalette.wood,
          foregroundColor: AppPalette.parchment,
          minimumSize: const Size(220, 58),
          textStyle: const TextStyle(
            fontFamily: displayFont,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
