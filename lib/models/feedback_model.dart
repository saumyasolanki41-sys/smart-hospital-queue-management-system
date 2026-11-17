
class FeedbackModel {
  final String tokenId;
  final int rating;
  final String? comment;
  final DateTime? submittedAt;

  const FeedbackModel({
    required this.tokenId,
    required this.rating,
    this.comment,
    this.submittedAt,
  });

  factory FeedbackModel.fromJson(Map<String, dynamic> json) {
    return FeedbackModel(
      tokenId: json['tokenId']?.toString() ?? '',
      rating: json['rating'] is num
          ? (json['rating'] as num).toInt()
          : 0,
      comment: json['comment']?.toString(),
      submittedAt: json['submittedAt'] == null
          ? null
          : DateTime.tryParse(json['submittedAt'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tokenId': tokenId,
      'rating': rating,
      'comment': comment,
      'submittedAt': submittedAt?.toIso8601String(),
    };
  }

  bool get hasComment => comment != null && comment!.trim().isNotEmpty;
}
