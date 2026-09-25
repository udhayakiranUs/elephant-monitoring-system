import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_text.dart';
import '../core/utils/helpers.dart';
import '../models/alert_model.dart';
import 'dashboard_card.dart';

/// Alert tile. `compact` = live-feed row, otherwise the full detail card.
class AlertCard extends StatelessWidget {
  const AlertCard({
    super.key,
    required this.alert,
    this.compact = false,
    this.onResolve,
  });

  final AlertModel alert;
  final bool compact;
  final VoidCallback? onResolve;

  @override
  Widget build(BuildContext context) {
    final color = Helpers.alertColor(alert.type);
    return compact ? _compact(color) : _full(color);
  }

  Widget _compact(Color color) => AccentBox(
        color: color,
        stripe: 3,
        radius: 8,
        background: AppColors.bg2,
        margin: const EdgeInsets.only(bottom: 7),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(alert.icon, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 5),
              Expanded(
                child: Text(alert.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.heading(size: 13, weight: FontWeight.w600)),
              ),
              Text(Helpers.time(alert.time),
                  style: AppText.body(size: 10, color: AppColors.text3)),
            ]),
            const SizedBox(height: 3),
            Text(alert.message, style: AppText.body(size: 11, height: 1.3)),
          ],
        ),
      );

  Widget _full(Color color) {
    Widget field(String l, String v) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.bg2,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.toUpperCase(),
                  style: AppText.body(size: 9, color: AppColors.text3)),
              const SizedBox(height: 1),
              Text(v,
                  style: AppText.body(size: 12, color: AppColors.text, weight: FontWeight.w500)),
            ],
          ),
        );

    return AccentBox(
      color: color,
      margin: const EdgeInsets.only(bottom: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(alert.icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(alert.title, style: AppText.heading(size: 16, weight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(Helpers.relativeDay(alert.time),
                      style: AppText.body(size: 10, color: AppColors.text3)),
                ],
              ),
            ),
            if (alert.pendingSync)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Queued', style: AppText.body(size: 10, color: AppColors.amber)),
              ),
          ]),
          const SizedBox(height: 8),
          LayoutBuilder(builder: (context, c) {
            final w = (c.maxWidth - 6) / 2;
            return Wrap(spacing: 6, runSpacing: 6, children: [
              for (final f in [
                ('Range', alert.range),
                ('Elephants', '${alert.elephants}'),
                ('Threat', alert.threat.label),
                ('Officer', alert.officer),
                ('GPS', alert.gps),
                ('Damage', alert.damage),
              ])
                SizedBox(width: w, child: field(f.$1, f.$2)),
            ]);
          }),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: .06),
              border: Border.all(color: AppColors.green3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('📲 ${alert.sentTo}',
                style: AppText.body(size: 11, color: AppColors.text, weight: FontWeight.w500)),
          ),
          if (onResolve != null && !alert.resolved) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: onResolve,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.green,
                  side: const BorderSide(color: AppColors.green3),
                ),
                child: const Text('Mark Resolved'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
