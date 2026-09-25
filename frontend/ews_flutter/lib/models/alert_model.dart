enum ThreatLevel {
  high('HIGH'),
  medium('MEDIUM'),
  low('LOW');

  const ThreatLevel(this.label);
  final String label;

  static ThreatLevel parse(String? v) => ThreatLevel.values.firstWhere(
        (t) => t.label == v?.toUpperCase(),
        orElse: () => ThreatLevel.medium,
      );
}

/// danger = emergency, warn = movement, info = sighting, ok = resolved.
enum AlertType { danger, warn, info, ok }

class AlertModel {
  final String id;
  final AlertType type;
  final String title;
  final String range;
  final int elephants;
  final ThreatLevel threat;
  final String officer;
  final String gps;
  final String damage;
  final String sentTo;
  final String message;
  final DateTime time;
  final bool resolved;

  /// True while the alert is only stored locally (offline queue).
  final bool pendingSync;

  const AlertModel({
    required this.id,
    required this.type,
    required this.title,
    required this.range,
    required this.elephants,
    required this.threat,
    required this.officer,
    required this.gps,
    required this.damage,
    required this.sentTo,
    required this.message,
    required this.time,
    this.resolved = false,
    this.pendingSync = false,
  });

  String get icon => switch (type) {
        AlertType.danger => '🚨',
        AlertType.warn => '⚠️',
        AlertType.info => '📍',
        AlertType.ok => '✅',
      };

  AlertModel copyWith({bool? resolved, bool? pendingSync, AlertType? type}) => AlertModel(
        id: id,
        type: type ?? this.type,
        title: title,
        range: range,
        elephants: elephants,
        threat: threat,
        officer: officer,
        gps: gps,
        damage: damage,
        sentTo: sentTo,
        message: message,
        time: time,
        resolved: resolved ?? this.resolved,
        pendingSync: pendingSync ?? this.pendingSync,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'range': range,
        'elephants': elephants,
        'threat': threat.label,
        'officer': officer,
        'gps': gps,
        'damage': damage,
        'sent_to': sentTo,
        'message': message,
        'time': time.toIso8601String(),
        'resolved': resolved,
      };

  factory AlertModel.fromJson(Map<String, dynamic> j) => AlertModel(
        id: '${j['id']}',
        type: AlertType.values.firstWhere(
          (t) => t.name == j['type'],
          orElse: () => AlertType.info,
        ),
        title: j['title'] as String? ?? '',
        range: j['range'] as String? ?? '',
        elephants: (j['elephants'] as num?)?.toInt() ?? 0,
        threat: ThreatLevel.parse(j['threat'] as String?),
        officer: j['officer'] as String? ?? '',
        gps: j['gps'] as String? ?? '',
        damage: j['damage'] as String? ?? '',
        sentTo: j['sent_to'] as String? ?? '',
        message: j['message'] as String? ?? '',
        time: DateTime.tryParse('${j['time']}') ?? DateTime.now(),
        resolved: j['resolved'] as bool? ?? false,
      );
}
