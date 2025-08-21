// lib/constants/app_colors.dart
import 'package:flutter/material.dart';

// Futuristic, minimal, bold color tokens with light/dark variants
class AppColors {
  // Dark neutrals
  static const Color bgDark = Color(0xFF0B0F12);
  static const Color surfaceDark = Color(0xFF11161A);
  static const Color surfaceAltDark = Color(0xFF0E1317);
  static const Color onSurfaceDark = Color(0xFFE6E9EF);
  static const Color outlineDark = Color(0xFF25313A);

  // Brand accents
  static const Color primary = Color(0xFF00E5FF); // electric cyan
  static const Color secondary = Color(0xFFFF2D95); // magenta
  static const Color tertiary = Color(0xFF8A63FF); // violet

  // Feedback
  static const Color success = Color(0xFF21D07A);
  static const Color warning = Color(0xFFFFC857);
  static const Color error = Color(0xFFFF5A67);

  // Light neutrals
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceAltLight = Color(0xFFF2F4F7);
  static const Color onSurfaceLight = Color(0xFF0B1220);
  static const Color outlineLight = Color(0xFFE3E8EF);

  // Gradients (used sparingly for hero/primary CTA)
  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF00E5FF), Color(0xFF8A63FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ---------------------------------------------------------------------------
  // Backward-compatibility aliases (to minimize refactors across the app)
  // ---------------------------------------------------------------------------
  static const Color pink = primary; // old primary now maps to new primary
  static const Color purple = secondary;
  static const Color teal = tertiary;
  static const Color blue = primary;

  static const Color dark = surfaceDark;
  static const Color darkShade = surfaceAltDark;
  static const Color lightGrey = bgLight;
  static const Color border = outlineLight;
  static const Color gold = warning;

  static const LinearGradient primaryGradient = accentGradient;
  static const LinearGradient fitsyncGradient = accentGradient;
  static const LinearGradient quizGradient = LinearGradient(
    colors: [surfaceDark, surfaceAltDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
