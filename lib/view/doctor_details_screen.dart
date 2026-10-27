import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/doctor_model.dart';
import '../controller/token_controller.dart';
import 'booking_confirmation_screen.dart';

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
  static const Color _primary = Color.fromARGB(255, 14, 58, 111);
  static const Color _skyBlue = Color(0xFF8DB8F5);
  static const Color _background = Color(0xFFE6EFFF);
  static const Color _darkText = Color.fromARGB(255, 5, 26, 37);
  // static const Color _muted = Color(0xFF60758A);

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

    final token = await tokenController.bookToken(
      doctorId: widget.doctor.id,
    );

    if (!mounted) return;

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;

    final specialization =
        doctor.specialization?.trim().isNotEmpty == true
            ? doctor.specialization!.trim()
            : 'Medical Specialist';

    return Scaffold(
      backgroundColor: _background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _background,
              Color(0xFFF2F6FF),
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
                    Row(
                      children: [
                        _HeaderButton(
                          icon: Icons.arrow_back_rounded,
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Text(
                            'Doctor Details',
                            style: TextStyle(
                              color: _primary,
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          height: 46,
                          width: 46,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: _primary.withValues(alpha: 0.06),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.local_hospital_rounded,
                            color: _primary,
                            size: 25,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: _primary,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: _primary.withValues(alpha: 0.15),
                            blurRadius: 14,
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
                                  'View doctor details and book your queue token.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 12),
                          Icon(
                            Icons.medical_services_rounded,
                            color: _skyBlue,
                            size: 43,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? colors.surface : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _skyBlue.withValues(alpha: 0.35),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _primary.withValues(alpha: 0.06),
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
                                color: _skyBlue,
                                width: 2,
                              ),
                            ),
                            child: const CircleAvatar(
                              radius: 48,
                              backgroundColor: _background,
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
                              color: isDark
                                  ? colors.onSurface
                                  : _primary,
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 10),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _background,
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

                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? colors.surface : Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: _skyBlue.withValues(alpha: 0.35),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _primary.withValues(alpha: 0.05),
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
                                  color: _primary,
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
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _background,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: _skyBlue.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.confirmation_number_outlined,
                            color: _primary,
                            size: 23,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Book your token to join today’s queue. '
                              'Your token number will help you track your '
                              'position in the queue.',
                              style: TextStyle(
                                color: _darkText,
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

              Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                decoration: BoxDecoration(
                  color: isDark ? colors.surface : Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _primary.withValues(alpha: 0.08),
                      blurRadius: 14,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: !doctor.isAvailable ||
                              tokenController.isBooking
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _HeaderButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 14, 18, 33)
                .withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: const Color.fromARGB(255, 14, 18, 33),
          size: 25,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  static const Color _primary = Color.fromARGB(255, 14, 18, 33);
  static const Color _muted = Color(0xFF60758A);
  static const Color _background = Color(0xFFE6EFFF);

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 39,
          width: 39,
          decoration: BoxDecoration(
            color: _background,
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
                  color: isDark ? colors.onSurface : _primary,
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
