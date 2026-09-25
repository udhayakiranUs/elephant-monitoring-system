import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text.dart';
import '../../core/utils/helpers.dart';
import '../../models/alert_model.dart';
import '../../models/elephant_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/gps_service.dart';
import '../../services/map_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/elephant_counter.dart';
import '../../widgets/gps_status.dart';
import '../../widgets/threat_level_selector.dart';

/// One-tap emergency broadcast: GPS + elephant count + threat level.
class RaiseAlertScreen extends StatefulWidget {
  const RaiseAlertScreen({super.key});

  @override
  State<RaiseAlertScreen> createState() => _RaiseAlertScreenState();
}

class _RaiseAlertScreenState extends State<RaiseAlertScreen> {
  ElephantCounts _counts = ElephantCounts();
  ThreatLevel _threat = ThreatLevel.high;
  bool _sending = false;
  bool _showBanner = false;
  String _bannerText = 'All staff notified. HQ activated.';

  Future<void> _broadcast() async {
    final notify = context.read<NotificationService>();
    final loc = context.read<GpsService>().current;

    if (_counts.total == 0) {
      notify.show(ToastType.warn, 'Add Count', 'Enter at least 1 elephant', icon: '⚠️');
      return;
    }
    if (loc == null) {
      notify.show(ToastType.warn, 'No GPS fix', 'Tap Refresh to get your location', icon: '📍');
      return;
    }

    final api = context.read<ApiService>();
    final user = context.read<AuthService>().user;
    final range = loc.rangeName ?? 'Unknown';
    final total = _counts.total;
    // Outside every range boundary: still tag the nearest range so HQ can
    // route the alert, but say so explicitly.
    final outsideNote = loc.insideRange
        ? ''
        : ' (outside range boundary, nearest: $range, ${loc.distanceKm.toStringAsFixed(1)} km)';

    final (type, prefix) = switch (_threat) {
      ThreatLevel.high => (AlertType.danger, 'EMERGENCY'),
      ThreatLevel.medium => (AlertType.warn, 'MOVEMENT'),
      ThreatLevel.low => (AlertType.info, 'SIGHTING'),
    };

    setState(() => _sending = true);
    final res = await api.raiseAlert(AlertModel(
      id: 'AL-${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      title: loc.insideRange ? '$prefix — $range Range' : '$prefix — near $range Range',
      range: range,
      elephants: total,
      threat: _threat,
      officer: user?.name ?? 'Field Officer',
      gps: Helpers.coordsShort(loc.lat, loc.lon),
      damage: 'Pending',
      sentTo: 'All 24 staff notified',
      message: '${_counts.summary}. GPS: ${Helpers.coordsShort(loc.lat, loc.lon)}$outsideNote',
      time: DateTime.now(),
    ));
    if (!mounted) return;

    setState(() {
      _sending = false;
      _showBanner = true;
      _bannerText = res.pendingSync
          ? 'No network — alert saved and will send automatically.'
          : 'All staff notified. HQ activated.';
    });

    if (res.pendingSync) {
      notify.show(ToastType.warn, 'Alert queued', 'Offline — will be sent when network returns',
          icon: '📡');
      return;
    }
    notify.show(ToastType.danger, '🚨 ALERT BROADCAST',
        'All 24 staff notified: $total elephants at $range',
        icon: '🚨');
    Future.delayed(const Duration(milliseconds: 1200), () => notify.show(
        ToastType.danger, '📲 SMS Sent', 'Field staff & HQ received emergency alert',
        icon: '📲'));
    Future.delayed(const Duration(milliseconds: 2400),
        () => notify.show(ToastType.ok, 'HQ Confirmed', 'Command Centre activated', icon: '🖥'));
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<GpsService>().current;
    final maps = context.watch<MapService>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_showBanner)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                AppColors.red.withValues(alpha: .18),
                AppColors.red.withValues(alpha: .04),
              ]),
              border: Border.all(color: AppColors.red2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              const Text('🚨', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('ALERT BROADCAST SENT',
                      style: AppText.heading(size: 14, weight: FontWeight.w600, color: AppColors.red)),
                  Text(_bannerText, style: AppText.body(size: 11)),
                ]),
              ),
              TextButton(
                onPressed: () => setState(() => _showBanner = false),
                child: Text('Dismiss', style: AppText.body(size: 11, color: AppColors.red)),
              ),
            ]),
          ),
        SectionCard(
          title: '📍 Live GPS Location',
          child: Column(children: [
            const GpsStatus(),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 200,
                decoration: BoxDecoration(border: Border.all(color: AppColors.border2)),
                child: loc == null
                    ? const Center(child: CircularProgressIndicator(color: AppColors.green))
                    : Stack(children: [
                        FlutterMap(
                          key: ValueKey('${loc.lat}_${loc.lon}'),
                          options: MapOptions(
                            initialCenter: LatLng(loc.lat, loc.lon),
                            initialZoom: 12.5,
                            interactionOptions: const InteractionOptions(
                              flags: InteractiveFlag.pinchZoom | InteractiveFlag.doubleTapZoom,
                            ),
                          ),
                          children: [
                            MapService.tileLayer(),
                            PolygonLayer(
                              polygons: maps.polygons(
                                colorOf: (_) => AppColors.green,
                                fillOpacity: .07,
                                borderWidth: 1.5,
                              ),
                            ),
                            MarkerLayer(markers: [
                              Marker(
                                point: LatLng(loc.lat, loc.lon),
                                width: 20,
                                height: 20,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.red,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 3),
                                    boxShadow: [
                                      BoxShadow(color: AppColors.red.withValues(alpha: .8), blurRadius: 8),
                                    ],
                                  ),
                                ),
                              ),
                            ]),
                          ],
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.bg2.withValues(alpha: .85),
                              border: Border.all(color: AppColors.green3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(loc.rangeShort,
                                style: AppText.body(
                                    size: 11,
                                    color: loc.insideRange ? AppColors.green : AppColors.amber)),
                          ),
                        ),
                      ]),
              ),
            ),
          ]),
        ),
        SectionCard(
          title: '🐘 Elephant Count',
          child: ElephantCounterGrid(
            counts: _counts,
            onChanged: (t, d) => setState(() => _counts = _counts.change(t, d)),
          ),
        ),
        SectionCard(
          title: '⚠️ Threat Level',
          child: ThreatLevelSelector(
            value: _threat,
            onChanged: (t) => setState(() => _threat = t),
          ),
        ),
        ElevatedButton(
          onPressed: _sending ? null : _broadcast,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.red,
            foregroundColor: Colors.white,
            elevation: 8,
            shadowColor: AppColors.red.withValues(alpha: .5),
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: _sending
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text('🚨 BROADCAST ALERT TO ALL 24 STAFF',
                  style: AppText.heading(size: 16, color: Colors.white, letterSpacing: 1)),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text('Sent to field staff, HQ command centre & control room instantly',
              textAlign: TextAlign.center,
              style: AppText.body(size: 11, color: AppColors.text3)),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
