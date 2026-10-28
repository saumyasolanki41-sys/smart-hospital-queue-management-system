import '../models/token_model.dart';
import 'api_service.dart';

class QueueService {
  final ApiService _apiService;

  QueueService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  static const String _duplicateBookingMessage =
      'Token already booked.';

  static const String _loadTokensErrorMessage =
      'Unable to load your tokens. Please try again.';

  static const String _tokenStatusErrorMessage =
      'Unable to load token status. Please try again.';

  static const String _cancelTokenErrorMessage =
      'Unable to cancel your token. Please try again.';

  String? _getErrorCode(Object error) {
    if (error is! ApiException) return null;

    final code = error.code?.trim().toUpperCase();

    if (code == null || code.isEmpty) return null;

    return code;
  }

  bool _isDuplicateBooking(Object error) {
    final code = _getErrorCode(error);

    if (code == 'QUEUE_CONFLICT') {
      return false;
    }

    if (code == 'ALREADY_IN_QUEUE' ||
        code == 'ALREADY_IN_QUEUE_TODAY' ||
        code == 'ALREADY_HAVE_ACTIVE_TOKEN' ||
        code == 'ALREADY_HAVE_TOKEN' ||
        code == 'DUPLICATE_BOOKING' ||
        code == 'DUPLICATE_ACTIVE_TOKEN' ||
        code == 'ACTIVE_TOKEN_EXISTS' ||
        code == 'ALREADY_BOOKED' ||
        code == 'ALREADY_BOOKED_FOR_DOCTOR') {
      return true;
    }

    if (error is ApiException) {
      return _containsDuplicateMessage(error.message);
    }

    return _containsDuplicateMessage(error.toString());
  }

  bool _containsDuplicateMessage(String message) {
    final normalizedMessage = message
        .toLowerCase()
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .trim();

    const indicators = <String>[
      'already in queue',
      'already booked',
      'already have an active token',
      'already has an active token',
      'already have a token',
      'already has a token',
      'active token exists',
      'active token already exists',
      'duplicate token',
      'duplicate booking',
      'token already exists',
      'already booked for this doctor',
    ];

    return indicators.any(normalizedMessage.contains);
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return <String, dynamic>{};
  }

  Map<String, dynamic> _copyQueueFields(
    Map<String, dynamic> data,
    Map<String, dynamic> tokenJson,
  ) {
    final result = Map<String, dynamic>.from(tokenJson);

    const queueFields = <String>[
      'peopleAhead',
      'patientsAhead',
      'estimatedWaitMinutes',
      'averageConsultationMinutes',
      'consultationOverdue',
      'prediction',
    ];

    for (final field in queueFields) {
      if (result.containsKey(field) && result[field] != null) {
        continue;
      }

      if (data.containsKey(field) && data[field] != null) {
        result[field] = data[field];
      }
    }

    return result;
  }

  Future<TokenModel> bookToken({
    required String doctorId,
  }) async {
    try {
      final response = await _apiService.post(
        '/api/queue/tokens',
        body: <String, dynamic>{
          'doctorId': doctorId,
        },
        debugBackendErrors: true,
      );

      final responseData = _asMap(response);
      final data = _asMap(responseData['data']);

      final tokenJson = _asMap(
        data['token'] ?? responseData['token'] ?? data,
      );

      if (tokenJson.isEmpty) {
        throw const ApiException(
          'The booking response did not contain token details.',
        );
      }

      final tokenWithQueueFields = _copyQueueFields(
        data,
        tokenJson,
      );

      return TokenModel.fromJson(tokenWithQueueFields);
    } catch (error) {
      final code = _getErrorCode(error);

      if (code == 'QUEUE_CONFLICT') {
        if (error is ApiException) {
          rethrow;
        }

        throw const ApiException(
          'Queue conflict occurred while booking.',
          statusCode: 409,
          code: 'QUEUE_CONFLICT',
        );
      }

      if (_isDuplicateBooking(error)) {
        throw const ApiException(
          _duplicateBookingMessage,
          statusCode: 409,
          code: 'ALREADY_IN_QUEUE',
        );
      }

      if (error is ApiException) {
        rethrow;
      }

      throw Exception(error.toString());
    }
  }

  Future<List<TokenModel>> getMyTokens() async {
    try {
      final response = await _apiService.get(
        '/api/queue/tokens/mine',
      );

      final responseData = _asMap(response);
      final data = responseData['data'];

      dynamic tokensData;

      if (data is List) {
        tokensData = data;
      } else if (data is Map) {
        final dataMap = _asMap(data);

        tokensData = dataMap['tokens'] ??
            dataMap['items'] ??
            dataMap['results'];
      }

      tokensData ??= responseData['tokens'];

      if (tokensData is! List) {
        return <TokenModel>[];
      }

      return tokensData
          .whereType<Map>()
          .map(
            (item) => TokenModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } catch (_) {
      throw const ApiException(
        _loadTokensErrorMessage,
      );
    }
  }

  Future<TokenModel> getTokenStatus(String tokenId) async {
    try {
      final response = await _apiService.get(
        '/api/queue/tokens/$tokenId',
      );

      final responseData = _asMap(response);
      final data = _asMap(responseData['data']);

      final tokenJson = _asMap(
        data['token'] ?? responseData['token'] ?? data,
      );

      if (tokenJson.isEmpty) {
        throw const ApiException(
          _tokenStatusErrorMessage,
        );
      }

      final tokenWithQueueFields = _copyQueueFields(
        data,
        tokenJson,
      );

      return TokenModel.fromJson(tokenWithQueueFields);
    } catch (_) {
      throw const ApiException(
        _tokenStatusErrorMessage,
      );
    }
  }

  Future<void> cancelToken(String tokenId) async {
    try {
      await _apiService.patch(
        '/api/queue/tokens/$tokenId/cancel',
        body: <String, dynamic>{},
      );
    } catch (_) {
      throw const ApiException(
        _cancelTokenErrorMessage,
      );
    }
  }
}
