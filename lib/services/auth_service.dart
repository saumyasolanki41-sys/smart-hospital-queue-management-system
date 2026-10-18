
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

    final data = response['data'] as Map<String, dynamic>;
    final userJson = data['user'] as Map<String, dynamic>;

    return UserModel.fromJson(userJson);
  }

  Future<String> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiService.login(
      email: email,
      password: password,
    );

    final data = response['data'] as Map<String, dynamic>;
    final challengeId = data['challengeId']?.toString();

    if (challengeId == null || challengeId.isEmpty) {
      throw ApiException('The server did not return a login challenge.');
    }

    return challengeId;
  }

  Future<UserModel> verifyLogin({
    required String challengeId,
    required String otp,
  }) async {
    final response = await _apiService.verifyLogin(
      challengeId: challengeId,
      otp: otp,
    );

    final data = response['data'] as Map<String, dynamic>;
    final token = data['accessToken']?.toString();

    if (token == null || token.isEmpty) {
      throw ApiException('The server did not return an access token.');
    }

    final userJson = data['user'] as Map<String, dynamic>;
    final user = UserModel.fromJson(userJson);

    _accessToken = token;

    return user;
  }


  Future<UserModel> loginWithGoogle({
    required String idToken,
  }) async {
    final response = await _apiService.loginWithGoogle(
      idToken: idToken,
    );

    final data = response['data'] as Map<String, dynamic>;
    final token = data['accessToken']?.toString();

    if (token == null || token.isEmpty) {
      throw ApiException('The server did not return an access token.');
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
      throw ApiException('Please sign in to continue.');
    }

    final response = await _apiService.getCurrentUser(
      accessToken: currentToken,
    );

    final data = response['data'] as Map<String, dynamic>;
    final userJson = data['user'] as Map<String, dynamic>;

    _accessToken = currentToken;

    return UserModel.fromJson(userJson);
  }

  Future<void> forgotPassword({
    required String email,
  }) async {
    await _apiService.forgotPassword(email: email);
  }

  
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    await _apiService.resetPassword(
      email: email,
      otp: otp,
      newPassword: newPassword,
    );

    _accessToken = null;
  }

 
  void logout() {
    _accessToken = null;
  }
}
