import 'package:flutter/foundation.dart';
import '../models/ambulance_request_model.dart';
import '../services/ambulance_service.dart';
import '../services/api_service.dart';

class AmbulanceController extends ChangeNotifier {
  final AmbulanceService _ambulanceService;

  AmbulanceController({
    AmbulanceService? ambulanceService,
  }) : _ambulanceService =
            ambulanceService ?? AmbulanceService();

  List<AmbulanceRequestModel> _requests = [];
  AmbulanceRequestModel? _selectedRequest;

  bool _isLoading = false;
  bool _isRequesting = false;
  bool _isCancelling = false;
  bool _isLoadingEta = false;

  String? _error;

  List<AmbulanceRequestModel> get requests =>
      List.unmodifiable(_requests);

  AmbulanceRequestModel? get selectedRequest =>
      _selectedRequest;

  bool get isLoading => _isLoading;

  bool get isRequesting => _isRequesting;

  bool get isCancelling => _isCancelling;

  bool get isLoadingEta => _isLoadingEta;

  String? get error => _error;

  bool get hasRequests => _requests.isNotEmpty;

  Future<AmbulanceRequestModel?> requestAmbulance({
    required String pickupAddress,
    required double latitude,
    required double longitude,
    required String contactPhone,
  }) async {
    if (_isRequesting) return null;

    _isRequesting = true;
    _error = null;
    notifyListeners();

    try {
      final request = await _ambulanceService.requestAmbulance(
        pickupAddress: pickupAddress,
        latitude: latitude,
        longitude: longitude,
        contactPhone: contactPhone,
      );

      _selectedRequest = request;

      _requests = [
        request,
        ..._requests.where((item) => item.id != request.id),
      ];

      return request;
    } on ApiException catch (exception) {
      _error = exception.message;
      return null;
    } catch (_) {
      _error = 'Unable to request an ambulance. Please try again.';
      return null;
    } finally {
      _isRequesting = false;
      notifyListeners();
    }
  }

  Future<void> fetchMyRequests({
    bool refresh = false,
  }) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _requests = await _ambulanceService.getMyRequests();

      if (_selectedRequest != null) {
        for (final request in _requests) {
          if (request.id == _selectedRequest!.id) {
            _selectedRequest = request;
            break;
          }
        }
      }
    } on ApiException catch (exception) {
      _error = exception.message;

      if (!refresh) {
        _requests = [];
      }
    } catch (_) {
      _error = 'Unable to load ambulance requests. Please try again.';

      if (!refresh) {
        _requests = [];
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<AmbulanceRequestModel?> fetchRequestById(
    String requestId,
  ) async {
    _error = null;

    try {
      final request =
          await _ambulanceService.getRequestById(requestId);

      _selectedRequest = request;
      _updateRequestInList(request);

      return request;
    } on ApiException catch (exception) {
      _error = exception.message;
    } catch (_) {
      _error = 'Unable to load request details. Please try again.';
    }

    notifyListeners();
    return null;
  }

  Future<int?> refreshEta(String requestId) async {
    if (_isLoadingEta) return null;

    _isLoadingEta = true;
    _error = null;
    notifyListeners();

    try {
      final minutes =
          await _ambulanceService.getEtaMinutes(requestId);

      if (minutes != null) {
        final index = _requests.indexWhere(
          (request) => request.id == requestId,
        );

        if (index >= 0) {
          final oldRequest = _requests[index];

          final updatedRequest = AmbulanceRequestModel(
            id: oldRequest.id,
            pickupAddress: oldRequest.pickupAddress,
            latitude: oldRequest.latitude,
            longitude: oldRequest.longitude,
            contactPhone: oldRequest.contactPhone,
            status: oldRequest.status,
            ambulanceId: oldRequest.ambulanceId,
            estimatedArrivalMinutes: minutes,
            createdAt: oldRequest.createdAt,
          );

          _updateRequestInList(updatedRequest);
        }

        if (_selectedRequest?.id == requestId) {
          final oldRequest = _selectedRequest!;

          _selectedRequest = AmbulanceRequestModel(
            id: oldRequest.id,
            pickupAddress: oldRequest.pickupAddress,
            latitude: oldRequest.latitude,
            longitude: oldRequest.longitude,
            contactPhone: oldRequest.contactPhone,
            status: oldRequest.status,
            ambulanceId: oldRequest.ambulanceId,
            estimatedArrivalMinutes: minutes,
            createdAt: oldRequest.createdAt,
          );
        }
      }

      return minutes;
    } on ApiException catch (exception) {
      _error = exception.message;
      return null;
    } catch (_) {
      _error = 'Unable to calculate ambulance ETA. Please try again.';
      return null;
    } finally {
      _isLoadingEta = false;
      notifyListeners();
    }
  }

  Future<bool> cancelRequest(String requestId) async {
    if (_isCancelling) return false;

    _isCancelling = true;
    _error = null;
    notifyListeners();

    try {
      await _ambulanceService.cancelRequest(requestId);

      await fetchMyRequests(refresh: true);

      return true;
    } on ApiException catch (exception) {
      _error = exception.message;
      return false;
    } catch (_) {
      _error = 'Unable to cancel the ambulance request. Please try again.';
      return false;
    } finally {
      _isCancelling = false;
      notifyListeners();
    }
  }

  void selectRequest(AmbulanceRequestModel request) {
    _selectedRequest = request;
    notifyListeners();
  }

  void _updateRequestInList(
    AmbulanceRequestModel request,
  ) {
    final index = _requests.indexWhere(
      (item) => item.id == request.id,
    );

    if (index >= 0) {
      final updatedRequests = [..._requests];
      updatedRequests[index] = request;
      _requests = updatedRequests;
    } else {
      _requests = [..._requests, request];
    }

    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearRequests() {
    _requests = [];
    _selectedRequest = null;
    _error = null;
    notifyListeners();
  }
}
