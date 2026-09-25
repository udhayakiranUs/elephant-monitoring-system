import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text.dart';
import '../../models/staff_model.dart';
import '../../services/api_service.dart';
import '../../widgets/staff_card.dart';

class StaffStatusScreen extends StatefulWidget {
  const StaffStatusScreen({super.key});

  @override
  State<StaffStatusScreen> createState() => _StaffStatusScreenState();
}

class _StaffStatusScreenState extends State<StaffStatusScreen> {
  StaffStatus? _filter; // null = all

  @override
  Widget build(BuildContext context) {
    final staff = context.watch<ApiService>().staff;
    final shown = _filter == null ? staff : staff.where((s) => s.status == _filter).toList();
    int count(StaffStatus s) => staff.where((e) => e.status == s).length;

    return Column(children: [
      SizedBox(
        height: 56,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text('All (${staff.length})'),
                selected: _filter == null,
                onSelected: (_) => setState(() => _filter = null),
              ),
            ),
            for (final s in StaffStatus.values)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('${s.label} (${count(s)})'),
                  selected: _filter == s,
                  onSelected: (_) => setState(() => _filter = s),
                ),
              ),
          ],
        ),
      ),
      Expanded(
        child: shown.isEmpty
            ? Center(child: Text('No staff', style: AppText.body(size: 13, color: AppColors.text3)))
            : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 340,
                  mainAxisExtent: 52,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: shown.length,
                itemBuilder: (_, i) => StaffCard(staff: shown[i]),
              ),
      ),
    ]);
  }
}
