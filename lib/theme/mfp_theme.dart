import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Dark UI inspired by MyFitnessPal screenshots (unofficial).
abstract final class MfpColors {
  static const scaffold = Color(0xFF0F1419);
  static const surface = Color(0xFF1A2029);
  static const surfaceElevated = Color(0xFF222833);
  static const searchField = Color(0xFF1C222C);
  static const border = Color(0xFF2D3542);
  static const primary = Color(0xFF3F7EE8);
  static const primaryText = Color(0xFF5B9BFF);
  static const textPrimary = Color(0xFFF3F4F6);
  static const textSecondary = Color(0xFF9CA3AF);
  static const textMuted = Color(0xFF6B7280);
  static const carbs = Color(0xFF2DD4BF);
  static const fat = Color(0xFFA78BFA);
  static const protein = Color(0xFFFB923C);
  static const logPillBg = Color(0xFF1E2A3D);
  static const navBar = Color(0xCC151A22);
  static const premium = Color(0xFFF5C518);
}

abstract final class AppRadii {
  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 18.0;
  static const pill = 24.0;
}

ThemeData buildMfpTheme() {
  final textTheme = GoogleFonts.interTextTheme(
    ThemeData(brightness: Brightness.dark).textTheme,
  ).apply(
    bodyColor: MfpColors.textPrimary,
    displayColor: MfpColors.textPrimary,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: MfpColors.scaffold,
    textTheme: textTheme,
    colorScheme: const ColorScheme.dark(
      primary: MfpColors.primary,
      onPrimary: Colors.white,
      surface: MfpColors.surface,
      onSurface: MfpColors.textPrimary,
      outline: MfpColors.border,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: MfpColors.scaffold,
      foregroundColor: MfpColors.textPrimary,
      centerTitle: true,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: MfpColors.textPrimary,
      ),
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),
    dividerTheme: const DividerThemeData(color: MfpColors.border, thickness: 1),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: MfpColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: MfpColors.searchField,
      hintStyle: GoogleFonts.inter(color: MfpColors.textMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: const BorderSide(color: MfpColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: const BorderSide(color: MfpColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: const BorderSide(color: MfpColors.primary, width: 1.5),
      ),
    ),
    tabBarTheme: TabBarThemeData(
      indicatorColor: MfpColors.textPrimary,
      indicatorSize: TabBarIndicatorSize.label,
      labelColor: MfpColors.textPrimary,
      unselectedLabelColor: MfpColors.textMuted,
      labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
      unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
      dividerColor: Colors.transparent,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: MfpColors.surfaceElevated,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

BoxDecoration mfpCardDecoration() => BoxDecoration(
      color: MfpColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      border: Border.all(color: MfpColors.border.withValues(alpha: 0.6)),
    );