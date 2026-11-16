import '../models/doctor_model.dart';
import 'api_service.dart';

class DoctorService {
  final ApiService _apiService;

  DoctorService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  Future<List<DoctorModel>> getDoctors({
    int page = 1,
    int limit = 20,
    String? departmentId,
    bool? isAvailable,
  }) async {
    final queryParameters = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (departmentId != null && departmentId.trim().isNotEmpty) {
      queryParameters['departmentId'] = departmentId.trim();
    }

    if (isAvailable != null) {
      queryParameters['isAvailable'] = isAvailable.toString();
    }

    final uri = Uri(
      path: '/api/doctors',
      queryParameters: queryParameters,
    );

    final response = await _apiService.get(
      uri.toString(),
      authenticated: false,
    );

    final data = response['data'];

    dynamic doctors;

    if (data is List) {
      doctors = data;
    } else if (data is Map) {
      doctors = data['doctors'] ??
          data['items'] ??
          data['results'];
    }

    doctors ??= response['doctors'];

    if (doctors is! List) {
      throw const ApiException(
        'Unexpected doctors response from the server.',
      );
    }

    return doctors
        .whereType<Map>()
        .map(
          (doctor) => DoctorModel.fromJson(
            Map<String, dynamic>.from(doctor),
          ),
        )
        .toList();
  }

  Future<DoctorModel> getDoctorById(String doctorId) async {
    if (doctorId.trim().isEmpty) {
      throw const ApiException('Doctor ID is required.');
    }

    final response = await _apiService.get(
      '/api/doctors/${Uri.encodeComponent(doctorId.trim())}',
      authenticated: false,
    );

    final data = response['data'];

    dynamic doctor;

    if (data is Map) {
      doctor = data['doctor'] ?? data;
    }

    doctor ??= response['doctor'];

    if (doctor is! Map) {
      throw const ApiException(
        'Unexpected doctor details response from the server.',
      );
    }

    return DoctorModel.fromJson(
      Map<String, dynamic>.from(doctor),
    );
  }
}
