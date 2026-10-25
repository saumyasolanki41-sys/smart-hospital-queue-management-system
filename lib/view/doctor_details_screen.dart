
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
  static const Color _primary = Color(0xFF246F96);
  static const Color _background = Color(0xFFE6EFFF);
  static const Color _heading = Color(0xFF173B5E);
  static const Color _lightBlue = Color(0xFFE8F0FF);
  static const Color _muted = Color(0xFF7892B0);

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
            backgroundColor: _primary,
            behavior: SnackBarBehavior.floating,
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
      backgroundColor: _background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE6EFFF),
              Color(0xFFF5F8FF),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  children: [
                    // App bar
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(13),
                            boxShadow: [
                              BoxShadow(
                                color: _heading.withValues(alpha: 0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: _heading,
                              size: 25,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Text(
                            'Doctor Details',
                            style: TextStyle(
                              color: _heading,
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          height: 44,
                          width: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(
                            Icons.local_hospital_rounded,
                            color: _primary,
                            size: 24,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Doctor information banner
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF246F96),
                            Color(0xFF8DB8F5),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: _primary.withValues(alpha: 0.16),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Meet Your Doctor',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 21,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'View doctor information and book your appointment.',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 12),
                          Icon(
                            Icons.medical_information_rounded,
                            color: Colors.white,
                            size: 43,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Doctor profile card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? colors.surface : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFFB7D2F8)
                              .withValues(alpha: 0.65),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _heading.withValues(alpha: 0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFB7D2F8),
                                width: 2,
                              ),
                            ),
                            child: const CircleAvatar(
                              radius: 48,
                              backgroundColor: _lightBlue,
                              child: Icon(
                                Icons.person_rounded,
                                color: _primary,
                                size: 58,
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          Text(
                            doctor.name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark ? colors.onSurface : _heading,
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: _lightBlue,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              specialization,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: _primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          Text(
                            qualification,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 14,
                            ),
                          ),

                          const SizedBox(height: 18),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: doctor.isAvailable
                                  ? const Color(0xFFE6F6EC)
                                  : const Color(0xFFFFE9E9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  doctor.isAvailable
                                      ? Icons.check_circle_rounded
                                      : Icons.cancel_rounded,
                                  size: 17,
                                  color: doctor.isAvailable
                                      ? Colors.green.shade700
                                      : Colors.red.shade700,
                                ),
                                const SizedBox(width: 7),
                                Text(
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
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Information section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? colors.surface : Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: const Color(0xFFB7D2F8)
                              .withValues(alpha: 0.65),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _heading.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: _primary,
                                size: 23,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Doctor Information',
                                style: TextStyle(
                                  color: _heading,
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 22),

                          _InfoRow(
                            icon: Icons.person_outline_rounded,
                            label: 'Doctor',
                            value: doctor.name,
                          ),

                          const SizedBox(height: 20),

                          _InfoRow(
                            icon: Icons.medical_services_outlined,
                            label: 'Specialization',
                            value: specialization,
                          ),

                          const SizedBox(height: 20),

                          _InfoRow(
                            icon: Icons.school_outlined,
                            label: 'Qualification',
                            value: qualification,
                          ),

                          if (_selectedSlot != null) ...[
                            const SizedBox(height: 20),
                            const Divider(
                              color: _lightBlue,
                              height: 1,
                            ),
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

                    const SizedBox(height: 18),

                    // Appointment reminder
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F0FF),
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.calendar_month_rounded,
                            color: _primary,
                            size: 23,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Choose an available time slot before booking your token.',
                              style: TextStyle(
                                color: _heading,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom booking buttons
              Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                decoration: BoxDecoration(
                  color: isDark ? colors.surface : Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _heading.withValues(alpha: 0.08),
                      blurRadius: 14,
                      offset: const Offset(0, -4),
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
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: _isSelectingSlot ||
                                  tokenController.isBooking
                              ? null
                              : _checkSlots,
                          icon: _isSelectingSlot
                              ? const SizedBox(
                                  width: 19,
                                  height: 19,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: _primary,
                                  ),
                                )
                              : const Icon(
                                  Icons.calendar_month_rounded,
                                ),
                          label: Text(
                            _selectedSlot == null
                                ? 'Available Slots'
                                : 'Change Time Slot',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _primary,
                            side: const BorderSide(
                              color: _primary,
                              width: 1.4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 11),

                      SizedBox(
                        width: double.infinity,
                        height: 55,
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
                            elevation: 2,
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
                                        fontSize: 17,
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
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  static const Color _primary = Color(0xFF246F96);
  static const Color _heading = Color(0xFF173B5E);
  static const Color _muted = Color(0xFF7892B0);

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
        Container(
          height: 39,
          width: 39,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F0FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: _primary,
            size: 21,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                value,
                style: TextStyle(
                  color: isDark ? colors.onSurface : _heading,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
