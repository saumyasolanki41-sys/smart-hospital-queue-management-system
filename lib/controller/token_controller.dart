
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
  bool _isRefreshingStatus = false;
  bool _refreshRequested = false;

  String? _error;
  String? _statusError;

  List<TokenModel> get tokens => List.unmodifiable(_tokens);

  TokenModel? get selectedToken => _selectedToken;

  bool get isLoading => _isLoading;

  bool get isBooking => _isBooking;

  bool get isCancelling => _isCancelling;

  bool get isRefreshingStatus => _isRefreshingStatus;

  String? get error => _error;

  String? get statusError => _statusError;

  bool get hasTokens => _tokens.isNotEmpty;

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
        (item) => item.id == token.id,
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
    notifyListeners();

    try {
      do {
        _refreshRequested = false;

        try {
          final fetchedTokens =
              await _queueService.getMyTokens();

          _tokens = fetchedTokens;

          if (_selectedToken != null) {
            final selectedId = _selectedToken!.id;

            final matchingTokens = _tokens.where(
              (token) => token.id == selectedId,
            );

            _selectedToken = matchingTokens.isNotEmpty
                ? matchingTokens.first
                : null;
          }

          _error = null;
        } catch (_) {
          _error = 'Unable to load your tokens. Please try again.';

          // Preserve existing token data if a refresh fails.
        }

        notifyListeners();
      } while (_refreshRequested);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<TokenModel?> fetchTokenStatus(
    String tokenId,
  ) async {
    final normalizedId = tokenId.trim();

    if (normalizedId.isEmpty || _isRefreshingStatus) {
      return null;
    }

    _isRefreshingStatus = true;
    _statusError = null;
    notifyListeners();

    try {
      final updatedToken =
          await _queueService.getTokenStatus(normalizedId);

      // Replace the existing token with the latest API response.
      final index = _tokens.indexWhere(
        (item) => item.id.trim() == normalizedId,
      );

      if (index >= 0) {
        _tokens[index] = updatedToken;
      } else {
        _tokens = [..._tokens, updatedToken];
      }

      // Keep the selected token synchronized with the refreshed data.
      if (_selectedToken?.id.trim() == normalizedId) {
        _selectedToken = updatedToken;
      }

      _statusError = null;
      notifyListeners();

      return updatedToken;
    } catch (_) {
      // Do not replace valid existing values with zero or null.
      _statusError =
          'Unable to refresh waiting time. Please try again.';

      notifyListeners();
      return null;
    } finally {
      _isRefreshingStatus = false;
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

    notifyListeners();
  }
}
