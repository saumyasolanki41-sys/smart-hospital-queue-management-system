
class DoctorModel {
  final String id;
  final String name;
  final String? departmentId;
  final String? departmentName;
  final String? specialization;
  final String? qualification;
  final String? imageUrl;
  final bool isAvailable;

  const DoctorModel({
    required this.id,
    required this.name,
    this.departmentId,
    this.departmentName,
    this.specialization,
    this.qualification,
    this.imageUrl,
    this.isAvailable = true,
  });

  factory DoctorModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final dynamic department =
        json['department'] ?? json['departmentId'];

    String? extractedDepartmentId;
    String? extractedDepartmentName;

    if (department is Map<String, dynamic>) {
      extractedDepartmentId = (
        department['_id'] ??
        department['id'] ??
        department['departmentId']
      )?.toString();

      extractedDepartmentName = (
        department['name'] ??
        department['departmentName']
      )?.toString();
    } else if (department != null) {
      extractedDepartmentId = department.toString();
    }

    return DoctorModel(
      id: (
        json['_id'] ??
        json['id'] ??
        json['doctorId'] ??
        ''
      ).toString(),
      name: (
        json['name'] ??
        json['fullName'] ??
        json['doctorName'] ??
        'Unknown Doctor'
      ).toString(),
      departmentId: (
        json['departmentId'] ??
        extractedDepartmentId
      )?.toString(),
      departmentName: (
        json['departmentName'] ??
        extractedDepartmentName
      )?.toString(),
      specialization: (
        json['specialization'] ??
        json['speciality']
      )?.toString(),
      qualification: json['qualification']?.toString(),
      imageUrl: (
        json['imageUrl'] ??
        json['photoUrl'] ??
        json['image']
      )?.toString(),
      isAvailable: json['isAvailable'] != false &&
          json['isAvailable'] != 0,
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
      'isAvailable': isAvailable,
    };
  }
}
