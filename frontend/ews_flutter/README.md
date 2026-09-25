# EWS Flutter app

Field app + Command Centre + Analytics for the Coimbatore Forest Division,
ported from `elephant_monitoring_system.html`.

## First-time setup

The `android/`, `ios/`, `web/` folders are empty placeholders. Generate them
inside this folder (keeps `lib/` and `pubspec.yaml` untouched):

```bash
cd frontend/ews_flutter
flutter create . --platforms=android,ios,web --project-name ews_flutter --org com.ews
flutter pub get
flutter run
```

### Permissions
**Android** — `android/app/src/main/AndroidManifest.xml`, inside `<manifest>`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.CAMERA"/>
```
**iOS** — `ios/Runner/Info.plist`:
```xml
<key>NSLocationWhenInUseUsageDescription</key><string>Needed to tag elephant sightings with your position.</string>
<key>NSCameraUsageDescription</key><string>Needed for photo evidence in reports.</string>
<key>NSPhotoLibraryUsageDescription</key><string>Needed to attach photos to reports.</string>
```

## Demo login (mock mode)
| Role | Username | Password |
|------|----------|----------|
| Field staff | `murugan` | `ews123` |
| Command centre | `vel` | `ews123` |

## Backend
`lib/core/constants/api_constants.dart` -> `useMock = true` runs everything on
in-memory data. Set it to `false` and point `baseUrl` at the FastAPI server
once it exists. `ApiService` already maps to these endpoints:
`POST /auth/login`, `GET/POST /alerts`, `PATCH /alerts/{id}/resolve`,
`GET/POST /reports`, `GET /staff`, `GET /ranges`.

Still mocked / TODO for the backend:
- `GET /analytics` (charts read `core/constants/analytics_mock.dart`)
- report photo upload (multipart)
- push notifications (hook into `NotificationService`)

## Structure notes
- State: `provider`. Services are `ChangeNotifier`s created in `app.dart`.
- `ApiService` also caches alerts/reports/staff/ranges.
- Offline: failed alerts/reports go to `database/local_database.dart` (sqflite)
  and `SyncService` retries every 30 s.
- GPS falls back to simulated fixes when no GPS (emulator/web).
- Range polygons: `assets/maps/forest_boundaries.json` (from the KMZ).
- Files added beyond your tree: `core/constants/mock_data.dart`,
  `core/constants/analytics_mock.dart`.
