import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text.dart';
import '../../core/utils/helpers.dart';

TextStyle _axis() => AppText.body(size: 9, color: AppColors.text3);

FlTitlesData _titles({
  required List<String> labels,
  int labelEvery = 1,
  double leftReserved = 34,
}) =>
    FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: leftReserved,
          getTitlesWidget: (v, meta) => Text(Helpers.compact(v), style: _axis()),
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 22,
          interval: 1,
          getTitlesWidget: (v, meta) {
            final i = v.toInt();
            if (i < 0 || i >= labels.length || i % labelEvery != 0) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(labels[i], style: _axis()),
            );
          },
        ),
      ),
    );

FlGridData _grid() => FlGridData(
      show: true,
      drawVerticalLine: false,
      getDrawingHorizontalLine: (_) =>
          FlLine(color: AppColors.border.withValues(alpha: .5), strokeWidth: .6),
    );

/// "Jan-2024" -> "Jan'24"
String shortMonth(String m) => "${m.substring(0, 3)}'${m.substring(m.length - 2)}";

class LineSeries {
  final String label;
  final List<int> data;
  final Color color;
  final bool dashed;
  const LineSeries(this.label, this.data, this.color, {this.dashed = false});
}

/// Multi-series line chart (dashboard trend).
class TrendLineChart extends StatelessWidget {
  const TrendLineChart({super.key, required this.labels, required this.series, this.height = 170});

  final List<String> labels;
  final List<LineSeries> series;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            for (final s in series) ...[
              Container(width: 10, height: 3, color: s.color),
              const SizedBox(width: 5),
              Text(s.label, style: AppText.body(size: 10)),
              const SizedBox(width: 12),
            ],
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: height,
          child: LineChart(
            LineChartData(
              minY: 0,
              gridData: _grid(),
              borderData: FlBorderData(show: false),
              titlesData: _titles(labels: labels, labelEvery: 3),
              lineBarsData: [
                for (final s in series)
                  LineChartBarData(
                    spots: [
                      for (var i = 0; i < s.data.length; i++)
                        FlSpot(i.toDouble(), s.data[i].toDouble()),
                    ],
                    isCurved: true,
                    color: s.color,
                    barWidth: 1.5,
                    dashArray: s.dashed ? [4, 3] : null,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: s.color.withValues(alpha: .07)),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Monthly bars coloured by intensity (red >70%, amber >40%, green).
class MonthlyBarChart extends StatelessWidget {
  const MonthlyBarChart({super.key, required this.labels, required this.data, this.height = 210});

  final List<String> labels;
  final List<int> data;
  final double height;

  @override
  Widget build(BuildContext context) {
    final maxV = data.isEmpty ? 1 : data.reduce((a, b) => a > b ? a : b);
    Color colorFor(int v) {
      final r = maxV == 0 ? 0 : v / maxV;
      if (r > .7) return AppColors.red.withValues(alpha: .75);
      if (r > .4) return AppColors.amber.withValues(alpha: .75);
      return AppColors.green.withValues(alpha: .65);
    }

    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          gridData: _grid(),
          borderData: FlBorderData(show: false),
          titlesData: _titles(labels: labels.map(shortMonth).toList(), labelEvery: 3),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                '${labels[group.x]}\n${Helpers.number(rod.toY)}',
                AppText.body(size: 11, color: AppColors.text),
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < data.length; i++)
              BarChartGroupData(x: i, barRods: [
                BarChartRodData(
                  toY: data[i].toDouble(),
                  color: colorFor(data[i]),
                  width: 6,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                ),
              ]),
          ],
        ),
      ),
    );
  }
}

/// Year-over-year: elephants vs incidents.
class YearOverYearChart extends StatelessWidget {
  const YearOverYearChart({super.key, required this.years, this.height = 170});

  final List<({int year, int elephants, int incidents})> years;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          gridData: _grid(),
          borderData: FlBorderData(show: false),
          alignment: BarChartAlignment.spaceAround,
          titlesData: _titles(labels: [for (final y in years) '${y.year}']),
          barGroups: [
            for (var i = 0; i < years.length; i++)
              BarChartGroupData(x: i, barsSpace: 4, barRods: [
                BarChartRodData(
                  toY: years[i].elephants.toDouble(),
                  color: AppColors.green.withValues(alpha: .7),
                  width: 14,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
                BarChartRodData(
                  toY: years[i].incidents.toDouble(),
                  color: AppColors.amber.withValues(alpha: .7),
                  width: 14,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ]),
          ],
        ),
      ),
    );
  }
}

/// Average elephants by calendar month.
class SeasonalityChart extends StatelessWidget {
  const SeasonalityChart({super.key, required this.months, required this.monthly, this.height = 170});

  final List<String> months; // "Jan-2024"...
  final List<int> monthly;
  final double height;

  static const _names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  List<int> _averages() {
    final sum = List<int>.filled(12, 0);
    final cnt = List<int>.filled(12, 0);
    for (var i = 0; i < months.length; i++) {
      final mi = _names.indexOf(months[i].substring(0, 3));
      if (mi >= 0) {
        sum[mi] += monthly[i];
        cnt[mi]++;
      }
    }
    return [for (var i = 0; i < 12; i++) cnt[i] == 0 ? 0 : (sum[i] / cnt[i]).round()];
  }

  @override
  Widget build(BuildContext context) {
    final avg = _averages();
    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: 0,
          gridData: _grid(),
          borderData: FlBorderData(show: false),
          titlesData: _titles(labels: _names, labelEvery: 2),
          lineBarsData: [
            LineChartBarData(
              spots: [for (var i = 0; i < 12; i++) FlSpot(i.toDouble(), avg[i].toDouble())],
              isCurved: true,
              color: AppColors.purple,
              barWidth: 2,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: true, color: AppColors.purple.withValues(alpha: .12)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Top peak months as horizontal bars (fl_chart has no horizontal bars).
class PeakMonthsChart extends StatelessWidget {
  const PeakMonthsChart({super.key, required this.peaks});

  final List<({String month, int elephants})> peaks;

  @override
  Widget build(BuildContext context) {
    final maxV = peaks.map((p) => p.elephants).reduce((a, b) => a > b ? a : b);
    return Column(
      children: [
        for (final p in peaks)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                SizedBox(
                  width: 64,
                  child: Text(p.month, style: AppText.body(size: 10)),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: p.elephants / maxV,
                      minHeight: 12,
                      backgroundColor: AppColors.bg,
                      valueColor: AlwaysStoppedAnimation(AppColors.red.withValues(alpha: .7)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 38,
                  child: Text(Helpers.number(p.elephants),
                      textAlign: TextAlign.right, style: AppText.body(size: 10, color: AppColors.text)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
