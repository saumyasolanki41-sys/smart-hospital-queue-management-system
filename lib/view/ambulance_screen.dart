
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../models/ambulance_request_model.dart';
import '../viewmodels/ambulance_viewmodel.dart';

class AmbulanceScreen extends StatefulWidget {
  const AmbulanceScreen({super.key});

  @override
  State<AmbulanceScreen> createState() => _AmbulanceScreenState();
}

class _AmbulanceScreenState extends State<AmbulanceScreen> {
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
      context.read<AmbulanceViewModel>().fetchMyRequests(refresh: true);
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

      _showMessage('Current location detected successfully.');
      return true;
    } catch (e) {
      if (mounted) {
        _showMessage('Could not get location. Please try again.');
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

    final viewModel = context.read<AmbulanceViewModel>();

    await viewModel.requestAmbulance(
  pickupAddress: address,
  latitude: latitude,
  longitude: longitude,
  contactPhone: phone,
);

    if (!mounted) return;

    if (viewModel.error == null &&
        viewModel.selectedRequest != null) {
      _addressController.clear();
      _phoneController.clear();

      _showMessage('Ambulance request submitted successfully.');
    } else {
      _showMessage(
        viewModel.error ?? 'Unable to submit ambulance request.',
      );
    }
  }

  Future<void> _refreshRequests() async {
    await context
        .read<AmbulanceViewModel>()
        .fetchMyRequests(refresh: true);
  }

  Future<void> _refreshEta(
    AmbulanceRequestModel request,
  ) async {
    final viewModel = context.read<AmbulanceViewModel>();

    await viewModel.refreshEta(request.id);

    if (!mounted) return;

    if (viewModel.error != null) {
      _showMessage(viewModel.error!);
    } else {
      _showMessage('ETA refreshed.');
    }
  }

  Future<void> _cancelRequest(
    AmbulanceRequestModel request,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Request'),
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
            onPressed: () =>
                Navigator.pop(dialogContext, true),
            child: const Text('Cancel Request'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final viewModel = context.read<AmbulanceViewModel>();

    await viewModel.cancelRequest(request.id);

    if (!mounted) return;

    if (viewModel.error == null) {
      _showMessage('Cancellation request processed.');
      await _refreshRequests();
    } else {
      _showMessage(viewModel.error!);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  String _display(dynamic value, [String fallback = 'Not available']) {
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
    final viewModel = context.watch<AmbulanceViewModel>();
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ambulance Assistance'),
        actions: [
          IconButton(
            tooltip: 'Refresh requests',
            onPressed: viewModel.isLoading ? null : _refreshRequests,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.errorContainer,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.emergency,
                  size: 40,
                  color: colors.onErrorContainer,
                ),
                const SizedBox(height: 12),
                Text(
                  'Request an Ambulance',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colors.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your pickup address and contact number. '
                  'The app can obtain your GPS coordinates automatically.',
                  style: TextStyle(
                    height: 1.5,
                    color: colors.onErrorContainer,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          TextField(
            controller: _addressController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Pickup Address',
              hintText: 'Enter your current pickup address',
              prefixIcon: Icon(Icons.location_on_outlined),
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 14),

          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Contact Phone Number',
              hintText: 'Enter your phone number',
              prefixIcon: Icon(Icons.phone_outlined),
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          OutlinedButton.icon(
            onPressed: _isGettingLocation
                ? null
                : _getCurrentLocation,
            icon: _isGettingLocation
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.my_location),
            label: Text(
              _isGettingLocation
                  ? 'Getting Current Location...'
                  : 'Use My Current Location',
            ),
          ),

          if (_latitude != null && _longitude != null) ...[
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.location_on,
                  color: Colors.green,
                ),
                title: const Text('GPS Location Detected'),
                subtitle: Text(
                  'Latitude: ${_latitude!.toStringAsFixed(6)}\n'
                  'Longitude: ${_longitude!.toStringAsFixed(6)}',
                ),
                trailing: IconButton(
                  tooltip: 'Update location',
                  onPressed: _isGettingLocation
                      ? null
                      : _getCurrentLocation,
                  icon: const Icon(Icons.refresh),
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: viewModel.isRequesting ||
                      _isGettingLocation
                  ? null
                  : _submitRequest,
              icon: viewModel.isRequesting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.emergency),
              label: Text(
                viewModel.isRequesting
                    ? 'Submitting Request...'
                    : 'Request Ambulance',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),

          const SizedBox(height: 28),

          Row(
            children: [
              const Expanded(
                child: Text(
                  'My Ambulance Requests',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: _refreshRequests,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),

          if (viewModel.isLoading &&
              viewModel.requests.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (viewModel.error != null &&
              viewModel.requests.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    viewModel.error!,
                    textAlign: TextAlign.center,
                  ),
                  TextButton(
                    onPressed: _refreshRequests,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            )
          else if (viewModel.requests.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text('No ambulance requests yet.'),
              ),
            )
          else
            ...viewModel.requests.map(
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
    final colors = Theme.of(context).colorScheme;

    final status = display(request.status, 'Pending');
    final eta = request.estimatedArrivalMinutes;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colors.errorContainer,
                  child: Icon(
                    Icons.emergency,
                    color: colors.onErrorContainer,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Ambulance Request',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(status),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              'Pickup: ${display(request.pickupAddress)}',
            ),
            const SizedBox(height: 10),
            Text(
              'Estimated arrival: '
              '${eta == null ? 'Not available yet' : '$eta minutes'}',
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onRefreshEta,
                  icon: const Icon(Icons.schedule),
                  label: const Text('Refresh ETA'),
                ),
                if (canCancel(status))
                  TextButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Cancel Request'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
