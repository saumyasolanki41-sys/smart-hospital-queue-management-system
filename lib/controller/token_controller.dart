import 'package:flutter/foundation.dart';
import '../models/token_model.dart';
import '../services/queue_service.dart';

class TokenController extends ChangeNotifier {
  final QueueService _queueService;

  TokenController({QueueService? queueService})
      : _queueService = queueService ?? QueueService();

  List<TokenModel> _tokens = [];
  TokenModel? _selectedToken;

  bool _isLoading = false;
  bool _isBooking = false;
  bool _isCancelling = false;
  bool _refreshRequested = false;

  final Set<String> _refreshingTokenIds = {};

  String? _error;
  String? _statusError;

  List<TokenModel> get tokens => List.unmodifiable(_tokens);

  TokenModel? get selectedToken => _selectedToken;

  bool get isLoading => _isLoading;

  bool get isBooking => _isBooking;

  bool get isCancelling => _isCancelling;

  bool get isRefreshingStatus => _refreshingTokenIds.isNotEmpty;

  String? get error => _error;

  String? get statusError => _statusError;

  bool get hasTokens => _tokens.isNotEmpty;

  TokenModel _mergeToken(
    TokenModel previous,
    TokenModel updated,
  ) {
    return TokenModel(
      id: updated.id.isNotEmpty ? updated.id : previous.id,
      tokenNumber: updated.tokenNumber != 'N/A'
          ? updated.tokenNumber
          : previous.tokenNumber,
      patientId: updated.patientId.isNotEmpty
          ? updated.patientId
          : previous.patientId,
      doctorId: updated.doctorId.isNotEmpty
          ? updated.doctorId
          : previous.doctorId,
      departmentId: updated.departmentId.isNotEmpty
          ? updated.departmentId
          : previous.departmentId,
      doctorName: updated.doctorName ?? previous.doctorName,
      departmentName:
          updated.departmentName ?? previous.departmentName,

      patientsAhead: updated.patientsAhead,
      estimatedWaitMinutes: updated.estimatedWaitMinutes,

      status: updated.status,
      appointmentTime:
          updated.appointmentTime ?? previous.appointmentTime,
      createdAt: updated.createdAt ?? previous.createdAt,

      averageConsultationMinutes:
          updated.averageConsultationMinutes,
      consultationOverdue: updated.consultationOverdue,
      prediction: updated.prediction,
    );
  }

  Future<TokenModel?> bookToken({
    required String doctorId,
  }) async {
    if (_isBooking) return null;

    _isBooking = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _queueService.bookToken(
        doctorId: doctorId,
      );

      _selectedToken = token;
      notifyListeners();

      await fetchMyTokens(refresh: true);

      final matchingTokens = _tokens.where(
        (item) => item.id.trim() == token.id.trim(),
      );

      _selectedToken = matchingTokens.isNotEmpty
          ? matchingTokens.first
          : token;

      return _selectedToken;
    } catch (_) {
      _error = 'Unable to book your token. Please try again.';
      return null;
    } finally {
      _isBooking = false;
      notifyListeners();
    }
  }

  Future<void> fetchMyTokens({
    bool refresh = false,
  }) async {
    if (_isLoading) {
      if (refresh) {
        _refreshRequested = true;
      }
      return;
    }

    _isLoading = true;
    _error = null;

    bool loadedSuccessfully = false;

    notifyListeners();

    try {
      do {
        _refreshRequested = false;

        try {
          final fetchedTokens =
              await _queueService.getMyTokens();

          _tokens = fetchedTokens;
          loadedSuccessfully = true;

          if (_selectedToken != null) {
            final selectedId = _selectedToken!.id.trim();

            final matchingTokens = _tokens.where(
              (token) => token.id.trim() == selectedId,
            );

            _selectedToken = matchingTokens.isNotEmpty
                ? matchingTokens.first
                : null;
          }

          _error = null;
        } catch (_) {
          _error = 'Unable to load your tokens. Please try again.';
        }

        notifyListeners();
      } while (_refreshRequested);
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    if (loadedSuccessfully) {
      await _refreshActiveTokenStatuses();
    }
  }

  Future<void> _refreshActiveTokenStatuses() async {
    final activeTokenIds = _tokens
        .where((token) {
          final status = token.status.trim().toLowerCase();

          return status == 'waiting' ||
              status == 'pending' ||
              status == 'in-progress' ||
              status == 'in_progress' ||
              status == 'called';
        })
        .map((token) => token.id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    if (activeTokenIds.isEmpty) return;

    await Future.wait(
      activeTokenIds.map(fetchTokenStatus),
    );
  }

  Future<TokenModel?> fetchTokenStatus(
    String tokenId,
  ) async {
    final normalizedId = tokenId.trim();

    if (normalizedId.isEmpty ||
        _refreshingTokenIds.contains(normalizedId)) {
      return null;
    }

    _refreshingTokenIds.add(normalizedId);
    _statusError = null;
    notifyListeners();

    try {
      final updatedToken =
          await _queueService.getTokenStatus(normalizedId);

      final index = _tokens.indexWhere(
        (item) => item.id.trim() == normalizedId,
      );

      late final TokenModel mergedToken;

      if (index >= 0) {
        mergedToken = _mergeToken(
          _tokens[index],
          updatedToken,
        );

        _tokens[index] = mergedToken;
      } else {
        mergedToken = updatedToken;
        _tokens = [..._tokens, mergedToken];
      }

      if (_selectedToken?.id.trim() == normalizedId) {
        _selectedToken = mergedToken;
      }

      _statusError = null;
      notifyListeners();

      return mergedToken;
    } catch (_) {
      _statusError =
          'Unable to refresh waiting time. Please try again.';

      notifyListeners();
      return null;
    } finally {
      _refreshingTokenIds.remove(normalizedId);
      notifyListeners();
    }
  }

  Future<bool> cancelToken(String tokenId) async {
    if (_isCancelling) return false;

    final normalizedId = tokenId.trim();

    if (normalizedId.isEmpty) {
      _error = 'Unable to cancel token. Please try again.';
      notifyListeners();
      return false;
    }

    _isCancelling = true;
    _error = null;
    notifyListeners();

    try {
      await _queueService.cancelToken(normalizedId);

      _tokens = _tokens
          .where((token) => token.id.trim() != normalizedId)
          .toList();

      if (_selectedToken?.id.trim() == normalizedId) {
        _selectedToken = null;
      }

      _statusError = null;
      notifyListeners();

      await fetchMyTokens(refresh: true);

      return true;
    } catch (_) {
      _error = 'Unable to cancel your token. Please try again.';
      return false;
    } finally {
      _isCancelling = false;
      notifyListeners();
    }
  }

  void selectToken(TokenModel token) {
    _selectedToken = token;
    _statusError = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    _statusError = null;
    notifyListeners();
  }

  void clearTokens() {
    _tokens = [];
    _selectedToken = null;
    _error = null;
    _statusError = null;
    _refreshRequested = false;
    _refreshingTokenIds.clear();

    notifyListeners();
  }
}
