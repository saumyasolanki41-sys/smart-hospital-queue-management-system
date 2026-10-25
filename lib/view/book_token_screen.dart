import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controller/token_controller.dart';
import '../models/doctor_model.dart';
import 'doctor_slots_screen.dart';

class BookTokenScreen extends StatefulWidget {
  final DoctorModel doctor;

  const BookTokenScreen({
    super.key,
    required this.doctor,
  });

  @override
  State<BookTokenScreen> createState() => _BookTokenScreenState();
}

class _BookTokenScreenState extends State<BookTokenScreen> {
  static const Color _primary = Color(0xFF246F96);
  static const Color _background = Color(0xFFE6EFFF);
  static const Color _heading = Color(0xFF173B5E);
  static const Color _lightBlue = Color(0xFFB7D2F8);
  static const Color _muted = Color(0xFF7892B0);

  String? _selectedSlot;
  bool _isOpeningSlots = false;

  Future<void> _selectSlot() async {
    if (_isOpeningSlots) return;

    setState(() {
      _isOpeningSlots = true;
    });

    try {
      final slot = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (_) => DoctorSlotsScreen(
            doctor: widget.doctor,
          ),
        ),
      );

      if (!mounted) return;

      if (slot != null && slot.trim().isNotEmpty) {
        setState(() {
          _selectedSlot = slot;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isOpeningSlots = false;
        });
      }
    }
  }

  Future<void> _bookToken() async {
    if (_selectedSlot == null || _selectedSlot!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a time slot first.'),
        ),
      );
      return;
    }

    final controller = context.read<TokenController>();

    final token = await controller.bookToken(
      doctorId: widget.doctor.id,
      selectedSlot: _selectedSlot!,
    );

    if (!mounted) return;

    if (token != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Token booked successfully for ${_selectedSlot!}.',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, token);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            controller.error ?? 'Unable to book your token.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokenController = context.watch<TokenController>();

    return Scaffold(
      backgroundColor: _background,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: _background,
        foregroundColor: _heading,
        title: const Text(
          'Book Token',
          style: TextStyle(
            color: _heading,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
      ),

      body: Container(
        width: double.infinity,
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
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Appointment heading banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
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
                        color: _primary.withValues(alpha: 0.18),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),

                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Confirm Your Appointment',
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 9),
                            Text(
                              'Choose your preferred time and book your token.',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.5,
                                color: Colors.white.withValues(
                                  alpha: 0.92,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.calendar_month_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // Doctor information heading
                const Row(
                  children: [
                    Icon(
                      Icons.medical_services_outlined,
                      color: _primary,
                      size: 22,
                    ),
                    SizedBox(width: 9),
                    Text(
                      'Doctor Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _heading,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 13),

                // Selected doctor card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _lightBlue.withValues(alpha: 0.65),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _heading.withValues(alpha: 0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),

                  child: Row(
                    children: [
                      Container(
                        height: 58,
                        width: 58,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFE8F0FF),
                              Color(0xFFB7D2F8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: const Icon(
                          Icons.medical_services_rounded,
                          color: _primary,
                          size: 30,
                        ),
                      ),

                      const SizedBox(width: 15),

                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selected Doctor',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: _heading,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Your appointment will be booked with your selected doctor.',
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.4,
                                color: _muted,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Icon(
                        Icons.verified_rounded,
                        color: _primary,
                        size: 24,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // Appointment time heading
                const Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      color: _primary,
                      size: 22,
                    ),
                    SizedBox(width: 9),
                    Text(
                      'Appointment Time',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _heading,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 13),

                // Time selection card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(19),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _lightBlue.withValues(alpha: 0.65),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _heading.withValues(alpha: 0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Choose a suitable time slot',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _heading,
                        ),
                      ),

                      const SizedBox(height: 15),

                      // Selected time display
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 17,
                        ),
                        decoration: BoxDecoration(
                          color: _selectedSlot == null
                              ? const Color(0xFFF3F7FF)
                              : const Color(0xFFE8F0FF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _selectedSlot == null
                                ? const Color(0xFFD9E5F7)
                                : _primary.withValues(alpha: 0.4),
                          ),
                        ),

                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                _selectedSlot == null
                                    ? Icons.schedule_rounded
                                    : Icons.check_circle_rounded,
                                color: _primary,
                                size: 23,
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedSlot == null
                                        ? 'No time slot selected'
                                        : 'Selected Time Slot',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: _muted,
                                    ),
                                  ),

                                  const SizedBox(height: 5),

                                  Text(
                                    _selectedSlot ?? 'Select a time below',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: _heading,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 17),

                      // Select or change time slot
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed:
                              _isOpeningSlots || tokenController.isBooking
                                  ? null
                                  : _selectSlot,

                          icon: _isOpeningSlots
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
                                  size: 20,
                                ),

                          label: Text(
                            _selectedSlot == null
                                ? 'Select Time Slot'
                                : 'Change Time Slot',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          style: OutlinedButton.styleFrom(
                            foregroundColor: _primary,
                            side: const BorderSide(
                              color: _primary,
                              width: 1.3,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Confirm booking button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: tokenController.isBooking
                        ? null
                        : _bookToken,

                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF173B5E),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _muted,
                      elevation: 3,
                      shadowColor: _heading.withValues(alpha: 0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),

                    child: tokenController.isBooking
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_outline_rounded,
                                size: 22,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Confirm Booking',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 12),

                // Security note
                const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        size: 15,
                        color: _muted,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Please verify your selected appointment time',
                        style: TextStyle(
                          fontSize: 11,
                          color: _muted,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
