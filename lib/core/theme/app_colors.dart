import 'package:flutter/material.dart';

class AppColors {
  // Primary Islamic Green Shades
  static const Color primaryDark = Color(0xFF0A261E); // Deep Forest Green
  static const Color primary = Color(0xFF0F382C);     // Royal Islamic Green
  static const Color primaryLight = Color(0xFF165342); // Emerald Green
  static const Color primaryAccent = Color(0xFF10B981); // Bright Emerald

  // Islamic Gold Accents
  static const Color goldLight = Color(0xFFF6E0A4);
  static const Color gold = Color(0xFFD4AF37);      // Classic Gold
  static const Color goldDark = Color(0xFFA67C1E);
  static const Color amberAccent = Color(0xFFE5B842);

  // Background & Surface (Parchment & Warm White)
  static const Color parchment = Color(0xFFF9F6F0);
  static const Color parchmentDark = Color(0xFFF0EAE1);
  static const Color cardLight = Color(0xFFFFFFFF);

  // Dark Mode Surfaces
  static const Color darkBackground = Color(0xFF07120E);
  static const Color darkSurface = Color(0xFF0F1E19);
  static const Color darkCard = Color(0xFF142721);
  static const Color darkBorder = Color(0xFF223E35);

  // Text Colors
  static const Color textDark = Color(0xFF1B2E27);
  static const Color textMuted = Color(0xFF5B6E67);
  static const Color textLight = Color(0xFFF3F5F4);
  static const Color textGold = Color(0xFFE6CA65);

  // Functional Colors
  static const Color success = Color(0xFF10B981);
  static const Color info = Color(0xFF3B82F6);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // Decorative Gradients
  static const LinearGradient islamicGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF0F382C), Color(0xFF0A261E), Color(0xFF051712)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF6E0A4), Color(0xFFD4AF37), Color(0xFFA67C1E)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF165342), Color(0xFF0F382C)],
  );

  static const LinearGradient paperGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFAF7F2), Color(0xFFF4ECE1)],
  );
}
