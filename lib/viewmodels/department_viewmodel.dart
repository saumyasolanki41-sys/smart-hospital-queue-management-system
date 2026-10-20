import 'package:flutter/foundation.dart';
import '../models/department_model.dart';
import '../services/api_service.dart';
import '../services/department_service.dart';

class DepartmentViewModel extends ChangeNotifier {
  final DepartmentService _departmentService;

  DepartmentViewModel({
    DepartmentService? departmentService,
  }) : _departmentService =
            departmentService ?? DepartmentService();

  List<DepartmentModel> _departments = [];
  bool _isLoading = false;
  String? _error;

  List<DepartmentModel> get departments =>
      List.unmodifiable(_departments);

  bool get isLoading => _isLoading;

  String? get error => _error;

  bool get hasDepartments => _departments.isNotEmpty;

  Future<void> fetchDepartments({
    bool refresh = false,
  }) async {
    if (_isLoading) return;

    if (!refresh && _departments.isNotEmpty) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _departmentService.getDepartments();

      _departments = result;
    } on ApiException catch (exception) {
      _error = exception.message;
    } catch (_) {
      _error = 'Unable to load departments. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshDepartments() async {
    await fetchDepartments(refresh: true);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
