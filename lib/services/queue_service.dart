import '../models/token_model.dart';
import 'api_service.dart';

class QueueService {
  final ApiService _apiService;

  QueueService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  static const String _duplicateBookingMessage =
      'Token is already booked for this doctor.';

  static const String _bookingErrorMessage =
      'Unable to book your token. Please try again.';

  static const String _loadTokensErrorMessage =
      'Unable to load your tokens. Please try again.';

  static const String _tokenStatusErrorMessage =
      'Unable to load token status. Please try again.';

  static const String _cancelTokenErrorMessage =
      'Unable to cancel your token. Please try again.';

  bool _isDuplicateBooking(Object error) {
    if (error is ApiException) {
      final code = error.code?.toLowerCase().trim();

      if (code == 'already_in_queue' ||
          code == 'already_have_active_token' ||
          code == 'already_have_token' ||
          code == 'duplicate_booking') {
        return true;
      }

      return _containsDuplicateMessage(error.message);
    }

    return _containsDuplicateMessage(error.toString());
  }

  bool _containsDuplicateMessage(String message) {
    final text = message.toLowerCase();

    const duplicateIndicators = [
      'already_in_queue',
      'already in queue',
      'already booked',
      'already has an active token',
      'already_have_active_token',
      'already_have_token',
      'active token exists',
      'duplicate token',
      'duplicate_booking',
      'already has a token',
      'active token already exists',
      'you already have an active token',
      'token already exists',
    ];

    return duplicateIndicators.any(text.contains);
  }

  Future<TokenModel> bookToken({
    required String doctorId,
  }) async {
    if (doctorId.trim().isEmpty) {
      throw const ApiException('Please select a doctor.');
    }

    try {
      final response = await _apiService.post(
        '/api/queue/tokens',
        body: {
          'doctorId': doctorId.trim(),
        },
        authenticated: true,
      );

      final data = response['data'];

      if (data is! Map) {
        throw const ApiException(_bookingErrorMessage);
      }

      final tokenData = data['token'] ?? data;

      if (tokenData is! Map) {
        throw const ApiException(_bookingErrorMessage);
      }

      final tokenJson = Map<String, dynamic>.from(tokenData);

      _copyQueueFields(data, tokenJson);

      return TokenModel.fromJson(tokenJson);
    } catch (error) {
      if (_isDuplicateBooking(error)) {
        throw const ApiException(
          _duplicateBookingMessage,
          statusCode: 409,
          code: 'ALREADY_IN_QUEUE',
        );
      }

      throw const ApiException(_bookingErrorMessage);
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

        if (tokens == null && data['data'] is List) {
          tokens = data['data'];
        }
      }

      tokens ??= response['tokens'];

      if (tokens is! List) {
        throw const ApiException(_loadTokensErrorMessage);
      }

      return tokens.whereType<Map>().map((token) {
        final tokenJson = Map<String, dynamic>.from(token);
        return TokenModel.fromJson(tokenJson);
      }).toList();
    } catch (_) {
      throw const ApiException(_loadTokensErrorMessage);
    }
  }

  Future<TokenModel> getTokenStatus(String tokenId) async {
    final id = tokenId.trim();

    if (id.isEmpty) {
      throw const ApiException(_tokenStatusErrorMessage);
    }

    try {
      final response = await _apiService.get(
        '/api/queue/tokens/${Uri.encodeComponent(id)}',
        authenticated: true,
      );

      final data = response['data'];

      if (data is! Map) {
        throw const ApiException(_tokenStatusErrorMessage);
      }

      final tokenData = data['token'] ?? data;

      if (tokenData is! Map) {
        throw const ApiException(_tokenStatusErrorMessage);
      }

      final tokenJson = Map<String, dynamic>.from(tokenData);

      _copyQueueFields(data, tokenJson);

      final queueData = data['queue'];

      if (queueData is Map) {
        _copyQueueFields(queueData, tokenJson);
      }

      final predictionData = data['prediction'] ??
          (queueData is Map ? queueData['prediction'] : null);

      if (predictionData is Map) {
        tokenJson['prediction'] =
            Map<String, dynamic>.from(predictionData);
      }

      return TokenModel.fromJson(tokenJson);
    } catch (_) {
      throw const ApiException(_tokenStatusErrorMessage);
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
      throw const ApiException(_cancelTokenErrorMessage);
    }

    try {
      await _apiService.patch(
        '/api/queue/tokens/${Uri.encodeComponent(id)}/cancel',
        authenticated: true,
      );
    } catch (_) {
      throw const ApiException(_cancelTokenErrorMessage);
    }
  }
}
