import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../core/constants/api_constants.dart';
import '../models/range_model.dart';
import 'storage_service.dart';

class RangeMatch {
  final String name;
  final bool inside;
  final double distanceKm;
  const RangeMatch(this.name, this.inside, this.distanceKm);
}

/// Range boundaries (KMZ-derived asset + HQ edits) and map helpers.
///
/// HQ edits are stored on this device (SharedPreferences) until the backend
/// has `PUT /ranges/{name}/boundary` and field apps download boundaries.
class MapService extends ChangeNotifier {
  MapService(this._storage);

  final StorageService _storage;
  static const _kOverrides = 'boundary_overrides';

  List<RangeBoundary> boundaries = [];
  final Map<String, List<LatLng>> _original = {};
  Map<String, dynamic> _overrides = {};

  Future<void> load() async {
    final raw = await rootBundle.loadString('assets/maps/forest_boundaries.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    boundaries = [
      for (final f in json['features'] as List)
        RangeBoundary(
          (f['properties'] as Map)['name'] as String,
          [
            for (final c in ((f['geometry'] as Map)['coordinates'] as List).first as List)
              LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
          ],
        ),
    ];
    for (final b in boundaries) {
      _original[b.name] = List.of(b.points);
    }
    _applyOverrides();
  }

  void _applyOverrides() {
    final raw = _storage.getString(_kOverrides);
    if (raw == null) return;
    try {
      _overrides = jsonDecode(raw) as Map<String, dynamic>;
      boundaries = [
        for (final b in boundaries)
          _overrides[b.name] == null
              ? b
              : RangeBoundary(b.name, [
                  for (final p in _overrides[b.name] as List)
                    LatLng((p[0] as num).toDouble(), (p[1] as num).toDouble()),
                ]),
      ];
    } catch (_) {
      _overrides = {};
    }
  }

  RangeBoundary? boundaryFor(String name) {
    for (final b in boundaries) {
      if (b.name == name) return b;
    }
    return null;
  }

  bool isEdited(String name) => _overrides.containsKey(name);

  /// Saves a new border for [name] (needs >= 3 points).
  Future<void> updateBoundary(String name, List<LatLng> points) async {
    if (points.length < 3) return;
    _replace(name, points);
    _overrides[name] = [for (final p in points) [p.latitude, p.longitude]];
    await _storage.setString(_kOverrides, jsonEncode(_overrides));
    notifyListeners();
  }

  /// Restores the original KMZ border for [name].
  Future<void> resetBoundary(String name) async {
    final orig = _original[name];
    if (orig == null) return;
    _replace(name, orig);
    _overrides.remove(name);
    await _storage.setString(_kOverrides, jsonEncode(_overrides));
    notifyListeners();
  }

  void _replace(String name, List<LatLng> points) {
    boundaries = [
      for (final b in boundaries) b.name == name ? RangeBoundary(name, List.of(points)) : b,
    ];
  }

  /// Inserts [p] into the polygon on the edge closest to it.
  static List<LatLng> insertVertex(List<LatLng> poly, LatLng p) {
    var bestI = 0;
    var bestD = double.infinity;
    for (var i = 0; i < poly.length; i++) {
      final d = _segmentDistanceKm(poly[i], poly[(i + 1) % poly.length], p.latitude, p.longitude);
      if (d < bestD) {
        bestD = d;
        bestI = i;
      }
    }
    return [...poly.sublist(0, bestI + 1), p, ...poly.sublist(bestI + 1)];
  }

  // ── matching ────────────────────────────────────────────────
  /// Which range is this point in? If outside every polygon, returns the range
  /// whose *boundary* is closest, with [RangeMatch.inside] = false.
  RangeMatch? match(double lat, double lon) {
    if (boundaries.isEmpty) return null;
    final p = LatLng(lat, lon);
    for (final b in boundaries) {
      if (_contains(b.points, p)) return RangeMatch(b.name, true, 0);
    }
    RangeMatch? best;
    for (final b in boundaries) {
      var d = double.infinity;
      for (var i = 0; i < b.points.length; i++) {
        final e = _segmentDistanceKm(b.points[i], b.points[(i + 1) % b.points.length], lat, lon);
        if (e < d) d = e;
      }
      if (best == null || d < best.distanceKm) best = RangeMatch(b.name, false, d);
    }
    return best;
  }

  /// Distance (km) from point (lat, lon) to segment a-b (flat-earth approx).
  static double _segmentDistanceKm(LatLng a, LatLng b, double lat, double lon) {
    final kx = 111.32 * math.cos(lat * math.pi / 180);
    const ky = 110.574;
    final ax = (a.longitude - lon) * kx, ay = (a.latitude - lat) * ky;
    final bx = (b.longitude - lon) * kx, by = (b.latitude - lat) * ky;
    final dx = bx - ax, dy = by - ay;
    final len2 = dx * dx + dy * dy;
    final t = len2 == 0 ? 0.0 : (-(ax * dx + ay * dy) / len2).clamp(0.0, 1.0).toDouble();
    final px = ax + t * dx, py = ay + t * dy;
    return math.sqrt(px * px + py * py);
  }

  // Ray-casting point-in-polygon.
  bool _contains(List<LatLng> poly, LatLng p) {
    var inside = false;
    for (var i = 0, j = poly.length - 1; i < poly.length; j = i++) {
      final a = poly[i];
      final b = poly[j];
      final crosses = (a.latitude > p.latitude) != (b.latitude > p.latitude) &&
          p.longitude <
              (b.longitude - a.longitude) * (p.latitude - a.latitude) /
                      (b.latitude - a.latitude) +
                  a.longitude;
      if (crosses) inside = !inside;
    }
    return inside;
  }

  // ── flutter_map helpers ─────────────────────────────────────
  /// OSM tiles dimmed + tinted green to match the dark theme.
  static TileLayer tileLayer() => TileLayer(
        urlTemplate: ApiConstants.tileUrl,
        userAgentPackageName: ApiConstants.userAgentPackage,
        maxZoom: 18,
        tileBuilder: _darkTile,
      );

  static Widget _darkTile(BuildContext context, Widget tile, TileImage image) =>
      ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.22, 0.25, 0.06, 0, 0,
          0.26, 0.34, 0.07, 0, 0,
          0.16, 0.20, 0.08, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        child: tile,
      );

  List<Polygon> polygons({
    required Color Function(RangeBoundary) colorOf,
    double fillOpacity = 0.2,
    double borderWidth = 2,
    String? exclude,
  }) =>
      [
        for (final b in boundaries)
          if (b.name != exclude)
            Polygon(
              points: b.points,
              color: colorOf(b).withValues(alpha: fillOpacity),
              borderColor: colorOf(b),
              borderStrokeWidth: borderWidth,
            ),
      ];
}
