import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class QueueController extends ChangeNotifier {
  final ApiService _apiService;

  QueueController({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  bool _isLoading = false;
  bool _isBackendConnected = false;
  String? _error;
  Map<String, dynamic>? _healthData;

  bool get isLoading => _isLoading;
  bool get isBackendConnected => _isBackendConnected;
  String? get error => _error;
  Map<String, dynamic>? get healthData => _healthData;

  Future<bool> checkBackendConnection() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _healthData = await _apiService.checkHealth();
      _isBackendConnected = true;
      return true;
    } on ApiException catch (exception) {
      _isBackendConnected = false;
      _error = exception.message;
      return false;
    } catch (_) {
      _isBackendConnected = false;
      _error = 'Unable to connect to the hospital server.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
