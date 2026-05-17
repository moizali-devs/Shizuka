import 'package:flutter/material.dart';

abstract final class ShizukaTokens {
  // Colors
  static const Color background = Color(0xFFFAF8F3);
  static const Color card = Color(0xFFFFFCF9);
  static const Color primary = Color(0xFFE8B4B8);
  static const Color primaryDark = Color(0xFFC47B5A);
  static const Color textPrimary = Color(0xFF2C2420);
  static const Color textSecondary = Color(0xFF8C7B75);
  static const Color matcha = Color(0xFF8FAF8F);
  static const Color error = Color(0xFFD4756B);

  // Border radii
  static const double radiusSm = 8.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 24.0;
  static const double radiusPill = 100.0;

  // Shadows
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: textPrimary.withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get elevatedShadow => [
        BoxShadow(
          color: primaryDark.withValues(alpha: 0.15),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];
}
