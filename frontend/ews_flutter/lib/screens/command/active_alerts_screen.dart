import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/alert_card.dart';

class ActiveAlertsScreen extends StatefulWidget {
  const ActiveAlertsScreen({super.key});

  @override
  State<ActiveAlertsScreen> createState() => _ActiveAlertsScreenState();
}

class _ActiveAlertsScreenState extends State<ActiveAlertsScreen> {
  bool _onlyActive = true;

  @override
  Widget build(BuildContext context) {
    final api = context.watch<ApiService>();
    final list = [...(_onlyActive ? api.activeAlerts : api.alerts)]
      ..sort((a, b) => b.time.compareTo(a.time));

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Row(children: [
          ChoiceChip(
            label: Text('Active (${api.activeAlerts.length})'),
            selected: _onlyActive,
            onSelected: (_) => setState(() => _onlyActive = true),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: Text('All (${api.alerts.length})'),
            selected: !_onlyActive,
            onSelected: (_) => setState(() => _onlyActive = false),
          ),
        ]),
      ),
      Expanded(
        child: RefreshIndicator(
          color: AppColors.green,
          backgroundColor: AppColors.card,
          onRefresh: () => api.loadAll(force: true),
          child: list.isEmpty
              ? ListView(children: [
                  const SizedBox(height: 100),
                  Center(child: Text('No active alerts ✅', style: AppText.body(size: 13, color: AppColors.text3))),
                ])
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final a = list[i];
                    return AlertCard(
                      alert: a,
                      onResolve: a.resolved
                          ? null
                          : () {
                              api.resolveAlert(a.id);
                              context.read<NotificationService>().show(
                                  ToastType.ok, 'Alert Resolved', a.title,
                                  icon: '✅');
                            },
                    );
                  },
                ),
        ),
      ),
    ]);
  }
}
