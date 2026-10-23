import 'package:flutter/material.dart';
import '../models/token_model.dart';
import 'home_screen.dart';

class BookingConfirmationScreen extends StatelessWidget {
  final TokenModel token;

  const BookingConfirmationScreen({
    super.key,
    required this.token,
  });

  static const Color _primary = Color(0xFF286C91);
  static const Color _background = Color(0xFFC2E7EB);
  static const Color _lightBlue = Color(0xFFF1F9FF);
  static const Color _muted = Color(0xFF80A5B8);

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not available';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String _formatTime(DateTime? date) {
    if (date == null) return 'Not available';

    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  String _statusText(String status) {
    switch (status.toLowerCase()) {
      case 'waiting':
        return 'Waiting';
      case 'called':
        return 'Your turn has been called';
      case 'serving':
        return 'Consultation in progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.isEmpty ? 'Pending' : status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;

    final doctorName =
        token.doctorName?.trim().isNotEmpty == true
            ? token.doctorName!
            : 'Doctor details unavailable';

    final departmentName =
        token.departmentName?.trim().isNotEmpty == true
            ? token.departmentName!
            : 'Department details unavailable';

    final appointmentTime = token.appointmentTime;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: isDark ? colors.surface : _background,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 30, 22, 28),
            children: [
              const SizedBox(height: 10),

              Center(
                child: Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                    size: 76,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Booking Confirmed!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? colors.onSurface : _primary,
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Your hospital queue token has been generated successfully.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _muted,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 30),

              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark
                      ? colors.surfaceContainer
                      : _lightBlue,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: _primary.withValues(alpha: 0.12),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'YOUR TOKEN NUMBER',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 13,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                     token.tokenNumber.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _primary,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 14),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _statusText(token.status),
                        style: const TextStyle(
                          color: _primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Divider(
                      color: _muted.withValues(alpha: 0.3),
                    ),

                    const SizedBox(height: 18),

                    _DetailRow(
                      icon: Icons.person_outline_rounded,
                      label: 'Doctor',
                      value: doctorName,
                    ),

                    const SizedBox(height: 20),

                    _DetailRow(
                      icon: Icons.local_hospital_outlined,
                      label: 'Department',
                      value: departmentName,
                    ),

                    const SizedBox(height: 20),

                    _DetailRow(
                      icon: Icons.people_outline_rounded,
                      label: 'Patients ahead',
                      value: '${token.patientsAhead}',
                    ),

                    const SizedBox(height: 20),

                    _DetailRow(
                      icon: Icons.access_time_rounded,
                      label: 'Estimated wait',
                      value: '${token.estimatedWaitMinutes} minutes',
                    ),

                    if (appointmentTime != null) ...[
                      const SizedBox(height: 20),

                      _DetailRow(
                        icon: Icons.calendar_month_outlined,
                        label: 'Appointment date',
                        value: _formatDate(appointmentTime),
                      ),

                      const SizedBox(height: 20),

                      _DetailRow(
                        icon: Icons.schedule_rounded,
                        label: 'Appointment time',
                        value: _formatTime(appointmentTime),
                      ),
                    ],

                    const SizedBox(height: 20),

                    _DetailRow(
                      icon: Icons.event_available_outlined,
                      label: 'Booking date',
                      value: _formatDate(token.createdAt),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? colors.surfaceContainer
                      : Colors.white.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: _primary,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Please arrive at the hospital before your turn. '
                        'You can check your latest queue status from My Tokens.',
                        style: TextStyle(
                          color: _muted,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HomeScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.home_rounded),
                      SizedBox(width: 10),
                      Text(
                        'Back to Home',
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
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  static const Color _primary = Color(0xFF286C91);
  static const Color _muted = Color(0xFF80A5B8);

  const _DetailRow({
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
        Icon(
          icon,
          color: _primary,
          size: 23,
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              color: _muted,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: isDark ? colors.onSurface : _primary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}