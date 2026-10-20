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
        'Unexpected token booking response from the server.',
      );
    }

    return TokenModel.fromJson(
      Map<String, dynamic>.from(data['token'] as Map),
    );
  }

  Future<List<TokenModel>> getMyTokens() async {
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
        'Unexpected queue tokens response from the server.',
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
  }

  Future<TokenModel> getTokenStatus(String tokenId) async {
    if (tokenId.trim().isEmpty) {
      throw const ApiException('Token ID is required.');
    }

    final response = await _apiService.get(
      '/api/queue/tokens/${Uri.encodeComponent(tokenId.trim())}',
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
        'Unexpected token status response from the server.',
      );
    }

    return TokenModel.fromJson(
      Map<String, dynamic>.from(token),
    );
  }

  Future<void> cancelToken(String tokenId) async {
    if (tokenId.trim().isEmpty) {
      throw const ApiException('Token ID is required.');
    }

    await _apiService.post(
      '/api/queue/tokens/${Uri.encodeComponent(tokenId.trim())}/cancel',
      authenticated: true,
    );
  }
}
