import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../core/constants/api_constants.dart';
import '../core/constants/mock_data.dart';
import '../database/local_database.dart';
import '../models/alert_model.dart';
import '../models/range_model.dart';
import '../models/report_model.dart';
import '../models/staff_model.dart';
import '../models/user_model.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String message;
  ApiException(this.message, [this.statusCode]);
  @override
  String toString() => message;
}

/// Data gateway + in-memory cache. Talks to the FastAPI backend, or serves
/// mock data when [ApiConstants.useMock] is true. Failed writes go to the
/// offline queue ([LocalDatabase]) and are retried by SyncService.
///
/// Offline queue item kinds:
///   'alert'  - an alert to POST
///   'report' - a report to POST (may carry photos under [_photosKey])
///   'photos' - photos still to upload for an already-synced report
class ApiService extends ChangeNotifier {
  ApiService(this._db);

  /// Key used inside a queued payload to carry base64-encoded photos.
  static const _photosKey = '_photos';

  final LocalDatabase _db;
  String? _token;

  List<AlertModel> alerts = [];
  List<ReportModel> reports = [];
  List<StaffModel> staff = [];
  List<RangeModel> ranges = [];

  bool loading = false;
  int pendingCount = 0;
  bool _loadedOnce = false;

  void setToken(String? token) => _token = token;

  // ── derived values ──────────────────────────────────────────
  List<AlertModel> get activeAlerts =>
      alerts.where((a) => !a.resolved).toList();
  int get elephantsOutToday => ranges.fold(0, (s, r) => s + r.today);
  int get activeRangeCount => ranges.where((r) => r.today > 0).length;
  int get deployedStaff => staff.where((s) => s.deployed).length;
  int get standbyStaff =>
      staff.where((s) => s.status == StaffStatus.standby).length;
  int get offDutyStaff =>
      staff.where((s) => s.status == StaffStatus.offDuty).length;

  // ── auth ────────────────────────────────────────────────────
  Future<({UserModel user, String token})> login(
      String username, String password) async {
    if (ApiConstants.useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      final user = MockData.users[username.trim().toLowerCase()];
      if (user == null || password != MockData.demoPassword) {
        throw ApiException('Invalid username or password', 401);
      }
      return (user: user, token: 'mock-token-${user.id}');
    }
    final data = await _send('POST', ApiConstants.login, {
      'username': username,
      'password': password,
    }) as Map<String, dynamic>;
    return (
      user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
      token: data['access_token'] as String,
    );
  }

