
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../controller/auth_controller.dart';
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
  static const Color _blue = Color(0xFF246F96);
  static const Color _navy = Color(0xFF173B5E);
  static const Color _darkButton = Color.fromARGB(255, 14, 18, 33);

  static const int _resendCooldown = 60;

  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());

  final List<FocusNode> _focusNodes =
      List.generate(6, (_) => FocusNode());

  Timer? _timer;
  int _secondsRemaining = _resendCooldown;
  bool _isVerifying = false;
  bool _isResending = false;

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
      _secondsRemaining = _resendCooldown;
    });

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
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
      },
    );
  }

  String get _otp =>
      _controllers.map((controller) => controller.text).join();

  void _showMessage(String message, {bool isError = true}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Colors.red.shade700 : const Color.fromARGB(255, 7, 22, 31),
      ),
    );
  }

  Future<void> _resendOtp() async {
    if (_secondsRemaining > 0 ||
        _isResending ||
        _isVerifying) {
      return;
    }

    setState(() => _isResending = true);

    final auth = context.read<AuthController>();

    try {
      final success = await auth.resendOtp(
        isRegistration: widget.isRegistration,
      );

      if (!mounted) return;

      if (!success) {
        _showMessage(
          auth.error ?? 'Unable to resend OTP. Please try again.',
        );
        return;
      }

      for (final controller in _controllers) {
        controller.clear();
      }

      FocusScope.of(context).requestFocus(_focusNodes.first);

      _startTimer();

      _showMessage(
        'A new OTP request was accepted. Check your email.',
        isError: false,
      );
    } catch (_) {
      if (mounted) {
        _showMessage('Unable to resend OTP. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  Future<void> _verifyOtp() async {
    FocusScope.of(context).unfocus();

    if (_otp.length != 6 ||
        _otp.contains(RegExp(r'[^0-9]'))) {
      _showMessage('Please enter the complete 6-digit OTP.');
      return;
    }

    setState(() => _isVerifying = true);

    final auth = context.read<AuthController>();

    try {
      if (widget.isRegistration) {
        final registrationSuccess =
            await auth.verifyRegistration(
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
            isError: false,
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

  Widget _buildLogo() {
    return const MedicalLogo();
  }

  Widget _buildOtpBox(int index) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: AspectRatio(
          aspectRatio: 0.8,
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
            decoration: const InputDecoration(
              counterText: '',
              filled: true,
              fillColor: Color(0xFFF8FAFD),
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(
                  color: Color(0xFFD0D7E2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(
                  color: _blue,
                  width: 1.5,
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
        ),
      ),
    );
  }

  Widget _buildResendControl() {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text(
          "Didn't receive the code? ",
          style: TextStyle(
            color: Color.fromARGB(255, 1, 16, 27),
            fontSize: 13,
          ),
        ),
        if (_secondsRemaining > 0)
          Text(
            '00:${_secondsRemaining.toString().padLeft(2, '0')}',
            style: const TextStyle(
              color: _blue,
              fontWeight: FontWeight.bold,
            ),
          )
        else
          TextButton(
            onPressed:
                _isResending || _isVerifying ? null : _resendOtp,
            style: TextButton.styleFrom(
              foregroundColor: _blue,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
            child: _isResending
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color.fromARGB(255, 12, 25, 39),
                    ),
                  )
                : const Text(
                    'Resend OTP',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final heading = widget.isRegistration
        ? 'Verify Your Email'
        : 'Verify Your Login';

    final description = widget.isRegistration
        ? 'Enter the 6-digit code sent to your email to complete your registration.'
        : 'Enter the 6-digit code sent to your email to securely continue.';

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF8DB8F5),
              Color(0xFFB7D2F8),
              Color(0xFFE6EFFF),
              Colors.white,
              Color(0xFFE8F0FF),
              Color(0xFF9DBDF2),
            ],
            stops: [0.0, 0.16, 0.32, 0.55, 0.78, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 450),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.zero,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(child: _buildLogo()),

                    const SizedBox(height: 8),

                    Text(
                      heading,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _navy,
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 24),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF3F6FA),
                        borderRadius: BorderRadius.zero,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.email_outlined,
                            color: _blue,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.email,
                              style: const TextStyle(
                                color: _navy,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    Row(
                      children: List.generate(6, _buildOtpBox),
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isVerifying || _isResending
                            ? null
                            : _verifyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _darkButton,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.blueGrey,
                          elevation: 0,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        child: _isVerifying
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Verify OTP',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Center(child: _buildResendControl()),

                    const SizedBox(height: 12),

                    TextButton.icon(
                      onPressed: _isVerifying || _isResending
                          ? null
                          : () {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                                (route) => false,
                              );
                            },
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        size: 18,
                      ),
                      label: const Text('Back to Login'),
                      style: TextButton.styleFrom(
                        foregroundColor: _blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MedicalLogo extends StatelessWidget {
  const MedicalLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 155,
      height: 145,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ShaderMask(
            shaderCallback: (bounds) {
              return const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.fromARGB(255, 71, 127, 177),
                  Color.fromARGB(255, 44, 70, 141),
                  Color.fromARGB(255, 11, 37, 56),
                  Color.fromARGB(255, 4, 15, 29),
                ],
              ).createShader(bounds);
            },
            child: const Icon(
              Icons.favorite_rounded,
              size: 145,
              color: Colors.white,
            ),
          ),
          const Positioned(
            top: 35,
            child: Icon(
              Icons.add_rounded,
              size: 65,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
