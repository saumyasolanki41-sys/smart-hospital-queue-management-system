import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService;

  AuthViewModel({
    AuthService? authService,
  }) : _authService = authService ?? AuthService();

  UserModel? _user;
  String? _challengeId;
  String? _pendingEmail;
  String? _errorMessage;

  bool _isLoading = false;
  bool _isAuthenticated = false;

  UserModel? get user => _user;
  String? get challengeId => _challengeId;
  String? get pendingEmail => _pendingEmail;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void _setError(Object error) {
    _errorMessage = error is ApiException
        ? error.message
        : 'Something went wrong. Please try again.';
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.register(
        name: name,
        email: email,
        password: password,
      );

      _pendingEmail = email.trim().toLowerCase();
      _challengeId = null;

      return true;
    } catch (error) {
      _setError(error);
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
    _clearError();

    try {
      await _authService.verifyRegistration(
        email: email,
        otp: otp,
      );

      _pendingEmail = null;
      return true;
    } catch (error) {
      _setError(error);
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
    _clearError();

    _challengeId = null;
    _pendingEmail = null;
    _user = null;
    _isAuthenticated = false;

    try {
      final challenge = await _authService.login(
        email: email,
        password: password,
      );

      _challengeId = challenge;
      _pendingEmail = email.trim().toLowerCase();

      return true;
    } catch (error) {
      _setError(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> verifyLogin({
    required String otp,
  }) async {
    final challenge = _challengeId;

    if (challenge == null || challenge.isEmpty) {
      _errorMessage =
          'Please log in again to request a new OTP.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final user = await _authService.verifyLogin(
        challengeId: challenge,
        otp: otp,
      );

      _user = user;
      _isAuthenticated = true;
      _challengeId = null;
      _pendingEmail = null;

      return true;
    } catch (error) {
      _setError(error);

      _user = null;
      _isAuthenticated = false;

      try {
        await _authService.logout();
      } catch (_) {
        // Preserve the original authentication error.
      }

      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> loginWithGoogle({
    required String idToken,
  }) async {
    _setLoading(true);
    _clearError();

    _user = null;
    _isAuthenticated = false;

    try {
      final user = await _authService.loginWithGoogle(
        idToken: idToken,
      );

      _user = user;
      _isAuthenticated = true;
      _challengeId = null;
      _pendingEmail = null;

      return true;
    } catch (error) {
      _setError(error);

      _user = null;
      _isAuthenticated = false;

      try {
        await _authService.logout();
      } catch (_) {
        // Preserve the original authentication error.
      }

      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> restoreSession() async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authService.restoreSession();

      _user = user;
      _isAuthenticated = true;

      return true;
    } catch (_) {
      _user = null;
      _isAuthenticated = false;

      try {
        await _authService.logout();
      } catch (_) {
        // Session cleanup failed.
      }

      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> forgotPassword({
    required String email,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.forgotPassword(email: email);

      _pendingEmail = email.trim().toLowerCase();
      return true;
    } catch (error) {
      _setError(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.resetPassword(
        email: email,
        otp: otp,
        newPassword: newPassword,
      );

      _user = null;
      _isAuthenticated = false;
      _challengeId = null;
      _pendingEmail = null;

      return true;
    } catch (error) {
      _setError(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.logout();
    } catch (error) {
      _setError(error);
    } finally {
      _user = null;
      _challengeId = null;
      _pendingEmail = null;
      _isAuthenticated = false;

      _setLoading(false);
    }
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }
}
