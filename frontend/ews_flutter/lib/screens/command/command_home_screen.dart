import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/analytics_mock.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text.dart';
import '../../core/utils/helpers.dart';
import '../../models/range_model.dart';
import '../../routes/app_routes.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/alert_card.dart';
import '../../widgets/app_bottom_navigation.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/staff_card.dart';
import '../analytics/analytics_screen.dart';
import '../analytics/trend_chart.dart';
import 'active_alerts_screen.dart';
import 'live_map_screen.dart';
import 'staff_status_screen.dart';

/// Shell for HQ: Dashboard · Live Map · Alerts · Staff · Analytics.
class CommandHomeScreen extends StatefulWidget {
  const CommandHomeScreen({super.key});

  @override
  State<CommandHomeScreen> createState() => _CommandHomeScreenState();
}

class _CommandHomeScreenState extends State<CommandHomeScreen> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<ApiService>().loadAll());
  }

  @override
  Widget build(BuildContext context) {
    final active = context.select<ApiService, int>((a) => a.activeAlerts.length);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.green3,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.green, width: 2),
            ),
            child: const Text('🐘', style: TextStyle(fontSize: 15)),
          ),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('EWS'),
            Text(AppText.division, style: AppText.body(size: 9, color: AppColors.text3)),
          ]),
        ]),
        actions: [
          _StatusPill(alert: active > 0),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.profile),
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: const [
          _DashboardTab(),
          LiveMapScreen(editable: true),
          ActiveAlertsScreen(),
          StaffStatusScreen(),
          AnalyticsScreen(),
        ],
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: [
          const NavItem(Icons.dashboard_outlined, 'Dashboard'),
          const NavItem(Icons.map_outlined, 'Map'),
          NavItem(Icons.notifications_none, 'Alerts', badge: active),
          const NavItem(Icons.groups_outlined, 'Staff'),
          const NavItem(Icons.bar_chart, 'Analytics'),
        ],
      ),
    );
  }
}

class _StatusPill extends StatefulWidget {
  const _StatusPill({required this.alert});
  final bool alert;

  @override
  State<_StatusPill> createState() => _StatusPillState();
}

class _StatusPillState extends State<_StatusPill> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))
        ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.alert ? AppColors.red : AppColors.green;
    return FadeTransition(
      opacity: widget.alert ? Tween(begin: 1.0, end: .5).animate(_c) : const AlwaysStoppedAnimation(1.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .13),
          border: Border.all(color: widget.alert ? AppColors.red2 : AppColors.green3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(widget.alert ? '⚠ ACTIVE ALERT' : '● MONITORING',
            style: AppText.heading(size: 11, weight: FontWeight.w600, color: color)),
      ),
    );
  }
}

class _Clock extends StatefulWidget {
  const _Clock();
  @override
  State<_Clock> createState() => _ClockState();
}

