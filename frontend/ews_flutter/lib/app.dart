import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_text.dart';
import 'core/theme/app_theme.dart';
import 'database/local_database.dart';
import 'routes/app_routes.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/camera_service.dart';
import 'services/gps_service.dart';
import 'services/map_service.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'services/sync_service.dart';

class EwsApp extends StatefulWidget {
  const EwsApp({
    super.key,
    required this.storage,
    required this.database,
    required this.mapService,
  });

  final StorageService storage;
  final LocalDatabase database;
  final MapService mapService;

  @override
  State<EwsApp> createState() => _EwsAppState();
}

class _EwsAppState extends State<EwsApp> {
  late final NotificationService _notifications = NotificationService();
  late final ApiService _api = ApiService(widget.database);
  late final AuthService _auth = AuthService(widget.storage, _api);
  late final GpsService _gps = GpsService(widget.mapService);
  late final SyncService _sync = SyncService(_api, _notifications);
  final CameraService _camera = CameraService();

  @override
  void dispose() {
    _sync.dispose();
    _notifications.dispose();
    _api.dispose();
    _auth.dispose();
    _gps.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<StorageService>.value(value: widget.storage),
        ChangeNotifierProvider<MapService>.value(value: widget.mapService),
        Provider<CameraService>.value(value: _camera),
        ChangeNotifierProvider<NotificationService>.value(value: _notifications),
        ChangeNotifierProvider<ApiService>.value(value: _api),
        ChangeNotifierProvider<AuthService>.value(value: _auth),
        ChangeNotifierProvider<GpsService>.value(value: _gps),
        ChangeNotifierProvider<SyncService>.value(value: _sync),
      ],
      child: MaterialApp(
        title: '${AppText.appName} — ${AppText.appTitle}',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRoutes.generate,
        builder: (context, child) => Stack(
          fit: StackFit.expand,
          children: [child ?? const SizedBox.shrink(), const ToastHost()],
        ),
      ),
    );
  }
}
