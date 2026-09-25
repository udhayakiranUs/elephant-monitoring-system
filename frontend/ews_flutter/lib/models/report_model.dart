import 'elephant_model.dart';
import 'alert_model.dart';

class ReportModel {
  final String id;
  final String range;
  final String beat;
  final double lat;
  final double lon;
  final String locationDescription;
  final DateTime dateTime;
  final String officer;
  final String designation;
  final String team;
  final ElephantCounts counts;
  final bool damage;
  final String damageType;
  final String damageDescription;
  final String chaseStart;
  final String chaseResult;
  final String remarks;
  final List<String> elephantPhotoPaths;
  final List<String> damagePhotoPaths;
  final bool pendingSync;

  const ReportModel({
    required this.id,
    required this.range,
    required this.beat,
    required this.lat,
    required this.lon,
    required this.locationDescription,
    required this.dateTime,
    required this.officer,
    required this.designation,
    required this.team,
    required this.counts,
    required this.damage,
    required this.damageType,
    required this.damageDescription,
    required this.chaseStart,
    required this.chaseResult,
    required this.remarks,
    this.elephantPhotoPaths = const [],
    this.damagePhotoPaths = const [],
    this.pendingSync = false,
  });

  int get total => counts.total;

  ThreatLevel get severity {
    if (total > 10) {
      return ThreatLevel.high;
    }

    if (total > 4) {
      return ThreatLevel.medium;
    }

    return ThreatLevel.low;
  }

  String get summary {
    if (remarks.isNotEmpty) {
      return remarks;
    }

    return 'Field report submitted';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'range': range,
      'beat': beat,
      'lat': lat,
      'lon': lon,
      'location_description': locationDescription,
      'date_time': dateTime.toIso8601String(),
      'officer': officer,
      'designation': designation,
      'team': team,
      'counts': counts.toJson(),
      'total': total,
      'damage': damage,
      'damage_type': damageType,
      'damage_description': damageDescription,
      'chase_start': chaseStart,
      'chase_result': chaseResult,
      'remarks': remarks,
      // NOTE: the backend does not accept photos at report-creation time.
      // It only stores photos via POST /reports/{id}/photos, and returns
      // them all merged into a single 'photos' array (no elephant/damage
      // split server-side). Sending elephant_photos/damage_photos here
      // was a no-op the backend silently ignored, so we no longer send
      // them — this also stops stale blob: URLs from being persisted.
    };
  }

  factory ReportModel.fromJson(Map<String, dynamic> j) {
    // The backend stores all photos (elephant + damage) together under
    // a single 'photos' key, with no server-side split. We also filter
    // out any stale browser blob: URLs here — those were saved by an
    // older bug, point to nothing after a page reload, and can never
    // be displayed.
    final allPhotos = (j['photos'] as List?)
            ?.map((e) => '$e')
            .where((p) => !p.startsWith('blob:'))
            .toList() ??
        const <String>[];

    return ReportModel(
      id: '${j['id']}',
      range: j['range'] as String? ?? '',
      beat: j['beat'] as String? ?? '',
      lat: (j['lat'] as num?)?.toDouble() ?? 0,
      lon: (j['lon'] as num?)?.toDouble() ?? 0,
      locationDescription: j['location_description'] as String? ?? '',
      dateTime: DateTime.tryParse('${j['date_time']}') ?? DateTime.now(),
      officer: j['officer'] as String? ?? '',
      designation: j['designation'] as String? ?? '',
      team: j['team'] as String? ?? '',
      counts: ElephantCounts.fromJson(
        j['counts'] as Map<String, dynamic>?,
      ),
      damage: j['damage'] as bool? ?? false,
      damageType: j['damage_type'] as String? ?? '',
      damageDescription: j['damage_description'] as String? ?? '',
      chaseStart: j['chase_start'] as String? ?? '',
      chaseResult: j['chase_result'] as String? ?? '',
      remarks: j['remarks'] as String? ?? '',
      elephantPhotoPaths: allPhotos,
      damagePhotoPaths: const [],
      pendingSync: false,
    );
  }

  ReportModel copyWith({
    String? id,
    String? range,
    String? beat,
    double? lat,
    double? lon,
    String? locationDescription,
    DateTime? dateTime,
    String? officer,
    String? designation,
    String? team,
    ElephantCounts? counts,
    bool? damage,
    String? damageType,
    String? damageDescription,
    String? chaseStart,
    String? chaseResult,
    String? remarks,
    List<String>? elephantPhotoPaths,
    List<String>? damagePhotoPaths,
    bool? pendingSync,
  }) {
    return ReportModel(
      id: id ?? this.id,
      range: range ?? this.range,
      beat: beat ?? this.beat,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      locationDescription: locationDescription ?? this.locationDescription,
      dateTime: dateTime ?? this.dateTime,
      officer: officer ?? this.officer,
      designation: designation ?? this.designation,
      team: team ?? this.team,
      counts: counts ?? this.counts,
      damage: damage ?? this.damage,
      damageType: damageType ?? this.damageType,
      damageDescription: damageDescription ?? this.damageDescription,
      chaseStart: chaseStart ?? this.chaseStart,
      chaseResult: chaseResult ?? this.chaseResult,
      remarks: remarks ?? this.remarks,
      elephantPhotoPaths: elephantPhotoPaths ?? this.elephantPhotoPaths,
      damagePhotoPaths: damagePhotoPaths ?? this.damagePhotoPaths,
      pendingSync: pendingSync ?? this.pendingSync,
    );
  }
}
