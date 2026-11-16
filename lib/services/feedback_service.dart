
import '../models/feedback_model.dart';
import 'api_service.dart';

class FeedbackService {
  final ApiService _apiService;

  FeedbackService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  Future<FeedbackModel?> getFeedback(String tokenId) async {
    final response = await _apiService.get(
      '/api/queue/tokens/$tokenId/feedback',
    );

    final data = response['data'];

    if (data is! Map<String, dynamic>) {
      return null;
    }

    final feedback = data['feedback'];

    if (feedback == null) {
      return null;
    }

    if (feedback is! Map<String, dynamic>) {
      return null;
    }

    return FeedbackModel.fromJson({
      ...feedback,
      'tokenId': data['tokenId']?.toString() ?? tokenId,
    });
  }

  Future<FeedbackModel> submitFeedback({
    required String tokenId,
    required int rating,
    String? comment,
  }) async {
    if (rating < 1 || rating > 5) {
      throw ArgumentError('Rating must be between 1 and 5.');
    }

    final trimmedComment = comment?.trim();

    if (trimmedComment != null && trimmedComment.length > 1000) {
      throw ArgumentError('Comment cannot exceed 1000 characters.');
    }

    final Map<String, dynamic> body = {
      'rating': rating,
    };

    if (trimmedComment != null && trimmedComment.isNotEmpty) {
      body['comment'] = trimmedComment;
    }

    final response = await _apiService.post(
      '/api/queue/tokens/$tokenId/feedback',
      body: body,
    );

    final data = response['data'];

    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid feedback response.');
    }

    final feedback = data['feedback'];

    if (feedback is! Map<String, dynamic>) {
      throw Exception('Invalid feedback response.');
    }

    return FeedbackModel.fromJson({
      ...feedback,
      'tokenId': data['tokenId']?.toString() ?? tokenId,
    });
  }
}
