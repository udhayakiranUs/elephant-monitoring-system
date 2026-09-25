/// Central place for backend + map configuration.
class ApiConstants {
  ApiConstants._();

  /// While the FastAPI backend is not built, the app runs on in-memory mock
  /// data. Flip to `false` once the backend is running.
  static const bool useMock = false;

  /// Android emulator -> host machine. Use your LAN IP on a physical device.
  static const String baseUrl = 'http://192.168.1.12:8000/api/v1';

  /// Host root without the `/api/v1` suffix — used to resolve relative
  /// photo paths like `/uploads/xyz.jpeg` returned by the backend.
  static String get hostUrl {
    const marker = '/api/v1';
    final idx = baseUrl.indexOf(marker);
    return idx == -1 ? baseUrl : baseUrl.substring(0, idx);
  }

  static const Duration timeout = Duration(seconds: 15);

  // Endpoints (mirror backend/app/routes/*)
  static const String login = '/auth/login';
  static const String users = '/users';
  static const String alerts = '/alerts';
  static const String reports = '/reports';
  static const String elephants = '/elephants';
  static const String staff = '/staff';
  static const String ranges = '/ranges';
  static const String analytics = '/analytics';

  // Map
  static const String tileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String userAgentPackage = 'com.ews.ews_flutter';
  static const double defaultLat = 11.18;
  static const double defaultLon = 76.88;
}
