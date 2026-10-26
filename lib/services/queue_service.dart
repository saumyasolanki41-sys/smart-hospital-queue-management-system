
import 'package:flutter/foundation.dart';
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
        body: {
          'doctorId': doctorId.trim(),
        },
        authenticated: true,
      );

      final data = response['data'];

      if (data is! Map || data['token'] is! Map) {
        throw const ApiException(
          'Unable to complete token booking. Please try again.',
        );
      }

      final tokenData = Map<String, dynamic>.from(
        data['token'] as Map,
      );

      return TokenModel.fromJson(tokenData);
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('Book token processing failed: $e');

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

      return tokens
          .whereType<Map>()
          .map(
            (token) => TokenModel.fromJson(
              Map<String, dynamic>.from(token),
            ),
          )
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('Fetch tokens processing failed: $e');

      throw const ApiException(
        'Unable to load your tokens. Please try again.',
      );
    }
  }

  Future<TokenModel> getTokenStatus(String tokenId) async {
    if (tokenId.trim().isEmpty) {
      throw const ApiException('Token ID is required.');
    }

    try {
      final encodedTokenId =
          Uri.encodeComponent(tokenId.trim());

      final response = await _apiService.get(
        '/api/queue/tokens/$encodedTokenId',
        authenticated: true,
      );

      final data = response['data'];

      dynamic token;

      if (data is Map) {
        token = data['token'] ?? data;
      }

      token ??= response['token'];

      if (token is! Map) {
        throw const ApiException(
          'Unable to fetch token status. Please try again.',
        );
      }

      return TokenModel.fromJson(
        Map<String, dynamic>.from(token),
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('Token status processing failed: $e');

      throw const ApiException(
        'Unable to fetch token status. Please try again.',
      );
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
    } catch (e) {
      debugPrint('Cancel token processing failed: $e');

      throw const ApiException(
        'Unable to cancel your token. Please try again.',
      );
    }
  }
}
