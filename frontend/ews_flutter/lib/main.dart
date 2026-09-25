import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'database/local_database.dart';
import 'services/map_service.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

  final storage = StorageService();
  await storage.init();
  final database = LocalDatabase();
  await database.init();
  final mapService = MapService(storage);
  await mapService.load();

  runApp(EwsApp(storage: storage, database: database, mapService: mapService));
}
