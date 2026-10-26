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

  static String? _readName(dynamic value) {
    if (value is Map) {
      final name = value['name'] ??
          value['departmentName'] ??
          value['department_name'] ??
          value['title'];

      if (name != null && name.toString().trim().isNotEmpty) {
        return name.toString().trim();
      }
    }

    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }

    return null;
  }

  static String _readId(dynamic value) {
    if (value is Map) {
      return (value['_id'] ?? value['id'] ?? '').toString();
    }

    return value?.toString() ?? '';
  }

  static String _parseTokenNumber(Map<String, dynamic> json) {
    return (
      json['tokenNumber'] ??
      json['tokenNo'] ??
      json['number'] ??
      'N/A'
    ).toString();
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    if (value is DateTime) return value;

    if (value is num) {
      final timestamp = value.toInt();
      final milliseconds = timestamp.abs() < 1000000000000
          ? timestamp * 1000
          : timestamp;

      return DateTime.fromMillisecondsSinceEpoch(milliseconds);
    }

    if (value is String) {
      final text = value.trim();

      if (text.isEmpty || text.toLowerCase() == 'null') {
        return null;
      }

      return DateTime.tryParse(text);
    }

    if (value is Map) {
      if (value['_seconds'] != null) {
        return _parseDate(value['_seconds']);
      }

      if (value['seconds'] != null) {
        return _parseDate(value['seconds']);
      }
    }

    return null;
  }

  factory TokenModel.fromJson(Map<String, dynamic> json) {
    final dynamic doctor = json['doctor'];
    final dynamic department = json['department'];

    final dynamic doctorDepartment =
        doctor is Map ? doctor['department'] : null;

    final appointmentValue =
        json['appointmentTime'] ??
        json['appointment_time'] ??
        json['scheduledAt'] ??
        json['scheduled_at'] ??
        json['appointmentDate'] ??
        json['appointment_date'] ??
        json['dateTime'] ??
        json['date_time'] ??
        json['appointmentDateTime'] ??
        json['appointment_date_time'];

    final patient = json['patient'];

    final departmentId = (
      json['departmentId'] ??
      json['department_id'] ??
      (department is Map
          ? department['_id'] ?? department['id']
          : department is String
              ? department
              : null) ??
      (doctor is Map
          ? doctor['departmentId'] ??
              doctor['department_id'] ??
              _readId(doctorDepartment)
          : null) ??
      ''
    ).toString();

    return TokenModel(
      id: (
        json['_id'] ??
        json['id'] ??
        json['tokenId'] ??
        ''
      ).toString(),

      tokenNumber: _parseTokenNumber(json),

      patientId: (
        json['patientId'] ??
        json['userId'] ??
        (patient is Map ? patient['_id'] ?? patient['id'] : null) ??
        ''
      ).toString(),

      doctorId: (
        json['doctorId'] ??
        json['doctor_id'] ??
        _readId(doctor)
      ).toString(),

      departmentId: departmentId,

      doctorName: (
        _readName(json['doctorName']) ??
        _readName(doctor)
      ),

      departmentName: (
        _readName(json['departmentName']) ??
        _readName(json['department_name']) ??
        _readName(department) ??
        _readName(doctorDepartment) ??
        _readName(doctor is Map ? doctor['departmentName'] : null)
      ),

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

      status: (json['status'] ?? 'waiting').toString(),

      appointmentTime: _parseDate(appointmentValue),

      createdAt: _parseDate(
        json['createdAt'] ?? json['created_at'],
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
