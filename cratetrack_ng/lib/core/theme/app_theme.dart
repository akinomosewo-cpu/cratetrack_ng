import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Warm, soft, light-first palette. A single vibrant brand accent (amber-orange)
/// is used sparingly against off-white/cream surfaces, with generous rounding
/// and soft shadows instead of flat borders.
class AppColors {
  AppColors._();
  static const Color primary = Color(0xFFFF7A1A);
  static const Color primaryDeep = Color(0xFFE85D04);
  static const Color success = Color(0xFF2FB673);
  static const Color warning = Color(0xFFF5A524);
  static const Color danger = Color(0xFFE84B4B);
  static const Color background = Color(0xFFFBF5EC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFFF3E4);
  static const Color textPrimary = Color(0xFF241F1A);
  static const Color textSecondary = Color(0xFF7A7169);
  static const Color textTertiary = Color(0xFFB6AC9F);
  static const Color border = Color(0xFFF0E6D6);
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFF9F45), Color(0xFFFF6A1A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Shared radii for the app's soft, rounded aesthetic.
class AppRadii {
  AppRadii._();
  static const double card = 24;
  static const double cardLarge = 28;
  static const double button = 20;
  static const double chip = 999;
  static const double sheet = 28;
}

/// Soft drop shadows used in place of flat borders on cards/surfaces.
class AppShadows {
  AppShadows._();
  static List<BoxShadow> get card => [
        BoxShadow(
          color: const Color(0xFF241F1A).withValues(alpha: 0.06),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];
  static List<BoxShadow> get soft => [
        BoxShadow(
          color: const Color(0xFF241F1A).withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
  static List<BoxShadow> colored(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.28),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ];
}

class AppTextStyles {
  AppTextStyles._();
  static TextStyle get displayLarge => GoogleFonts.inter(fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: -0.8);
  static TextStyle get displayMedium => GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.5);
  static TextStyle get displaySmall => GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.3);
  static TextStyle get headlineLarge => GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700);
  static TextStyle get headlineMedium => GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700);
  static TextStyle get headlineSmall => GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700);
  static TextStyle get bodyLarge => GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w400, height: 1.5);
  static TextStyle get bodyMedium => GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w400, height: 1.5);
  static TextStyle get bodySmall => GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400, height: 1.5);
  static TextStyle get labelLarge => GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600);
  static TextStyle get labelMedium => GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600);
  static TextStyle get labelSmall => GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.4);
}

class AppTheme {
  AppTheme._();
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      surface: AppColors.surface,
      error: AppColors.danger,
      onPrimary: Colors.white,
      onSurface: AppColors.textPrimary,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleTextStyle: AppTextStyles.headlineMedium.copyWith(color: AppColors.textPrimary),
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.card)),
      margin: EdgeInsets.zero,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.button)),
        textStyle: AppTextStyles.headlineSmall,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceElevated,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.button), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadii.button), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.button), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
  );
}
