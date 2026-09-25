class LocationModel {
  final double lat;
  final double lon;
  final double accuracy; // metres
  final String? rangeName;

  /// true = the point is inside [rangeName]'s boundary;
  /// false = outside every range and [rangeName] is only the nearest one.
  final bool insideRange;

  /// Distance to the nearest range boundary in km (0 when inside).
  final double distanceKm;
  final DateTime timestamp;

  /// True when the fix is simulated (no GPS permission / emulator).
  final bool simulated;

  const LocationModel({
    required this.lat,
    required this.lon,
    required this.accuracy,
    required this.timestamp,
    this.rangeName,
    this.insideRange = false,
    this.distanceKm = 0,
    this.simulated = false,
  });

  /// Long label: "Madukkarai Range" or "Outside ranges · nearest: X (12.3 km)".
  String get rangeLabel {
    if (rangeName == null) return 'Unknown range';
    if (insideRange) return '$rangeName Range';
    return 'Outside ranges · nearest: $rangeName (${distanceKm.toStringAsFixed(1)} km)';
  }

  /// Short label for map chips.
  String get rangeShort {
    if (rangeName == null) return 'Unknown range';
    return insideRange ? '$rangeName Range' : 'Outside · nearest $rangeName';
  }
}
