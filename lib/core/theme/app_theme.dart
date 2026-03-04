import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const primary = Color(0xFF4361EE);
  static const pink = Color(0xFFF72585);
  static const cyan = Color(0xFF4CC9F0);
  static const purple = Color(0xFF7209B7);
  static const background = Color(0xFFF2F3F7);
  static const cardWhite = Color(0xFFFFFFFF);
  static const textDark = Color(0xFF2C3E50);
  static const textGrey = Color(0xFF95A5A6);
  static const income = Color(0xFF2ECC71);
  static const expense = Color(0xFFF72585);

  static const List<Color> categoryColors = [
    primary, pink, cyan, purple,
    Color(0xFFFF6B6B), Color(0xFFFFD93D), Color(0xFF6BCB77),
  ];
}

class AppTheme {
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      background: AppColors.background,
    ),
    scaffoldBackgroundColor: AppColors.background,
    textTheme: GoogleFonts.nunitoTextTheme().copyWith(
      displayLarge: GoogleFonts.nunito(fontWeight: FontWeight.w800),
      titleLarge: GoogleFonts.nunito(fontWeight: FontWeight.w800, fontSize: 20),
      titleMedium: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 16),
      bodyLarge: GoogleFonts.nunito(fontWeight: FontWeight.w600, fontSize: 14),
      bodyMedium: GoogleFonts.nunito(fontWeight: FontWeight.w500, fontSize: 13),
      labelSmall: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 10),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: GoogleFonts.nunito(
        color: Colors.white,
        fontWeight: FontWeight.w800,
        fontSize: 20,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.cardWhite,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.pink,
      foregroundColor: Colors.white,
      elevation: 6,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textGrey,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    ),
  );
}