  // ── loading ─────────────────────────────────────────────────
  Future<void> loadAll({bool force = false}) async {
    if (_loadedOnce && !force) return;
    loading = true;
    notifyListeners();
    try {
      if (ApiConstants.useMock) {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        if (!_loadedOnce) {
          alerts = MockData.alerts();
          reports = MockData.reports();
          staff = List.of(MockData.staff);
          ranges = List.of(MockData.ranges);
        }
      } else {
        final a = await _send('GET', ApiConstants.alerts) as List;
        final r = await _send('GET', ApiConstants.reports) as List;
        final s = await _send('GET', ApiConstants.staff) as List;
        final g = await _send('GET', ApiConstants.ranges) as List;
        alerts = a
            .map((e) => AlertModel.fromJson(e as Map<String, dynamic>))
            .toList();
        reports = r
            .map((e) => ReportModel.fromJson(e as Map<String, dynamic>))
            .toList();
        staff = s
            .map((e) => StaffModel.fromJson(e as Map<String, dynamic>))
            .toList();
        ranges = g
            .map((e) => RangeModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      _loadedOnce = true;
    } catch (e) {
      debugPrint('loadAll failed: $e');
    }
    pendingCount = await _db.pendingCount();
    loading = false;
    notifyListeners();
  }

  // ── my reports ────────────────────────────────────────────────
  Future<List<ReportModel>> loadMyReports() async {
    if (ApiConstants.useMock) {
      return reports;
    }

    try {
      final data = await _send(
        'GET',
        '${ApiConstants.reports}/mine',
      ) as List;

      return data
          .map(
            (e) => ReportModel.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('loadMyReports failed: $e');
      return [];
    }
  }

  // ── alerts ──────────────────────────────────────────────────
  Future<AlertModel> raiseAlert(AlertModel alert) async {
    var result = alert;
    try {
      await _send('POST', ApiConstants.alerts, alert.toJson());
    } catch (_) {
      await _db.enqueue('alert', alert.toJson());
      result = alert.copyWith(pendingSync: true);
    }
    alerts.insert(0, result);
    // Bump the range's live counters.
    final i = ranges.indexWhere((r) => r.name == alert.range);
    if (i >= 0) {
      final r = ranges[i];
      ranges[i] = RangeModel(
        name: r.name,
        today: r.today + alert.elephants,
        totalElephants: r.totalElephants + alert.elephants,
        totalIncidents: r.totalIncidents + 1,
        status: alert.threat == ThreatLevel.high
            ? RangeStatus.alert
            : RangeStatus.active,
        lastReport: '${alert.time.hour.toString().padLeft(2, '0')}:'
            '${alert.time.minute.toString().padLeft(2, '0')}',
      );
    }
    pendingCount = await _db.pendingCount();
    notifyListeners();
    return result;
  }

  Future<void> resolveAlert(String id) async {
    final i = alerts.indexWhere((a) => a.id == id);
    if (i < 0) return;
    alerts[i] = alerts[i].copyWith(resolved: true, type: AlertType.ok);
    notifyListeners();
    try {
      await _send('PATCH', '${ApiConstants.alerts}/$id/resolve');
    } catch (e) {
      debugPrint('resolveAlert sync failed: $e');
    }
  }

  // ── range borders ───────────────────────────────────────────
  /// Best-effort push of an HQ-edited border. Always saved locally first
  /// (MapService); the backend copy lets other devices pick it up.
  Future<void> saveRangeBoundary(String range, List<LatLng> points) async {
    try {
      await _send('PUT', '${ApiConstants.ranges}/$range/boundary', {
        'points': [
          for (final p in points) [p.latitude, p.longitude]
        ],
      });
    } catch (e) {
      debugPrint('saveRangeBoundary failed (kept locally): $e');
    }
  }

  // ── reports ─────────────────────────────────────────────────
  /// Creates the report, then uploads photos as a separate step.
  ///
  /// - Failed CREATE  -> report (and its photos) are queued offline.
  /// - Failed PHOTOS  -> photos are queued for a later retry; the report
  ///   is NOT re-created and is NOT marked "saved offline".
  Future<ReportModel> submitReport(
    ReportModel report, {
    List<XFile> photos = const [],
  }) async {
    var result = report;
    var created = false;

    // Step 1: create the report on the server.
    try {
      final data = await _send(
        'POST',
        ApiConstants.reports,
        report.toJson(),
      );
      created = true;

      // _send returns decoded JSON (a Map), not a ReportModel, so it must
      // be parsed. Fall back to the local report if parsing fails.
      if (data is Map<String, dynamic>) {
        try {
          result = ReportModel.fromJson(data);
        } catch (e) {
          debugPrint('submitReport: could not parse server response: $e');
          result = report;
        }
      }
    } catch (e) {
      debugPrint('submitReport: create failed, queued offline: $e');
      await _enqueueReport(report, photos);
      result = report.copyWith(
        pendingSync: true,
      );
    }

    // Step 2: upload photos (only if the report now exists on the server).
    if (created && photos.isNotEmpty) {
      try {
        result = await uploadReportPhotos(result, photos);
      } catch (e) {
        debugPrint('submitReport: photo upload failed, queued for retry: $e');
        await _enqueuePhotos(result.id, photos);
      }
    }

    reports.insert(0, result);
    pendingCount = await _db.pendingCount();
    notifyListeners();

    return result;
  }

  Future<ReportModel> uploadReportPhotos(
    ReportModel report,
    List<XFile> photos,
  ) async {
    final data = await _postPhotos(report.id, photos);

    // The upload itself succeeded. If the response is not a full report,
    // keep the current report instead of treating it as a failure.
    if (data is Map<String, dynamic>) {
      try {
        return ReportModel.fromJson(data);
      } catch (e) {
        debugPrint('uploadReportPhotos: could not parse response: $e');
      }
    }
    return report;
  }

  /// Uploads [photos] for [reportId]. Returns the decoded response body
  /// (or null). Throws [ApiException] on a non-2xx response.
  Future<dynamic> _postPhotos(String reportId, List<XFile> photos) async {
    if (photos.isEmpty || ApiConstants.useMock) {
      return null;
    }

    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.reports}/$reportId/photos',
    );

    final request = http.MultipartRequest('POST', uri);

    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }

    for (final xFile in photos) {
      final bytes = await xFile.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'files',
          bytes,
          filename: xFile.name,
        ),
      );
    }

    // Photos are large, so allow much longer than a normal JSON call,
    // but never hang forever (a hung upload would block the sync queue).
    final streamedResponse =
        await request.send().timeout(ApiConstants.timeout * 4);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        'Photo upload failed (${response.statusCode}): ${response.body}',
        response.statusCode,
      );
    }

    if (response.body.isEmpty) return null;
    try {
      return jsonDecode(response.body);
    } catch (e) {
      debugPrint('_postPhotos: response was not JSON: $e');
      return null;
    }
  }

  // ── offline queue: photo helpers ────────────────────────────
  /// Photos are stored as base64 inside the queued payload. On Flutter Web
  /// XFile.path is a temporary blob URL that does not survive a reload, so
  /// the bytes themselves must be saved.
  Future<List<Map<String, String>>> _encodePhotos(List<XFile> photos) async {
    final out = <Map<String, String>>[];
    for (final p in photos) {
      out.add({
        'name': p.name,
        'data': base64Encode(await p.readAsBytes()),
      });
    }
    return out;
  }

  List<XFile> _decodePhotos(dynamic raw) {
    final out = <XFile>[];
    if (raw is List) {
      for (final p in raw) {
        try {
          out.add(
            XFile.fromData(
              base64Decode(p['data'] as String),
              name: p['name'] as String?,
            ),
          );
        } catch (e) {
          debugPrint('_decodePhotos: skipped a bad photo entry: $e');
        }
      }
    }
    return out;
  }

  Future<void> _enqueueReport(ReportModel report, List<XFile> photos) async {
    final payload = report.toJson();

    if (photos.isNotEmpty) {
      try {
        await _db.enqueue('report', {
          ...payload,
          _photosKey: await _encodePhotos(photos),
        });
        return;
      } catch (e) {
        // e.g. storage quota exceeded - still keep the report itself.
        debugPrint('_enqueueReport: could not queue with photos: $e');
      }
    }

    await _db.enqueue('report', payload);
  }

  Future<void> _enqueuePhotos(String reportId, List<XFile> photos) async {
    try {
      await _db.enqueue('photos', {
        'id': reportId,
        _photosKey: await _encodePhotos(photos),
      });
    } catch (e) {
      debugPrint('_enqueuePhotos: could not queue photos: $e');
    }
  }

  // ── offline queue ───────────────────────────────────────────
  /// Sends a queued create request. A 409 means the server already has it
  /// (e.g. the earlier response was lost), so that counts as success.
  Future<void> _sendCreate(String path, Map<String, dynamic> payload) async {
    try {
      await _send('POST', path, payload);
    } on ApiException catch (e) {
      if (e.statusCode == 409) return;
      rethrow;
    }
  }

  /// Pushes queued items. Returns how many alerts/reports were synced.
  Future<int> flushPending() async {
    final items = await _db.pending();
    var synced = 0;

    for (final item in items) {
      final payload = Map<String, dynamic>.from(item.payload as Map);
      final id = '${payload['id']}';
      final photos = _decodePhotos(payload.remove(_photosKey));

      switch (item.kind) {
        case 'photos':
          {
            // Photos for a report that already exists on the server.
            // A failure here must not block the rest of the queue.
            try {
              await _postPhotos(id, photos);
              await _db.remove(item.id);
            } on ApiException catch (e) {
              if (e.statusCode == 404) {
                // Report no longer exists - retrying would never succeed.
                debugPrint('flushPending: report $id gone, dropping photos');
                await _db.remove(item.id);
              } else {
                debugPrint('flushPending: photo retry failed for $id: $e');
              }
            } catch (e) {
              debugPrint('flushPending: photo retry failed for $id: $e');
            }
          }

        case 'alert':
          {
            await _sendCreate(ApiConstants.alerts, payload); // throws -> caller
            await _db.remove(item.id);
            final i = alerts.indexWhere((a) => a.id == id);
            if (i >= 0) alerts[i] = alerts[i].copyWith(pendingSync: false);
            synced++;
          }

        default: // 'report'
          {
            await _sendCreate(
                ApiConstants.reports, payload); // throws -> caller
            if (photos.isNotEmpty) {
              try {
                await _postPhotos(id, photos);
              } catch (e) {
                debugPrint('flushPending: photo upload failed, re-queued: $e');
                await _enqueuePhotos(id, photos);
              }
            }
            await _db.remove(item.id);
            final i = reports.indexWhere((r) => r.id == id);
            if (i >= 0) reports[i] = reports[i].copyWith(pendingSync: false);
            synced++;
          }
      }
    }

    pendingCount = await _db.pendingCount();
    notifyListeners();
    return synced;
  }

  // ── http core ───────────────────────────────────────────────
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<dynamic> _send(String method, String path, [Object? body]) async {
    if (ApiConstants.useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      return null;
    }
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');
    final encoded = body == null ? null : jsonEncode(body);
    final http.Response res;
    switch (method) {
      case 'GET':
        res = await http
            .get(uri, headers: _headers)
            .timeout(ApiConstants.timeout);
      case 'POST':
        res = await http
            .post(uri, headers: _headers, body: encoded)
            .timeout(ApiConstants.timeout);
      case 'PUT':
        res = await http
            .put(uri, headers: _headers, body: encoded)
            .timeout(ApiConstants.timeout);
      case 'PATCH':
        res = await http
            .patch(uri, headers: _headers, body: encoded)
            .timeout(ApiConstants.timeout);
      default:
        throw ApiException('Unsupported method $method');
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(
        res.statusCode == 401
            ? 'Invalid username or password'
            : 'Server error (${res.statusCode})',
        res.statusCode,
      );
    }
    return res.body.isEmpty ? null : jsonDecode(res.body);
  }
}
