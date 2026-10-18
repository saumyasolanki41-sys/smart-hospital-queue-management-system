
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      'https://smart-hospital-queue-management-system-production.up.railway.app';

  final http.Client _client;

  ApiService({http.Client? client})
      : _client = client ?? http.Client();

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Map<String, dynamic> _decodeResponse(http.Response response) {
    dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw ApiException(
        'The server returned an invalid response.',
        response.statusCode,
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw ApiException(
        'Unexpected server response.',
        response.statusCode,
      );
    }

    final isSuccessfulStatus =
        response.statusCode >= 200 && response.statusCode < 300;

    if (!isSuccessfulStatus || decoded['success'] == false) {
      final error = decoded['error'];

      final message = error is Map
          ? error['message']?.toString()
          : null;

      final code = error is Map
          ? error['code']?.toString()
          : null;

      throw ApiException(
        message ?? 'Request failed. Please try again.',
        response.statusCode,
        code,
      );
    }

    return decoded;
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _client
          .post(
            _uri(path),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));

      return _decodeResponse(response);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException(
        'The request timed out. Please try again.',
      );
    } catch (_) {
      throw ApiException(
        'Unable to connect to the server. Check your internet connection.',
      );
    }
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    String? token,
  }) async {
    try {
      final headers = <String, String>{
        'Accept': 'application/json',
      };

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await _client
          .get(
            _uri(path),
            headers: headers,
          )
          .timeout(const Duration(seconds: 20));

      return _decodeResponse(response);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException(
        'The request timed out. Please try again.',
      );
    } catch (_) {
      throw ApiException(
        'Unable to connect to the server. Check your internet connection.',
      );
    }
  }

  // Check backend health.
  Future<Map<String, dynamic>> checkHealth() {
    return _get('/api/health');
  }

  // Request registration OTP.
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) {
    return _post('/api/auth/register', {
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
    });
  }

  // Verify registration OTP.
  Future<Map<String, dynamic>> verifyRegistration({
    required String email,
    required String otp,
  }) {
    return _post('/api/auth/register/verify', {
      'email': email.trim().toLowerCase(),
      'otp': otp.trim(),
    });
  }

  // Check password and request login OTP.
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) {
    return _post('/api/auth/login', {
      'email': email.trim().toLowerCase(),
      'password': password,
    });
  }

  // Verify login OTP and receive an access token.
  Future<Map<String, dynamic>> verifyLogin({
    required String challengeId,
    required String otp,
  }) {
    return _post('/api/auth/login/verify', {
      'challengeId': challengeId,
      'otp': otp.trim(),
    });
  }

  // Sign in using a Google ID token.
  Future<Map<String, dynamic>> loginWithGoogle({
    required String idToken,
  }) {
    return _post('/api/auth/google', {
      'idToken': idToken,
    });
  }

  // Get the currently authenticated user.
  Future<Map<String, dynamic>> getCurrentUser({
    required String accessToken,
  }) {
    return _get(
      '/api/auth/me',
      token: accessToken,
    );
  }

  // Request a password-reset OTP.
  Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) {
    return _post('/api/auth/forgot-password', {
      'email': email.trim().toLowerCase(),
    });
  }

  // Reset password using the OTP.
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) {
    return _post('/api/auth/reset-password', {
      'email': email.trim().toLowerCase(),
      'otp': otp.trim(),
      'newPassword': newPassword,
    });
  }

  void dispose() {
    _client.close();
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;

  ApiException(
    this.message, [
    this.statusCode,
    this.code,
  ]);

  @override
  String toString() => message;
}
