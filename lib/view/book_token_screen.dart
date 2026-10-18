
import 'package:flutter/material.dart';

class BookTokenScreen extends StatefulWidget {
  const BookTokenScreen({super.key});

  @override
  State<BookTokenScreen> createState() => _BookTokenScreenState();
}

class _BookTokenScreenState extends State<BookTokenScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientNameController = TextEditingController();
  final _ageController = TextEditingController();

  String? _selectedDepartment;
  String? _selectedDoctor;
  String? _visitType;

  final List<String> _departments = [
    'General Medicine',
    'Orthopedics',
    'Cardiology',
    'Dermatology',
    'Pediatrics',
  ];

  final List<String> _doctors = [
    'Dr. Sharma',
    'Dr. Verma',
    'Dr. Singh',
    'Dr. Gupta',
  ];

  @override
  void dispose() {
    _patientNameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _requestToken() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDepartment == null ||
        _selectedDoctor == null ||
        _visitType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select department, doctor, and visit type.'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Form completed. Token booking will work after API integration.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF176B87);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                'Enter your details to request a hospital queue token.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),

              _buildLabel('Patient Name'),
              TextFormField(
                controller: _patientNameController,
                textCapitalization: TextCapitalization.words,
                decoration: _inputDecoration(
                  hint: 'Enter patient name',
                  icon: Icons.person_outline,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter patient name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              _buildLabel('Age'),
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration(
                  hint: 'Enter age',
                  icon: Icons.calendar_today_outlined,
                ),
                validator: (value) {
                  final age = int.tryParse(value ?? '');
                  if (age == null || age < 1 || age > 120) {
                    return 'Enter a valid age between 1 and 120';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              _buildLabel('Department'),
              DropdownButtonFormField<String>(
               initialValue: _selectedDepartment,
                decoration: _inputDecoration(
                  hint: 'Select department',
                  icon: Icons.local_hospital_outlined,
                ),
                items: _departments.map((department) {
                  return DropdownMenuItem(
                    value: department,
                    child: Text(department),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDepartment = value;
                    _selectedDoctor = null;
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select a department' : null,
              ),
              const SizedBox(height: 18),

              _buildLabel('Doctor'),
              DropdownButtonFormField<String>(
              initialValue: _selectedDoctor,
                decoration: _inputDecoration(
                  hint: 'Select doctor',
                  icon: Icons.medical_services_outlined,
                ),
                items: _doctors.map((doctor) {
                  return DropdownMenuItem(
                    value: doctor,
                    child: Text(doctor),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDoctor = value;
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select a doctor' : null,
              ),
              const SizedBox(height: 18),

              _buildLabel('Visit Type'),
              DropdownButtonFormField<String>(
         initialValue: _visitType,
                decoration: _inputDecoration(
                  hint: 'Select visit type',
                  icon: Icons.event_note_outlined,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'New Visit',
                    child: Text('New Visit'),
                  ),
                  DropdownMenuItem(
                    value: 'Follow-up',
                    child: Text('Follow-up'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _visitType = value;
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select visit type' : null,
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _requestToken,
                  icon: const Icon(Icons.confirmation_num_outlined),
                  label: const Text(
                    'Request Token',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
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
          color: Color(0xFF176B87),
          width: 1.5,
        ),
      ),
    );
  }
}
