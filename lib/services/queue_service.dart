
import 'dart:convert';

import 'package:http/http.dart' as http;

class QueueService {
  static const String baseUrl =
      'https://smart-hospital-queue-management-system-production.up.railway.app';

  final http.Client _client;

  QueueService({http.Client? client})
      : _client = client ?? http.Client();

  Future<Map<String, dynamic>> checkHealth() async {
    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl/api/health'),
            headers: const {
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 20));

      final dynamic decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw QueueException('Unexpected server response.');
      }

      if (response.statusCode != 200 ||
          decoded['success'] == false) {
        final error = decoded['error'];
        final message = error is Map<String, dynamic>
            ? error['message']?.toString()
            : null;

        throw QueueException(
          message ?? 'The backend is currently unavailable.',
        );
      }

      return decoded;
    } on QueueException {
      rethrow;
    } on FormatException {
      throw QueueException('The server returned invalid JSON.');
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

  QueueException(this.message);

  @override
  String toString() => message;
}
