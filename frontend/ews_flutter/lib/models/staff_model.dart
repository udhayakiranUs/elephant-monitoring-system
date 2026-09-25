enum StaffStatus {
  field('Field'),
  hq('HQ'),
  standby('Standby'),
  offDuty('Off Duty');

  const StaffStatus(this.label);
  final String label;
}

class StaffModel {
  final String id;
  final String name;
  final String assignment; // range name or "HQ Command"
  final StaffStatus status;

  const StaffModel({
    required this.id,
    required this.name,
    required this.assignment,
    required this.status,
  });

  /// Field + HQ staff count as deployed.
  bool get deployed => status == StaffStatus.field || status == StaffStatus.hq;

  factory StaffModel.fromJson(Map<String, dynamic> j) => StaffModel(
        id: '${j['id']}',
        name: j['name'] as String? ?? '',
        assignment: j['assignment'] as String? ?? '',
        status: StaffStatus.values.firstWhere(
          (s) => s.name == j['status'],
          orElse: () => StaffStatus.standby,
        ),
      );
}
