
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
  static const Color _primary = Color(0xFF236D96);
  static const Color _background = Color(0xFFC2E9EC);

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
        title: const Text('Book Token'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Confirm Your Appointment',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF285C7D),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select a time slot before booking your token.',
                style: TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 24),
              Card(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: _primary.withValues(alpha: 0.12),
                        child: const Icon(
                          Icons.medical_services,
                          color: _primary,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          'Selected Doctor',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Appointment Time',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _background.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              color: _primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _selectedSlot ?? 'No time slot selected',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed:
                              _isOpeningSlots || tokenController.isBooking
                                  ? null
                                  : _selectSlot,
                          icon: _isOpeningSlots
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.calendar_month),
                          label: Text(
                            _selectedSlot == null
                                ? 'Select Time Slot'
                                : 'Change Time Slot',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _primary,
                            side: const BorderSide(color: _primary),
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: tokenController.isBooking
                      ? null
                      : _bookToken,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: tokenController.isBooking
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : const Text(
                          'Confirm Booking',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
}
