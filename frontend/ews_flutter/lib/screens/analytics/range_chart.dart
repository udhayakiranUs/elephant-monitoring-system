import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text.dart';
import '../../core/utils/helpers.dart';
import '../../models/range_model.dart';

/// Range-wise share (donut + legend).
class RangeDonutChart extends StatelessWidget {
  const RangeDonutChart({super.key, required this.stats, required this.elephantsView, this.height = 210});

  final List<RangeStat> stats; // already sorted
  final bool elephantsView;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 1.5,
                centerSpaceRadius: 42,
                sections: [
                  for (final s in stats)
                    PieChartSectionData(
                      value: s.metric(elephantsView).toDouble(),
                      color: AppColors.rangeColor(s.range),
                      radius: 30,
                      showTitle: false,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final s in stats)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.rangeColor(s.range),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      s.range.length > 12 ? '${s.range.substring(0, 11)}…' : s.range,
                      style: AppText.body(size: 10),
                    ),
                  ]),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Elephants vs incidents per range (grouped bars).
class RangeComparisonChart extends StatelessWidget {
  const RangeComparisonChart({super.key, required this.stats, this.height = 210});

  final List<RangeStat> stats;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(children: [
          Container(width: 10, height: 10, color: AppColors.green.withValues(alpha: .65)),
          const SizedBox(width: 5),
          Text('Elephants out', style: AppText.body(size: 10)),
          const SizedBox(width: 12),
          Container(width: 10, height: 10, color: AppColors.amber.withValues(alpha: .65)),
          const SizedBox(width: 5),
          Text('Incidents', style: AppText.body(size: 10)),
        ]),
        const SizedBox(height: 8),
        SizedBox(
          height: height - 24,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              gridData: FlGridData(
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: AppColors.border.withValues(alpha: .5), strokeWidth: .6),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 34,
                    getTitlesWidget: (v, _) => Text(Helpers.compact(v),
                        style: AppText.body(size: 9, color: AppColors.text3)),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= stats.length) return const SizedBox.shrink();
                      final n = stats[i].range;
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(n.length > 5 ? n.substring(0, 4) : n,
                            style: AppText.body(size: 9, color: AppColors.text3)),
                      );
                    },
                  ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < stats.length; i++)
                  BarChartGroupData(x: i, barsSpace: 2, barRods: [
                    BarChartRodData(
                      toY: stats[i].elephants.toDouble(),
                      color: AppColors.green.withValues(alpha: .65),
                      width: 8,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                    ),
                    BarChartRodData(
                      toY: stats[i].incidents.toDouble(),
                      color: AppColors.amber.withValues(alpha: .65),
                      width: 8,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                    ),
                  ]),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Elephant-type breakdown across all ranges.
class ElephantTypeChart extends StatelessWidget {
  const ElephantTypeChart({super.key, required this.stats, this.height = 210});

  final List<RangeStat> stats;
  final double height;

  static const _types = [
    ('Lone Male', AppColors.blue),
    ('Male Group', AppColors.teal),
    ('Female Group', AppColors.pink),
    ('Female+Calf', AppColors.red),
    ('Single Female', AppColors.purple),
    ('Unidentified', AppColors.amber),
    ('Makhna', AppColors.green),
  ];

  @override
  Widget build(BuildContext context) {
    int sum(int Function(RangeStat) f) => stats.fold(0, (a, s) => a + f(s));
    final totals = [
      sum((s) => s.lm),
      sum((s) => s.mg),
      sum((s) => s.fg),
      sum((s) => s.fc),
      sum((s) => s.sf),
      sum((s) => s.ug),
      sum((s) => s.mk),
    ];
    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: AppColors.border.withValues(alpha: .5), strokeWidth: .6),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 34,
                getTitlesWidget: (v, _) =>
                    Text(Helpers.compact(v), style: AppText.body(size: 9, color: AppColors.text3)),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 64,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= _types.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: Text(_types[i].$1,
                          style: AppText.body(size: 9, color: AppColors.text3)),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < _types.length; i++)
              BarChartGroupData(x: i, barRods: [
                BarChartRodData(
                  toY: totals[i].toDouble(),
                  color: _types[i].$2,
                  width: 16,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                ),
              ]),
          ],
        ),
      ),
    );
  }
}
