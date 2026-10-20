import 'package:flutter/foundation.dart';
import '../models/token_model.dart';
import '../services/api_service.dart';
import '../services/queue_service.dart';

class TokenViewModel extends ChangeNotifier {
  final QueueService _queueService;

  TokenViewModel({
    QueueService? queueService,
  }) : _queueService = queueService ?? QueueService();

  List<TokenModel> _tokens = [];
  TokenModel? _selectedToken;

  bool _isLoading = false;
  bool _isBooking = false;
  bool _isCancelling = false;
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

      await fetchMyTokens();

      _selectedToken = token;

      return token;
    } on ApiException catch (exception) {
      _error = exception.message;
      return null;
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
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _tokens = await _queueService.getMyTokens();

      if (_selectedToken != null) {
        for (final token in _tokens) {
          if (token.id == _selectedToken!.id) {
            _selectedToken = token;
            break;
          }
        }
      }
    } on ApiException catch (exception) {
      _error = exception.message;
      if (!refresh) {
        _tokens = [];
      }
    } catch (_) {
      _error = 'Unable to load your tokens. Please try again.';
      if (!refresh) {
        _tokens = [];
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<TokenModel?> fetchTokenStatus(
    String tokenId,
  ) async {
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
    } catch (_) {
      _error = 'Unable to fetch token status. Please try again.';
    }

    notifyListeners();
    return null;
  }

  Future<bool> cancelToken(
    String tokenId,
  ) async {
    if (_isCancelling) return false;

    _isCancelling = true;
    _error = null;
    notifyListeners();

    try {
      await _queueService.cancelToken(tokenId);

      _selectedToken = null;

      await fetchMyTokens(refresh: true);

      return true;
    } on ApiException catch (exception) {
      _error = exception.message;
      return false;
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
    notifyListeners();
  }
}
