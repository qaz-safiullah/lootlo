import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants/app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        surface: AppColors.surfaceLight,
        error: AppColors.error,
      ),
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: AppColors.textMainLight,
        displayColor: AppColors.textMainLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: AppColors.textMainLight),
        titleTextStyle: TextStyle(color: AppColors.textMainLight, fontSize: 20, fontWeight: FontWeight.w600),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.backgroundDark, // OLED Black
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        surface: AppColors.surfaceDark,
        error: AppColors.error,
      ),
      // We use white text for dark mode
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: AppColors.textMainDark,
        displayColor: AppColors.textMainDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: AppColors.textMainDark),
        titleTextStyle: TextStyle(color: AppColors.textMainDark, fontSize: 20, fontWeight: FontWeight.w600),
      ),
    );
  }
}