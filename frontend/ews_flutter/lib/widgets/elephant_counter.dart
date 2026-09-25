import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_text.dart';
import '../models/elephant_model.dart';

/// One − / value / + counter.
class ElephantCounter extends StatelessWidget {
  const ElephantCounter({
    super.key,
    required this.label,
    required this.value,
    required this.onIncrement,
    required this.onDecrement,
  });

  final String label;
  final int value;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        border: Border.all(color: AppColors.border2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.body(size: 10)),
          const SizedBox(height: 5),
          Row(
            children: [
              _RoundBtn(icon: Icons.remove, onTap: onDecrement),
              Expanded(
                child: Text('$value',
                    textAlign: TextAlign.center, style: AppText.heading(size: 19)),
              ),
              _RoundBtn(icon: Icons.add, onTap: onIncrement),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  const _RoundBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.card,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border2),
          ),
          child: Icon(icon, size: 16, color: AppColors.text),
        ),
      );
}

/// Responsive grid with a counter for every [ElephantType].
class ElephantCounterGrid extends StatelessWidget {
  const ElephantCounterGrid({super.key, required this.counts, required this.onChanged});

  final ElephantCounts counts;
  final void Function(ElephantType type, int delta) onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      const gap = 8.0;
      final cols = c.maxWidth >= 480 ? 3 : 2;
      final w = (c.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final t in ElephantType.values)
            SizedBox(
              width: w,
              child: ElephantCounter(
                label: t.label,
                value: counts[t],
                onIncrement: () => onChanged(t, 1),
                onDecrement: () => onChanged(t, -1),
              ),
            ),
        ],
      );
    });
  }
}
