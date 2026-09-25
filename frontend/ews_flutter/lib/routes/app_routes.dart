import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/command/command_home_screen.dart';
import '../screens/field/field_home_screen.dart';
import '../screens/profile/profile_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const login = '/login';
  static const fieldHome = '/field';
  static const commandHome = '/command';
  static const profile = '/profile';

  static String homeFor(UserRole role) =>
      role == UserRole.command ? commandHome : fieldHome;

  static Route<dynamic> generate(RouteSettings settings) {
    final Widget page = switch (settings.name) {
      login => const LoginScreen(),
      fieldHome => const FieldHomeScreen(),
      commandHome => const CommandHomeScreen(),
      profile => const ProfileScreen(),
      _ => const SplashScreen(),
    };
    return MaterialPageRoute<void>(builder: (_) => page, settings: settings);
  }
}
