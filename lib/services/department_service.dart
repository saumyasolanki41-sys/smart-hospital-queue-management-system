
import '../models/department_model.dart';
import 'api_service.dart';

class DepartmentService {
  final ApiService _apiService;

  DepartmentService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  Future<List<DepartmentModel>> getDepartments({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _apiService.get(
      '/api/departments?page=$page&limit=$limit',
      authenticated: false,
    );

    final data = response['data'];

    dynamic departments;

    if (data is List) {
      departments = data;
    } else if (data is Map) {
      departments = data['departments'] ??
          data['items'] ??
          data['results'];
    }

    // Also handle APIs that return the list at the top level.
    departments ??= response['departments'];

    if (departments is! List) {
      throw const ApiException(
        'Unexpected departments response from the server.',
      );
    }

    return departments
        .whereType<Map>()
        .map(
          (department) => DepartmentModel.fromJson(
            Map<String, dynamic>.from(department),
          ),
        )
        .toList();
  }
}
