class AmbulanceRequestModel {
  final String id;
  final String pickupAddress;
  final double? latitude;
  final double? longitude;
  final String? contactPhone;
  final String status;
  final String? ambulanceId;
  final int? estimatedArrivalMinutes;
  final DateTime? createdAt;

  const AmbulanceRequestModel({
    required this.id,
    required this.pickupAddress,
    this.latitude,
    this.longitude,
    this.contactPhone,
    required this.status,
    this.ambulanceId,
    this.estimatedArrivalMinutes,
    this.createdAt,
  });

  factory AmbulanceRequestModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final ambulance = json['ambulance'];

    final etaValue = json['estimatedArrivalMinutes'] ??
        json['etaMinutes'] ??
        json['estimatedWaitMinutes'];

    return AmbulanceRequestModel(
      id: (json['_id'] ?? json['id'] ?? json['requestId'] ?? '')
          .toString(),
      pickupAddress:
          (json['pickupAddress'] ?? json['address'] ?? '').toString(),
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      contactPhone:
          (json['contactPhone'] ?? json['phone'])?.toString(),
      status: (json['status'] ?? 'pending').toString(),
      ambulanceId: json['ambulanceId']?.toString() ??
          (ambulance is Map ? ambulance['_id']?.toString() : null),
      estimatedArrivalMinutes: _toInt(etaValue),
      createdAt: DateTime.tryParse(
        (json['createdAt'] ?? json['created_at'] ?? '').toString(),
      ),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static int? _toInt(dynamic value) {
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '');
  }
}
