// lib/constants/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette
  static const Color pink = Color(0xFFFF6B9D);
  static const Color purple = Color(0xFFC44DC7);
  static const Color teal = Color(0xFF4ECDC4);
  static const Color blue = Color(0xFF45B7D1);

  // Neutral Palette
  static const Color dark = Color(0xFF2C3E50);
  static const Color darkShade = Color(0xFF34495E);
  static const Color lightGrey = Color(0xFFF8F9FA);
  static const Color border = Color(0xFFE0E0E0);

  // Accent Palette
  static const Color gold = Color(0xFFFFD700);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [pink, purple, teal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient fitsyncGradient = LinearGradient(
    colors: [pink, teal],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient quizGradient = LinearGradient(
    colors: [dark, darkShade],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
