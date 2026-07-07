import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Dark sports-app theme for Football Stats Dashboard.
abstract class AppTheme {
  // ── Brand Palette ─────────────────────────────────────────────────────────
  static const Color background = Color(0xFF0D0F14);
  static const Color surface = Color(0xFF161A23);
  static const Color surfaceElevated = Color(0xFF1E2330);
  static const Color accent = Color(0xFF00E5FF);       // Electric cyan
  static const Color accentGold = Color(0xFFFFD700);   // Gold for top-4
  static const Color accentGreen = Color(0xFF00C853);  // Win highlight
  static const Color accentRed = Color(0xFFFF1744);    // Loss highlight
  static const Color accentDraw = Color(0xFFFFAB00);   // Draw highlight
  static const Color textPrimary = Color(0xFFF0F2F5);
  static const Color textSecondary = Color(0xFF8A9BB0);
  static const Color divider = Color(0xFF252A35);
  static const Color shimmerBase = Color(0xFF1E2330);
  static const Color shimmerHighlight = Color(0xFF2A3040);

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF00E5FF), Color(0xFF0066FF)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1E2330), Color(0xFF161A23)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── ThemeData ─────────────────────────────────────────────────────────────
  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: accentGold,
        surface: surface,
        onPrimary: background,
        onSurface: textPrimary,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      dividerColor: divider,
      cardColor: surface,
    );
  }
}
