
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import '../models/ambulance_request_model.dart';
import '../controller/ambulance_controller.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';

class AmbulanceScreen extends StatefulWidget {
  const AmbulanceScreen({super.key});

  @override
  State<AmbulanceScreen> createState() => _AmbulanceScreenState();
}

class _AmbulanceScreenState extends State<AmbulanceScreen> {
  static const Color _primary = Color.fromARGB(255, 126, 211, 232);
  static const Color _background = Color(0xFFF0FAFC);
  static const Color _heading = Color(0xFF173B4D);
  static const Color _cardColor = Color(0xFFFFFFFF);
  static const Color _muted = Color(0xFF668694);

  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  double? _latitude;
  double? _longitude;
  bool _isGettingLocation = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<AmbulanceController>().fetchMyRequests(refresh: true);
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<bool> _getCurrentLocation() async {
    if (_isGettingLocation) return false;

    setState(() => _isGettingLocation = true);

    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (mounted) {
          _showMessage(
            'Please turn on Location/GPS on your device.',
          );
        }
        return false;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (mounted) {
          _showMessage(
            'Location permission is required to request an ambulance.',
          );
        }
        return false;
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          _showMessage(
            'Location permission is permanently denied. '
            'Enable it in your app settings.',
          );

          await Geolocator.openAppSettings();
        }
        return false;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 30),
        ),
      );

      if (!mounted) return false;

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      try {
        final geocoding = Geocoding();

        final placemarks =
            await geocoding.placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (!mounted) return false;

        if (placemarks.isEmpty) {
          _showMessage(
            'GPS detected, but no readable address was found. '
            'Please enter the address manually.',
          );
          return true;
        }

        final place = placemarks.first;
        final addressParts = <String?>[
          place.name,
          place.street,
          place.subLocality,
          place.locality,
          place.subAdministrativeArea,
          place.administrativeArea,
          place.postalCode,
          place.country,
        ]
            .whereType<String>()
            .map((part) => part.trim())
            .where((part) => part.isNotEmpty)
            .toList();

        final uniqueParts = <String>[];

        for (final part in addressParts) {
          if (!uniqueParts.any(
            (existing) =>
                existing.toLowerCase() == part.toLowerCase(),
          )) {
            uniqueParts.add(part);
          }
        }

        final address = uniqueParts.join(', ');

        if (address.isNotEmpty) {
          _addressController.text = address;

          _showMessage('Pickup address filled successfully.');
        } else {
          _showMessage(
            'GPS detected, but no readable address was found. '
            'Please enter the address manually.',
          );
        }
      } catch (e) {
        debugPrint('Address lookup failed: $e');

        if (mounted) {
          _showMessage(
            'GPS detected, but the address could not be retrieved. '
            'Please enter it manually.',
          );
        }
      }

      return true;
    } catch (e) {
      debugPrint('Getting current location failed: $e');

      if (mounted) {
        _showMessage(
          'Could not get location. Please try again.',
        );
      }

      return false;
    } finally {
      if (mounted) {
        setState(() => _isGettingLocation = false);
      }
    }
  }

  Future<void> _submitRequest() async {
    FocusScope.of(context).unfocus();

    final address = _addressController.text.trim();
    final phone = _phoneController.text.trim();

    if (address.isEmpty) {
      _showMessage('Please enter your pickup address.');
      return;
    }

    if (phone.isEmpty) {
      _showMessage('Please enter your contact phone number.');
      return;
    }

    if (_latitude == null || _longitude == null) {
      final locationObtained = await _getCurrentLocation();

      if (!locationObtained || !mounted) return;
    }

    final latitude = _latitude;
    final longitude = _longitude;

    if (latitude == null || longitude == null) {
      _showMessage('Current location is unavailable.');
      return;
    }

    final controller = context.read<AmbulanceController>();

    try {
      await controller.requestAmbulance(
        pickupAddress: _addressController.text.trim(),
        latitude: latitude,
        longitude: longitude,
        contactPhone: phone,
      );

      if (!mounted) return;

      if (controller.error == null &&
          controller.selectedRequest != null) {
        _addressController.clear();
        _phoneController.clear();

        setState(() {
          _latitude = null;
          _longitude = null;
        });

        _showMessage(
          'Ambulance request submitted successfully.',
        );
      } else {
        _showMessage(
          'Unable to submit ambulance request. Please try again.',
        );
      }
    } catch (e) {
      debugPrint('Ambulance request failed: $e');

      if (mounted) {
        _showMessage(
          'Unable to submit ambulance request. Please try again.',
        );
      }
    }
  }

  Future<void> _refreshRequests() async {
    try {
      await context
          .read<AmbulanceController>()
          .fetchMyRequests(refresh: true);
    } catch (e) {
      debugPrint('Refreshing ambulance requests failed: $e');

      if (mounted) {
        _showMessage(
          'Unable to refresh requests. Please try again.',
        );
      }
    }
  }

  Future<void> _refreshEta(
    AmbulanceRequestModel request,
  ) async {
    final controller = context.read<AmbulanceController>();

    try {
      await controller.refreshEta(request.id);

      if (!mounted) return;

      if (controller.error != null) {
        _showMessage(
          'Unable to refresh ETA. Please try again.',
        );
      } else {
        _showMessage('ETA refreshed.');
      }
    } catch (e) {
      debugPrint('Refreshing ambulance ETA failed: $e');

      if (mounted) {
        _showMessage(
          'Unable to refresh ETA. Please try again.',
        );
      }
    }
  }

  Future<void> _cancelRequest(
    AmbulanceRequestModel request,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _cardColor,
        title: const Text(
          'Cancel Request',
          style: TextStyle(color: _heading),
        ),
        content: const Text(
          'Are you sure you want to cancel this ambulance request?',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: const Text('Keep Request'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: _heading,
            ),
            onPressed: () =>
                Navigator.pop(dialogContext, true),
            child: const Text('Cancel Request'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final controller = context.read<AmbulanceController>();

    try {
      await controller.cancelRequest(request.id);

      if (!mounted) return;

      if (controller.error == null) {
        _showMessage('Cancellation request processed.');
        await _refreshRequests();
      } else {
        _showMessage(
          'Unable to cancel the request. Please try again.',
        );
      }
    } catch (e) {
      debugPrint('Cancelling ambulance request failed: $e');

      if (mounted) {
        _showMessage(
          'Unable to cancel the request. Please try again.',
        );
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: _heading,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  String _display(
    dynamic value, [
    String fallback = 'Not available',
  ]) {
    if (value == null) return fallback;

    final text = value.toString().trim();

    if (text.isEmpty || text == 'null') return fallback;

    return text;
  }

  bool _canCancel(String status) {
    final value = status.toLowerCase();

    return value != 'cancelled' &&
        value != 'canceled' &&
        value != 'completed' &&
        value != 'served';
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AmbulanceController>();

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: _heading,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Ambulance Assistance',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh requests',
            onPressed:
                controller.isLoading ? null : _refreshRequests,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: RefreshIndicator(
        color: _primary,
        onRefresh: _refreshRequests,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(21),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF267D98),
                    Color.fromARGB(255, 126, 211, 232),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: _primary.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    height: 78,
                    width: 78,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.airport_shuttle_rounded,
                      size: 47,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ambulance Assistance',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Request emergency transport and track your request.',
                          style: TextStyle(
                            color: Color(0xFFF0FAFC),
                            height: 1.45,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const _SectionHeading(
              title: 'Request an Ambulance',
              subtitle: 'Enter your pickup and contact details',
            ),

            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: _heading.withValues(alpha: 0.07),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _addressController,
                    textCapitalization: TextCapitalization.words,
                    style: const TextStyle(color: _heading),
                    decoration: _inputDecoration(
                      label: 'Pickup Address',
                      hint: 'Enter your current pickup address',
                      icon: Icons.location_on_outlined,
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: _heading),
                    decoration: _inputDecoration(
                      label: 'Contact Phone Number',
                      hint: 'Enter your phone number',
                      icon: Icons.phone_outlined,
                    ),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isGettingLocation
                          ? null
                          : _getCurrentLocation,
                      icon: _isGettingLocation
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _primary,
                              ),
                            )
                          : const Icon(
                              Icons.my_location_rounded,
                            ),
                      label: Text(
                        _isGettingLocation
                            ? 'Getting Current Location...'
                            : 'Use My Current Location',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF267D98),
                        side: const BorderSide(
                          color: _primary,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                    ),
                  ),

                  if (_latitude != null &&
                      _longitude != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE1F8EE),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            color: Color(0xFF299B76),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'GPS Location Detected',
                                  style: TextStyle(
                                    color: Color(0xFF26785F),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'Latitude: ${_latitude!.toStringAsFixed(6)}\n'
                                  'Longitude: ${_longitude!.toStringAsFixed(6)}',
                                  style: const TextStyle(
                                    color: Color(0xFF397C6C),
                                    fontSize: 12,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Update location',
                            onPressed: _isGettingLocation
                                ? null
                                : _getCurrentLocation,
                            icon: const Icon(
                              Icons.refresh_rounded,
                              color: Color(0xFF267D98),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed:
                          controller.isRequesting ||
                                  _isGettingLocation
                              ? null
                              : _submitRequest,
                      icon: controller.isRequesting
                          ? const SizedBox(
                              height: 19,
                              width: 19,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.airport_shuttle_rounded,
                            ),
                      label: Text(
                        controller.isRequesting
                            ? 'Submitting Request...'
                            : 'Request Ambulance',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF267D98),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: _muted,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            Row(
              children: [
                const Expanded(
                  child: _SectionHeading(
                    title: 'My Ambulance Requests',
                    subtitle: 'View status and estimated arrival',
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: IconButton(
                    tooltip: 'Refresh requests',
                    onPressed:
                        controller.isLoading ? null : _refreshRequests,
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: Color(0xFF267D98),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            if (controller.isLoading &&
                controller.requests.isEmpty)
              const Padding(
                padding: EdgeInsets.all(28),
                child: Center(
                  child: CircularProgressIndicator(
                    color: _primary,
                  ),
                ),
              )
            else if (controller.error != null &&
                controller.requests.isEmpty)
              _EmptyState(
                icon: Icons.cloud_off_rounded,
                title: 'Unable to load requests',
                message:
                    'Unable to load requests. Please try again.',
                buttonLabel: 'Try Again',
                onPressed: _refreshRequests,
              )
            else if (controller.requests.isEmpty)
              const _EmptyState(
                icon: Icons.airport_shuttle_rounded,
                title: 'No requests yet',
                message:
                    'Your ambulance requests will appear here.',
              )
            else
              ...controller.requests.map(
                (request) => _RequestCard(
                  request: request,
                  display: _display,
                  canCancel: _canCancel,
                  onRefreshEta: () => _refreshEta(request),
                  onCancel: () => _cancelRequest(request),
                ),
              ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF267D98)),
      labelStyle: const TextStyle(color: _heading),
      hintStyle: const TextStyle(
        color: _muted,
        fontSize: 13,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 17,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFD0EAF0),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFD0EAF0),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFF267D98),
          width: 1.5,
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeading({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF173B4D),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF668694),
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _RequestCard extends StatelessWidget {
  final AmbulanceRequestModel request;
  final String Function(dynamic, [String]) display;
  final bool Function(String) canCancel;
  final VoidCallback onRefreshEta;
  final VoidCallback onCancel;

  const _RequestCard({
    required this.request,
    required this.display,
    required this.canCancel,
    required this.onRefreshEta,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final status = display(request.status, 'Pending');
    final eta = request.estimatedArrivalMinutes;

    final normalizedStatus = status.toLowerCase();

    final statusColor =
        normalizedStatus == 'completed' ||
                normalizedStatus == 'served'
            ? const Color(0xFF268566)
            : normalizedStatus == 'cancelled' ||
                    normalizedStatus == 'canceled'
                ? const Color(0xFFB94D58)
                : const Color(0xFF267D98);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: const Color(0xFFD0EAF0),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF173B4D)
                .withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 49,
                width: 49,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5F7FB),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.airport_shuttle_rounded,
                  color: Color(0xFF267D98),
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Ambulance Request',
                  style: TextStyle(
                    color: Color(0xFF173B4D),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(
              color: Color(0xFFD0EAF0),
              height: 1,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: Color(0xFF4FAFCB),
                size: 21,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  display(request.pickupAddress),
                  style: const TextStyle(
                    color: Color(0xFF527786),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFFE5F7FB),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  color: Color(0xFF267D98),
                  size: 23,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Estimated arrival',
                    style: TextStyle(
                      color: Color(0xFF527786),
                      fontSize: 13,
                    ),
                  ),
                ),
                Text(
                  eta == null ? 'Pending' : '$eta min',
                  style: const TextStyle(
                    color: Color(0xFF173B4D),
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 13),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onRefreshEta,
                icon: const Icon(
                  Icons.schedule_rounded,
                  size: 18,
                ),
                label: const Text('Refresh ETA'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF267D98),
                  side: const BorderSide(
                    color: Color(0xFF7ED3E8),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              if (canCancel(status))
                TextButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                  ),
                  label: const Text('Cancel Request'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFB94D58),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? buttonLabel;
  final VoidCallback? onPressed;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.buttonLabel,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(21),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 43,
            color: const Color(0xFF4FAFCB),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF173B4D),
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF668694),
              height: 1.45,
            ),
          ),
          if (buttonLabel != null && onPressed != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onPressed,
              child: Text(
                buttonLabel!,
                style: const TextStyle(
                  color: Color(0xFF267D98),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
