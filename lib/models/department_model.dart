class DepartmentModel {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final bool isActive;

  const DepartmentModel({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.isActive = true,
  });

  factory DepartmentModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return DepartmentModel(
      id: (
        json['_id'] ??
        json['id'] ??
        json['departmentId'] ??
        ''
      ).toString(),
      name: (
        json['name'] ??
        json['departmentName'] ??
        json['title'] ??
        'Unnamed Department'
      ).toString(),
      description: (
        json['description'] ??
        json['details']
      )?.toString(),
      imageUrl: (
        json['imageUrl'] ??
        json['image']
      )?.toString(),
      isActive: json['isActive'] != false &&
          json['isActive'] != 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'isActive': isActive,
    };
  }
}
