import 'package:flutter/material.dart';

/// Professional EWS colour system
/// White + Forest Green theme

class AppColors {
  AppColors._();

  // ============================================================
  // MAIN BACKGROUND
  // ============================================================

  static const bg = Color(0xFFF7FAF8);
  static const bg2 = Color(0xFFFFFFFF);

  // ============================================================
  // CARDS
  // ============================================================

  static const card = Color(0xFFFFFFFF);
  static const card2 = Color(0xFFF0F7F2);

  // ============================================================
  // BORDERS
  // ============================================================

  static const border = Color(0xFFD9E7DD);
  static const border2 = Color(0xFFB9D5C1);

  // ============================================================
  // PRIMARY GREEN
  // ============================================================

  static const green = Color(0xFF16A34A);
  static const green2 = Color(0xFF15803D);
  static const green3 = Color(0xFF166534);

  // ============================================================
  // STATUS COLOURS
  // ============================================================

  static const amber = Color(0xFFF59E0B);
  static const amber2 = Color(0xFFD97706);

  static const red = Color(0xFFDC2626);
  static const red2 = Color(0xFFB91C1C);

  static const blue = Color(0xFF2563EB);
  static const purple = Color(0xFF7C3AED);
  static const pink = Color(0xFFDB2777);
  static const teal = Color(0xFF0D9488);

  // ============================================================
  // TEXT
  // ============================================================

  static const text = Color(0xFF17201A);
  static const text2 = Color(0xFF52665A);
  static const text3 = Color(0xFF7A8B80);

  // ============================================================
  // RANGE COLOURS
  // ============================================================

  static const Map<String, Color> rangeColors = {
    'Bolampatty': green,
    'Coimbatore': red,
    'Karamadai': blue,
    'Madukkarai': purple,
    'Mettupalayam': amber,
    'Periyanaickenpalayam': teal,
    'Sirumugai': pink,
  };

  static Color rangeColor(String name) {
    return rangeColors[name] ?? text2;
  }

  // ============================================================
  // ELEPHANT COUNT STATUS
  // ============================================================

  /// HIGH    : More than 10
  /// MEDIUM  : 5 - 10
  /// LOW     : 0 - 4

  static Color forCount(int today) {
    if (today > 10) {
      return red;
    }

    if (today > 4) {
      return amber;
    }

    return green;
  }
}