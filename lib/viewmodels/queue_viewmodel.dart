import 'package:flutter/foundation.dart';
import '../services/queue_service.dart';
import '../services/storage_service.dart';

class QueueViewModel extends ChangeNotifier {
  final QueueService _queueService;

  QueueViewModel({QueueService? queueService})
      : _queueService = queueService ??
            QueueService(
              tokenProvider: () =>
                  StorageService().getAccessToken(),
            );

  bool _isChecking = false;
  bool? _isBackendOnline;
  String? _errorMessage;

  bool _isLoadingHomeData = false;
  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _myTokens = [];

  bool get isChecking => _isChecking;
  bool? get isBackendOnline => _isBackendOnline;
  String? get errorMessage => _errorMessage;

  bool get isLoadingHomeData => _isLoadingHomeData;
  List<Map<String, dynamic>> get departments => _departments;
  List<Map<String, dynamic>> get myTokens => _myTokens;

  Map<String, dynamic>? get nextToken {
    for (final token in _myTokens) {
      final status =
          _read(token, ['status', 'queueStatus']).toLowerCase();

      if ([
        'waiting',
        'pending',
        'called',
        'in_consultation',
        'in consultation',
      ].contains(status)) {
        return token;
      }
    }

    return null;
  }

  String _read(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = data[key];

      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    return '';
  }

  Future<void> checkBackendStatus() async {
    _isChecking = true;
    notifyListeners();

    try {
      await _queueService.checkHealth();
      _isBackendOnline = true;
      _errorMessage = null;
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

  Future<void> loadHomeData() async {
    if (_isLoadingHomeData) return;

    _isLoadingHomeData = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _queueService.getDepartments(),
        _queueService.getMyQueueTokens(),
      ]);

      _departments = _extractList(
        results[0],
        ['departments', 'items', 'results'],
      );

      _myTokens = _extractList(
        results[1],
        ['tokens', 'queueTokens', 'items', 'results'],
      );

      _errorMessage = null;
    } on QueueException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Unable to load hospital information.';
    } finally {
      _isLoadingHomeData = false;
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> _extractList(
    dynamic response,
    List<String> possibleKeys,
  ) {
    dynamic value = response;

    for (var i = 0; i < 4; i++) {
      if (value is List) {
        return value
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }

      if (value is! Map) return [];

      final map = Map<String, dynamic>.from(value);

      dynamic next;
      if (map.containsKey('data')) {
        next = map['data'];
      } else {
        for (final key in possibleKeys) {
          if (map.containsKey(key)) {
            next = map[key];
            break;
          }
        }
      }

      if (next == null || identical(next, value)) return [];
      value = next;
    }

    return [];
  }

  @override
  void dispose() {
    _queueService.dispose();
    super.dispose();
  }
}
