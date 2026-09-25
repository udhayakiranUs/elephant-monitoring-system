import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';

/// Small wrapper over SharedPreferences (session + simple prefs).
class StorageService {
  SharedPreferences? _prefs;

  static const _kUser = 'session_user';
  static const _kToken = 'session_token';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> saveSession(UserModel user, String token) async {
    await _prefs?.setString(_kUser, jsonEncode(user.toJson()));
    await _prefs?.setString(_kToken, token);
  }

  UserModel? readUser() {
    final raw = _prefs?.getString(_kUser);
    if (raw == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  String? readToken() => _prefs?.getString(_kToken);

  Future<void> clearSession() async {
    await _prefs?.remove(_kUser);
    await _prefs?.remove(_kToken);
  }

  Future<void> setString(String key, String value) async => _prefs?.setString(key, value);
  String? getString(String key) => _prefs?.getString(key);
}
