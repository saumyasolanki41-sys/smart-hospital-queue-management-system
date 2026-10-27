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
          throw const ApiException(
            'Unable to process your request. Please try again.',
          );
      }

      Map<String, dynamic> result = {};

      if (response.body.trim().isNotEmpty) {
        final decoded = jsonDecode(response.body);

        if (decoded is Map) {
          result = Map<String, dynamic>.from(decoded);
        } else {
          throw const ApiException(
            'The server returned an unexpected response. Please try again.',
          );
        }
      }

      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          result['success'] == false) {
        final backendMessage = _extractErrorMessage(result);
        final backendCode = _extractErrorCode(result);

        throw ApiException(
          backendMessage ?? _getSafeErrorMessage(response.statusCode),
          statusCode: response.statusCode,
          code: backendCode,
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
        'The server returned an invalid response. Please try again.',
      );
    } catch (e) {
      debugPrint('API request failed: $e');

      throw const ApiException(
        'Something went wrong. Please try again.',
      );
    }
  }

  String? _extractErrorMessage(Map<String, dynamic> result) {
    final error = result['error'];

    final candidates = <dynamic>[
      result['message'],
      result['details'],
      error is Map ? error['message'] : null,
      error is String ? error : null,
    ];

    for (final candidate in candidates) {
      if (candidate is String && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }

    return null;
  }

  String? _extractErrorCode(Map<String, dynamic> result) {
    final error = result['error'];

    final candidates = <dynamic>[
      result['code'],
      error is Map ? error['code'] : null,
    ];

    for (final candidate in candidates) {
      if (candidate is String && candidate.trim().isNotEmpty) {
        return candidate.trim();
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
        return 'This action conflicts with the current information.';

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
  final String? code;

  const ApiException(
    this.message, {
    this.statusCode,
    this.code,
  });

  @override
  String toString() => message;
}
