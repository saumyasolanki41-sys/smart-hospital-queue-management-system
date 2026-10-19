import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/queue_status.dart';
import '../services/queue_service.dart';

class LiveQueueViewModel extends ChangeNotifier {
  final QueueService service;
  final String tokenId;
  final Duration interval;

  final void Function(QueueStatus status)? onNearTurn;

  final VoidCallback? onUnauthorized;

  LiveQueueViewModel({
    required this.service,
    required this.tokenId,
    this.interval = const Duration(seconds: 8),
    this.onNearTurn,
    this.onUnauthorized,
  });

  QueueStatus? status; 
  String? error;
  bool isLoading = true;

  Timer? _timer;
  bool _inFlight = false;
  bool _disposed = false;
  bool _nearTurnNotified = false;

  void start() {
    refresh();
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => refresh());
  }

  void stop() => _timer?.cancel();

  Future<void> refresh() async {
    if (_inFlight) return; 
    _inFlight = true;
    try {
      final result = await service.fetchStatus(tokenId);
      status = result;
      error = null;

      if (!_nearTurnNotified && !result.isFinished && result.patientsAhead <= 2) {
        _nearTurnNotified = true;
        onNearTurn?.call(result);
      }
      if (result.isFinished) stop();
    } on QueueException catch (e) {
      error = e.message;
      if (e.unauthorized) {
        stop();
        onUnauthorized?.call();
      }
    } finally {
      _inFlight = false;
      isLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}