import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/location_model.dart';
import 'map_service.dart';

/// GPS service for the Elephant Monitoring System.
///
/// The device GPS is NOT restricted to any particular forest range,
/// division, or district. It can capture the device's actual location
/// anywhere in Tamil Nadu or elsewhere.
///
/// Forest-range matching is kept only as optional additional information.
class GpsService extends ChangeNotifier {
  GpsService(this._map);

  final MapService _map;
  final math.Random _rng = math.Random();

  LocationModel? current;

  bool loading = false;

  String? error;

  /// Gets the current real device GPS location.
  Future<void> refresh() async {
    if (loading) return;

    loading = true;
    error = null;
    notifyListeners();

    try {
      // ----------------------------------------------------------
      // 1. Check whether location services are enabled
      // ----------------------------------------------------------
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception(
          'Location services are disabled. '
          'Please enable GPS/location services on your device.',
        );
      }

      // ----------------------------------------------------------
      // 2. Check location permission
      // ----------------------------------------------------------
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw Exception(
          'Location permission was denied.',
        );
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permission is permanently denied. '
          'Please enable it from device settings.',
        );
      }

      // ----------------------------------------------------------
      // 3. Get REAL device GPS
      // ----------------------------------------------------------
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      final double latitude = position.latitude;
      final double longitude = position.longitude;

      // ----------------------------------------------------------
      // 4. Try to identify the forest range.
      //
      // IMPORTANT:
      // This does NOT restrict GPS.
      //
      // If the location is outside the configured ranges,
      // rangeName will simply be null.
      // ----------------------------------------------------------
      final match = _map.match(
        latitude,
        longitude,
      );

      current = LocationModel(
        lat: latitude,
        lon: longitude,
        accuracy: position.accuracy,
        rangeName: match?.name,
        insideRange: match?.inside ?? false,
        distanceKm: match?.distanceKm ?? 0,
        timestamp: DateTime.now(),
        simulated: false,
      );

      error = null;
    } catch (e) {
      error = e.toString();

      // ----------------------------------------------------------
      // Do NOT automatically replace real GPS with a fake
      // location on Android/iOS.
      //
      // For web/desktop development we can use the fallback.
      // ----------------------------------------------------------
      if (kIsWeb) {
        _useWebFallback();
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Development fallback for Chrome/web when browser GPS is
  /// unavailable or permission is not granted.
  ///
  /// This fallback is ONLY for development.
  /// Android/iOS will use real GPS.
  void _useWebFallback() {
    try {
      // We deliberately do not depend on MockData here.
      //
      // Use a neutral development coordinate around Tamil Nadu.
      // This is clearly marked as simulated.
      const double defaultLatitude = 11.0168;
      const double defaultLongitude = 76.9558;

      final double latitude =
          defaultLatitude + (_rng.nextDouble() - 0.5) * 0.002;

      final double longitude =
          defaultLongitude + (_rng.nextDouble() - 0.5) * 0.002;

      final match = _map.match(
        latitude,
        longitude,
      );

      current = LocationModel(
        lat: latitude,
        lon: longitude,
        accuracy: 100.0,
        rangeName: match?.name,
        insideRange: match?.inside ?? false,
        distanceKm: match?.distanceKm ?? 0,
        timestamp: DateTime.now(),
        simulated: true,
      );
    } catch (_) {
      // If even the map matching fails, provide a basic simulated
      // location so the UI does not crash during development.
      current = LocationModel(
        lat: 11.0168,
        lon: 76.9558,
        accuracy: 100.0,
        rangeName: null,
        insideRange: false,
        distanceKm: 0,
        timestamp: DateTime.now(),
        simulated: true,
      );
    }
  }

  /// Clears the currently displayed location.
  void clear() {
    current = null;
    error = null;
    notifyListeners();
  }
}
