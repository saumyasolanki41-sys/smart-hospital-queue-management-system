
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/doctor_model.dart';
import '../viewmodels/department_viewmodel.dart';
import '../viewmodels/doctor_viewmodel.dart';
import '../viewmodels/token_viewmodel.dart';

class BookTokenScreen extends StatefulWidget {
  const BookTokenScreen({super.key});

  @override
  State<BookTokenScreen> createState() => _BookTokenScreenState();
}

class _BookTokenScreenState extends State<BookTokenScreen> {
  String? _selectedDepartmentId;
  DoctorModel? _selectedDoctor;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<DepartmentViewModel>().fetchDepartments();
    });
  }

  Future<void> _selectDepartment(String? departmentId) async {
    setState(() {
      _selectedDepartmentId = departmentId;
      _selectedDoctor = null;
    });

    final doctorViewModel = context.read<DoctorViewModel>();

    await doctorViewModel.fetchDoctors(
      departmentId: departmentId,
      isAvailable: true,
      refresh: true,
    );
  }

  Future<void> _bookToken() async {
    final doctor = _selectedDoctor;

    if (doctor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a doctor first.'),
        ),
      );
      return;
    }

    final tokenViewModel = context.read<TokenViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final token = await tokenViewModel.bookToken(
      doctorId: doctor.id,
    );

    if (!mounted) return;

    if (token != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Token booked successfully: ${token.tokenNumber}',
          ),
        ),
      );

      navigator.pop();
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            tokenViewModel.error ?? 'Unable to book token.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final departmentViewModel = context.watch<DepartmentViewModel>();
    final doctorViewModel = context.watch<DoctorViewModel>();
    final tokenViewModel = context.watch<TokenViewModel>();

    final selectedDoctorId = doctorViewModel.doctors.any(
      (doctor) => doctor.id == _selectedDoctor?.id,
    )
        ? _selectedDoctor!.id
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book a Token'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(
            Icons.confirmation_number_outlined,
            size: 64,
            color: Color(0xFF1479A4),
          ),
          const SizedBox(height: 12),
          const Text(
            'Book Your Hospital Token',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose a department and an available doctor.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          const Text(
            'Select Department',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),

          if (departmentViewModel.isLoading &&
              departmentViewModel.departments.isEmpty)
            const Center(
              child: CircularProgressIndicator(),
            )
          else if (departmentViewModel.error != null &&
              departmentViewModel.departments.isEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(departmentViewModel.error!),
                TextButton(
                  onPressed: () {
                    departmentViewModel.refreshDepartments();
                  },
                  child: const Text('Retry'),
                ),
              ],
            )
          else if (departmentViewModel.departments.isEmpty)
            const Text('No departments are available.')
          else
            DropdownButtonFormField<String>(
              initialValue: departmentViewModel.departments.any(
                (department) => department.id == _selectedDepartmentId,
              )
                  ? _selectedDepartmentId
                  : null,
              isExpanded: true,
              decoration: const InputDecoration(
                hintText: 'Choose department',
                prefixIcon: Icon(Icons.local_hospital_outlined),
              ),
              items: departmentViewModel.departments.map((department) {
                return DropdownMenuItem<String>(
                  value: department.id,
                  child: Text(
                    department.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: _selectDepartment,
            ),

          const SizedBox(height: 24),

          const Text(
            'Select Doctor',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),

          if (_selectedDepartmentId == null)
            const Text('Select a department first.')
          else if (doctorViewModel.isLoading)
            const Center(
              child: CircularProgressIndicator(),
            )
          else if (doctorViewModel.error != null &&
              doctorViewModel.doctors.isEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doctorViewModel.error!),
                TextButton(
                  onPressed: () {
                    doctorViewModel.fetchDoctors(
                      departmentId: _selectedDepartmentId,
                      isAvailable: true,
                      refresh: true,
                    );
                  },
                  child: const Text('Retry'),
                ),
              ],
            )
          else if (doctorViewModel.doctors.isEmpty)
            const Text(
              'No available doctors found in this department.',
            )
          else
            DropdownButtonFormField<String>(
              initialValue: selectedDoctorId,
              isExpanded: true,
              decoration: const InputDecoration(
                hintText: 'Choose doctor',
                prefixIcon: Icon(Icons.person_outline),
              ),
              items: doctorViewModel.doctors.map((doctor) {
                return DropdownMenuItem<String>(
                  value: doctor.id,
                  child: Text(
                    doctor.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (doctorId) {
                setState(() {
                  _selectedDoctor = doctorViewModel.doctors
                      .where((doctor) => doctor.id == doctorId)
                      .firstOrNull;
                });
              },
            ),

          if (_selectedDoctor != null) ...[
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.medical_services_outlined),
                ),
                title: Text(_selectedDoctor!.name),
                subtitle: Text(
                  _selectedDoctor!.specialization ?? 'Doctor',
                ),
                trailing: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                ),
              ),
            ),
          ],

          const SizedBox(height: 28),

          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: tokenViewModel.isBooking ||
                      _selectedDoctor == null
                  ? null
                  : _bookToken,
              icon: tokenViewModel.isBooking
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.confirmation_number_outlined),
              label: Text(
                tokenViewModel.isBooking
                    ? 'Booking Token...'
                    : 'Confirm Booking',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
