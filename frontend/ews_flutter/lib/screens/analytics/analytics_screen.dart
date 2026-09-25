import 'package:flutter/material.dart';

import '../../core/constants/analytics_mock.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text.dart';
import '../../core/utils/helpers.dart';
import '../../widgets/dashboard_card.dart';
import 'heatmap.dart';
import 'range_chart.dart';
import 'trend_chart.dart';

/// Historical analysis (Excel data Jan 2024 – Mar 2026).
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _range = 'ALL';
  bool _elephants = true;

  @override
  Widget build(BuildContext context) {
    final stats = [...AnalyticsMock.rangeStats]
      ..sort((a, b) => b.metric(_elephants).compareTo(a.metric(_elephants)));
    final totalE = stats.fold<int>(0, (s, r) => s + r.elephants);
    final totalI = stats.fold<int>(0, (s, r) => s + r.incidents);
    final top = stats.first;

    final monthly = _range == 'ALL'
        ? (_elephants ? AnalyticsMock.monthlyElephants : AnalyticsMock.monthlyIncidents)
        : (AnalyticsMock.pivot[_range] ?? AnalyticsMock.monthlyElephants);

    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth >= 900;

      Widget row(List<Widget> children) {
        if (!wide) {
          return Column(children: [for (final w in children) w]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              Expanded(child: children[i]),
              if (i != children.length - 1) const SizedBox(width: 14),
            ],
          ],
        );
      }

      return ListView(
        padding: const EdgeInsets.all(14),
        children: [
          _FilterBar(
            range: _range,
            elephants: _elephants,
            onRange: (v) => setState(() => _range = v),
            onMetric: (v) => setState(() => _elephants = v),
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _Pill(Helpers.number(totalE), 'total elephants', kind: _PillKind.good),
            _Pill(Helpers.number(totalI), 'chase-back incidents'),
            const _Pill('27', 'months tracked'),
            const _Pill('Nov-2024', '(1,449 elephants)', kind: _PillKind.bad, prefix: 'Peak month: '),
            _Pill('${top.range} (${Helpers.number(top.metric(_elephants))})', '',
                kind: _PillKind.good, prefix: 'Top range: '),
            _Pill('${(totalI / totalE * 100).toStringAsFixed(1)}%', 'incident / elephant ratio'),
          ]),
          const SizedBox(height: 14),
          row([
            SectionCard(
              panel: true,
              title: _range == 'ALL' ? 'Monthly Trend (27 months)' : 'Monthly Trend — $_range',
              child: MonthlyBarChart(labels: AnalyticsMock.months, data: monthly),
            ),
            SectionCard(
              panel: true,
              title: 'Range-wise Share',
              child: RangeDonutChart(stats: stats, elephantsView: _elephants),
            ),
          ]),
          row([
            SectionCard(
              panel: true,
              title: 'Range Comparison — Elephants vs Incidents',
              child: RangeComparisonChart(stats: stats),
            ),
            SectionCard(
              panel: true,
              title: 'Elephant Type Breakdown (All Ranges)',
              child: ElephantTypeChart(stats: stats),
            ),
          ]),
          row([
            const SectionCard(
              panel: true,
              title: 'Year-over-Year',
              child: YearOverYearChart(years: AnalyticsMock.yearly),
            ),
            const SectionCard(
              panel: true,
              title: 'Top 5 Peak Months',
              child: PeakMonthsChart(peaks: AnalyticsMock.peakMonths),
            ),
            const SectionCard(
              panel: true,
              title: 'Seasonality (Avg by Month)',
              child: SeasonalityChart(
                months: AnalyticsMock.months,
                monthly: AnalyticsMock.monthlyElephants,
              ),
            ),
          ]),
          const SectionCard(
            panel: true,
            title: 'Range × Month Heatmap',
            child: RangeMonthHeatmap(months: AnalyticsMock.months, pivot: AnalyticsMock.pivot),
          ),
        ],
      );
    });
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.range,
    required this.elephants,
    required this.onRange,
    required this.onMetric,
  });

  final String range;
  final bool elephants;
  final ValueChanged<String> onRange;
  final ValueChanged<bool> onMetric;

  @override
  Widget build(BuildContext context) {
    Widget dropdown<T>(String label, T value, List<DropdownMenuItem<T>> items, ValueChanged<T?> cb) =>
        Row(mainAxisSize: MainAxisSize.min, children: [
          Text('$label ', style: AppText.body(size: 12)),
          const SizedBox(width: 4),
          DropdownButtonHideUnderline(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: AppColors.bg2,
                border: Border.all(color: AppColors.border2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<T>(
                value: value,
                items: items,
                onChanged: cb,
                dropdownColor: AppColors.bg2,
                style: AppText.body(size: 12, color: AppColors.text),
                isDense: true,
              ),
            ),
          ),
        ]);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Wrap(spacing: 16, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
        dropdown<String>(
          'Range Filter:',
          range,
          [
            const DropdownMenuItem(value: 'ALL', child: Text('All Ranges')),
            for (final r in ([...AppText.rangeNames]..sort()))
              DropdownMenuItem(value: r, child: Text(r)),
          ],
          (v) => onRange(v ?? 'ALL'),
        ),
        dropdown<bool>(
          'Metric:',
          elephants,
          const [
            DropdownMenuItem(value: true, child: Text('Elephants Stayed Out')),
            DropdownMenuItem(value: false, child: Text('Total Incidents')),
          ],
          (v) => onMetric(v ?? true),
        ),
      ]),
    );
  }
}

enum _PillKind { normal, good, bad }

class _Pill extends StatelessWidget {
  const _Pill(this.strong, this.text, {this.kind = _PillKind.normal, this.prefix = ''});

  final String strong;
  final String text;
  final _PillKind kind;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    final (border, bg, fg) = switch (kind) {
      _PillKind.good => (AppColors.green3, AppColors.green.withValues(alpha: .06), AppColors.green),
      _PillKind.bad => (AppColors.red2, AppColors.red.withValues(alpha: .08), AppColors.red),
      _PillKind.normal => (AppColors.border, AppColors.bg2, AppColors.text),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text.rich(TextSpan(
        style: AppText.body(size: 12),
        children: [
          if (prefix.isNotEmpty) TextSpan(text: prefix),
          TextSpan(text: strong, style: AppText.body(size: 12, color: fg, weight: FontWeight.w500)),
          if (text.isNotEmpty) TextSpan(text: ' $text'),
        ],
      )),
    );
  }
}
