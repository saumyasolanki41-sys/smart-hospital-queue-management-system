
class DoctorModel {
  final String id;
  final String name;
  final String? departmentId;
  final String? departmentName;
  final String? specialization;
  final String? qualification;
  final String? imageUrl;
  final int? experienceYears;
  final double? consultationFee;
  final bool isAvailable;
  final bool isQueuePaused;
  final String? queuePauseReason;
  final DateTime? queuePausedAt;

  const DoctorModel({
    required this.id,
    required this.name,
    this.departmentId,
    this.departmentName,
    this.specialization,
    this.qualification,
    this.imageUrl,
    this.experienceYears,
    this.consultationFee,
    this.isAvailable = true,
    this.isQueuePaused = false,
    this.queuePauseReason,
    this.queuePausedAt,
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    final dynamic department = json['department'] ?? json['departmentId'];

    final dynamic queueState = json['queueState'];

    final Map<String, dynamic>? queueStateData =
        queueState is Map
            ? Map<String, dynamic>.from(queueState)
            : null;

    String? extractedDepartmentId;
    String? extractedDepartmentName;

    if (department is Map<String, dynamic>) {
      extractedDepartmentId =
          (department['_id'] ??
                  department['id'] ??
                  department['departmentId'])
              ?.toString();

      extractedDepartmentName =
          (department['name'] ?? department['departmentName'])?.toString();
    } else if (department != null) {
      extractedDepartmentId = department.toString();
    }

    return DoctorModel(
      id: (json['_id'] ?? json['id'] ?? json['doctorId'] ?? '').toString(),
      name: (json['name'] ??
              json['fullName'] ??
              json['doctorName'] ??
              'Unknown Doctor')
          .toString(),
      departmentId:
          (json['departmentId'] ?? extractedDepartmentId)?.toString(),
      departmentName:
          (json['departmentName'] ?? extractedDepartmentName)?.toString(),
      specialization:
          (json['specialization'] ?? json['speciality'])?.toString(),
      qualification:
          (json['qualification'] ??
                  json['qualifications'] ??
                  json['degree'] ??
                  json['education'])
              ?.toString(),
      imageUrl:
          (json['imageUrl'] ?? json['photoUrl'] ?? json['image'])?.toString(),
      experienceYears:
          (json['experienceYears'] as num?)?.toInt(),
      consultationFee:
          (json['consultationFee'] as num?)?.toDouble(),
      isAvailable: json['isAvailable'] != false &&
          json['isAvailable'] != 0,
      isQueuePaused:
          json['queuePaused'] == true ||
          queueStateData?['paused'] == true,
      queuePauseReason:
          (json['queuePauseReason'] ?? queueStateData?['reason'])?.toString(),
      queuePausedAt: DateTime.tryParse(
        (json['queuePausedAt'] ?? queueStateData?['pausedAt'])?.toString() ?? '',
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'departmentId': departmentId,
      'departmentName': departmentName,
      'specialization': specialization,
      'qualification': qualification,
      'imageUrl': imageUrl,
      'experienceYears': experienceYears,
      'consultationFee': consultationFee,
      'isAvailable': isAvailable,
      'queuePaused': isQueuePaused,
      'queuePauseReason': queuePauseReason,
      'queuePausedAt': queuePausedAt?.toIso8601String(),
    };
  }
}
