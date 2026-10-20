
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'storage_service.dart';

class ApiService {
  static const String baseUrl =
      'https://smart-hospital-queue-management-system-production.up.railway.app';

  final http.Client _client;
  final StorageService _storageService;

  ApiService({
    http.Client? client,
    StorageService? storageService,
  })  : _client = client ?? http.Client(),
        _storageService = storageService ?? StorageService();

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (authenticated) {
      final token = await _storageService.getAccessToken();

      if (token != null && token.trim().isNotEmpty) {
        headers['Authorization'] = 'Bearer ${token.trim()}';
      }
    }

    final uri = Uri.parse('$baseUrl$path');

    try {
      late http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await _client
              .get(uri, headers: headers)
              .timeout(const Duration(seconds: 30));
          break;

        case 'POST':
          response = await _client
              .post(
                uri,
                headers: headers,
                body: jsonEncode(body ?? <String, dynamic>{}),
              )
              .timeout(const Duration(seconds: 30));
          break;

        case 'PATCH':
          response = await _client
              .patch(
                uri,
                headers: headers,
                body: jsonEncode(body ?? <String, dynamic>{}),
              )
              .timeout(const Duration(seconds: 30));
          break;

        default:
          throw ApiException(
            'Unsupported HTTP method: $method',
          );
      }

      Map<String, dynamic> result = {};

      if (response.body.trim().isNotEmpty) {
        final decoded = jsonDecode(response.body);

        if (decoded is Map) {
          result = Map<String, dynamic>.from(decoded);
        } else {
          throw const ApiException(
            'The server returned an unexpected response format.',
          );
        }
      }

      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          result['success'] == false) {
        final errorData = result['error'];

        String message = 'Request failed. Please try again.';

        if (errorData is Map &&
            errorData['message'] is String) {
          message = errorData['message'] as String;
        } else if (result['message'] is String) {
          message = result['message'] as String;
        }

        throw ApiException(
          message,
          statusCode: response.statusCode,
        );
      }

      return result;
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(
        'The server took too long to respond. Please try again.',
      );
    } on http.ClientException {
      throw const ApiException(
        'Unable to connect to the hospital server. '
        'Check your internet connection.',
      );
    } on FormatException {
      throw const ApiException(
        'The server returned invalid JSON.',
      );
    }
  }

  // Authentication

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) {
    return _request(
      'POST',
      '/api/auth/register',
      authenticated: false,
      body: {
        'name': name,
        'email': email,
        'password': password,
      },
    );
  }

  Future<Map<String, dynamic>> verifyRegistration({
    required String email,
    required String otp,
  }) async {
    final response = await _request(
      'POST',
      '/api/auth/register/verify',
      authenticated: false,
      body: {
        'email': email,
        'otp': otp,
      },
    );

    // Save a token if registration verification returns one.
    final token = _findAccessToken(response);

    if (token != null) {
      await _storageService.saveAccessToken(token);
    }

    return response;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) {
    return _request(
      'POST',
      '/api/auth/login',
      authenticated: false,
      body: {
        'email': email,
        'password': password,
      },
    );
  }

  Future<Map<String, dynamic>> verifyLogin({
    required String challengeId,
    required String otp,
  }) async {
    final response = await _request(
      'POST',
      '/api/auth/login/verify',
      authenticated: false,
      body: {
        'challengeId': challengeId,
        'otp': otp,
      },
    );

    final token = _findAccessToken(response);

    if (token == null) {
      throw const ApiException(
        'Login verification succeeded, but the server response '
        'did not contain an access token. Check the backend response.',
      );
    }

    await _storageService.saveAccessToken(token);

    return response;
  }

  Future<Map<String, dynamic>> loginWithGoogle({
    required String idToken,
  }) async {
    final response = await _request(
      'POST',
      '/api/auth/google',
      authenticated: false,
      body: {
        'idToken': idToken,
      },
    );

    final token = _findAccessToken(response);

    if (token == null) {
      throw const ApiException(
        'Google login response did not contain an access token.',
      );
    }

    await _storageService.saveAccessToken(token);

    return response;
  }

  Future<Map<String, dynamic>> linkGoogle({
    required String idToken,
  }) {
    return _request(
      'POST',
      '/api/auth/google/link',
      body: {
        'idToken': idToken,
      },
    );
  }

  Future<Map<String, dynamic>> getCurrentUser() {
    return _request(
      'GET',
      '/api/auth/me',
    );
  }

  Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) {
    return _request(
      'POST',
      '/api/auth/forgot-password',
      authenticated: false,
      body: {
        'email': email,
      },
    );
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final response = await _request(
      'POST',
      '/api/auth/reset-password',
      authenticated: false,
      body: {
        'email': email,
        'otp': otp,
        'newPassword': newPassword,
      },
    );

    await _storageService.deleteAccessToken();

    return response;
  }

  Future<Map<String, dynamic>> checkHealth() {
    return _request(
      'GET',
      '/api/health',
      authenticated: false,
    );
  }

  // Generic API methods

  Future<Map<String, dynamic>> get(
    String path, {
    bool authenticated = true,
  }) {
    return _request(
      'GET',
      path,
      authenticated: authenticated,
    );
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) {
    return _request(
      'POST',
      path,
      body: body,
      authenticated: authenticated,
    );
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) {
    return _request(
      'PATCH',
      path,
      body: body,
      authenticated: authenticated,
    );
  }

  // Find access tokens in common nested response formats.

  String? _findAccessToken(dynamic value) {
    if (value is! Map) return null;

    for (final key in [
      'accessToken',
      'access_token',
      'token',
    ]) {
      final candidate = value[key];

      if (candidate is String &&
          candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }

    for (final entry in value.entries) {
      if (entry.value is Map) {
        final token = _findAccessToken(entry.value);

        if (token != null) return token;
      }
    }

    return null;
  }

  Future<void> logout() async {
    await _storageService.deleteAccessToken();
  }

  void dispose() {
    _client.close();
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(
    this.message, {
    this.statusCode,
  });

  @override
  String toString() => message;
}
