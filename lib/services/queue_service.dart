
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

      if (data is! Map || data['token'] is! Map) {
        throw const ApiException(
          'Unable to book your token. Please try again.',
        );
      }

      final tokenJson = Map<String, dynamic>.from(
        data['token'] as Map,
      );

      _copyQueueFields(data, tokenJson);

      return TokenModel.fromJson(tokenJson);
    } on ApiException {
      rethrow;
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
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        'Unable to load your tokens. Please try again.',
      );
    }
  }

  Future<TokenModel> getTokenStatus(String tokenId) async {
    final id = tokenId.trim();

    if (id.isEmpty) {
      throw const ApiException('Token ID is required.');
    }

    try {
      final response = await _apiService.get(
        '/api/queue/tokens/${Uri.encodeComponent(id)}',
        authenticated: true,
      );

      final data = response['data'];

      if (data is! Map || data['token'] is! Map) {
        throw const ApiException(
          'Unable to load token status. Please try again.',
        );
      }

      final tokenJson = Map<String, dynamic>.from(
        data['token'] as Map,
      );

      _copyQueueFields(data, tokenJson);

      return TokenModel.fromJson(tokenJson);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        'Unable to fetch token status. Please try again.',
      );
    }
  }

  void _copyQueueFields(
    Map data,
    Map<String, dynamic> tokenJson,
  ) {
    const fields = [
      'peopleAhead',
      'patientsAhead',
      'estimatedWaitMinutes',
      'estimatedWaitingTime',
      'estimatedWait',
      'prediction',
      'averageConsultationMinutes',
      'consultationOverdue',
    ];

    for (final field in fields) {
      if (data.containsKey(field)) {
        tokenJson[field] = data[field];
      }
    }
  }

  Future<void> cancelToken(String tokenId) async {
    if (tokenId.trim().isEmpty) {
      throw const ApiException('Token ID is required.');
    }

    try {
      final encodedTokenId =
          Uri.encodeComponent(tokenId.trim());

      await _apiService.patch(
        '/api/queue/tokens/$encodedTokenId/cancel',
        authenticated: true,
      );
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        'Unable to cancel your token. Please try again.',
      );
    }
  }
}
