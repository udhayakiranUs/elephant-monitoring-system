import 'dart:async';

import 'package:flutter/foundation.dart';

import 'api_service.dart';
import 'notification_service.dart';

/// Periodically pushes offline-queued alerts/reports to the server.
class SyncService extends ChangeNotifier {
  SyncService(this._api, this._notify);

  final ApiService _api;
  final NotificationService _notify;

  Timer? _timer;
  bool syncing = false;
  DateTime? lastSync;

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => syncNow(silent: true));
  }

  Future<int> syncNow({bool silent = false}) async {
    if (syncing) return 0;
    if (_api.pendingCount == 0 && silent) return 0;
    syncing = true;
    notifyListeners();
    var n = 0;
    try {
      n = await _api.flushPending();
      lastSync = DateTime.now();
      if (n > 0) {
        _notify.show(ToastType.ok, 'Sync complete', '$n queued item(s) sent to HQ', icon: '🔄');
      } else if (!silent) {
        _notify.show(ToastType.info, 'Up to date', 'Nothing waiting to sync', icon: '🔄');
      }
    } catch (_) {
      if (!silent) {
        _notify.show(ToastType.warn, 'Sync failed', 'Server unreachable — will retry', icon: '📡');
      }
    }
    syncing = false;
    notifyListeners();
    return n;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
