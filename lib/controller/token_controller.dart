
import 'package:flutter/foundation.dart';

import '../models/token_model.dart';
import '../services/api_service.dart';
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
    required String selectedSlot,
  }) async {
    if (_isBooking) return null;

    if (selectedSlot.trim().isEmpty) {
      _error = 'Please select a time slot before booking.';
      notifyListeners();
      return null;
    }

    _isBooking = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _queueService.bookToken(
        doctorId: doctorId,
        selectedSlot: selectedSlot,
      );

      _selectedToken = token;

      await fetchMyTokens(refresh: true);

      // Select the latest version of the booked token.
      final matchingTokens = _tokens.where(
        (item) => item.id == token.id,
      );

      _selectedToken = matchingTokens.isNotEmpty
          ? matchingTokens.first
          : token;

      return _selectedToken;
    } on ApiException catch (exception) {
      _error = exception.message;
      return null;
    } catch (e) {
      debugPrint('Book token error: $e');
      _error = 'Unable to book your token. Please try again.';
      return null;
    } finally {
      _isBooking = false;
      notifyListeners();
    }
  }

  Future<void> fetchMyTokens({bool refresh = false}) async {
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
          final fetchedTokens = await _queueService.getMyTokens();

          _tokens = fetchedTokens;

          // Print appointment times for debugging.
          for (final token in fetchedTokens) {
            debugPrint(
              'Token: ${token.id}, '
              'Appointment Time: ${token.appointmentTime}',
            );
          }

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
        } on ApiException catch (exception) {
          _error = exception.message;

          if (!refresh && _tokens.isEmpty) {
            _tokens = [];
          }
        } catch (e) {
          debugPrint('Fetch tokens error: $e');
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

  Future<TokenModel?> fetchTokenStatus(String tokenId) async {
    _error = null;

    try {
      final token = await _queueService.getTokenStatus(tokenId);

      _selectedToken = token;

      final index = _tokens.indexWhere(
        (item) => item.id == token.id,
      );

      if (index >= 0) {
        _tokens[index] = token;
      } else {
        _tokens = [..._tokens, token];
      }

      notifyListeners();
      return token;
    } on ApiException catch (exception) {
      _error = exception.message;
    } catch (e) {
      debugPrint('Fetch token status error: $e');
      _error = 'Unable to fetch token status. Please try again.';
    }

    notifyListeners();
    return null;
  }

  Future<bool> cancelToken(String tokenId) async {
    if (_isCancelling) return false;

    final normalizedId = tokenId.trim();

    if (normalizedId.isEmpty) {
      _error = 'Token ID is missing.';
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
    } on ApiException catch (exception) {
      _error = exception.message;
      return false;
    } catch (e) {
      debugPrint('Cancel token error: $e');
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
