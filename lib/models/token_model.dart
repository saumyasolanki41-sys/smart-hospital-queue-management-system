
class TokenModel {
  final String id;
  final String tokenNumber;
  final String patientId;
  final String doctorId;
  final String departmentId;
  final String? doctorName;
  final String? departmentName;
  final int patientsAhead;
  final int estimatedWaitMinutes;
  final String status;
  final DateTime? appointmentTime;
  final DateTime? createdAt;

  const TokenModel({
    required this.id,
    required this.tokenNumber,
    required this.patientId,
    required this.doctorId,
    required this.departmentId,
    this.doctorName,
    this.departmentName,
    this.patientsAhead = 0,
    this.estimatedWaitMinutes = 0,
    this.status = 'waiting',
    this.appointmentTime,
    this.createdAt,
  });

  factory TokenModel.fromJson(Map<String, dynamic> json) {
    final dynamic doctor = json['doctor'];
    final dynamic department = json['department'];

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    return TokenModel(
      id: (
        json['_id'] ??
        json['id'] ??
        json['tokenId'] ??
        ''
      ).toString(),
      tokenNumber: (
        json['tokenNumber'] ??
        json['tokenNo'] ??
        json['number'] ??
        ''
      ).toString(),
      patientId: (
        json['patientId'] ??
        json['userId'] ??
        ''
      ).toString(),
      doctorId: (
        json['doctorId'] ??
        (doctor is Map ? doctor['_id'] : null) ??
        ''
      ).toString(),
      departmentId: (
        json['departmentId'] ??
        (department is Map ? department['_id'] : null) ??
        ''
      ).toString(),
      doctorName: (
        json['doctorName'] ??
        (doctor is Map ? doctor['name'] : null)
      )?.toString(),
      departmentName: (
        json['departmentName'] ??
        (department is Map ? department['name'] : null)
      )?.toString(),
      patientsAhead: int.tryParse(
            (
              json['patientsAhead'] ??
              json['peopleAhead'] ??
              0
            ).toString(),
          ) ??
          0,
      estimatedWaitMinutes: int.tryParse(
            (
              json['estimatedWaitMinutes'] ??
              json['estimatedWaitingTime'] ??
              json['estimatedWait'] ??
              0
            ).toString(),
          ) ??
          0,
      status: (
        json['status'] ??
        'waiting'
      ).toString(),
      appointmentTime: parseDate(
        json['appointmentTime'] ?? json['scheduledAt'],
      ),
      createdAt: parseDate(
        json['createdAt'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'tokenNumber': tokenNumber,
      'patientId': patientId,
      'doctorId': doctorId,
      'departmentId': departmentId,
      'doctorName': doctorName,
      'departmentName': departmentName,
      'patientsAhead': patientsAhead,
      'estimatedWaitMinutes': estimatedWaitMinutes,
      'status': status,
      'appointmentTime': appointmentTime?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
