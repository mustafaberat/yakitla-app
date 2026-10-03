library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class YakitlaColors {
  static const accent = Color(0xFF1FA855);
  static const accentDark = Color(0xFF178A44);
  static const ink = Color(0xFF111827);
  static const muted = Color(0xFF6B7280);
  static const line = Color(0xFFE5E7EB);
  static const canvas = Color(0xFFF7F8FA);
  static const card = Color(0xFFFFFFFF);
  static const asphalt = Color(0xFF121418);
  static const asphaltElevated = Color(0xFF1C1F24);
}

abstract final class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: YakitlaColors.accent,
        brightness: Brightness.light,
        primary: YakitlaColors.accent,
        surface: YakitlaColors.card,
        onSurface: YakitlaColors.ink,
      ),
      scaffoldBackgroundColor: YakitlaColors.canvas,
    );
    return _polish(base, YakitlaColors.ink, YakitlaColors.muted);
  }

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: YakitlaColors.accent,
        brightness: Brightness.dark,
        primary: const Color(0xFF34D399),
        surface: YakitlaColors.asphaltElevated,
        onSurface: const Color(0xFFF3F4F6),
      ),
      scaffoldBackgroundColor: YakitlaColors.asphalt,
    );
    return _polish(base, const Color(0xFFF3F4F6), const Color(0xFF9CA3AF));
  }

  static ThemeData _polish(ThemeData base, Color ink, Color muted) {
    final text = GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
      bodyColor: ink,
      displayColor: ink,
    );
    final isDark = base.brightness == Brightness.dark;
    return base.copyWith(
      textTheme: text,
      dividerColor: isDark ? Colors.white12 : YakitlaColors.line,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: ink,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w800,
          fontSize: 28,
          letterSpacing: -0.8,
          color: ink,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? YakitlaColors.asphaltElevated : Colors.white,
        elevation: 8,
        shadowColor: Colors.black12,
        indicatorColor: YakitlaColors.accent.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? YakitlaColors.accent : muted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? YakitlaColors.accent : muted,
            size: 22,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: YakitlaColors.accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

/// Soft pastel header tint per brand (reference-app style).
Color brandHeaderTint(String brand) {
  final b = brand.toLowerCase();
  if (b.contains('opet')) return const Color(0xFFE8F7F4);
  if (b.contains('aytemiz')) return const Color(0xFFFDECEE);
  if (b.contains('shell')) return const Color(0xFFFFF4E5);
  if (b.contains('bp')) return const Color(0xFFEAF4FF);
  if (b.contains('total')) return const Color(0xFFFFF0F0);
  if (b.contains('petrol')) return const Color(0xFFEAF7FF);
  if (b.contains('socar')) return const Color(0xFFFFF5E8);
  if (b.contains('lukoil')) return const Color(0xFFFFF0E8);
  if (b.contains('alpet')) return const Color(0xFFEEF6FF);
  if (b.startsWith('go') || b.contains('güzel') || b.contains('guzel')) {
    return const Color(0xFFEAF8EE);
  }
  if (b.contains('kadoil')) return const Color(0xFFFFF3E8);
  if (b.startsWith('tp') || b.contains('petroller')) {
    return const Color(0xFFEDEFF5);
  }
  final hue = (brand.hashCode.abs() % 360).toDouble();
  return HSLColor.fromAHSL(1, hue, 0.35, 0.94).toColor();
}
