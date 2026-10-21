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

  String? _challengeId;

  String? get challengeId => _challengeId;

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await _apiService.register(
      name: name,
      email: email,
      password: password,
    );
  }

  Future<void> resendRegistrationOtp({
    required String name,
    required String email,
    required String password,
  }) async {
    await _apiService.register(
      name: name,
      email: email,
      password: password,
    );
  }

  Future<UserModel> verifyRegistration({
    required String email,
    required String otp,
  }) async {
    final response = await _apiService.verifyRegistration(
      email: email,
      otp: otp,
    );

    final data = response['data'];

    if (data is! Map || data['user'] is! Map) {
      throw const ApiException(
        'Registration response did not contain user details.',
      );
    }

    final accessToken =
        data['accessToken'] ??
        data['access_token'] ??
        data['token'];

    if (accessToken is String && accessToken.trim().isNotEmpty) {
      await _storageService.saveAccessToken(accessToken.trim());
    }

    return UserModel.fromJson(
      Map<String, dynamic>.from(data['user'] as Map),
    );
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiService.login(
      email: email,
      password: password,
    );

    _updateChallengeId(response);
  }

  Future<void> resendLoginOtp({
    required String email,
    required String password,
  }) async {
    final response = await _apiService.login(
      email: email,
      password: password,
    );

    // Use the latest challenge ID returned by the backend.
    _updateChallengeId(response);
  }

  void _updateChallengeId(Map<String, dynamic> response) {
    final data = response['data'];

    if (data is! Map) {
      throw const ApiException(
        'Login response did not contain challenge details.',
      );
    }

    final challenge = data['challengeId'];

    if (challenge is! String || challenge.isEmpty) {
      throw const ApiException(
        'Login response did not contain a valid challenge ID.',
      );
    }

    _challengeId = challenge;
  }

  Future<UserModel> verifyLogin({
    required String otp,
  }) async {
    final challenge = _challengeId;

    if (challenge == null || challenge.isEmpty) {
      throw const ApiException(
        'Please enter your email and password again.',
      );
    }

    final response = await _apiService.verifyLogin(
      challengeId: challenge,
      otp: otp,
    );

    final data = response['data'];

    if (data is! Map || data['user'] is! Map) {
      throw const ApiException(
        'Login response did not contain user details.',
      );
    }

    final user = UserModel.fromJson(
      Map<String, dynamic>.from(data['user'] as Map),
    );

    _challengeId = null;

    return user;
  }

  Future<UserModel> loginWithGoogle({
    required String idToken,
  }) async {
    final response = await _apiService.loginWithGoogle(
      idToken: idToken,
    );

    final data = response['data'];

    if (data is! Map || data['user'] is! Map) {
      throw const ApiException(
        'Google login response did not contain user details.',
      );
    }

    return UserModel.fromJson(
      Map<String, dynamic>.from(data['user'] as Map),
    );
  }

  Future<UserModel?> getCurrentUser() async {
    final hasToken = await _storageService.hasAccessToken();

    if (!hasToken) {
      return null;
    }

    try {
      final response = await _apiService.getCurrentUser();
      final data = response['data'];

      if (data is! Map || data['user'] is! Map) {
        throw const ApiException(
          'Current-user response did not contain user details.',
        );
      }

      return UserModel.fromJson(
        Map<String, dynamic>.from(data['user'] as Map),
      );
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await logout();
        return null;
      }

      rethrow;
    }
  }

  Future<void> logout() async {
    _challengeId = null;
    await _apiService.logout();
  }
}