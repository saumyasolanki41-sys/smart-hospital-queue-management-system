
import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class AuthController extends ChangeNotifier {
  final AuthService _authService;

  AuthController({AuthService? authService})
      : _authService = authService ?? AuthService();

  UserModel? _user;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;
  bool _isOtpPending = false;

  String? _registrationName;
  String? _registrationEmail;
  String? _registrationPassword;

  String? _loginEmail;
  String? _loginPassword;

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

  // Update profile using one Full Name field.
  bool updateProfile({
    required String fullName,
    required String age,
    required String gender,
  }) {
    if (_user == null) {
      _setError('Please log in before editing your profile.');
      return false;
    }

    final trimmedFullName = fullName.trim();
    final parsedAge = int.tryParse(age.trim());
    final trimmedGender = gender.trim();

    if (trimmedFullName.isEmpty) {
      _setError('Please enter your full name.');
      return false;
    }

    if (parsedAge == null || parsedAge < 1 || parsedAge > 120) {
      _setError('Please enter a valid age between 1 and 120.');
      return false;
    }

    if (trimmedGender.isEmpty) {
      _setError('Please select your gender.');
      return false;
    }

    _user = _user!.copyWith(
      name: trimmedFullName,
      age: parsedAge,
      gender: trimmedGender,
    );

    _error = null;
    notifyListeners();
    return true;
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

      _registrationName = name;
      _registrationEmail = email;
      _registrationPassword = password;

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

      _registrationName = null;
      _registrationEmail = null;
      _registrationPassword = null;

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

      _loginEmail = email;
      _loginPassword = password;

      _isOtpPending = true;
      return true;
    } catch (error) {
      _setError(_messageFrom(error));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resendOtp({
    required bool isRegistration,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      if (isRegistration) {
        final name = _registrationName;
        final email = _registrationEmail;
        final password = _registrationPassword;

        if (name == null || email == null || password == null) {
          throw const ApiException(
            'Registration details are no longer available. '
            'Please return to registration and try again.',
          );
        }

        await _authService.resendRegistrationOtp(
          name: name,
          email: email,
          password: password,
        );
      } else {
        final email = _loginEmail;
        final password = _loginPassword;

        if (email == null || password == null) {
          throw const ApiException(
            'Your login details are no longer available. '
            'Please return to login and try again.',
          );
        }

        await _authService.resendLoginOtp(
          email: email,
          password: password,
        );
      }

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

      _loginEmail = null;
      _loginPassword = null;
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

      _loginEmail = null;
      _loginPassword = null;
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

      _registrationName = null;
      _registrationEmail = null;
      _registrationPassword = null;

      _loginEmail = null;
      _loginPassword = null;
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
    debugPrint('Authentication error: $error');

    if (error is ApiException) {
      return error.message;
    }

    return 'Something went wrong. Please try again.';
  }
}
