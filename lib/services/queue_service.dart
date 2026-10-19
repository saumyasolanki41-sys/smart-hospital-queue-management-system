// lib/services/queue_service.dart
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

  QueueService({http.Client? client, this.tokenProvider})
      : _client = client ?? http.Client();

  Future<Map<String, dynamic>> checkHealth() async {
    final decoded = await _get('/api/health', auth: false);
    return decoded;
  }

  Future<QueueStatus> fetchStatus(String tokenId) async {
    final decoded = await _get('/api/queue/status/$tokenId');
    final data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      throw QueueException('Unexpected server response.');
    }
    return QueueStatus.fromJson(data);
  }

  Future<Map<String, dynamic>> _get(String path, {bool auth = true}) async {
    try {
      final headers = <String, String>{'Accept': 'application/json'};
      if (auth) {
        final token = tokenProvider == null ? null : await tokenProvider!();
        if (token == null || token.isEmpty) {
          throw QueueException('Session expired. Please log in again.',
              unauthorized: true);
        }
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await _client
          .get(Uri.parse('$baseUrl$path'), headers: headers)
          .timeout(const Duration(seconds: 20));

      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw QueueException('Unexpected server response.');
      }

      if (response.statusCode == 401) {
        throw QueueException('Session expired. Please log in again.',
            unauthorized: true);
      }
      if (response.statusCode != 200 || decoded['success'] == false) {
        final error = decoded['error'];
        final message =
            error is Map<String, dynamic> ? error['message']?.toString() : null;
        throw QueueException(message ?? 'The backend is currently unavailable.');
      }
      return decoded;
    } on QueueException {
      rethrow;
    } on FormatException {
      throw QueueException('The server returned invalid JSON.');
    } on TimeoutException {
      throw QueueException('The server is taking too long. Retrying...');
    } on SocketException {
      throw QueueException('No internet connection.');
    } catch (_) {
      throw QueueException('Unable to connect. Check your internet connection.');
    }
  }

  void dispose() => _client.close();
}

class QueueException implements Exception {
  final String message;
  final bool unauthorized;

  QueueException(this.message, {this.unauthorized = false});

  @override
  String toString() => message;
}