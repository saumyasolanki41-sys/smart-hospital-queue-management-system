
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService;

  AuthService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  String? _accessToken;

  String? get accessToken => _accessToken;

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await _apiService.register(
      name: name.trim(),
      email: email.trim(),
      password: password,
    );
  }

  Future<UserModel> verifyRegistration({
    required String email,
    required String otp,
  }) async {
    final response = await _apiService.verifyRegistration(
      email: email.trim(),
      otp: otp.trim(),
    );

    final data = response['data'];

    if (data is! Map<String, dynamic> ||
        data['user'] is! Map<String, dynamic>) {
      throw ApiException(
        'Invalid registration response from server.',
      );
    }

    final userJson = data['user'] as Map<String, dynamic>;

    return UserModel.fromJson(userJson);
  }

  Future<String> login({
    required String email,
    required String password,
  }) async {
    // A new login attempt must not reuse an old session.
    _accessToken = null;

    final response = await _apiService.login(
      email: email.trim(),
      password: password,
    );

    final data = response['data'];

    if (data is! Map<String, dynamic>) {
      throw ApiException(
        'Invalid login response from server.',
      );
    }

    final challengeId = data['challengeId']?.toString();

    if (challengeId == null || challengeId.isEmpty) {
      throw ApiException(
        'The server did not return a login challenge.',
      );
    }

    return challengeId;
  }

  Future<UserModel> verifyLogin({
    required String challengeId,
    required String otp,
  }) async {
    _accessToken = null;

    final response = await _apiService.verifyLogin(
      challengeId: challengeId,
      otp: otp.trim(),
    );

    final data = response['data'];

    if (data is! Map<String, dynamic>) {
      throw ApiException(
        'Invalid login verification response.',
      );
    }

    final token = data['accessToken']?.toString();

    if (token == null || token.isEmpty) {
      throw ApiException(
        'The server did not return an access token.',
      );
    }

    if (data['user'] is! Map<String, dynamic>) {
      throw ApiException(
        'User information is missing from the response.',
      );
    }

    final userJson = data['user'] as Map<String, dynamic>;
    final user = UserModel.fromJson(userJson);

    _accessToken = token;

    return user;
  }

  Future<UserModel> loginWithGoogle({
    required String idToken,
  }) async {
    _accessToken = null;

    final response = await _apiService.loginWithGoogle(
      idToken: idToken,
    );

    final data = response['data'];

    if (data is! Map<String, dynamic>) {
      throw ApiException(
        'Invalid Google login response.',
      );
    }

    final token = data['accessToken']?.toString();

    if (token == null || token.isEmpty) {
      throw ApiException(
        'The server did not return an access token.',
      );
    }

    if (data['user'] is! Map<String, dynamic>) {
      throw ApiException(
        'User information is missing from the response.',
      );
    }

    final userJson = data['user'] as Map<String, dynamic>;
    final user = UserModel.fromJson(userJson);

    _accessToken = token;

    return user;
  }

  Future<UserModel> getCurrentUser({
    String? token,
  }) async {
    final currentToken = token ?? _accessToken;

    if (currentToken == null || currentToken.isEmpty) {
      throw ApiException(
        'Please sign in to continue.',
      );
    }

    try {
      final response = await _apiService.getCurrentUser(
        accessToken: currentToken,
      );

      final data = response['data'];

      if (data is! Map<String, dynamic> ||
          data['user'] is! Map<String, dynamic>) {
        throw ApiException(
          'Invalid current-user response.',
        );
      }

      final userJson = data['user'] as Map<String, dynamic>;
      final user = UserModel.fromJson(userJson);

      _accessToken = currentToken;

      return user;
    } catch (_) {
      // Do not retain a token rejected by the server.
      _accessToken = null;
      rethrow;
    }
  }

  Future<void> forgotPassword({
    required String email,
  }) async {
    await _apiService.forgotPassword(
      email: email.trim(),
    );
  }

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    await _apiService.resetPassword(
      email: email.trim(),
      otp: otp.trim(),
      newPassword: newPassword,
    );

    _accessToken = null;
  }

  void logout() {
    _accessToken = null;
  }
}
