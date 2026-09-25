import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_text.dart';
import '../core/utils/helpers.dart';
import '../services/gps_service.dart';

/// Pulsing GPS box with live coordinates + refresh button.
class GpsStatus extends StatefulWidget {
  const GpsStatus({super.key});

  @override
  State<GpsStatus> createState() => _GpsStatusState();
}

class _GpsStatusState extends State<GpsStatus> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gps = context.watch<GpsService>();
    final loc = gps.current;
    final coords = loc == null ? 'Acquiring GPS…' : Helpers.coords(loc.lat, loc.lon);
    final sub = loc == null
        ? 'Waiting for location fix'
        : 'Accuracy: ±${loc.accuracy.round()}m · ${loc.rangeLabel}'
            '${loc.simulated ? ' · simulated' : ''}';
    final outside = loc != null && !loc.insideRange;
    final dotColor = loc == null
        ? AppColors.amber
        : (loc.simulated ? AppColors.amber : AppColors.green);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        border: Border.all(color: AppColors.border2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) => Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: dotColor, blurRadius: 4 + 10 * _pulse.value),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(coords, style: AppText.heading(size: 14, weight: FontWeight.w500)),
                const SizedBox(height: 1),
                Text(sub,
                    style: AppText.body(
                        size: 11, color: outside ? AppColors.amber : AppColors.text3)),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: gps.loading ? null : () => gps.refresh(),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.green,
              backgroundColor: AppColors.green3,
              side: const BorderSide(color: AppColors.green2),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: const Size(0, 32),
              textStyle: AppText.body(size: 11),
            ),
            icon: gps.loading
                ? const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.green))
                : const Icon(Icons.refresh, size: 14),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}
