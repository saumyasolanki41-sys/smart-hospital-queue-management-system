
import 'package:flutter/foundation.dart';

import '../services/queue_service.dart';

class QueueViewModel extends ChangeNotifier {
  final QueueService _queueService;

  QueueViewModel({QueueService? queueService})
      : _queueService = queueService ?? QueueService();

  bool _isChecking = false;
  bool? _isBackendOnline;
  String? _errorMessage;

  bool get isChecking => _isChecking;
  bool? get isBackendOnline => _isBackendOnline;
  String? get errorMessage => _errorMessage;

  Future<void> checkBackendStatus() async {
    _isChecking = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _queueService.checkHealth();
      _isBackendOnline = true;
    } on QueueException catch (error) {
      _isBackendOnline = false;
      _errorMessage = error.message;
    } catch (_) {
      _isBackendOnline = false;
      _errorMessage = 'Unable to check server status.';
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _queueService.dispose();
    super.dispose();
  }
}
