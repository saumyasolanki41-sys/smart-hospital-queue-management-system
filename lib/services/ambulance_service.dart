
import '../models/ambulance_request_model.dart';
import 'api_service.dart';

class AmbulanceService {
  final ApiService _apiService;

  AmbulanceService({
    ApiService? apiService,
  }) : _apiService = apiService ?? ApiService();

  Future<AmbulanceRequestModel> requestAmbulance({
    required String pickupAddress,
    required double latitude,
    required double longitude,
    required String contactPhone,
  }) async {
    if (pickupAddress.trim().isEmpty) {
      throw const ApiException('Please enter your pickup address.');
    }

    if (contactPhone.trim().isEmpty) {
      throw const ApiException('Please enter your contact number.');
    }

    final response = await _apiService.post(
      '/api/ambulance-requests',
      body: {
        'pickupAddress': pickupAddress.trim(),
        'latitude': latitude,
        'longitude': longitude,
        'contactPhone': contactPhone.trim(),
      },
      authenticated: true,
    );

    final data = response['data'];
    dynamic request;

    if (data is Map) {
      request = data['request'] ??
          data['ambulanceRequest'] ??
          data;
    }

    request ??= response['request'];

    if (request is! Map) {
      throw const ApiException(
        'Unexpected ambulance request response from the server.',
      );
    }

    return AmbulanceRequestModel.fromJson(
      Map<String, dynamic>.from(request),
    );
  }

  Future<List<AmbulanceRequestModel>> getMyRequests() async {
    final response = await _apiService.get(
      '/api/ambulance-requests',
      authenticated: true,
    );

    final data = response['data'];
    dynamic requests;

    if (data is List) {
      requests = data;
    } else if (data is Map) {
      requests = data['requests'] ??
          data['ambulanceRequests'] ??
          data['items'] ??
          data['results'];
    }

    requests ??= response['requests'];

    if (requests is! List) {
      throw const ApiException(
        'Unexpected ambulance requests response from the server.',
      );
    }

    return requests
        .whereType<Map>()
        .map(
          (request) => AmbulanceRequestModel.fromJson(
            Map<String, dynamic>.from(request),
          ),
        )
        .toList();
  }

  Future<AmbulanceRequestModel> getRequestById(
    String requestId,
  ) async {
    if (requestId.trim().isEmpty) {
      throw const ApiException('Ambulance request ID is required.');
    }

    final response = await _apiService.get(
      '/api/ambulance-requests/${Uri.encodeComponent(requestId.trim())}',
      authenticated: true,
    );

    final data = response['data'];
    dynamic request;

    if (data is Map) {
      request = data['request'] ??
          data['ambulanceRequest'] ??
          data;
    }

    request ??= response['request'];

    if (request is! Map) {
      throw const ApiException(
        'Unexpected ambulance request details response.',
      );
    }

    return AmbulanceRequestModel.fromJson(
      Map<String, dynamic>.from(request),
    );
  }

  Future<int?> getEtaMinutes(String requestId) async {
    if (requestId.trim().isEmpty) {
      throw const ApiException('Ambulance request ID is required.');
    }

    final response = await _apiService.get(
      '/api/ambulance-requests/'
      '${Uri.encodeComponent(requestId.trim())}/eta',
      authenticated: true,
    );

    final data = response['data'];

    dynamic etaData = data;

    if (data is Map) {
      etaData = data['eta'] ??
          data['estimate'] ??
          data['request'] ??
          data;
    }

    dynamic minutes;

    if (etaData is Map) {
      minutes = etaData['estimatedArrivalMinutes'] ??
          etaData['etaMinutes'] ??
          etaData['estimatedMinutes'] ??
          etaData['minutes'];
    } else if (etaData is num) {
      minutes = etaData;
    }

    if (minutes is num) {
      return minutes.round();
    }

    if (minutes is String) {
      return int.tryParse(minutes);
    }

    // The backend may not have calculated an ETA yet.
    return null;
  }

  Future<void> cancelRequest(String requestId) async {
    if (requestId.trim().isEmpty) {
      throw const ApiException('Ambulance request ID is required.');
    }

    await _apiService.patch(
      '/api/ambulance-requests/'
      '${Uri.encodeComponent(requestId.trim())}/cancel',
      authenticated: true,
    );
  }
}
