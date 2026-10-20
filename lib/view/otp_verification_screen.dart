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

  const OtpVerificationScreen({
    super.key,
    required this.email,
    required this.isRegistration,
  });

  @override
  State<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _otpFocusNode = FocusNode();

  Timer? _timer;
  int _remainingSeconds = 45;

  static const Color _navy = Color(0xFF164C78);
  static const Color _cyan = Color(0xFF35C4D0);
  // static const Color _paleBlue = Color(0xFFD7F5FA);

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    _remainingSeconds = 45;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthViewModel>();
    final otp = _otpController.text.trim();

    final bool success;

    if (widget.isRegistration) {
      success = await auth.verifyRegistration(
        email: widget.email,
        otp: otp,
      );
    } else {
      success = await auth.verifyLogin(otp: otp);
    }

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            auth.error ?? 'OTP verification failed. Please try again.',
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    if (widget.isRegistration) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration successful. Please log in.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
        (route) => false,
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
        (route) => false,
      );
    }
  }

  Widget _buildOtpBoxes() {
    return GestureDetector(
      onTap: () {
        _otpFocusNode.requestFocus();
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            children: List.generate(6, (index) {
              final digits = _otpController.text;
              final hasDigit = index < digits.length;
              final isCurrent = index == digits.length && digits.length < 6;

              return Expanded(
                child: Container(
                  height: 66,
                  margin: EdgeInsets.only(
                    right: index == 5 ? 0 : 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FEFF),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: isCurrent
                          ? _cyan
                          : const Color(0xFFE1F0F4),
                      width: isCurrent ? 1.8 : 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _navy.withValues(alpha: 0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    hasDigit ? digits[index] : '',
                    style: const TextStyle(
                      color: _navy,
                      fontSize: 25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }),
          ),

          Positioned.fill(
            child: Opacity(
              opacity: 0.015,
              child: TextField(
                controller: _otpController,
                focusNode: _otpFocusNode,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                maxLength: 6,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                onChanged: (_) {
                  setState(() {});
                  if (_otpController.text.length == 6) {
                    FocusScope.of(context).unfocus();
                  }
                },
                onSubmitted: (_) => _verifyOtp(),
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 1,
                ),
                cursorColor: Colors.transparent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFB8EDF4),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: Container(
                width: double.infinity,
                height: constraints.maxHeight,
                margin: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FCFE),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: _navy.withValues(alpha: 0.09),
                      blurRadius: 18,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    const Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFF4FEFF),
                              Color(0xFFE7FAFD),
                              Color(0xFFF5FEFF),
                            ],
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      top: -35,
                      left: -80,
                      right: -60,
                      height: constraints.maxHeight * 0.23,
                      child: const CustomPaint(
                        painter: OtpBackgroundWavePainter(),
                      ),
                    ),

                    Positioned(
                      bottom: -10,
                      left: -10,
                      right: -10,
                      height: constraints.maxHeight * 0.23,
                      child: const CustomPaint(
                        painter: OtpBottomWavePainter(),
                      ),
                    ),

                    SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        28,
                        28,
                        28,
                        35,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 63,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 18),

                              Row(
                                children: [
                                  IconButton(
                                    onPressed: auth.isLoading
                                        ? null
                                        : () => Navigator.pop(context),
                                    icon: const Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      size: 25,
                                      color: _navy,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  const Expanded(
                                    child: Text(
                                      'OTP Verification',
                                      style: TextStyle(
                                        color: _navy,
                                        fontSize: 27,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 38),

                              Padding(
                                padding: const EdgeInsets.only(left: 13),
                                child: Text(
                                  widget.isRegistration
                                      ? 'Enter the 6-digit code sent to your email or phone'
                                      : 'Enter the 6-digit code sent to your email or phone',
                                  style: const TextStyle(
                                    color: Color(0xFF477393),
                                    fontSize: 18,
                                    height: 1.55,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 46),

                              _buildOtpBoxes(),

                              if (auth.error != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  auth.error!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 13,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],

                              const SizedBox(height: 60),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.access_time_rounded,
                                    color: Color(0xFF477393),
                                    size: 25,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    _remainingSeconds > 0
                                        ? 'Resend code in 00:${_remainingSeconds.toString().padLeft(2, '0')}'
                                        : 'Code timer expired',
                                    style: const TextStyle(
                                      color: Color(0xFF7298AD),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 43),

                              TextButton(
                                onPressed: auth.isLoading
                                    ? null
                                    : () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  foregroundColor: _navy,
                                ),
                                child: const Text(
                                  'Use a different email',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 25),

                              SizedBox(
                                height: 54,
                                child: ElevatedButton(
                                  onPressed:
                                      auth.isLoading ? null : _verifyOtp,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _cyan,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor:
                                        _cyan.withValues(alpha: 0.6),
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: auth.isLoading
                                      ? const SizedBox(
                                          height: 22,
                                          width: 22,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : const Text(
                                          'Verify OTP',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
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

class OtpBackgroundWavePainter extends CustomPainter {
  const OtpBackgroundWavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height * 0.25)
      ..cubicTo(
        size.width * 0.24,
        size.height * 0.04,
        size.width * 0.48,
        size.height * 0.27,
        size.width * 0.72,
        size.height * 0.04,
      )
      ..cubicTo(
        size.width * 0.88,
        -size.height * 0.04,
        size.width,
        size.height * 0.02,
        size.width,
        size.height * 0.02,
      )
      ..lineTo(size.width, size.height * 0.36)
      ..cubicTo(
        size.width * 0.72,
        size.height * 0.46,
        size.width * 0.50,
        size.height * 0.18,
        size.width * 0.23,
        size.height * 0.37,
      )
      ..close();

    canvas.drawPath(
      path,
      Paint()..color = _waveColor,
    );
  }

  static const Color _waveColor = Color(0xFFDCF8FB);

  @override
  bool shouldRepaint(covariant OtpBackgroundWavePainter oldDelegate) => false;
}

class OtpBottomWavePainter extends CustomPainter {
  const OtpBottomWavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.78)
      ..cubicTo(
        size.width * 0.25,
        size.height * 0.55,
        size.width * 0.43,
        size.height * 0.78,
        size.width * 0.65,
        size.height * 0.68,
      )
      ..cubicTo(
        size.width * 0.83,
        size.height * 0.61,
        size.width * 0.94,
        size.height * 0.49,
        size.width,
        size.height * 0.53,
      )
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(
      path,
      Paint()..color = const Color(0xFFDDF8FB),
    );
  }

  @override
  bool shouldRepaint(covariant OtpBottomWavePainter oldDelegate) => false;
}
