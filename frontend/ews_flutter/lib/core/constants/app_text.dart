import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Strings, dropdown option lists and text styles.
class AppText {
  AppText._();

  static const appName = 'EWS';
  static const appTitle = 'Elephant Warning System';
  static const division = 'COIMBATORE FOREST DIVISION';
  static const divisionTitle = 'Coimbatore Forest Division';

  static const List<String> rangeNames = [
    'Periyanaickenpalayam',
    'Mettupalayam',
    'Madukkarai',
    'Sirumugai',
    'Karamadai',
    'Coimbatore',
    'Bolampatty',
  ];

  static const List<String> designations = [
    'Forest Guard',
    'Beat Forest Officer',
    'Range Forest Officer',
    'Deputy Ranger',
    'Watcher',
    'Anti-Poaching Squad',
  ];

  static const List<String> damageTypes = [
    'Crop Damage',
    'Property Damage',
    'Human Injury',
    'Human Death',
    'Livestock Attack',
    'Road Blockage',
  ];

  static const List<String> chaseResults = [
    'All chased back successfully',
    'Partially — 1 remaining',
    'Partially — multiple remaining',
    'Chase unsuccessful',
    'Not attempted (dark/danger)',
  ];

  /// Rajdhani — headings, numbers, labels.
  static TextStyle heading({
    double size = 18,
    FontWeight weight = FontWeight.w700,
    Color color = AppColors.text,
    double letterSpacing = 0.5,
  }) =>
      GoogleFonts.rajdhani(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
      );

  /// DM Sans — body copy.
  static TextStyle body({
    double size = 13,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.text2,
    double? height,
  }) =>
      GoogleFonts.dmSans(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
      );
}
