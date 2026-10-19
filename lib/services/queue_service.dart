import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/queue_status.dart';

class QueueService {
  static const String baseUrl =
      'https://smart-hospital-queue-management-system-production.up.railway.app';

  final http.Client _client;
  final Future<String?> Function()? tokenProvider;

  QueueService({
    http.Client? client,
    this.tokenProvider,
  }) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> checkHealth() {
    return _get('/api/health', auth: false);
  }

  Future<Map<String, dynamic>> getDepartments() {
    return _get('/api/departments?page=1&limit=20', auth: false);
  }

  Future<Map<String, dynamic>> getMyQueueTokens() {
    return _get('/api/queue/tokens/mine');
  }

  Future<QueueStatus> fetchStatus(String tokenId) async {
    final decoded = await _get(
      '/api/queue/tokens/${Uri.encodeComponent(tokenId)}',
    );

    dynamic data = decoded['data'];

    if (data is Map<String, dynamic> && data['token'] is Map) {
      data = data['token'];
    }

    if (data is! Map<String, dynamic>) {
      throw QueueException('Unexpected queue status response.');
    }

    return QueueStatus.fromJson(data);
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    bool auth = true,
  }) async {
    try {
      final headers = <String, String>{
        'Accept': 'application/json',
      };

      if (auth) {
        final token = tokenProvider == null
            ? null
            : await tokenProvider!();

        if (token == null || token.isEmpty) {
          throw QueueException(
            'Session expired. Please log in again.',
            unauthorized: true,
          );
        }

        headers['Authorization'] = 'Bearer $token';
      }

      final response = await _client
          .get(
            Uri.parse('$baseUrl$path'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 20));

      final dynamic decoded;

      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        throw QueueException('The server returned invalid JSON.');
      }

      if (decoded is! Map<String, dynamic>) {
        throw QueueException('Unexpected server response.');
      }

      if (response.statusCode == 401) {
        throw QueueException(
          'Session expired. Please log in again.',
          unauthorized: true,
        );
      }

      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          decoded['success'] == false) {
        final error = decoded['error'];
        final message = error is Map
            ? error['message']?.toString()
            : null;

        throw QueueException(
          message ?? 'Request failed (${response.statusCode}).',
        );
      }

      return decoded;
    } on QueueException {
      rethrow;
    } on TimeoutException {
      throw QueueException(
        'The server is taking too long to respond.',
      );
    } on SocketException {
      throw QueueException('No internet connection.');
    } on http.ClientException {
      throw QueueException('Unable to connect to the server.');
    } catch (_) {
      throw QueueException(
        'Unable to connect. Check your internet connection.',
      );
    }
  }

  void dispose() {
    _client.close();
  }
}

class QueueException implements Exception {
  final String message;
  final bool unauthorized;

  QueueException(
    this.message, {
    this.unauthorized = false,
  });

  @override
  String toString() => message;
}
