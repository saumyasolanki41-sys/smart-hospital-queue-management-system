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

      final message =
          error is Map ? error['message']?.toString() : null;

      final code = error is Map ? error['code']?.toString() : null;

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
    Map<String, dynamic> body, {
    String? token,
  }) async {
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await _client
          .post(
            _uri(path),
            headers: headers,
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

 

  Future<Map<String, dynamic>> checkHealth() {
    return _get('/api/health');
  }

  
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

  Future<Map<String, dynamic>> verifyRegistration({
    required String email,
    required String otp,
  }) {
    return _post('/api/auth/register/verify', {
      'email': email.trim().toLowerCase(),
      'otp': otp.trim(),
    });
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) {
    return _post('/api/auth/login', {
      'email': email.trim().toLowerCase(),
      'password': password,
    });
  }

  Future<Map<String, dynamic>> verifyLogin({
    required String challengeId,
    required String otp,
  }) {
    return _post('/api/auth/login/verify', {
      'challengeId': challengeId,
      'otp': otp.trim(),
    });
  }

  Future<Map<String, dynamic>> loginWithGoogle({
    required String idToken,
  }) {
    return _post('/api/auth/google', {
      'idToken': idToken,
    });
  }

  Future<Map<String, dynamic>> getCurrentUser({
    required String accessToken,
  }) {
    return _get(
      '/api/auth/me',
      token: accessToken,
    );
  }

  Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) {
    return _post('/api/auth/forgot-password', {
      'email': email.trim().toLowerCase(),
    });
  }

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

  Future<Map<String, dynamic>> getDepartments({
    int page = 1,
    int limit = 20,
  }) {
    return _get(
      '/api/departments?page=$page&limit=$limit',
    );
  }


  Future<Map<String, dynamic>> getDoctors({
    String? departmentId,
    bool? isAvailable,
    int page = 1,
    int limit = 20,
  }) {
    final queryParameters = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      if (departmentId != null && departmentId.isNotEmpty)
        'departmentId': departmentId,
      if (isAvailable != null)
        'isAvailable': isAvailable.toString(),
    };

    final uri = _uri('/api/doctors').replace(
      queryParameters: queryParameters,
    );

    return _getUri(uri);
  }

  Future<Map<String, dynamic>> _getUri(
    Uri uri, {
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
          .get(uri, headers: headers)
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

  Future<Map<String, dynamic>> bookQueueToken({
    required String doctorId,
    required String accessToken,
  }) {
    if (accessToken.trim().isEmpty) {
      throw ApiException(
        'Please log in before booking a token.',
      );
    }

    if (doctorId.trim().isEmpty) {
      throw ApiException(
        'Please select a doctor.',
      );
    }

    return _post(
      '/api/queue/tokens',
      {
        'doctorId': doctorId.trim(),
      },
      token: accessToken,
    );
  }

  Future<Map<String, dynamic>> getMyQueueTokens({
    required String accessToken,
  }) {
    if (accessToken.trim().isEmpty) {
      throw ApiException('Please log in first.');
    }

    return _get(
      '/api/queue/tokens/mine',
      token: accessToken,
    );
  }

  Future<Map<String, dynamic>> getQueueTokenStatus({
    required String tokenId,
    required String accessToken,
  }) {
    if (accessToken.trim().isEmpty) {
      throw ApiException('Please log in first.');
    }

    if (tokenId.trim().isEmpty) {
      throw ApiException('Token ID is missing.');
    }

    final encodedTokenId = Uri.encodeComponent(tokenId.trim());

    return _get(
      '/api/queue/tokens/$encodedTokenId',
      token: accessToken,
    );
  }

  Future<Map<String, dynamic>> cancelQueueToken({
    required String tokenId,
    required String accessToken,
  }) {
    if (accessToken.trim().isEmpty) {
      throw ApiException('Please log in first.');
    }

    if (tokenId.trim().isEmpty) {
      throw ApiException('Token ID is missing.');
    }

    final encodedTokenId = Uri.encodeComponent(tokenId.trim());

    return _patch(
      '/api/queue/tokens/$encodedTokenId/cancel',
      token: accessToken,
    );
  }

  Future<Map<String, dynamic>> _patch(
    String path, {
    String? token,
    Map<String, dynamic>? body,
  }) async {
    try {
      final headers = <String, String>{
        'Accept': 'application/json',
        if (body != null) 'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty)
          'Authorization': 'Bearer $token',
      };

      final response = await _client
          .patch(
            _uri(path),
            headers: headers,
            body: body == null ? null : jsonEncode(body),
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
