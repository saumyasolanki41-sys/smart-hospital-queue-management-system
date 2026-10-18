
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionService {
  static const String _tokenKey = 'access_token';

  final FlutterSecureStorage _storage;

  SessionService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    final trimmedToken = token.trim();

    if (trimmedToken.isEmpty) {
      throw ArgumentError('Access token cannot be empty.');
    }

    await _storage.write(
      key: _tokenKey,
      value: trimmedToken,
    );
  }

  Future<String?> getToken() async {
    final token = await _storage.read(key: _tokenKey);

    if (token == null || token.trim().isEmpty) {
      return null;
    }

    return token;
  }

  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }
}
