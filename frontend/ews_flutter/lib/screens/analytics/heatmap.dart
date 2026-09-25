import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text.dart';
import '../../core/utils/helpers.dart';

/// Range × month heat table. Cell colour scales with the value
/// (red > 65%, amber > 35%, green > 10% of the global max).
class RangeMonthHeatmap extends StatelessWidget {
  const RangeMonthHeatmap({super.key, required this.months, required this.pivot});

  final List<String> months;
  final Map<String, List<int>> pivot;

  static const double _nameW = 140;
  static const double _cellW = 30;
  static const double _totalW = 56;

  Color _bg(int v, int maxV) {
    final p = maxV == 0 ? 0.0 : v / maxV;
    if (p > .65) return AppColors.red.withValues(alpha: .2 + p * .55);
    if (p > .35) return AppColors.amber.withValues(alpha: .15 + p * .45);
    if (p > .10) return AppColors.green.withValues(alpha: .08 + p * .3);
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    final maxV = pivot.values.expand((e) => e).reduce((a, b) => a > b ? a : b);
    final border = BorderSide(color: AppColors.border.withValues(alpha: .35));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header
          Row(
            children: [
              SizedBox(
                width: _nameW,
                height: 58,
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 4),
                    child: Text('Range', style: AppText.body(size: 10, color: AppColors.text3)),
                  ),
                ),
              ),
              for (final m in months)
                SizedBox(
                  width: _cellW,
                  height: 58,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: Text('${m.substring(0, 3)} ${m.substring(m.length - 2)}',
                            style: AppText.body(size: 9, color: AppColors.text3)),
                      ),
                    ),
                  ),
                ),
              SizedBox(
                width: _totalW,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text('Total', style: AppText.body(size: 10)),
                  ),
                ),
              ),
            ],
          ),
          // rows
          for (final e in pivot.entries)
            Container(
              decoration: BoxDecoration(border: Border(bottom: border)),
              child: Row(
                children: [
                  SizedBox(
                    width: _nameW,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Text(e.key,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.body(size: 11, color: AppColors.text, weight: FontWeight.w500)),
                    ),
                  ),
                  for (final v in e.value)
                    Container(
                      width: _cellW,
                      height: 26,
                      alignment: Alignment.center,
                      color: _bg(v, maxV),
                      child: Text(v == 0 ? '' : '$v',
                          style: AppText.body(size: 9)),
                    ),
                  SizedBox(
                    width: _totalW,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(Helpers.number(e.value.fold<int>(0, (a, b) => a + b)),
                          textAlign: TextAlign.right,
                          style: AppText.body(size: 11, color: AppColors.green, weight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
