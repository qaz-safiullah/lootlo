import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF16A34A); // Lootlo Green
  static const Color primaryDark = Color(0xFF15803D);
  static const Color error = Color(0xFFEF4444);

  // --- Light Mode Colors ---
  static const Color backgroundLight = Color(0xFFF9FAFB); // Very soft off-white
  static const Color surfaceLight = Colors.white; // For cards and inputs
  static const Color textMainLight = Color(0xFF111827);
  static const Color textMutedLight = Color(0xFF6B7280);
  static const Color borderLight = Color(0xFFE5E7EB);

  // --- Dark Mode Colors (OLED Optimized) ---
  static const Color backgroundDark = Colors.black; // Pure OLED Black
  static const Color surfaceDark = Color(0xFF121212); // Elevated dark for inputs/cards
  static const Color textMainDark = Color(0xFFF9FAFB);
  static const Color textMutedDark = Color(0xFF9CA3AF);
  static const Color borderDark = Color(0xFF1F2937);
}