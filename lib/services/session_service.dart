import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionService {
  static const String _tokenKey = 'access_token';

  final FlutterSecureStorage _storage;

  SessionService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    await _storage.write(
      key: _tokenKey,
      value: token,
    );
  }

  Future<String?> getToken() async {
    return _storage.read(key: _tokenKey);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }
}
