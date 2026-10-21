
import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService;

  AuthViewModel({AuthService? authService})
      : _authService = authService ?? AuthService();

  UserModel? _user;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;
  bool _isOtpPending = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isLoggedIn => _user != null;
  String? get error => _error;
  bool get isOtpPending => _isOtpPending;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _error = message;
    notifyListeners();
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    _setLoading(true);

    try {
      _user = await _authService.getCurrentUser();
    } catch (error) {
      _error = _messageFrom(error);
    } finally {
      _isInitialized = true;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      await _authService.register(
        name: name,
        email: email,
        password: password,
      );

      _isOtpPending = true;
      return true;
    } catch (error) {
      _setError(_messageFrom(error));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> verifyRegistration({
    required String email,
    required String otp,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      await _authService.verifyRegistration(
        email: email,
        otp: otp,
      );

      _isOtpPending = false;
      return true;
    } catch (error) {
      _setError(_messageFrom(error));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      await _authService.login(
        email: email,
        password: password,
      );

      _isOtpPending = true;
      return true;
    } catch (error) {
      _setError(_messageFrom(error));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> verifyLogin({
    required String otp,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      _user = await _authService.verifyLogin(otp: otp);
      _isOtpPending = false;
      return true;
    } catch (error) {
      _setError(_messageFrom(error));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> loginWithGoogle({
    required String idToken,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      _user = await _authService.loginWithGoogle(
        idToken: idToken,
      );

      _isOtpPending = false;
      return true;
    } catch (error) {
      _setError(_messageFrom(error));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    _error = null;

    try {
      await _authService.logout();
      _user = null;
      _isOtpPending = false;
    } catch (error) {
      _setError(_messageFrom(error));
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _messageFrom(Object error) {
    if (error is ApiException) {
      return error.message;
    }

    return 'Something went wrong. Please try again.';
  }
}
