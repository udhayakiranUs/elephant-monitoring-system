import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_text.dart';
import '../core/utils/helpers.dart';
import '../models/report_model.dart';

class ReportCard extends StatelessWidget {
  const ReportCard({
    super.key,
    required this.report,
    this.onTap,
  });

  final ReportModel report;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Widget tag(
      String text, {
      Color? bg,
      Color? fg,
    }) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 3,
        ),
        decoration: BoxDecoration(
          color: bg ?? Colors.white.withValues(alpha: .05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: AppText.body(
            size: 10,
            color: fg ?? AppColors.text2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.card,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  constraints: const BoxConstraints(minHeight: 55),
                  decoration: BoxDecoration(
                    color: Helpers.threatColor(report.severity),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📍 ${report.range}',
                        style: AppText.heading(
                          size: 14,
                          weight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          tag(
                            '🕐 ${Helpers.dateTime(report.dateTime)}',
                            bg: AppColors.blue.withValues(alpha: .1),
                            fg: AppColors.blue,
                          ),
                          tag(
                            '👤 ${report.officer}',
                            bg: AppColors.green.withValues(alpha: .1),
                            fg: AppColors.green,
                          ),
                          report.damage
                              ? tag(
                                  '💥 Damage',
                                  bg: AppColors.red.withValues(alpha: .15),
                                  fg: AppColors.red,
                                )
                              : tag('✓ No Damage'),
                          if (report.chaseResult.isNotEmpty)
                            tag(report.chaseResult),
                          if (report.pendingSync)
                            tag(
                              '⏳ Queued offline',
                              bg: AppColors.amber.withValues(alpha: .12),
                              fg: AppColors.amber,
                            ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        report.summary,
                        style: AppText.body(
                          size: 11,
                          color: AppColors.text3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${report.total}',
                      style: AppText.heading(size: 20),
                    ),
                    Text(
                      'elephants',
                      style: AppText.body(
                        size: 10,
                        color: AppColors.text3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppColors.text3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
