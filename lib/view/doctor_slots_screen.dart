
import 'package:flutter/material.dart';
import '../models/doctor_model.dart';

class DoctorSlotsScreen extends StatefulWidget {
  final DoctorModel doctor;

  const DoctorSlotsScreen({
    super.key,
    required this.doctor,
  });

  @override
  State<DoctorSlotsScreen> createState() => _DoctorSlotsScreenState();
}

class _DoctorSlotsScreenState extends State<DoctorSlotsScreen> {
  static const Color _primary = Color.fromARGB(255, 14, 18, 33);
  static const Color _background = Color(0xFFE8F0FF);
  static const Color _muted = Color(0xFF60758A);
  static const Color _darkText = Color.fromARGB(255, 5, 26, 37);
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _blue = Color(0xFF315B91);

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
        title: const Text(
          'Available Slots',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDark ? colors.surface : _background,
        foregroundColor: isDark ? colors.onSurface : _darkText,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? null
              : const LinearGradient(
                  colors: [
                    Color(0xFF8DB8F5),
                    Color(0xFFB7D2F8),
                    Color(0xFFE6EFFF),
                    Colors.white,
                    Color(0xFFE8F0FF),
                    Color(0xFF9DBDF2),
                  ],
                  stops: [0.0, 0.16, 0.32, 0.55, 0.78, 1.0],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color.fromARGB(255, 14, 18, 33),
                          Color(0xFF315B91),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: _blue.withValues(alpha: 0.16),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const CircleAvatar(
                            radius: 38,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.person_rounded,
                              size: 48,
                              color: _primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.doctor.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.doctor.specialization ??
                                'Medical Specialist',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.verified_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 7),
                            Flexible(
                              child: Text(
                                'Choose your appointment time',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

              
                  Text(
                    'Select a Time Slot',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? colors.onSurface : _darkText,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Choose a time that works best for you.',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? colors.onSurfaceVariant : _muted,
                    ),
                  ),

                  const SizedBox(height: 22),

                  ..._slots.map((slot) {
                    final isSelected = _selectedSlot == slot;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          setState(() {
                            _selectedSlot = slot;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 19,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark
                                    ? _blue.withValues(alpha: 0.2)
                                    : const Color(0xFFE6EFFF))
                                : (isDark
                                    ? colors.surfaceContainer
                                    : Colors.white),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isSelected ? _blue : _border,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: [
                              if (!isDark)
                                BoxShadow(
                                  color: _blue.withValues(alpha: 0.08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? _primary
                                      : const Color(0xFFE8F0FF),
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: Icon(
                                  Icons.access_time_rounded,
                                  color: isSelected ? Colors.white : _blue,
                                  size: 25,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      slot,
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? colors.onSurface
                                            : _darkText,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Available for appointment',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? colors.onSurfaceVariant
                                            : _muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                isSelected
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                color: isSelected ? _blue : _muted,
                                size: 24,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 10),

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
                        disabledBackgroundColor: isDark
                            ? colors.surfaceContainerHighest
                            : const Color(0xFFD5DFEB),
                        disabledForegroundColor: _muted,
                        elevation: _selectedSlot == null ? 0 : 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline_rounded),
                          SizedBox(width: 10),
                          Text(
                            'Confirm Slot',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

          
                  Center(
                    child: Text(
                      'Sample slots for demonstration only.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? colors.onSurfaceVariant : _muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