class _ClockState extends State<_Clock> {
  late Timer _t;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) => setState(() => _now = DateTime.now()));
  }

  @override
  void dispose() {
    _t.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text(
        DateFormat('dd MMM yyyy  HH:mm:ss').format(_now),
        style: AppText.heading(size: 13, weight: FontWeight.w500, color: AppColors.text2, letterSpacing: 1),
      );
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final api = context.watch<ApiService>();
    final active = api.activeAlerts;
    final danger = active.where((a) => a.type.name == 'danger').toList();
    final feed = [...api.alerts]..sort((a, b) => b.time.compareTo(a.time));

    final cards = [
      DashboardCard(
        label: 'Today — Elephants Out',
        value: '${api.elephantsOutToday}',
        valueColor: AppColors.red,
        sub: 'across ${api.activeRangeCount} active ranges',
        trend: '↑ +12 from yesterday',
        trendBad: true,
      ),
      DashboardCard(
        label: 'Active Incidents',
        value: '${active.length}',
        valueColor: AppColors.amber,
        sub: 'unresolved operations',
        trend: active.isEmpty ? '✓ All clear' : '🚨 Alert active',
        trendBad: active.isNotEmpty,
      ),
      DashboardCard(
        label: 'Staff in Field',
        value: '${api.deployedStaff}',
        valueColor: AppColors.green,
        sub: 'of ${api.staff.length} total staff',
        trend: '✓ Deployed',
      ),
      DashboardCard(
        label: 'All-Time Recorded',
        value: Helpers.number(AnalyticsMock.allTimeRecorded),
        sub: 'Jan 2024 – Mar 2026',
        trend: '27 months',
      ),
      DashboardCard(
        label: 'Total Incidents',
        value: Helpers.number(AnalyticsMock.totalIncidents),
        sub: 'chase-back operations',
        trend: '49.4% resolution',
        trendBad: true,
      ),
    ];

    return RefreshIndicator(
      color: AppColors.green,
      backgroundColor: AppColors.card,
      onRefresh: () => api.loadAll(force: true),
      child: LayoutBuilder(builder: (context, c) {
        const gap = 10.0;
        final cols = c.maxWidth >= 900 ? 5 : (c.maxWidth >= 600 ? 3 : 2);
        final w = (c.maxWidth - 28 - gap * (cols - 1)) / cols;
        final wide = c.maxWidth >= 900;

        Widget pair(Widget a, Widget b) => wide
            ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 3, child: a),
                const SizedBox(width: 14),
                Expanded(flex: 2, child: b),
              ])
            : Column(children: [a, b]);

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(14),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(children: [
                Expanded(
                  child: Text('COMMAND CENTRE · ${AppText.divisionTitle.toUpperCase()}',
                      style: AppText.heading(size: 15, letterSpacing: 1)),
                ),
                const _Clock(),
              ]),
            ),
            Wrap(spacing: gap, runSpacing: gap, children: [
              for (final card in cards) SizedBox(width: w, child: card),
            ]),
            const SizedBox(height: 14),
            if (danger.isNotEmpty)
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
                      Text('ACTIVE ALERT — ${danger.first.range} Range',
                          style: AppText.heading(size: 14, weight: FontWeight.w600, color: AppColors.red)),
                      const SizedBox(height: 2),
                      Text(
                        '${danger.first.message} · Reported ${Helpers.time(danger.first.time)} · '
                        '${danger.first.sentTo}',
                        style: AppText.body(size: 11),
                      ),
                    ]),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      api.resolveAlert(danger.first.id);
                      context.read<NotificationService>().show(
                          ToastType.ok, 'Alert Resolved', 'Incident closed by command centre',
                          icon: '✅');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.red,
                      side: const BorderSide(color: AppColors.red2),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Mark Resolved', style: TextStyle(fontSize: 11)),
                  ),
                ]),
              ),
            SectionCard(
              panel: true,
              title: 'Live Alerts Feed',
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: feed.isEmpty
                    ? Text('No alerts', style: AppText.body(size: 12, color: AppColors.text3))
                    : ListView(
                        shrinkWrap: true,
                        children: [for (final a in feed.take(8)) AlertCard(alert: a, compact: true)],
                      ),
              ),
            ),
            pair(
              SectionCard(panel: true, title: 'Range Status Today', child: _RangeTable(ranges: api.ranges)),
              SectionCard(
                panel: true,
                title: 'Staff Status',
                child: Column(children: [
                  for (final s in api.staff.take(6))
                    Padding(padding: const EdgeInsets.only(bottom: 7), child: StaffCard(staff: s)),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.bg2,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text.rich(TextSpan(style: AppText.body(size: 11), children: [
                      TextSpan(
                          text: '${api.deployedStaff}/${api.staff.length}',
                          style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w700)),
                      const TextSpan(text: ' deployed · '),
                      TextSpan(
                          text: '${api.standbyStaff}',
                          style: const TextStyle(color: AppColors.amber, fontWeight: FontWeight.w700)),
                      const TextSpan(text: ' standby · '),
                      TextSpan(
                          text: '${api.offDutyStaff}',
                          style: const TextStyle(color: AppColors.text3, fontWeight: FontWeight.w700)),
                      const TextSpan(text: ' off duty'),
                    ])),
                  ),
                ]),
              ),
            ),
            SectionCard(
              panel: true,
              title: 'Monthly Trend — Jan 2024 to Mar 2026',
              child: TrendLineChart(
                labels: AnalyticsMock.months.map(shortMonth).toList(),
                series: const [
                  LineSeries('Elephants out', AnalyticsMock.monthlyElephants, AppColors.green),
                  LineSeries('Incidents', AnalyticsMock.monthlyIncidents, AppColors.amber, dashed: true),
                ],
                height: 160,
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _RangeTable extends StatelessWidget {
  const _RangeTable({required this.ranges});
  final List<RangeModel> ranges;

  Color _dot(RangeStatus s) => switch (s) {
        RangeStatus.alert => AppColors.red,
        RangeStatus.active => AppColors.amber,
        RangeStatus.clear => AppColors.green,
      };

  @override
  Widget build(BuildContext context) {
    final maxToday = ranges.isEmpty ? 1 : ranges.map((r) => r.today).reduce((a, b) => a > b ? a : b);
    TextStyle head() => AppText.body(size: 10, color: AppColors.text3);
    TextStyle cell() => AppText.body(size: 12, color: AppColors.text);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 420),
        child: Table(
          columnWidths: const {
            0: FixedColumnWidth(140),
            1: FixedColumnWidth(76),
            2: FixedColumnWidth(34),
            3: FixedColumnWidth(80),
            4: FixedColumnWidth(76),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
              children: [
                for (final h in ['RANGE', 'STATUS', 'OUT', 'ACTIVITY', 'LAST'])
                  Padding(padding: const EdgeInsets.all(6), child: Text(h, style: head())),
              ],
            ),
            for (final r in ranges)
              TableRow(
                decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: .4)))),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(7),
                    child: Text(r.name, overflow: TextOverflow.ellipsis, style: cell()),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(7),
                    child: Row(children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(color: _dot(r.status), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      Text(r.status.label, style: cell()),
                    ]),
                  ),
                  Padding(padding: const EdgeInsets.all(7), child: Text('${r.today}', style: cell())),
                  Padding(
                    padding: const EdgeInsets.all(7),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: maxToday == 0 ? 0 : r.today / maxToday,
                        minHeight: 7,
                        backgroundColor: AppColors.bg,
                        valueColor: AlwaysStoppedAnimation(
                            r.status == RangeStatus.alert
                                ? AppColors.red
                                : r.status == RangeStatus.active
                                    ? AppColors.amber
                                    : AppColors.green),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(7),
                    child: Text(r.lastReport, style: AppText.body(size: 12, color: AppColors.text3)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
