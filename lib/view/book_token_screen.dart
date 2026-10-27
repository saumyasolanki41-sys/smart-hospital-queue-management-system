import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/token_controller.dart';
import '../models/doctor_model.dart';

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
  static const Color _primary = Color.fromARGB(255, 126, 211, 232);
  static const Color _background = Color(0xFFEAF8FB);
  static const Color _heading = Color(0xFF174A5B);
  static const Color _lightBlue = Color(0xFFC8EBF2);
  static const Color _muted = Color(0xFF648994);

  Future<void> _bookToken() async {
    final controller = context.read<TokenController>();

    try {
      final token = await controller.bookToken(
        doctorId: widget.doctor.id,
      );

      if (!mounted) return;

      if (token != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Queue token booked successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, token);
      } else {
        final errorMessage =
            (controller.error ?? '').toLowerCase();

        final isDuplicateBooking = [
          'already booked',
          'already_in_queue',
          'already in queue',
          'already has an active token',
          'already_have_active_token',
          'already_have_token',
          'active token exists',
          'active token already exists',
          'already has a token',
          'you already have an active token',
          'duplicate token',
          'duplicate_booking',
          'token already exists',
        ].any(errorMessage.contains);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isDuplicateBooking
                  ? 'Token is already booked for this doctor.'
                  : controller.error ??
                      'Unable to book your token. Please try again.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to book your token. Please try again.',
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
      ),
      body: Container(
        width: double.infinity,
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
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF174A5B),
                        Color(0xFF287F94),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: _primary.withValues(alpha: 0.25),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Confirm Your Booking',
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 9),
                            Text(
                              'Join today\'s OPD queue '
                              'with your selected doctor.',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.5,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: _primary.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.confirmation_number_rounded,
                          color: _primary,
                          size: 34,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                const Row(
                  children: [
                    Icon(
                      Icons.medical_services_outlined,
                      color: _heading,
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
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _lightBlue.withValues(alpha: 0.85),
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
                              Color(0xFFEAF8FB),
                              Color(0xFFC8EBF2),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: const Icon(
                          Icons.medical_services_rounded,
                          color: _heading,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.doctor.name,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: _heading,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Selected doctor for your '
                              'OPD queue token.',
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.5,
                                color: _muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.verified_rounded,
                        color: _primary,
                        size: 24,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _lightBlue.withValues(alpha: 0.85),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _heading.withValues(alpha: 0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.groups_rounded,
                            color: _heading,
                            size: 27,
                          ),
                          SizedBox(width: 11),
                          Expanded(
                            child: Text(
                              'Join Today\'s Queue',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: _heading,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 14),
                      Text(
                        'Confirm your booking to receive a '
                        'queue token for your selected doctor.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.6,
                          color: _muted,
                        ),
                      ),
                      SizedBox(height: 16),
                      Divider(color: Color(0xFFC8EBF2)),
                      SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            color: _primary,
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Your token number will be '
                              'assigned automatically.',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.5,
                                color: _heading,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            color: _primary,
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Check your queue position and '
                              'estimated waiting time after booking.',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.5,
                                color: _heading,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: tokenController.isBooking
                        ? null
                        : _bookToken,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _heading,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _muted,
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
                const SizedBox(height: 14),
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
                      Flexible(
                        child: Text(
                          'Secure booking for registered patients.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: _muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}