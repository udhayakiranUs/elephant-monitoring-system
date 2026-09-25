import 'package:flutter/material.dart';

import '../core/constants/app_text.dart';
import '../core/utils/helpers.dart';
import '../models/alert_model.dart';

class ThreatLevelSelector extends StatelessWidget {
  const ThreatLevelSelector({super.key, required this.value, required this.onChanged});

  final ThreatLevel value;
  final ValueChanged<ThreatLevel> onChanged;

  static const _icons = {
    ThreatLevel.high: '🔴',
    ThreatLevel.medium: '🟡',
    ThreatLevel.low: '🟢',
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final t in ThreatLevel.values) ...[
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => onChanged(t),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: value == t
                      ? Helpers.threatColor(t).withValues(alpha: .14)
                      : Colors.transparent,
                  border: Border.all(
                    color: Helpers.threatColor(t),
                    width: value == t ? 1.6 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${_icons[t]} ${t.label}',
                  style: AppText.body(
                    size: 12,
                    color: Helpers.threatColor(t),
                    weight: value == t ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
          if (t != ThreatLevel.low) const SizedBox(width: 7),
        ],
      ],
    );
  }
}
