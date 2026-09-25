import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../constants/app_text.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
    final radius = BorderRadius.circular(8);
    OutlineInputBorder border(Color c) =>
        OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: c));

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      canvasColor: AppColors.bg2,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.green,
        secondary: AppColors.amber,
        error: AppColors.red,
        surface: AppColors.card,
        onSurface: AppColors.text,
        onPrimary: AppColors.bg,
      ),
      textTheme: GoogleFonts.dmSansTextTheme(base.textTheme).apply(
        bodyColor: AppColors.text,
        displayColor: AppColors.text,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg2,
        foregroundColor: AppColors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        shape: const Border(bottom: BorderSide(color: AppColors.border)),
        titleTextStyle: AppText.heading(size: 17, color: AppColors.green, letterSpacing: 1),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bg2,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        labelStyle: AppText.body(size: 12),
        hintStyle: AppText.body(size: 13, color: AppColors.text3),
        border: border(AppColors.border2),
        enabledBorder: border(AppColors.border2),
        focusedBorder: border(AppColors.green),
        errorBorder: border(AppColors.red),
        focusedErrorBorder: border(AppColors.red),
      ),
      dividerColor: AppColors.border,
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.card2,
        surfaceTintColor: Colors.transparent,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.bg2,
        selectedColor: AppColors.green3,
        side: const BorderSide(color: AppColors.border),
        labelStyle: AppText.body(size: 12),
      ),
    );
  }
}
