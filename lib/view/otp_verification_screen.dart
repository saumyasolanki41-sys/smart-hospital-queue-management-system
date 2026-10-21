
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final bool isRegistration;
  final String? registrationPassword;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    this.isRegistration = false,
    this.registrationPassword,
  });

  @override
  State<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState
    extends State<OtpVerificationScreen> {
  static const Color _navy = Color(0xFF0B477A);
  static const Color _blue = Color(0xFF17699A);
  static const Color _cyan = Color(0xFF31CFDF);
  static const Color _paleCyan = Color(0xFFD9F8FC);
  static const Color _fieldColor = Color(0xFFF1FBFE);

  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());

  final List<FocusNode> _focusNodes =
      List.generate(6, (_) => FocusNode());

  Timer? _timer;
  int _secondsRemaining = 45;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();

    for (final controller in _controllers) {
      controller.dispose();
    }

    for (final node in _focusNodes) {
      node.dispose();
    }

    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = 45;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() => _secondsRemaining = 0);
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  String get _otp =>
      _controllers.map((controller) => controller.text).join();

  void _showMessage(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : _navy,
      ),
    );
  }

  Future<void> _verifyOtp() async {
    FocusScope.of(context).unfocus();

    if (_otp.length != 6 || _otp.contains(RegExp(r'[^0-9]'))) {
      _showMessage('Please enter the complete 6-digit OTP.');
      return;
    }

    setState(() => _isVerifying = true);

    final auth = context.read<AuthViewModel>();

    try {
      if (widget.isRegistration) {
        final registrationSuccess = await auth.verifyRegistration(
          email: widget.email,
          otp: _otp,
        );

        if (!mounted) return;

        if (!registrationSuccess) {
          _showMessage(
            auth.error ?? 'Registration OTP verification failed.',
          );
          return;
        }

        final password = widget.registrationPassword;

        if (password == null || password.isEmpty) {
          _showMessage(
            'Registration verified. Please log in to continue.',
          );

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => const LoginScreen(),
            ),
            (route) => false,
          );
          return;
        }

        // Request the login OTP using the same credentials.
        final loginSuccess = await auth.login(
          email: widget.email,
          password: password,
        );

        if (!mounted) return;

        if (!loginSuccess) {
          _showMessage(
            auth.error ??
                'Registration verified, but login could not start. '
                    'Please log in again.',
          );

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => const LoginScreen(),
            ),
            (route) => false,
          );
          return;
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OtpVerificationScreen(
              email: widget.email,
              isRegistration: false,
            ),
          ),
        );
      } else {
        final loginSuccess = await auth.verifyLogin(otp: _otp);

        if (!mounted) return;

        if (!loginSuccess) {
          _showMessage(
            auth.error ?? 'Invalid OTP. Please try again.',
          );
          return;
        }

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const HomeScreen(),
          ),
          (route) => false,
        );
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 245,
      width: double.infinity,
      child: Stack(
        children: [
          Container(
            height: 220,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFE9FCFE),
                  Color(0xFFB9F0F6),
                  Color(0xFFDDFBFC),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _OtpHeaderWavePainter(),
            ),
          ),
          Positioned(
            top: 24,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.75),
                    boxShadow: [
                      BoxShadow(
                        color: _blue.withValues(alpha: 0.12),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: _cyan,
                    size: 62,
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -47),
                  child: const Icon(
                    Icons.add_rounded,
                    color: _navy,
                    size: 40,
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -34),
                  child: Text(
                    widget.isRegistration
                        ? 'Verify Email'
                        : 'Verify OTP',
                    style: const TextStyle(
                      color: Color(0xFF159BB7),
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 43,
      height: 54,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(
          color: _navy,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1),
        ],
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: _fieldColor,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: const BorderSide(
              color: _cyan,
              width: 2,
            ),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }

          if (_otp.length == 6) {
            FocusScope.of(context).unfocus();
          }

          setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final heading = widget.isRegistration
        ? 'Verify your email'
        : 'Enter your login OTP';

    final description = widget.isRegistration
        ? 'Enter the 6-digit code sent to your email to complete registration.'
        : 'Enter the 6-digit code sent to your email to continue.';

    return Scaffold(
      backgroundColor: _navy,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Column(
                  children: [
                    _buildHeader(),
                    Container(
                      width: double.infinity,
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 245,
                      ),
                      padding: const EdgeInsets.fromLTRB(
                        24,
                        8,
                        24,
                        28,
                      ),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF17679B),
                            Color(0xFF0B477A),
                            Color(0xFF07365D),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            heading,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 27,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            description,
                            style: const TextStyle(
                              color: _paleCyan,
                              fontSize: 15,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.09),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.email_outlined,
                                  color: _cyan,
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    widget.email,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(
                              6,
                              _buildOtpBox,
                            ),
                          ),
                          const SizedBox(height: 22),
                          SizedBox(
                            height: 54,
                            child: ElevatedButton(
                              onPressed:
                                  _isVerifying ? null : _verifyOtp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _cyan,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.blueGrey,
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: _isVerifying
                                  ? const SizedBox(
                                      height: 23,
                                      width: 23,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Text(
                                      'Verify OTP',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Didn't receive the code? ",
                                style: TextStyle(
                                  color: _paleCyan,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                _secondsRemaining > 0
                                    ? '00:${_secondsRemaining.toString().padLeft(2, '0')}'
                                    : 'Resend unavailable',
                                style: const TextStyle(
                                  color: _cyan,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          TextButton.icon(
                            onPressed: _isVerifying
                                ? null
                                : () {
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const LoginScreen(),
                                      ),
                                      (route) => false,
                                    );
                                  },
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: _cyan,
                            ),
                            label: const Text(
                              'Back to Login',
                              style: TextStyle(
                                color: _cyan,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OtpHeaderWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cyanWave = Path()
      ..moveTo(0, size.height * 0.68)
      ..cubicTo(
        size.width * 0.28,
        size.height * 0.54,
        size.width * 0.43,
        size.height * 0.98,
        size.width * 0.69,
        size.height * 0.79,
      )
      ..cubicTo(
        size.width * 0.83,
        size.height * 0.70,
        size.width * 0.91,
        size.height * 0.62,
        size.width,
        size.height * 0.60,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      cyanWave,
      Paint()..color = _OtpVerificationScreenState._cyan,
    );

    final blueWave = Path()
      ..moveTo(0, size.height * 0.75)
      ..cubicTo(
        size.width * 0.27,
        size.height * 0.61,
        size.width * 0.45,
        size.height * 1.02,
        size.width * 0.70,
        size.height * 0.84,
      )
      ..cubicTo(
        size.width * 0.84,
        size.height * 0.75,
        size.width * 0.92,
        size.height * 0.68,
        size.width,
        size.height * 0.64,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      blueWave,
      Paint()..color = _OtpVerificationScreenState._blue,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
