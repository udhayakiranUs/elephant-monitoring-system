import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_text.dart';
import '../widgets/dashboard_card.dart';

enum ToastType { danger, warn, ok, info }

class ToastData {
  final int id;
  final ToastType type;
  final String title;
  final String message;
  final String icon;
  const ToastData(this.id, this.type, this.title, this.message, this.icon);

  Color get color => switch (type) {
        ToastType.danger => AppColors.red,
        ToastType.warn => AppColors.amber,
        ToastType.ok => AppColors.green,
        ToastType.info => AppColors.blue,
      };
}

/// In-app toast stack (top of screen), same behaviour as the prototype.
/// Push notifications (FCM) can be added here later.
class NotificationService extends ChangeNotifier {
  final List<ToastData> toasts = [];
  int _seq = 0;

  void show(ToastType type, String title, String message, {String icon = '🔔'}) {
    final t = ToastData(++_seq, type, title, message, icon);
    toasts.add(t);
    notifyListeners();
    Timer(const Duration(seconds: 5), () => dismiss(t.id));
  }

  void dismiss(int id) {
    toasts.removeWhere((t) => t.id == id);
    notifyListeners();
  }
}

/// Placed in MaterialApp.builder so toasts float above every screen.
class ToastHost extends StatelessWidget {
  const ToastHost({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<NotificationService>();
    // Positioned with only top/right => the host is exactly as big as its
    // toasts, so it never blocks touches on the screen underneath.
    return Positioned(
      top: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Material(
              type: MaterialType.transparency,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [for (final t in service.toasts) _Toast(key: ValueKey(t.id), data: t)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Toast extends StatelessWidget {
  const _Toast({super.key, required this.data});
  final ToastData data;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1, end: 0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, v, child) => Opacity(
        opacity: 1 - v,
        child: Transform.translate(offset: Offset(v * 120, 0), child: child),
      ),
      child: AccentBox(
        color: data.color,
        background: AppColors.card2,
        borderColor: AppColors.border2,
        margin: const EdgeInsets.only(bottom: 7),
        padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data.icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data.title, style: AppText.heading(size: 13, weight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(data.message, style: AppText.body(size: 11, height: 1.3)),
                ],
              ),
            ),
            InkWell(
              onTap: () => context.read<NotificationService>().dismiss(data.id),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.close, size: 14, color: AppColors.text3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
