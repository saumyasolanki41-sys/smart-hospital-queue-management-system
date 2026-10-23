
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/doctor_model.dart';
import '../controller/token_controller.dart';
import 'booking_confirmation_screen.dart';
import 'doctor_slots_screen.dart';

class DoctorDetailsScreen extends StatefulWidget {
  final DoctorModel doctor;

  const DoctorDetailsScreen({
    super.key,
    required this.doctor,
  });

  @override
  State<DoctorDetailsScreen> createState() =>
      _DoctorDetailsScreenState();
}

class _DoctorDetailsScreenState extends State<DoctorDetailsScreen> {
  static const Color _primary = Color(0xFF286C91);
  static const Color _background = Color(0xFFC2E7EB);
  static const Color _lightBlue = Color(0xFFF1F9FF);
  static const Color _muted = Color(0xFF80A5B8);

  String? _selectedSlot;
  bool _isSelectingSlot = false;

  Future<void> _checkSlots() async {
    if (_isSelectingSlot) return;

    setState(() {
      _isSelectingSlot = true;
    });

    try {
      final selectedSlot = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (_) => DoctorSlotsScreen(
            doctor: widget.doctor,
          ),
        ),
      );

      if (!mounted) return;

      if (selectedSlot != null && selectedSlot.trim().isNotEmpty) {
        setState(() {
          _selectedSlot = selectedSlot;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Selected time: $selectedSlot'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSelectingSlot = false;
        });
      }
    }
  }

  Future<void> _bookToken() async {
    final tokenController = context.read<TokenController>();

    if (!widget.doctor.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This doctor is currently unavailable.'),
        ),
      );
      return;
    }

    if (_selectedSlot == null || _selectedSlot!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an available time slot first.'),
        ),
      );
      return;
    }

    final token = await tokenController.bookToken(
      doctorId: widget.doctor.id,
      selectedSlot: _selectedSlot!,
    );

    if (!mounted) return;

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tokenController.error ??
                'Unable to book your token. Please try again.',
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingConfirmationScreen(
          token: token,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final doctor = widget.doctor;
    final tokenController = context.watch<TokenController>();
    final isDark =
        Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;

    final specialization =
        doctor.specialization?.trim().isNotEmpty == true
            ? doctor.specialization!.trim()
            : 'Medical Specialist';

    final qualification =
        doctor.qualification?.trim().isNotEmpty == true
            ? doctor.qualification!.trim()
            : 'Qualification not provided';

    return Scaffold(
      backgroundColor: isDark ? colors.surface : _background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: _primary,
                          size: 30,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Doctor Details',
                          style: TextStyle(
                            color: isDark ? colors.onSurface : _primary,
                            fontSize: 25,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: isDark
                          ? colors.surfaceContainer
                          : _lightBlue,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: _primary.withValues(alpha: 0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.medical_information_outlined,
                          color: _muted,
                          size: 22,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Doctor Information',
                          style: TextStyle(
                            color: _muted,
                            fontSize: 17,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: isDark
                          ? colors.surfaceContainer
                          : _lightBlue,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: _primary.withValues(alpha: 0.10),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 48,
                          backgroundColor: Color(0xFFD8F2FA),
                          child: Icon(
                            Icons.person_rounded,
                            color: _primary,
                            size: 58,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          doctor.name,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDark ? colors.onSurface : _primary,
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          specialization,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          qualification,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: doctor.isAvailable
                                ? Colors.green.withValues(alpha: 0.12)
                                : Colors.red.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            doctor.isAvailable
                                ? 'Available'
                                : 'Currently unavailable',
                            style: TextStyle(
                              color: doctor.isAvailable
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark
                          ? colors.surfaceContainer
                          : _lightBlue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Doctor Information',
                          style: TextStyle(
                            color: isDark ? colors.onSurface : _primary,
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 22),
                        _InfoRow(
                          icon: Icons.person_outline_rounded,
                          label: 'Doctor',
                          value: doctor.name,
                        ),
                        const SizedBox(height: 18),
                        _InfoRow(
                          icon: Icons.medical_services_outlined,
                          label: 'Specialization',
                          value: specialization,
                        ),
                        const SizedBox(height: 18),
                        _InfoRow(
                          icon: Icons.school_outlined,
                          label: 'Qualification',
                          value: qualification,
                        ),
                        if (_selectedSlot != null) ...[
                          const SizedBox(height: 18),
                          _InfoRow(
                            icon: Icons.access_time_rounded,
                            label: 'Selected Slot',
                            value: _selectedSlot!,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: isDark ? colors.surface : _lightBlue,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton.icon(
                        onPressed: _isSelectingSlot ||
                                tokenController.isBooking
                            ? null
                            : _checkSlots,
                        icon: _isSelectingSlot
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.calendar_month_rounded),
                        label: Text(
                          _selectedSlot == null
                              ? 'Available Slots'
                              : 'Change Time Slot',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primary,
                          side: const BorderSide(
                            color: _primary,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: !doctor.isAvailable ||
                                tokenController.isBooking ||
                                _isSelectingSlot
                            ? null
                            : _bookToken,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade400,
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: tokenController.isBooking
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.confirmation_number_outlined,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Book Token',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  static const Color _primary = Color(0xFF286C91);
  static const Color _muted = Color(0xFF80A5B8);

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _primary, size: 22),
        const SizedBox(width: 12),
        SizedBox(
          width: 105,
          child: Text(
            '$label:',
            style: TextStyle(
              color: isDark ? colors.onSurface : _primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: isDark ? colors.onSurfaceVariant : _muted,
            ),
          ),
        ),
      ],
    );
  }
}
