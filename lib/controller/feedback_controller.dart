
import 'package:flutter/foundation.dart';

import '../models/feedback_model.dart';
import '../services/api_service.dart';
import '../services/feedback_service.dart';

class FeedbackController extends ChangeNotifier {
  final FeedbackService _feedbackService;

  FeedbackController({FeedbackService? feedbackService})
      : _feedbackService = feedbackService ?? FeedbackService();

  final Map<String, FeedbackModel?> _feedback = {};
  final Set<String> _loadedTokens = {};
  final Set<String> _loadingTokens = {};
  final Set<String> _submittingTokens = {};
  final Map<String, String> _errors = {};

  FeedbackModel? feedbackFor(String tokenId) => _feedback[tokenId];

  bool hasLoadedFeedback(String tokenId) =>
      _loadedTokens.contains(tokenId);

  bool isLoading(String tokenId) =>
      _loadingTokens.contains(tokenId);

  bool isSubmitting(String tokenId) =>
      _submittingTokens.contains(tokenId);

  String? errorFor(String tokenId) => _errors[tokenId];

  Future<void> fetchFeedback(String tokenId) async {
    if (_loadingTokens.contains(tokenId)) return;

    _loadingTokens.add(tokenId);
    _errors.remove(tokenId);
    notifyListeners();

    try {
      final result = await _feedbackService.getFeedback(tokenId);

      _feedback[tokenId] = result;
      _loadedTokens.add(tokenId);
    } catch (_) {
      _errors[tokenId] = 'Unable to load feedback. Please try again.';
    } finally {
      _loadingTokens.remove(tokenId);
      notifyListeners();
    }
  }

  Future<bool> submitFeedback({
    required String tokenId,
    required int rating,
    String? comment,
  }) async {
    if (_submittingTokens.contains(tokenId)) return false;

    if (_feedback[tokenId] != null) {
      _errors[tokenId] = 'Feedback has already been submitted.';
      notifyListeners();
      return false;
    }

    _submittingTokens.add(tokenId);
    _errors.remove(tokenId);
    notifyListeners();

    try {
      final result = await _feedbackService.submitFeedback(
        tokenId: tokenId,
        rating: rating,
        comment: comment,
      );

      _feedback[tokenId] = result;
      _loadedTokens.add(tokenId);
      _errors.remove(tokenId);

      return true;
    } catch (error) {
      if (error is ApiException && error.code == 'FEEDBACK_EXISTS') {
        return await _recoverSavedFeedback(tokenId);
      }

      final recovered = await _recoverSavedFeedback(tokenId);

      if (recovered) {
        return true;
      }

      _errors[tokenId] =
          'Unable to submit feedback. Please check your connection and try again.';

      return false;
    } finally {
      _submittingTokens.remove(tokenId);
      notifyListeners();
    }
  }

  Future<bool> _recoverSavedFeedback(String tokenId) async {
    try {
      final savedFeedback =
          await _feedbackService.getFeedback(tokenId);

      if (savedFeedback != null) {
        _feedback[tokenId] = savedFeedback;
        _loadedTokens.add(tokenId);
        _errors.remove(tokenId);
        return true;
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  void clearError(String tokenId) {
    _errors.remove(tokenId);
    notifyListeners();
  }

  void clearFeedback(String tokenId) {
    _feedback.remove(tokenId);
    _loadedTokens.remove(tokenId);
    _errors.remove(tokenId);
    notifyListeners();
  }
}
