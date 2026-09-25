import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_text.dart';
import '../core/utils/helpers.dart';
import '../models/staff_model.dart';

class StaffCard extends StatelessWidget {
  const StaffCard({super.key, required this.staff});
  final StaffModel staff;

  Color get _color => switch (staff.status) {
        StaffStatus.field => AppColors.amber,
        StaffStatus.hq => AppColors.green,
        StaffStatus.standby => AppColors.blue,
        StaffStatus.offDuty => AppColors.text3,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.green3,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.green3, width: 2),
            ),
            child: Text(Helpers.initials(staff.name),
                style: AppText.heading(size: 12, color: AppColors.green)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(staff.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(size: 12, color: AppColors.text, weight: FontWeight.w500)),
                Text(staff.assignment,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(size: 10, color: AppColors.text3)),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: _color.withValues(alpha: .12),
              border: Border.all(color: _color.withValues(alpha: .6)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(staff.status.label, style: AppText.body(size: 10, color: _color)),
          ),
        ],
      ),
    );
  }
}
