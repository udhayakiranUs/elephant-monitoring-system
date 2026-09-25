import 'package:latlong2/latlong.dart';

enum RangeStatus {
  alert('Alert'),
  active('Active'),
  clear('Clear');

  const RangeStatus(this.label);
  final String label;
}

/// Live status of one forest range (Command Centre table + map).
class RangeModel {
  final String name;
  final int today;
  final int totalElephants;
  final int totalIncidents;
  final RangeStatus status;
  final String lastReport;

  const RangeModel({
    required this.name,
    required this.today,
    required this.totalElephants,
    required this.totalIncidents,
    required this.status,
    required this.lastReport,
  });

  factory RangeModel.fromJson(Map<String, dynamic> j) => RangeModel(
        name: j['name'] as String? ?? '',
        today: (j['today'] as num?)?.toInt() ?? 0,
        totalElephants: (j['total_elephants'] as num?)?.toInt() ?? 0,
        totalIncidents: (j['total_incidents'] as num?)?.toInt() ?? 0,
        status: RangeStatus.values.firstWhere(
          (s) => s.name == j['status'],
          orElse: () => RangeStatus.clear,
        ),
        lastReport: j['last_report'] as String? ?? '—',
      );
}

/// Polygon of a range loaded from assets/maps/forest_boundaries.json.
class RangeBoundary {
  final String name;
  final List<LatLng> points;

  const RangeBoundary(this.name, this.points);

  /// Vertex mean (same approach as the prototype).
  LatLng get centroid {
    final lat = points.fold<double>(0, (s, p) => s + p.latitude) / points.length;
    final lon = points.fold<double>(0, (s, p) => s + p.longitude) / points.length;
    return LatLng(lat, lon);
  }
}

/// Aggregated historical stats per range (Excel data, Jan 2024 – Mar 2026).
class RangeStat {
  final String range;
  final int lm, mg, fg, fc, sf, ug, mk;
  final int elephants;
  final int incidents;

  const RangeStat({
    required this.range,
    required this.lm,
    required this.mg,
    required this.fg,
    required this.fc,
    required this.sf,
    required this.ug,
    required this.mk,
    required this.elephants,
    required this.incidents,
  });

  int metric(bool elephantsView) => elephantsView ? elephants : incidents;
}
