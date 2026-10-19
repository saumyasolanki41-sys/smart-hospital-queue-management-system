
import '../models/user_model.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  final ApiService _apiService;
  final StorageService _storageService;

  AuthService({
    ApiService? apiService,
    StorageService? storageService,
  })  : _apiService = apiService ?? ApiService(),
        _storageService = storageService ?? StorageService();

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

    return UserModel.fromJson(
      data['user'] as Map<String, dynamic>,
    );
  }

  Future<String> login({
    required String email,
    required String password,
  }) async {
    await logout();

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

    final userData = data['user'];

    if (userData is! Map<String, dynamic>) {
      throw ApiException(
        'User information is missing from the response.',
      );
    }

    final user = UserModel.fromJson(userData);

    await _saveSession(token);

    return user;
  }

  Future<UserModel> loginWithGoogle({
    required String idToken,
  }) async {
    await logout();

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

    final userData = data['user'];

    if (userData is! Map<String, dynamic>) {
      throw ApiException(
        'User information is missing from the response.',
      );
    }

    final user = UserModel.fromJson(userData);

    await _saveSession(token);

    return user;
  }

  Future<void> _saveSession(String token) async {
    await _storageService.saveAccessToken(token);
    _accessToken = token;
  }

  Future<UserModel> restoreSession() async {
    final savedToken = await _storageService.getAccessToken();

    if (savedToken == null || savedToken.isEmpty) {
      _accessToken = null;
      throw ApiException('No saved session was found.');
    }

    return getCurrentUser(token: savedToken);
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

      final user = UserModel.fromJson(
        data['user'] as Map<String, dynamic>,
      );

      _accessToken = currentToken;

      return user;
    } on ApiException catch (error) {
      // Clear the session when the server rejects the token.
      if (error.statusCode == 401) {
        await logout();
      }

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

    await logout();
  }

  Future<void> logout() async {
    _accessToken = null;
    await _storageService.clearAccessToken();
  }

  Future<void> dispose() async {
    await logout();
    _apiService.dispose();
  }
}
