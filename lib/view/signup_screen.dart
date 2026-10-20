
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';
import 'otp_verification_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  static const Color _navy = Color(0xFF0B477A);
  static const Color _blue = Color(0xFF246F96);
  static const Color _cyan = Color(0xFF31CFDF);
  static const Color _pale = Color(0xFFBDEBF6);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthViewModel>();

    final success = await auth.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            email: _emailController.text.trim(),
            isRegistration: true,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            auth.error ?? 'Registration failed. Please try again.',
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  InputDecoration _inputDecoration({
    required String hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF7E8C96),
        fontSize: 17,
        fontWeight: FontWeight.w400,
      ),
      filled: true,
      fillColor: const Color(0xFFF0F8FF),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 19,
      ),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: _cyan,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: _pale,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Positioned.fill(
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0, -0.75),
                      radius: 1.35,
                      colors: [
                        Color(0xFFE6FAFF),
                        Color(0xFFBDEBF6),
                      ],
                    ),
                  ),
                ),
              ),

              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: constraints.maxHeight * 0.34,
                child: CustomPaint(
                  painter: SignupTopWavePainter(
                    navy: _navy,
                    blue: _blue,
                    cyan: _cyan,
                  ),
                ),
              ),

              Positioned(
                top: constraints.maxHeight * 0.30,
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    color: _blue,
                  ),
                ),
              ),

              Positioned(
                top: constraints.maxHeight * 0.275,
                left: 0,
                right: 0,
                height: constraints.maxHeight * 0.105,
                child: CustomPaint(
                  painter: SignupMiddleWavePainter(
                    navy: _blue,
                    cyan: _cyan,
                  ),
                ),
              ),

              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 16, 28, 20),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 2),

                            const Center(
                              child: SignupMedicalLogo(),
                            ),

                            const SizedBox(height: 12),

                            const Text(
                              'Register',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF35C4D0),
                                fontSize: 38,
                                fontWeight: FontWeight.w500,
                                letterSpacing: -0.5,
                              ),
                            ),

                            SizedBox(
                              height: constraints.maxHeight * 0.075,
                            ),

                            const Text(
                              'Welcome!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 35,
                                fontWeight: FontWeight.w400,
                              ),
                            ),

                            const SizedBox(height: 32),

                            TextFormField(
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              decoration: _inputDecoration(hint: 'Name'),
                              validator: (value) {
                                if (value == null ||
                                    value.trim().isEmpty) {
                                  return 'Please enter your name.';
                                }
                                if (value.trim().length < 2) {
                                  return 'Name must contain at least 2 characters.';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 24),

                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autocorrect: false,
                              decoration: _inputDecoration(hint: 'Email'),
                              validator: (value) {
                                final email = value?.trim() ?? '';

                                if (email.isEmpty) {
                                  return 'Please enter your email.';
                                }

                                if (!RegExp(
                                  r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                ).hasMatch(email)) {
                                  return 'Please enter a valid email.';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 24),

                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.next,
                              decoration: _inputDecoration(
                                hint: 'Password',
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: const Color(0xFF71818A),
                                    size: 24,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please create a password.';
                                }
                                if (value.length < 8) {
                                  return 'Password must contain at least 8 characters.';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 24),

                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _signup(),
                              decoration: _inputDecoration(
                                hint: 'Confirm Password',
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword =
                                          !_obscureConfirmPassword;
                                    });
                                  },
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: const Color(0xFF71818A),
                                    size: 24,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please confirm your password.';
                                }
                                if (value != _passwordController.text) {
                                  return 'Passwords do not match.';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 30),

                            SizedBox(
                              height: 64,
                              child: ElevatedButton(
                                onPressed: auth.isLoading ? null : _signup,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _cyan,
                                  disabledBackgroundColor:
                                      _cyan.withValues(alpha: 0.7),
                                  foregroundColor: Colors.white,
                                  elevation: 4,
                                  shadowColor: Colors.black.withValues(
                                    alpha: 0.22,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                child: auth.isLoading
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : const Text(
                                        'Register',
                                        style: TextStyle(
                                          fontSize: 25,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 50),

                            const Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: Color(0xFFD0EAF1),
                                    thickness: 1.4,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(
                                    'Or continue with',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: Color(0xFFD0EAF1),
                                    thickness: 1.4,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 40),

                            SizedBox(
                              height: 64,
                              child: OutlinedButton(
                                onPressed: auth.isLoading
                                    ? null
                                    : () {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Google sign-in is not connected on this registration screen yet.',
                                            ),
                                          ),
                                        );
                                      },
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF0F8FF),
                                  foregroundColor: const Color(0xFF81D8DC),
                                  side: const BorderSide(
                                    color: _cyan,
                                    width: 1.5,
                                  ),
                                  elevation: 3,
                                  shadowColor: Colors.black.withValues(
                                    alpha: 0.18,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                child: const Text(
                                  'Login with Google',
                                  style: TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 65),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Flexible(
                                  child: Text(
                                    'Already have an account? ',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: auth.isLoading
                                      ? null
                                      : () => Navigator.pop(context),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                  ),
                                  child: const Text(
                                    'Login',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class SignupMedicalLogo extends StatelessWidget {
  const SignupMedicalLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
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
                  Color(0xFF31CBD3),
                  Color(0xFF078BB0),
                  Color(0xFF07558C),
                  Color(0xFF062E67),
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
            top: 39,
            child: Icon(
              Icons.add_rounded,
              size: 70,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class SignupTopWavePainter extends CustomPainter {
  final Color navy;
  final Color blue;
  final Color cyan;

  SignupTopWavePainter({
    required this.navy,
    required this.blue,
    required this.cyan,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.50)
      ..cubicTo(
        size.width * 0.80,
        size.height * 0.57,
        size.width * 0.66,
        size.height * 0.98,
        size.width * 0.48,
        size.height * 0.74,
      )
      ..cubicTo(
        size.width * 0.27,
        size.height * 0.39,
        size.width * 0.13,
        size.height * 0.32,
        0,
        size.height * 0.52,
      )
      ..close();

    canvas.drawPath(
      path,
      Paint()..color = const Color(0xFF70C8D3),
    );

    final darkPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.40)
      ..cubicTo(
        size.width * 0.75,
        size.height * 0.52,
        size.width * 0.58,
        size.height * 0.86,
        size.width * 0.43,
        size.height * 0.66,
      )
      ..cubicTo(
        size.width * 0.25,
        size.height * 0.32,
        size.width * 0.13,
        size.height * 0.27,
        0,
        size.height * 0.43,
      )
      ..close();

    canvas.drawPath(
      darkPath,
      Paint()
        ..shader = LinearGradient(
          colors: [blue, navy],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ).createShader(Offset.zero & size),
    );

    final line = Path()
      ..moveTo(0, size.height * 0.43)
      ..cubicTo(
        size.width * 0.25,
        size.height * 0.48,
        size.width * 0.30,
        size.height * 0.38,
        size.width * 0.46,
        size.height * 0.68,
      )
      ..cubicTo(
        size.width * 0.62,
        size.height * 0.92,
        size.width * 0.79,
        size.height * 0.45,
        size.width,
        size.height * 0.40,
      );

    canvas.drawPath(
      line,
      Paint()
        ..color = const Color(0xFF45D4DF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    canvas.drawCircle(
      Offset(size.width * 0.49, size.height * 0.68),
      5.5,
      Paint()..color = const Color(0xFF45D4DF),
    );
  }

  @override
  bool shouldRepaint(covariant SignupTopWavePainter oldDelegate) => false;
}

class SignupMiddleWavePainter extends CustomPainter {
  final Color navy;
  final Color cyan;

  SignupMiddleWavePainter({
    required this.navy,
    required this.cyan,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final wave = Path()
      ..moveTo(0, size.height * 0.24)
      ..cubicTo(
        size.width * 0.23,
        -size.height * 0.20,
        size.width * 0.40,
        size.height * 0.50,
        size.width * 0.63,
        size.height * 0.52,
      )
      ..cubicTo(
        size.width * 0.80,
        size.height * 0.58,
        size.width * 0.89,
        size.height * 0.30,
        size.width,
        size.height * 0.05,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(wave, Paint()..color = navy);

    final rightWave = Path()
      ..moveTo(size.width * 0.60, size.height * 0.52)
      ..cubicTo(
        size.width * 0.77,
        size.height * 0.15,
        size.width * 0.91,
        size.height * 0.03,
        size.width,
        0,
      )
      ..lineTo(size.width, size.height * 0.45)
      ..cubicTo(
        size.width * 0.83,
        size.height * 0.76,
        size.width * 0.71,
        size.height * 0.68,
        size.width * 0.60,
        size.height * 0.52,
      )
      ..close();

    canvas.drawPath(
      rightWave,
      Paint()..color = cyan.withValues(alpha: 0.55),
    );

    final line = Path()
      ..moveTo(0, size.height * 0.24)
      ..cubicTo(
        size.width * 0.20,
        size.height * 0.35,
        size.width * 0.36,
        size.height * 0.05,
        size.width * 0.52,
        size.height * 0.45,
      )
      ..cubicTo(
        size.width * 0.74,
        size.height * 0.88,
        size.width * 0.89,
        size.height * 0.40,
        size.width,
        size.height * 0.05,
      );

    canvas.drawPath(
      line,
      Paint()
        ..color = const Color(0xFF45D4DF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    canvas.drawCircle(
      Offset(size.width * 0.50, size.height * 0.45),
      5.5,
      Paint()..color = const Color(0xFF45D4DF),
    );
  }

  @override
  bool shouldRepaint(covariant SignupMiddleWavePainter oldDelegate) => false;
}
