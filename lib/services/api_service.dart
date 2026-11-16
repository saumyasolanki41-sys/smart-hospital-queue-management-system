import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
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
    bool debugBackendErrors = false,
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
      late final http.Response response;

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
          throw const ApiException(
            'Unable to complete your request. Please try again.',
          );
      }

      Map<String, dynamic> result = <String, dynamic>{};

      if (response.body.trim().isNotEmpty) {
        dynamic decoded;

        try {
          decoded = jsonDecode(response.body);
        } on FormatException {
          if (debugBackendErrors) {
            debugPrint(
              '[API] Server returned invalid JSON '
              'for ${method.toUpperCase()} $path '
              '(HTTP ${response.statusCode}).',
            );
          }

          throw ApiException(
            _getSafeErrorMessage(response.statusCode),
            statusCode: response.statusCode,
          );
        }

        if (decoded is Map) {
          result = Map<String, dynamic>.from(decoded);
        } else {
          if (debugBackendErrors) {
            debugPrint(
              '[API] Unexpected response format for '
              '${method.toUpperCase()} $path '
              '(HTTP ${response.statusCode}).',
            );
          }

          throw ApiException(
            _getSafeErrorMessage(response.statusCode),
            statusCode: response.statusCode,
          );
        }
      }

      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          result['success'] == false) {
        final backendCode = _extractErrorCode(result);

        if (debugBackendErrors) {
          debugPrint(
            '[API] Request failed: ${method.toUpperCase()} $path',
          );
          debugPrint('HTTP status: ${response.statusCode}');
          debugPrint('Backend code: ${backendCode ?? "Not provided"}');
        }

        throw ApiException(
          _getSafeErrorMessage(response.statusCode),
          statusCode: response.statusCode,
          code: backendCode,
        );
      }

      return result;
    } on ApiException {
      rethrow;
    } on TimeoutException {
      if (debugBackendErrors) {
        debugPrint(
          '[API] Request timed out: ${method.toUpperCase()} $path',
        );
      }

      throw const ApiException(
        'The request took too long. Please try again.',
      );
    } on http.ClientException {
      if (debugBackendErrors) {
        debugPrint(
          '[API] Connection failed: ${method.toUpperCase()} $path',
        );
      }

      throw const ApiException(
        'Unable to connect. Please check your internet connection '
        'and try again.',
      );
    } on FormatException {
      if (debugBackendErrors) {
        debugPrint(
          '[API] Invalid response format: ${method.toUpperCase()} $path',
        );
      }

      throw const ApiException(
        'Something went wrong. Please try again.',
      );
    } catch (_) {
      if (debugBackendErrors) {
        debugPrint(
          '[API] Unexpected request failure: '
          '${method.toUpperCase()} $path',
        );
      }

      throw const ApiException(
        'Something went wrong. Please try again.',
      );
    }
  }

  String? _extractErrorCode(Map<String, dynamic> result) {
    const codeKeys = <String>[
      'code',
      'errorCode',
      'error_code',
    ];

    for (final key in codeKeys) {
      final value = result[key];

      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    const nestedKeys = <String>[
      'error',
      'data',
      'details',
      'response',
    ];

    for (final key in nestedKeys) {
      final value = result[key];

      if (value is Map) {
        final nestedCode = _extractErrorCode(
          Map<String, dynamic>.from(value),
        );

        if (nestedCode != null) {
          return nestedCode;
        }
      }
    }

    return null;
  }

  String _getSafeErrorMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Invalid request. Please check your details and try again.';
      case 401:
        return 'Your session may have expired. Please log in again.';
      case 403:
        return 'You do not have permission to perform this action.';
      case 404:
        return 'The requested information could not be found.';
      case 408:
        return 'The request timed out. Please try again.';
      case 409:
        return 'This action conflicts with your current information.';
      case 422:
        return 'Some details are invalid. Please check and try again.';
      case 429:
        return 'Too many requests. Please wait and try again.';
      case 500:
      case 501:
      case 502:
      case 503:
      case 504:
        return 'The hospital server is temporarily unavailable. '
            'Please try again later.';
      default:
        return 'Unable to complete your request. Please try again.';
    }
  }

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
        'Unable to complete login verification. Please try again.',
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
        'Unable to complete Google login. Please try again.',
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
    return _request('GET', '/api/auth/me');
  }

  Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) {
    return _request(
      'POST',
      '/api/auth/forgot-password',
      authenticated: false,
      body: {'email': email},
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
    bool debugBackendErrors = false,
  }) {
    return _request(
      'POST',
      path,
      body: body,
      authenticated: authenticated,
      debugBackendErrors: debugBackendErrors,
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

  String? _findAccessToken(dynamic value) {
    if (value is! Map) return null;

    for (final key in [
      'accessToken',
      'access_token',
      'token',
    ]) {
      final candidate = value[key];

      if (candidate is String && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }

    for (final entry in value.entries) {
      if (entry.value is Map) {
        final token = _findAccessToken(entry.value);

        if (token != null) {
          return token;
        }
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
  final String? code;

  const ApiException(
    this.message, {
    this.statusCode,
    this.code,
  });

  @override
  String toString() => message;
}
