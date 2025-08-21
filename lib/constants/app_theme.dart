// lib/constants/app_theme.dart
import 'package:fitsyncgemini/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Typography
  static TextTheme _textThemeDark = TextTheme(
    displayLarge: GoogleFonts.spaceGrotesk(
      fontWeight: FontWeight.w700,
      fontSize: 48,
      height: 1.1,
      letterSpacing: -0.5,
      color: AppColors.onSurfaceDark,
    ),
    headlineMedium: GoogleFonts.spaceGrotesk(
      fontWeight: FontWeight.w600,
      fontSize: 28,
      letterSpacing: -0.2,
      color: AppColors.onSurfaceDark,
    ),
    titleMedium: GoogleFonts.inter(
      fontWeight: FontWeight.w600,
      fontSize: 16,
      color: AppColors.onSurfaceDark,
    ),
    bodyLarge: GoogleFonts.inter(
      fontWeight: FontWeight.w400,
      fontSize: 16,
      color: AppColors.onSurfaceDark,
    ),
    labelLarge: GoogleFonts.inter(
      fontWeight: FontWeight.w600,
      fontSize: 14,
      color: AppColors.onSurfaceDark,
    ),
  );

  static TextTheme _textThemeLight = TextTheme(
    displayLarge: GoogleFonts.spaceGrotesk(
      fontWeight: FontWeight.w700,
      fontSize: 48,
      height: 1.1,
      letterSpacing: -0.5,
      color: AppColors.onSurfaceLight,
    ),
    headlineMedium: GoogleFonts.spaceGrotesk(
      fontWeight: FontWeight.w600,
      fontSize: 28,
      letterSpacing: -0.2,
      color: AppColors.onSurfaceLight,
    ),
    titleMedium: GoogleFonts.inter(
      fontWeight: FontWeight.w600,
      fontSize: 16,
      color: AppColors.onSurfaceLight,
    ),
    bodyLarge: GoogleFonts.inter(
      fontWeight: FontWeight.w400,
      fontSize: 16,
      color: AppColors.onSurfaceLight,
    ),
    labelLarge: GoogleFonts.inter(
      fontWeight: FontWeight.w600,
      fontSize: 14,
      color: AppColors.onSurfaceLight,
    ),
  );

  // Color schemes
  static final ColorScheme _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.primary,
    onPrimary: Colors.black,
    secondary: AppColors.secondary,
    onSecondary: Colors.black,
    tertiary: AppColors.tertiary,
    onTertiary: Colors.black,
    error: AppColors.error,
    onError: Colors.black,
    background: AppColors.bgDark,
    onBackground: AppColors.onSurfaceDark,
    surface: AppColors.surfaceDark,
    onSurface: AppColors.onSurfaceDark,
    surfaceVariant: AppColors.surfaceAltDark,
    onSurfaceVariant: AppColors.onSurfaceDark,
    outline: AppColors.outlineDark,
  );

  static final ColorScheme _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: Colors.white,
    secondary: AppColors.secondary,
    onSecondary: Colors.white,
    tertiary: AppColors.tertiary,
    onTertiary: Colors.white,
    error: AppColors.error,
    onError: Colors.white,
    background: AppColors.bgLight,
    onBackground: AppColors.onSurfaceLight,
    surface: AppColors.surfaceLight,
    onSurface: AppColors.onSurfaceLight,
    surfaceVariant: AppColors.surfaceAltLight,
    onSurfaceVariant: AppColors.onSurfaceLight,
    outline: AppColors.outlineLight,
  );

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _darkScheme,
      scaffoldBackgroundColor: _darkScheme.background,
      textTheme: _textThemeDark,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: _textThemeDark.titleMedium,
        foregroundColor: _darkScheme.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _darkScheme.primary,
          foregroundColor: _darkScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: _textThemeDark.labelLarge,
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _darkScheme.onSurface,
          side: BorderSide(color: _darkScheme.outline, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: _textThemeDark.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _darkScheme.onSurface,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: _textThemeDark.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkScheme.surface,
        hintStyle: _textThemeDark.bodyLarge?.copyWith(
          color: _darkScheme.onSurface.withOpacity(0.6),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _darkScheme.outline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _darkScheme.primary, width: 2),
        ),
      ),
      cardTheme: CardTheme(
        color: _darkScheme.surface,
        margin: EdgeInsets.zero,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: _darkScheme.outline, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _darkScheme.surface,
        contentTextStyle: _textThemeDark.bodyLarge,
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: _darkScheme.primary,
      ),
      dividerColor: _darkScheme.outline,
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: _darkScheme.primary,
        unselectedItemColor: _darkScheme.onSurface.withOpacity(0.6),
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
      ),
      iconTheme: IconThemeData(color: _darkScheme.onSurface.withOpacity(0.9)),
      listTileTheme: ListTileThemeData(
        iconColor: _darkScheme.onSurface.withOpacity(0.8),
        textColor: _darkScheme.onSurface,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: _darkScheme.outline, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _lightScheme,
      scaffoldBackgroundColor: _lightScheme.background,
      textTheme: _textThemeLight,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: _textThemeLight.titleMedium,
        foregroundColor: _lightScheme.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _lightScheme.primary,
          foregroundColor: _lightScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: _textThemeLight.labelLarge,
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _lightScheme.onSurface,
          side: BorderSide(color: _lightScheme.outline, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: _textThemeLight.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _lightScheme.onSurface,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: _textThemeLight.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightScheme.surface,
        hintStyle: _textThemeLight.bodyLarge?.copyWith(
          color: _lightScheme.onSurface.withOpacity(0.6),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _lightScheme.outline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _lightScheme.primary, width: 2),
        ),
      ),
      cardTheme: CardTheme(
        color: _lightScheme.surface,
        margin: EdgeInsets.zero,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: _lightScheme.outline, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _lightScheme.surface,
        contentTextStyle: _textThemeLight.bodyLarge,
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: _lightScheme.primary,
      ),
      dividerColor: _lightScheme.outline,
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: _lightScheme.primary,
        unselectedItemColor: _lightScheme.onSurface.withOpacity(0.6),
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
      ),
      iconTheme: IconThemeData(color: _lightScheme.onSurface.withOpacity(0.9)),
      listTileTheme: ListTileThemeData(
        iconColor: _lightScheme.onSurface.withOpacity(0.8),
        textColor: _lightScheme.onSurface,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: _lightScheme.outline, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
