
import 'package:flutter/material.dart';

import '../models/doctor_model.dart';

class DoctorSlotsScreen extends StatefulWidget {
  final DoctorModel doctor;

  const DoctorSlotsScreen({
    super.key,
    required this.doctor,
  });

  @override
  State<DoctorSlotsScreen> createState() =>
      _DoctorSlotsScreenState();
}

class _DoctorSlotsScreenState extends State<DoctorSlotsScreen> {
  static const Color _primary = Color(0xFF286C91);
  static const Color _background = Color(0xFFC2E7EB);
  static const Color _lightBlue = Color(0xFFF1F9FF);
  static const Color _muted = Color(0xFF80A5B8);

  final List<String> _slots = [
    '9:00 AM',
    '12:00 PM',
    '3:00 PM',
  ];

  String? _selectedSlot;

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: isDark ? colors.surface : _background,
      appBar: AppBar(
        title: const Text('Available Slots'),
        backgroundColor: isDark ? colors.surface : _background,
        foregroundColor: isDark ? colors.onSurface : _primary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: isDark
                      ? colors.surfaceContainer
                      : _lightBlue,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 38,
                      backgroundColor: Color(0xFFD8F2FA),
                      child: Icon(
                        Icons.person_rounded,
                        size: 48,
                        color: _primary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      widget.doctor.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color:
                            isDark ? colors.onSurface : _primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.doctor.specialization ??
                          'Medical Specialist',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        color: _muted,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              Text(
                'Select a Time Slot',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: isDark ? colors.onSurface : _primary,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Choose your preferred appointment time.',
                style: TextStyle(
                  fontSize: 14,
                  color: _muted,
                ),
              ),

              const SizedBox(height: 20),

              ..._slots.map((slot) {
                final isSelected = _selectedSlot == slot;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      setState(() {
                        _selectedSlot = slot;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _primary.withValues(alpha: 0.12)
                            : isDark
                                ? colors.surfaceContainer
                                : _lightBlue,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? _primary
                              : _muted.withValues(alpha: 0.35),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            color: _primary,
                            size: 26,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              slot,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? colors.onSurface
                                    : _primary,
                              ),
                            ),
                          ),
                          Icon(
                            isSelected
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: _primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _selectedSlot == null
                      ? null
                      : () {
                          Navigator.pop(context, _selectedSlot);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade400,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'Confirm Slot',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              const Center(
                child: Text(
                  'Sample slots for demonstration only.',
                  style: TextStyle(
                    fontSize: 12,
                    color: _muted,
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
