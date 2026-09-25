import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_text.dart';

/// Titled container used across screens.
/// [panel] = uppercase grey title with a divider line (command centre style);
/// otherwise a green field-form title.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.panel = false,
    this.trailing,
    this.margin = const EdgeInsets.only(bottom: 14),
  });

  final String title;
  final Widget child;
  final bool panel;
  final Widget? trailing;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final titleWidget = panel
        ? Row(children: [
            Text(title.toUpperCase(),
                style: AppText.heading(size: 12, weight: FontWeight.w600, color: AppColors.text2, letterSpacing: 1)),
            const SizedBox(width: 8),
            const Expanded(child: Divider(height: 1, color: AppColors.border)),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ])
        : Row(children: [
            Expanded(
              child: Text(title,
                  style: AppText.heading(size: 15, weight: FontWeight.w600, color: AppColors.green)),
            ),
            if (trailing != null) trailing!,
          ]);

    return Container(
      margin: margin,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [titleWidget, const SizedBox(height: 12), child],
      ),
    );
  }
}

/// KPI tile for the command-centre dashboard.
class DashboardCard extends StatelessWidget {
  const DashboardCard({
    super.key,
    required this.label,
    required this.value,
    required this.sub,
    required this.trend,
    this.valueColor = AppColors.text,
    this.trendBad = false,
  });

  final String label;
  final String value;
  final String sub;
  final String trend;
  final Color valueColor;

  /// true = red trend chip, false = green.
  final bool trendBad;

  @override
  Widget build(BuildContext context) {
    final chip = trendBad ? AppColors.red : AppColors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.body(size: 10, color: AppColors.text3, weight: FontWeight.w500)),
          const SizedBox(height: 3),
          Text(value, style: AppText.heading(size: 28, color: valueColor)),
          const SizedBox(height: 2),
          Text(sub, style: AppText.body(size: 10, color: AppColors.text3)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: chip.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(trend, style: AppText.body(size: 10, color: chip)),
          ),
        ],
      ),
    );
  }
}

/// Card with a coloured stripe on the left edge.
/// (BoxDecoration can't combine a rounded border with a one-sided colour,
/// so the stripe is a separate child clipped by the rounded container.)
class AccentBox extends StatelessWidget {
  const AccentBox({
    super.key,
    required this.color,
    required this.child,
    this.background = AppColors.card,
    this.borderColor = AppColors.border,
    this.stripe = 4,
    this.radius = 14,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
  });

  final Color color;
  final Widget child;
  final Color background;
  final Color borderColor;
  final double stripe;
  final double radius;
  final EdgeInsets padding;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(radius),
      ),
      // Stack (not IntrinsicHeight) so children may contain LayoutBuilder.
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(left: stripe) + padding,
            child: child,
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: stripe,
            child: ColoredBox(color: color),
          ),
        ],
      ),
    );
  }
}
