import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  static TextStyle get displayLarge => GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textPrimary);
  static TextStyle get displayMedium => GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary);
  static TextStyle get displaySmall => GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary);
  static TextStyle get headlineMedium => GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
  static TextStyle get titleLarge => GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
  static TextStyle get titleMedium => GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
  static TextStyle get bodyLarge => GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.textPrimary);
  static TextStyle get bodyMedium => GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.normal, color: AppColors.textPrimary);
  static TextStyle get bodySmall => GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.normal, color: AppColors.textSecondary);
  static TextStyle get labelLarge => GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white);
  static TextStyle get labelMedium => GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary);

  static TextTheme get textTheme {
    return GoogleFonts.interTextTheme().copyWith(
      displayLarge: displayLarge,
      displayMedium: displayMedium,
      displaySmall: displaySmall,
      headlineMedium: headlineMedium,
      titleLarge: titleLarge,
      titleMedium: titleMedium,
      bodyLarge: bodyLarge,
      bodyMedium: bodyMedium,
      bodySmall: bodySmall,
      labelLarge: labelLarge,
      labelMedium: labelMedium,
    );
  }
}
