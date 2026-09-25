import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text.dart';
import '../../core/utils/helpers.dart';
import '../../models/user_model.dart';
import '../../routes/app_routes.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/sync_service.dart';
import '../../widgets/dashboard_card.dart';

class ProfileScreen extends StatelessWidget {
  /// [embedded] = shown as a tab (no Scaffold); otherwise a standalone page.
  const ProfileScreen({super.key, this.embedded = false});
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final api = context.watch<ApiService>();
    final sync = context.watch<SyncService>();
    final user = auth.user;

    final body = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (user != null)
          SectionCard(
            title: 'Officer',
            child: Column(children: [
              Row(children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.green3,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.green, width: 2),
                  ),
                  child: Text(Helpers.initials(user.name),
                      style: AppText.heading(size: 20, color: AppColors.green)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(user.name, style: AppText.heading(size: 18)),
                    Text(user.designation, style: AppText.body(size: 12)),
                  ]),
                ),
              ]),
              const SizedBox(height: 14),
              _row(Icons.place_outlined, 'Assignment', user.range),
              _row(Icons.phone_outlined, 'Phone', user.phone),
              _row(Icons.badge_outlined, 'Role',
                  user.role == UserRole.field ? 'Field staff' : 'Command centre'),
            ]),
          ),
        SectionCard(
          title: 'Offline sync',
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              api.pendingCount == 0
                  ? 'All alerts and reports are synced with HQ.'
                  : '${api.pendingCount} item(s) saved on this device, waiting for network.',
              style: AppText.body(size: 12),
            ),
            if (sync.lastSync != null) ...[
              const SizedBox(height: 4),
              Text('Last sync: ${Helpers.relativeDay(sync.lastSync!)}',
                  style: AppText.body(size: 11, color: AppColors.text3)),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: sync.syncing ? null : () => sync.syncNow(),
              icon: sync.syncing
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.green))
                  : const Icon(Icons.sync, size: 16),
              label: const Text('Sync now'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.green,
                side: const BorderSide(color: AppColors.green3),
              ),
            ),
          ]),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            final nav = Navigator.of(context, rootNavigator: true);
            await context.read<AuthService>().logout();
            nav.pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
          },
          icon: const Icon(Icons.logout, size: 18),
          label: Text('SIGN OUT', style: AppText.heading(size: 15, color: Colors.white, letterSpacing: 1)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.red2,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Text('EWS · v1.0.0 · ${AppText.divisionTitle}',
              style: AppText.body(size: 10, color: AppColors.text3)),
        ),
      ],
    );

    if (embedded) return body;
    return Scaffold(appBar: AppBar(title: const Text('PROFILE')), body: body);
  }

  Widget _row(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Icon(icon, size: 16, color: AppColors.text3),
          const SizedBox(width: 10),
          Text(label, style: AppText.body(size: 12, color: AppColors.text3)),
          const Spacer(),
          Text(value, style: AppText.body(size: 12, color: AppColors.text, weight: FontWeight.w500)),
        ]),
      );
}
