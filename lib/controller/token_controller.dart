
import 'package:flutter/foundation.dart';

import '../models/token_model.dart';
// import '../services/api_service.dart';
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

  String? _error;

  List<TokenModel> get tokens => List.unmodifiable(_tokens);

  TokenModel? get selectedToken => _selectedToken;

  bool get isLoading => _isLoading;

  bool get isBooking => _isBooking;

  bool get isCancelling => _isCancelling;

  String? get error => _error;

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

          if (!refresh && _tokens.isEmpty) {
            _tokens = [];
          }
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

    if (normalizedId.isEmpty) {
      return null;
    }

    try {
      final updatedToken =
          await _queueService.getTokenStatus(normalizedId);

      final index = _tokens.indexWhere(
        (item) => item.id == normalizedId,
      );

      if (index >= 0) {
        _tokens[index] = updatedToken;
      } else {
        _tokens = [..._tokens, updatedToken];
      }

      if (_selectedToken?.id == normalizedId) {
        _selectedToken = updatedToken;
      }

      notifyListeners();

      return updatedToken;
    } catch (_) {
      // Keep the existing token data if live status is unavailable.
      return null;
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
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearTokens() {
    _tokens = [];
    _selectedToken = null;
    _error = null;
    _refreshRequested = false;

    notifyListeners();
  }
}
