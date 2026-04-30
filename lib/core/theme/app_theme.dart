import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static const double radiusCard = 26;
  static const double radiusSm = 16;
  static const double radiusPill = 999;

  static ThemeData get theme {
    final body = GoogleFonts.plusJakartaSansTextTheme();
    final display = GoogleFonts.frauncesTextTheme();

    final textTheme = body.copyWith(
      displayLarge: display.displayLarge?.copyWith(color: AppColors.ink),
      displayMedium: display.displayMedium?.copyWith(color: AppColors.ink),
      displaySmall: display.displaySmall?.copyWith(color: AppColors.ink),
      headlineLarge: display.headlineLarge?.copyWith(color: AppColors.ink),
      headlineMedium: display.headlineMedium?.copyWith(color: AppColors.ink),
      headlineSmall: display.headlineSmall?.copyWith(color: AppColors.ink),
      titleLarge: display.titleLarge?.copyWith(color: AppColors.ink),
      bodyLarge: body.bodyLarge?.copyWith(color: AppColors.ink, fontSize: 18),
      bodyMedium: body.bodyMedium?.copyWith(color: AppColors.ink, fontSize: 16),
      bodySmall: body.bodySmall?.copyWith(color: AppColors.muted, fontSize: 14),
      labelLarge: body.labelLarge?.copyWith(color: AppColors.ink, fontSize: 16),
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        primary: AppColors.accent,
        surface: AppColors.surface,
        onSurface: AppColors.ink,
        brightness: Brightness.light,
      ),
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        elevation: 0,
        foregroundColor: AppColors.ink,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.line),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.line),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.accent, width: 2),
        ),
        labelStyle: TextStyle(color: AppColors.muted),
      ),
    );
  }
}
