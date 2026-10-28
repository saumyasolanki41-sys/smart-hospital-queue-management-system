import 'package:flutter/material.dart';
import '../models/token_model.dart';
import 'home_screen.dart';

class BookingConfirmationScreen extends StatelessWidget {
  final TokenModel token;

  const BookingConfirmationScreen({
    super.key,
    required this.token,
  });

  static const Color _primary =
      Color.fromARGB(255, 126, 211, 232);
  static const Color _background = Color(0xFFEAF8FB);
  static const Color _heading = Color(0xFF174A5B);
  static const Color _lightBlue = Color(0xFFC8EBF2);
  static const Color _muted = Color(0xFF648994);

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
      canPop: true,
      child: Scaffold(
        backgroundColor: _background,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFEAF8FB),
                Color(0xFFF5FCFD),
                Colors.white,
              ],
            ),
          ),
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 25,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF174A5B),
                        Color(0xFF287F94),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: _primary.withValues(alpha: 0.25),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 86,
                        width: 86,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _primary.withValues(alpha: 0.8),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          color: _primary,
                          size: 62,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Booking Confirmed!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 27,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Your hospital queue token has been generated successfully.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.94),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: isDark ? colors.surface : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _lightBlue.withValues(alpha: 0.85),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _heading.withValues(alpha: 0.06),
                        blurRadius: 15,
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

                      const SizedBox(height: 10),

                      Text(
                        token.tokenNumber.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _heading,
                          fontSize: 52,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: _background,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: _lightBlue,
                          ),
                        ),
                        child: Text(
                          _statusText(token.status),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _heading,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Divider(
                        color: _muted.withValues(alpha: 0.25),
                      ),

                      const SizedBox(height: 20),

                      _DetailRow(
                        icon: Icons.person_outline_rounded,
                        label: 'Doctor',
                        value: doctorName,
                      ),

                      const SizedBox(height: 22),

                      _DetailRow(
                        icon: Icons.local_hospital_outlined,
                        label: 'Department',
                        value: departmentName,
                      ),

                      const SizedBox(height: 22),

                      _DetailRow(
                        icon: Icons.people_outline_rounded,
                        label: 'Patients ahead',
                        value: '${token.patientsAhead}',
                      ),

                      const SizedBox(height: 22),

                      _DetailRow(
                        icon: Icons.access_time_rounded,
                        label: 'Estimated wait',
                        value: '${token.estimatedWaitMinutes} minutes',
                      ),

                      if (appointmentTime != null) ...[
                        const SizedBox(height: 22),

                        _DetailRow(
                          icon: Icons.calendar_month_outlined,
                          label: 'Appointment date',
                          value: _formatDate(appointmentTime),
                        ),

                        const SizedBox(height: 22),

                        _DetailRow(
                          icon: Icons.schedule_rounded,
                          label: 'Appointment time',
                          value: _formatTime(appointmentTime),
                        ),
                      ],

                      const SizedBox(height: 22),

                      _DetailRow(
                        icon: Icons.event_available_outlined,
                        label: 'Booking date',
                        value: _formatDate(token.createdAt),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                Container(
                  padding: const EdgeInsets.all(17),
                  decoration: BoxDecoration(
                    color: isDark
                        ? colors.surfaceContainer
                        : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _lightBlue.withValues(alpha: 0.85),
                    ),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: _heading,
                        size: 25,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Please arrive at the hospital before your turn. '
                          'You can check your latest queue status from My Tokens.',
                          style: TextStyle(
                            color: _muted,
                            fontSize: 13,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 26),

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
                      backgroundColor: _heading,
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shadowColor: _heading.withValues(alpha: 0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.home_rounded, size: 23),
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

                const SizedBox(height: 15),

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
                        'Thank you for choosing our hospital',
                        style: TextStyle(
                          fontSize: 11,
                          color: _muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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

  static const Color _heading = Color(0xFF174A5B);
  static const Color _muted = Color(0xFF648994);

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
        Container(
          height: 39,
          width: 39,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF8FB),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: _heading,
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
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                textAlign: TextAlign.start,
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