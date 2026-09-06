import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

enum AppThemeMode {
  darkBlue,
  orange,
  skyBlue,
  red,
  normal;

  String get label {
    switch (this) {
      case AppThemeMode.darkBlue:
        return 'Dark Blue';
      case AppThemeMode.orange:
        return 'Orange';
      case AppThemeMode.skyBlue:
        return 'Sky Blue';
      case AppThemeMode.red:
        return 'Red';
      case AppThemeMode.normal:
        return 'Normal';
    }
  }

  Color get swatchColor {
    switch (this) {
      case AppThemeMode.darkBlue:
        return const Color(0xFF2563EB); // Royal Blue
      case AppThemeMode.orange:
        return const Color(0xFFF97316); // Bright Orange
      case AppThemeMode.skyBlue:
        return const Color(0xFF00D2FF); // Cyan / Sky Blue
      case AppThemeMode.red:
        return const Color(0xFFEF4444); // Crimson Red
      case AppThemeMode.normal:
        return const Color(0xFF22C55E); // Tactical Green Swatch
    }
  }

  Color get primaryColor {
    switch (this) {
      case AppThemeMode.darkBlue:
        return const Color(0xFF1E3A8A); // Deep Navy
      case AppThemeMode.orange:
        return const Color(0xFFC2410C); // Burnt Orange
      case AppThemeMode.skyBlue:
        return const Color(0xFF0284C7); // Deep Sky Blue
      case AppThemeMode.red:
        return const Color(0xFF991B1B); // Deep Red
      case AppThemeMode.normal:
        return const Color(0xFF354E28); // Original Olive Green
    }
  }

  Color get accentColor {
    switch (this) {
      case AppThemeMode.darkBlue:
        return const Color(0xFF3B82F6); // Blue Glow
      case AppThemeMode.orange:
        return const Color(0xFFF97316); // Orange Glow
      case AppThemeMode.skyBlue:
        return const Color(0xFF00D2FF); // Sky Blue Glow
      case AppThemeMode.red:
        return const Color(0xFFEF4444); // Red Glow
      case AppThemeMode.normal:
        return const Color(0xFF22C55E); // Green Glow
    }
  }

  Color get headerBackground {
    switch (this) {
      case AppThemeMode.darkBlue:
        return const Color(0xFF0A1224);
      case AppThemeMode.orange:
        return const Color(0xFF1C1008);
      case AppThemeMode.skyBlue:
        return const Color(0xFF081824);
      case AppThemeMode.red:
        return const Color(0xFF1C0A0A);
      case AppThemeMode.normal:
        return const Color(0xFF142416); // Original Dark Tactical Green
    }
  }

  Color get glowColor {
    return accentColor.withValues(alpha: 0.35);
  }

  ThemeData get themeData {
    final primary = primaryColor;
    final accent = accentColor;

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: accent,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.scaffoldBackground,
      textTheme: AppTypography.textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.textTheme.titleLarge?.copyWith(
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          textStyle: AppTypography.textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary),
          textStyle: AppTypography.textTheme.labelLarge?.copyWith(
            color: primary,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        hintStyle: AppTypography.textTheme.bodyMedium?.copyWith(
          color: AppColors.textHint,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 2,
        shadowColor: Colors.black.withAlpha(13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.zero,
      ),
    );
  }
}
