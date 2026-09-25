import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService extends ChangeNotifier {
  AuthService(this._storage, this._api);

  final StorageService _storage;
  final ApiService _api;

  UserModel? user;

  bool get isLoggedIn => user != null;

  /// Restores a saved session.
  /// The saved token is placed back into ApiService so that
  /// all future API requests contain the Authorization header.
  Future<bool> restoreSession() async {
    final savedUser = _storage.readUser();
    final savedToken = _storage.readToken();

    if (savedUser == null || savedToken == null || savedToken.trim().isEmpty) {
      return false;
    }

    user = savedUser;
    _api.setToken(savedToken);
    return true;
  }

  /// Logs the user into the FastAPI backend.
  ///
  /// Returns:
  ///   null  -> login successful
  ///   String -> error message
  Future<String?> login(String username, String password) async {
    try {
      final result = await _api.login(
        username.trim(),
        password,
      );

      // Save the logged-in user in memory.
      user = result.user;

      // IMPORTANT:
      // Put the JWT token into ApiService BEFORE making
      // any authenticated API requests.
      _api.setToken(result.token);

      // Persist the session for future app launches.
      await _storage.saveSession(
        result.user,
        result.token,
      );

      notifyListeners();

      return null;
    } on ApiException catch (e) {
      debugPrint(
        'Login API error: ${e.message} '
        '(status: ${e.statusCode})',
      );

      return e.message;
    } catch (e, st) {
      debugPrint('LOGIN UNEXPECTED ERROR: $e');
      debugPrintStack(stackTrace: st);
      return 'Login failed: $e';
    }
  }

  /// Logs the user out and removes the saved session.
  Future<void> logout() async {
    user = null;

    // Remove token from ApiService so future requests
    // are not authenticated with an old token.
    _api.setToken(null);

    await _storage.clearSession();

    notifyListeners();
  }
}
