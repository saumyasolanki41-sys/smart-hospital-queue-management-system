import '../models/token_model.dart';
import 'api_service.dart';

class QueueService {
  final ApiService _apiService;

  QueueService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  Future<TokenModel> bookToken({
    required String doctorId,
  }) async {
    if (doctorId.trim().isEmpty) {
      throw const ApiException('Please select a doctor.');
    }

    try {
      final response = await _apiService.post(
        '/api/queue/tokens',
        body: {'doctorId': doctorId.trim()},
        authenticated: true,
      );

      final data = response['data'];

      if (data is! Map) {
        throw const ApiException(
          'Unable to book your token. Please try again.',
        );
      }

      final tokenData = data['token'] ?? data;

      if (tokenData is! Map) {
        throw const ApiException(
          'Unable to book your token. Please try again.',
        );
      }

      final tokenJson = Map<String, dynamic>.from(tokenData);

      _copyQueueFields(data, tokenJson);

      return TokenModel.fromJson(tokenJson);
    } catch (_) {
      throw const ApiException(
        'Unable to book your token. Please try again.',
      );
    }
  }

  Future<List<TokenModel>> getMyTokens() async {
    try {
      final response = await _apiService.get(
        '/api/queue/tokens/mine',
        authenticated: true,
      );

      final data = response['data'];
      dynamic tokens;

      if (data is List) {
        tokens = data;
      } else if (data is Map) {
        tokens = data['tokens'] ??
            data['items'] ??
            data['results'];

        // Handle another common nested response structure.
        if (tokens == null && data['data'] is List) {
          tokens = data['data'];
        }
      }

      tokens ??= response['tokens'];

      if (tokens is! List) {
        throw const ApiException(
          'Unable to load your tokens. Please try again.',
        );
      }

      return tokens.whereType<Map>().map((token) {
        final tokenJson = Map<String, dynamic>.from(token);

        return TokenModel.fromJson(tokenJson);
      }).toList();
    } catch (_) {
      throw const ApiException(
        'Unable to load your tokens. Please try again.',
      );
    }
  }

  Future<TokenModel> getTokenStatus(String tokenId) async {
    final id = tokenId.trim();

    if (id.isEmpty) {
      throw const ApiException(
        'Unable to load token status. Please try again.',
      );
    }

    try {
      final response = await _apiService.get(
        '/api/queue/tokens/${Uri.encodeComponent(id)}',
        authenticated: true,
      );

      final data = response['data'];

      if (data is! Map) {
        throw const ApiException(
          'Unable to load token status. Please try again.',
        );
      }

      final tokenData = data['token'] ?? data;

      if (tokenData is! Map) {
        throw const ApiException(
          'Unable to load token status. Please try again.',
        );
      }

      final tokenJson = Map<String, dynamic>.from(tokenData);

      // Copy live queue values from the response into the token.
      _copyQueueFields(data, tokenJson);

      // Also support queue details nested inside a queue object.
      final queueData = data['queue'];

      if (queueData is Map) {
        _copyQueueFields(queueData, tokenJson);
      }

      // Keep prediction data available to TokenModel.
      final predictionData =
          data['prediction'] ??
          (queueData is Map ? queueData['prediction'] : null);

      if (predictionData is Map) {
        tokenJson['prediction'] =
            Map<String, dynamic>.from(predictionData);
      }

      return TokenModel.fromJson(tokenJson);
    } catch (_) {
      throw const ApiException(
        'Unable to load token status. Please try again.',
      );
    }
  }

  void _copyQueueFields(
    Map source,
    Map<String, dynamic> tokenJson,
  ) {
    const fields = [
      'peopleAhead',
      'patientsAhead',
      'estimatedWaitMinutes',
      'estimatedWaitingTime',
      'estimatedWait',
      'averageConsultationMinutes',
      'consultationOverdue',
    ];

    for (final field in fields) {
      final value = source[field];

      // Preserve valid zero values, but don't overwrite existing
      // values with null or absent response fields.
      if (value != null) {
        tokenJson[field] = value;
      }
    }

    final prediction = source['prediction'];

    if (prediction is Map) {
      tokenJson['prediction'] =
          Map<String, dynamic>.from(prediction);
    }
  }

  Future<void> cancelToken(String tokenId) async {
    final id = tokenId.trim();

    if (id.isEmpty) {
      throw const ApiException(
        'Unable to cancel your token. Please try again.',
      );
    }

    try {
      await _apiService.patch(
        '/api/queue/tokens/${Uri.encodeComponent(id)}/cancel',
        authenticated: true,
      );
    } catch (_) {
      throw const ApiException(
        'Unable to cancel your token. Please try again.',
      );
    }
  }
}