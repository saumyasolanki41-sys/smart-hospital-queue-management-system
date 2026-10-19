import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class BookTokenScreen extends StatefulWidget {
  const BookTokenScreen({super.key});

  @override
  State<BookTokenScreen> createState() => _BookTokenScreenState();
}

class _BookTokenScreenState extends State<BookTokenScreen> {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _doctors = [];

  String? _selectedDepartment;
  String? _selectedDoctor;

  bool _loadingDepartments = true;
  bool _loadingDoctors = false;
  bool _booking = false;

  String? _error;
  Map<String, dynamic>? _bookedToken;

  static const Color primaryColor = Color(0xFF176B87);

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _extractList(
    Map<String, dynamic> response,
    List<String> possibleKeys,
  ) {
    dynamic data = response['data'] ?? response;

    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    if (data is Map) {
      for (final key in possibleKeys) {
        final value = data[key];

        if (value is List) {
          return value
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        }
      }
    }

    return [];
  }

  String? _idOf(Map<String, dynamic> item) {
    final id = item['_id'] ?? item['id'];
    return id?.toString();
  }

  String _departmentName(Map<String, dynamic> item) {
    return (item['name'] ?? item['departmentName'] ?? 'Department')
        .toString();
  }

  String _doctorName(Map<String, dynamic> item) {
    return (item['name'] ?? item['doctorName'] ?? 'Doctor').toString();
  }

  Future<void> _loadDepartments() async {
    setState(() {
      _loadingDepartments = true;
      _error = null;
    });

    try {
      final response = await _apiService.getDepartments();
      final departments = _extractList(
        response,
        ['departments', 'items', 'results'],
      );

      if (!mounted) return;

      setState(() {
        _departments = departments
            .where((item) => _idOf(item) != null)
            .toList();
        _loadingDepartments = false;
      });

      if (_departments.isEmpty) {
        setState(() {
          _error = 'No departments found. Please try again later.';
        });
      }
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingDepartments = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loadingDepartments = false;
        _error = 'Unable to load departments.';
      });
    }
  }

  Future<void> _loadDoctors(String departmentId) async {
    setState(() {
      _selectedDoctor = null;
      _doctors = [];
      _loadingDoctors = true;
      _error = null;
    });

    try {
      final response = await _apiService.getDoctors(
        departmentId: departmentId,
      );

      final doctors = _extractList(
        response,
        ['doctors', 'items', 'results'],
      );

      if (!mounted) return;

      setState(() {
        _doctors = doctors.where((doctor) {
          final id = _idOf(doctor);
          final available = doctor['isAvailable'];

          return id != null && available != false;
        }).toList();

        _loadingDoctors = false;

        if (_doctors.isEmpty) {
          _error = 'No available doctors found in this department.';
        }
      });
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingDoctors = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loadingDoctors = false;
        _error = 'Unable to load doctors.';
      });
    }
  }

  Map<String, dynamic>? _extractToken(
    Map<String, dynamic> response,
  ) {
    final data = response['data'];

    if (data is Map) {
      final token = data['token'];

      if (token is Map) {
        return Map<String, dynamic>.from(token);
      }

      return Map<String, dynamic>.from(data);
    }

    return null;
  }

  Future<void> _requestToken() async {
    if (_selectedDepartment == null || _selectedDoctor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a department and doctor.'),
        ),
      );
      return;
    }

    setState(() {
      _booking = true;
      _error = null;
      _bookedToken = null;
    });

    try {
      final accessToken = await _storageService.getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        throw ApiException('Please log in before booking a token.');
      }

      final response = await _apiService.bookQueueToken(
        doctorId: _selectedDoctor!,
        accessToken: accessToken,
      );

      final token = _extractToken(response);

      if (!mounted) return;

      setState(() {
        _bookedToken = token ?? <String, dynamic>{};
        _booking = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token booking request completed.'),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _booking = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _booking = false;
        _error = 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _loadingDepartments
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDepartments,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'Get Your Queue Token',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose a department and an available doctor to join the hospital queue.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildLabel('Department'),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedDepartment,
                    isExpanded: true,
                    decoration: _inputDecoration(
                      'Select department',
                      Icons.local_hospital_outlined,
                    ),
                    items: _departments.map((department) {
                      return DropdownMenuItem<String>(
                        value: _idOf(department),
                        child: Text(_departmentName(department)),
                      );
                    }).toList(),
                    onChanged: _booking
                        ? null
                        : (value) {
                            if (value == null) return;

                            setState(() {
                              _selectedDepartment = value;
                              _selectedDoctor = null;
                              _bookedToken = null;
                            });

                            _loadDoctors(value);
                          },
                  ),
                  const SizedBox(height: 20),

                  _buildLabel('Doctor'),
                  if (_loadingDoctors)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else
                    DropdownButtonFormField<String>(
                      key: ValueKey(_selectedDepartment),
                      initialValue: _selectedDoctor,
                      isExpanded: true,
                      decoration: _inputDecoration(
                        'Select doctor',
                        Icons.medical_services_outlined,
                      ),
                      items: _doctors.map((doctor) {
                        return DropdownMenuItem<String>(
                          value: _idOf(doctor),
                          child: Text(_doctorName(doctor)),
                        );
                      }).toList(),
                      onChanged: _booking || _doctors.isEmpty
                          ? null
                          : (value) {
                              setState(() {
                                _selectedDoctor = value;
                                _bookedToken = null;
                              });
                            },
                    ),
                  const SizedBox(height: 24),

                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red.shade800),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (_bookedToken != null) ...[
                    _buildTokenConfirmation(_bookedToken!),
                    const SizedBox(height: 20),
                  ],

                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _booking ? null : _requestToken,
                      icon: _booking
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.confirmation_num_outlined,
                            ),
                      label: Text(
                        _booking ? 'Booking Token...' : 'Request Token',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTokenConfirmation(Map<String, dynamic> token) {
    final tokenNumber = token['tokenNumber'] ??
        token['number'] ??
        token['queueNumber'];

    final status = token['status'] ?? 'waiting';

    final wait = token['estimatedWaitMinutes'];
    final peopleAhead = token['peopleAhead'];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: Colors.green,
            size: 36,
          ),
          const SizedBox(height: 10),
          const Text(
            'Token Booking Successful',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Token number: ${tokenNumber ?? 'Created'}',
          ),
          Text('Status: $status'),
          if (peopleAhead != null)
            Text('People ahead: $peopleAhead'),
          if (wait != null)
            Text('Estimated waiting time: $wait minutes'),
          const SizedBox(height: 8),
          Text(
            'Waiting time is an estimate and may change.',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    String hint,
    IconData icon,
  ) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: primaryColor,
          width: 1.5,
        ),
      ),
    );
  }
}
