import '../../models/alert_model.dart';
import '../../models/elephant_model.dart';
import '../../models/range_model.dart';
import '../../models/report_model.dart';
import '../../models/staff_model.dart';
import '../../models/user_model.dart';

/// In-memory seed data used while ApiConstants.useMock is true.
class MockData {
  MockData._();

  static DateTime _today(int h, int m) {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day, h, m);
  }

  // ── Demo accounts ─────────────────────────────────────────────
  static const String demoPassword = 'ews123';

  static const Map<String, UserModel> users = {
    'murugan': UserModel(
      id: 'U-101',
      name: 'RFO Murugan',
      designation: 'Range Forest Officer',
      range: 'Mettupalayam',
      phone: '+91 98765 43210',
      role: UserRole.field,
    ),
    'vel': UserModel(
      id: 'U-201',
      name: 'Vel Kumar',
      designation: 'HQ Command Officer',
      range: 'Division HQ',
      phone: '+91 98765 01234',
      role: UserRole.command,
    ),
  };

  // ── Simulated GPS fixes (used when the device has no GPS) ─────
  static const List<({double lat, double lon, String range, double acc})> gpsFixes = [
    (lat: 11.0168, lon: 76.9558, range: 'Mettupalayam', acc: 4),
    (lat: 11.0610, lon: 76.9840, range: 'Sirumugai', acc: 6),
    (lat: 10.9254, lon: 76.9553, range: 'Coimbatore', acc: 3),
    (lat: 11.2588, lon: 76.9567, range: 'Karamadai', acc: 5),
    (lat: 10.9616, lon: 77.0072, range: 'Periyanaickenpalayam', acc: 4),
  ];

  // ── Alerts ────────────────────────────────────────────────────
  static List<AlertModel> alerts() => [
        AlertModel(
          id: 'AL-001',
          type: AlertType.danger,
          title: 'EMERGENCY — Mettupalayam Range',
          range: 'Mettupalayam',
          elephants: 16,
          threat: ThreatLevel.high,
          officer: 'RFO Murugan',
          gps: '11.0168°N 76.9558°E',
          damage: 'Crop damage reported',
          sentTo: 'All 24 staff · HQ activated · Control room',
          message: '3 Lone Males + Female+Calf at NH-209. Team deployed.',
          time: _today(14, 32),
        ),
        AlertModel(
          id: 'AL-002',
          type: AlertType.warn,
          title: 'MOVEMENT — Coimbatore Range',
          range: 'Coimbatore',
          elephants: 5,
          threat: ThreatLevel.medium,
          officer: 'Beat Officer Karthik',
          gps: '10.9254°N 76.9553°E',
          damage: 'Sugarcane crop damage',
          sentTo: '18 sector staff notified',
          message: '5 male group in sugarcane field. Chase ongoing.',
          time: _today(11, 15),
        ),
        AlertModel(
          id: 'AL-003',
          type: AlertType.info,
          title: 'SIGHTING — Sirumugai Range',
          range: 'Sirumugai',
          elephants: 7,
          threat: ThreatLevel.medium,
          officer: 'Forest Guard Selvam',
          gps: '11.0610°N 76.9840°E',
          damage: 'No damage',
          sentTo: 'Sirumugai team + HQ',
          message: '7 elephants toward village periphery.',
          time: _today(8, 40),
        ),
        AlertModel(
          id: 'AL-004',
          type: AlertType.ok,
          title: 'RESOLVED — Karamadai Range',
          range: 'Karamadai',
          elephants: 4,
          threat: ThreatLevel.low,
          officer: 'Watcher Babu',
          gps: '11.2588°N 76.9567°E',
          damage: 'No damage',
          sentTo: 'Karamadai team + HQ',
          message: '4 lone males chased back successfully.',
          time: _today(6, 20),
          resolved: true,
        ),
      ];

  // ── Reports ("My Reports") ────────────────────────────────────
  static List<ReportModel> reports() => [
        ReportModel(
          id: 'RP-001',
          range: 'Mettupalayam',
          beat: 'Beat 3 – Kovai Road',
          lat: 11.0168,
          lon: 76.9558,
          locationDescription: 'NH-209, village boundary',
          dateTime: _today(14, 32),
          officer: 'RFO Murugan',
          designation: 'Range Forest Officer',
          team: 'Anbu, Babu',
          counts: ElephantCounts({
            ElephantType.loneMale: 3,
            ElephantType.femaleCalf: 13,
          }),
          damage: true,
          damageType: 'Crop Damage',
          damageDescription: 'Banana plantation trampled',
          chaseStart: '14:45',
          chaseResult: 'All chased back successfully',
          remarks: '3 lone males + female+calf at NH-209',
        ),
        ReportModel(
          id: 'RP-002',
          range: 'Coimbatore',
          beat: 'Beat 1',
          lat: 10.9254,
          lon: 76.9553,
          locationDescription: 'Sugarcane fields, east boundary',
          dateTime: _today(11, 15),
          officer: 'Beat Officer Karthik',
          designation: 'Beat Forest Officer',
          team: 'Prakash',
          counts: ElephantCounts({ElephantType.maleGroup: 5}),
          damage: true,
          damageType: 'Crop Damage',
          damageDescription: 'Sugarcane crop eaten',
          chaseStart: '11:30',
          chaseResult: 'Partially — 1 remaining',
          remarks: '5 male group in sugarcane field',
        ),
        ReportModel(
          id: 'RP-003',
          range: 'Sirumugai',
          beat: 'Beat 5',
          lat: 11.0610,
          lon: 76.9840,
          locationDescription: 'Village periphery',
          dateTime: _today(8, 40),
          officer: 'Forest Guard Selvam',
          designation: 'Forest Guard',
          team: '',
          counts: ElephantCounts({
            ElephantType.femaleGroup: 4,
            ElephantType.femaleCalf: 3,
          }),
          damage: false,
          damageType: '',
          damageDescription: '',
          chaseStart: '',
          chaseResult: 'Not attempted (dark/danger)',
          remarks: 'Moving toward village',
        ),
        ReportModel(
          id: 'RP-004',
          range: 'Karamadai',
          beat: 'Beat 2',
          lat: 11.2588,
          lon: 76.9567,
          locationDescription: 'Near plantation',
          dateTime: _today(6, 20),
          officer: 'Watcher Babu',
          designation: 'Watcher',
          team: 'Anbu',
          counts: ElephantCounts({ElephantType.loneMale: 4}),
          damage: false,
          damageType: '',
          damageDescription: '',
          chaseStart: '06:30',
          chaseResult: 'All chased back successfully',
          remarks: 'Lone males near plantation',
        ),
      ];

  // ── Ranges (today) ────────────────────────────────────────────
  static const List<RangeModel> ranges = [
    RangeModel(name: 'Coimbatore', today: 18, totalElephants: 4654, totalIncidents: 2012, status: RangeStatus.alert, lastReport: '14:30'),
    RangeModel(name: 'Mettupalayam', today: 12, totalElephants: 3964, totalIncidents: 2289, status: RangeStatus.alert, lastReport: '14:32'),
    RangeModel(name: 'Sirumugai', today: 7, totalElephants: 2590, totalIncidents: 1565, status: RangeStatus.active, lastReport: '08:40'),
    RangeModel(name: 'Periyanaickenpalayam', today: 5, totalElephants: 4588, totalIncidents: 1600, status: RangeStatus.active, lastReport: '07:15'),
    RangeModel(name: 'Karamadai', today: 5, totalElephants: 1279, totalIncidents: 659, status: RangeStatus.clear, lastReport: '06:20'),
    RangeModel(name: 'Madukkarai', today: 0, totalElephants: 828, totalIncidents: 449, status: RangeStatus.clear, lastReport: '04:00'),
    RangeModel(name: 'Bolampatty', today: 0, totalElephants: 2170, totalIncidents: 1349, status: RangeStatus.clear, lastReport: '22:10 yday'),
  ];

  // ── Staff: 24 total = 16 field + 2 HQ + 4 standby + 2 off duty ─
  static const List<StaffModel> staff = [
    StaffModel(id: 'S01', name: 'RFO Murugan', assignment: 'Mettupalayam', status: StaffStatus.field),
    StaffModel(id: 'S02', name: 'Karthik P', assignment: 'Coimbatore', status: StaffStatus.field),
    StaffModel(id: 'S03', name: 'Selvam V', assignment: 'Sirumugai', status: StaffStatus.field),
    StaffModel(id: 'S04', name: 'Anbu R', assignment: 'Karamadai', status: StaffStatus.field),
    StaffModel(id: 'S05', name: 'Vel Kumar', assignment: 'HQ Command', status: StaffStatus.hq),
    StaffModel(id: 'S06', name: 'Ponraj S', assignment: 'Control Room', status: StaffStatus.hq),
    StaffModel(id: 'S07', name: 'Babu K', assignment: 'Karamadai', status: StaffStatus.field),
    StaffModel(id: 'S08', name: 'Ravi M', assignment: 'Periyanaickenpalayam', status: StaffStatus.field),
    StaffModel(id: 'S09', name: 'Suresh T', assignment: 'Periyanaickenpalayam', status: StaffStatus.field),
    StaffModel(id: 'S10', name: 'Dinesh G', assignment: 'Madukkarai', status: StaffStatus.field),
    StaffModel(id: 'S11', name: 'Kumar S', assignment: 'Bolampatty', status: StaffStatus.field),
    StaffModel(id: 'S12', name: 'Manoj R', assignment: 'Mettupalayam', status: StaffStatus.field),
    StaffModel(id: 'S13', name: 'Prakash L', assignment: 'Coimbatore', status: StaffStatus.field),
    StaffModel(id: 'S14', name: 'Senthil N', assignment: 'Sirumugai', status: StaffStatus.field),
    StaffModel(id: 'S15', name: 'Arun V', assignment: 'Coimbatore', status: StaffStatus.field),
    StaffModel(id: 'S16', name: 'Gopal D', assignment: 'Mettupalayam', status: StaffStatus.field),
    StaffModel(id: 'S17', name: 'Hari B', assignment: 'Sirumugai', status: StaffStatus.field),
    StaffModel(id: 'S18', name: 'Saravanan P', assignment: 'Periyanaickenpalayam', status: StaffStatus.field),
    StaffModel(id: 'S19', name: 'Ilango C', assignment: 'Madukkarai', status: StaffStatus.standby),
    StaffModel(id: 'S20', name: 'Mohan J', assignment: 'Bolampatty', status: StaffStatus.standby),
    StaffModel(id: 'S21', name: 'Rajesh A', assignment: 'Karamadai', status: StaffStatus.standby),
    StaffModel(id: 'S22', name: 'Vijay K', assignment: 'Coimbatore', status: StaffStatus.standby),
    StaffModel(id: 'S23', name: 'Nagaraj E', assignment: 'Sirumugai', status: StaffStatus.offDuty),
    StaffModel(id: 'S24', name: 'Balu T', assignment: 'Mettupalayam', status: StaffStatus.offDuty),
  ];
}
