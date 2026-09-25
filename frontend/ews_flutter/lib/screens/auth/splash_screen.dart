import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final auth = context.read<AuthService>();
    final results = await Future.wait([
      auth.restoreSession(),
      Future<void>.delayed(const Duration(milliseconds: 1200)),
    ]);
    if (!mounted) return;
    final signedIn = results.first as bool;
    final next = signedIn ? AppRoutes.homeFor(auth.user!.role) : AppRoutes.login;
    Navigator.of(context).pushReplacementNamed(next);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.green3,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.green, width: 3),
              ),
              child: const Text('🐘', style: TextStyle(fontSize: 40)),
            ),
            const SizedBox(height: 18),
            Text(AppText.appName,
                style: AppText.heading(size: 34, color: AppColors.green, letterSpacing: 4)),
            const SizedBox(height: 4),
            Text(AppText.appTitle, style: AppText.body(size: 13)),
            Text(AppText.division,
                style: AppText.body(size: 10, color: AppColors.text3)),
            const SizedBox(height: 28),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.green),
            ),
          ],
        ),
      ),
    );
  }
}
