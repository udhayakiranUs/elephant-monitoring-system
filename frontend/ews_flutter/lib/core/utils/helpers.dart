import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/alert_model.dart';
import '../constants/app_colors.dart';
import '../constants/api_constants.dart';

class Helpers {
  Helpers._();

  static String date(DateTime d) => DateFormat('dd MMM yyyy').format(d);
  static String time(DateTime d) => DateFormat('HH:mm').format(d);
  static String dateTime(DateTime d) => '${date(d)} ${time(d)}';
  static String isoDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  static String timeOfDay(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  /// "Today, 14:32" / "Yesterday, 22:10" / "26 Apr 2026, 09:00"
  static String relativeDay(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today, ${time(d)}';
    if (diff == 1) return 'Yesterday, ${time(d)}';
    return '${date(d)}, ${time(d)}';
  }

  static String number(num n) => NumberFormat.decimalPattern().format(n);

  static String compact(num n) => n >= 1000
      ? '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k'
      : n.toInt().toString();

  static String coords(double lat, double lon) =>
      '${lat.toStringAsFixed(4)}° N, ${lon.toStringAsFixed(4)}° E';

  static String coordsShort(double lat, double lon) =>
      '${lat.toStringAsFixed(4)}°N ${lon.toStringAsFixed(4)}°E';

  static String initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  static Color threatColor(ThreatLevel t) => switch (t) {
        ThreatLevel.high => AppColors.red,
        ThreatLevel.medium => AppColors.amber,
        ThreatLevel.low => AppColors.green,
      };

  static Color alertColor(AlertType t) => switch (t) {
        AlertType.danger => AppColors.red,
        AlertType.warn => AppColors.amber,
        AlertType.info => AppColors.blue,
        AlertType.ok => AppColors.green,
      };

  /// Severity from elephant total (same rule as the prototype).
  static ThreatLevel severityFor(int total) => total > 10
      ? ThreatLevel.high
      : (total > 4 ? ThreatLevel.medium : ThreatLevel.low);

  /// Resolves a photo reference returned by the backend into a
  /// displayable absolute URL.
  ///
  /// - Relative paths like `/uploads/xyz.jpeg` are prefixed with the
  ///   backend host.
  /// - Already-absolute URLs (http/https) are returned unchanged.
  /// - Stale browser `blob:` references are never valid here and
  ///   should already be filtered out upstream (see ReportModel), but
  ///   as a safety net this returns null for them so callers can skip
  ///   rendering instead of crashing.
  static String? resolvePhotoUrl(String raw) {
    if (raw.startsWith('blob:')) {
      return null;
    }

    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }

    final path = raw.startsWith('/') ? raw : '/$raw';
    return '${ApiConstants.hostUrl}$path';
  }
}
