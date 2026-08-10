import 'package:flutter/material.dart';

/// GroupRide visual theme — a warm, road-trip palette with strong status colors
/// for safety cues (green OK, amber falling behind, red assistance).
class AppTheme {
  AppTheme._();

  static const Color primary = Color(0xFFFF6B35); // sunset orange
  static const Color primaryDark = Color(0xFFE85A28);
  static const Color accent = Color(0xFF1B4965); // deep highway blue
  static const Color surfaceDark = Color(0xFF14181F);
  static const Color cardDark = Color(0xFF1E252E);

  static const Color statusOk = Color(0xFF2ECC71);
  static const Color statusWarn = Color(0xFFF5A623);
  static const Color statusDanger = Color(0xFFE74C3C);

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: surfaceDark,
      colorScheme: base.colorScheme.copyWith(
        primary: primary,
        secondary: accent,
        surface: cardDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: cardDark,
        side: BorderSide.none,
      ),
    );
  }

  static const EdgeInsets pagePadding = EdgeInsets.all(16);
  static const double radius = 16;
}
