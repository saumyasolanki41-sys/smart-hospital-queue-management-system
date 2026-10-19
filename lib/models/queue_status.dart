class UpcomingToken {
  final String token;
  final String status;

  const UpcomingToken({required this.token, required this.status});

  factory UpcomingToken.fromJson(Map<String, dynamic> json) => UpcomingToken(
        token: json['tokenNumber']?.toString() ?? '-',
        status: json['status']?.toString() ?? 'waiting',
      );
}

class QueueStatus {
  final String myToken;
  final String? currentlyServing;
  final int patientsAhead;
  final int? estimatedWaitMinutes;
  final String status; // waiting | called | in_consultation | completed
  final List<UpcomingToken> upcoming;

  const QueueStatus({
    required this.myToken,
    required this.currentlyServing,
    required this.patientsAhead,
    required this.estimatedWaitMinutes,
    required this.status,
    required this.upcoming,
  });

  factory QueueStatus.fromJson(Map<String, dynamic> json) {
    final rawUpcoming = json['upcoming'];
    return QueueStatus(
      myToken: json['tokenNumber']?.toString() ?? '-',
      currentlyServing: json['currentlyServing']?.toString(),
      patientsAhead: (json['patientsAhead'] as num?)?.toInt() ?? 0,
      estimatedWaitMinutes: (json['estimatedWaitMinutes'] as num?)?.round(),
      status: json['status']?.toString() ?? 'waiting',
      upcoming: rawUpcoming is List
          ? rawUpcoming
              .whereType<Map<String, dynamic>>()
              .map(UpcomingToken.fromJson)
              .toList()
          : const [],
    );
  }

  bool get isFinished => status == 'completed' || status == 'cancelled';
}