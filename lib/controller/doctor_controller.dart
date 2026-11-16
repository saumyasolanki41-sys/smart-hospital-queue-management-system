import 'package:flutter/foundation.dart';
import '../models/doctor_model.dart';
import '../services/api_service.dart';
import '../services/doctor_service.dart';

class DoctorController extends ChangeNotifier {
  final DoctorService _doctorService;

  DoctorController({
    DoctorService? doctorService,
  }) : _doctorService = doctorService ?? DoctorService();

  List<DoctorModel> _doctors = [];
  bool _isLoading = false;
  String? _error;
  String? _selectedDepartmentId;

  List<DoctorModel> get doctors => List.unmodifiable(_doctors);

  bool get isLoading => _isLoading;

  String? get error => _error;

  String? get selectedDepartmentId => _selectedDepartmentId;

  bool get hasDoctors => _doctors.isNotEmpty;

  Future<void> fetchDoctors({
    String? departmentId,
    bool? isAvailable,
    bool refresh = false,
  }) async {
    if (_isLoading) return;

    final normalizedDepartmentId =
        departmentId?.trim().isNotEmpty == true
            ? departmentId!.trim()
            : null;

    if (!refresh &&
        _doctors.isNotEmpty &&
        _selectedDepartmentId == normalizedDepartmentId) {
      return;
    }

    _isLoading = true;
    _error = null;
    _selectedDepartmentId = normalizedDepartmentId;
    notifyListeners();

    try {
      _doctors = await _doctorService.getDoctors(
        departmentId: normalizedDepartmentId,
        isAvailable: isAvailable,
      );
    } on ApiException catch (exception) {
      _error = exception.message;
      _doctors = [];
    } catch (_) {
      _error = 'Unable to load doctors. Please try again.';
      _doctors = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> filterByDepartment(String? departmentId) async {
    await fetchDoctors(
      departmentId: departmentId,
      refresh: true,
    );
  }

  Future<void> refreshDoctors() async {
    await fetchDoctors(
      departmentId: _selectedDepartmentId,
      refresh: true,
    );
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearDoctors() {
    _doctors = [];
    _selectedDepartmentId = null;
    _error = null;
    notifyListeners();
  }
}
