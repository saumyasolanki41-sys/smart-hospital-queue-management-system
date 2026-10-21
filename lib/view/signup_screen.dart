
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';
import 'login_screen.dart';
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
  static const Color _blue = Color(0xFF17699A);
  static const Color _cyan = Color(0xFF31CFDF);
  static const Color _paleCyan = Color(0xFFD9F8FC);
  static const Color _fieldColor = Color(0xFFF1FBFE);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : _navy,
      ),
    );
  }

  Future<void> _signup() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthViewModel>();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final success = await auth.register(
      name: _nameController.text.trim(),
      email: email,
      password: password,
    );

    if (!mounted) return;

    if (!success) {
      _showMessage(
        auth.error ?? 'Registration failed. Please try again.',
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtpVerificationScreen(
          email: email,
          isRegistration: true,
          registrationPassword: password,
        ),
      ),
    );
  }

  InputDecoration _decoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF8297AF),
        fontSize: 15,
      ),
      prefixIcon: Icon(icon, color: _blue, size: 22),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: _fieldColor,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 17,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(
          color: _cyan,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 290,
      width: double.infinity,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: 265,
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
              painter: _HeaderWavePainter(),
            ),
          ),
          Positioned(
            top: 24,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.72),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _blue.withValues(alpha: 0.10),
                        blurRadius: 16,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: _cyan,
                    size: 67,
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -53),
                  child: const Icon(
                    Icons.add_rounded,
                    color: _navy,
                    size: 45,
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -39),
                  child: const Text(
                    'Register',
                    style: TextStyle(
                      color: Color(0xFF159BB7),
                      fontSize: 35,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
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

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    bool obscureText = false,
    Widget? suffixIcon,
    Iterable<String>? autofillHints,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      validator: validator,
      autofillHints: autofillHints,
      autocorrect: false,
      enableSuggestions: !obscureText,
      style: const TextStyle(
        color: _navy,
        fontSize: 15,
      ),
      decoration: _decoration(
        hint: hint,
        icon: icon,
        suffixIcon: suffixIcon,
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
    bool isLast = false,
  }) {
    return _buildField(
      controller: controller,
      hint: hint,
      icon: Icons.lock_outline_rounded,
      obscureText: obscure,
      textInputAction:
          isLast ? TextInputAction.done : TextInputAction.next,
      validator: validator,
      autofillHints: isLast
          ? const [AutofillHints.newPassword]
          : const [AutofillHints.newPassword],
      suffixIcon: IconButton(
        onPressed: onToggle,
        icon: Icon(
          obscure
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: const Color(0xFF8297AF),
          size: 21,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: _navy,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Column(
                  children: [
                    _buildHeader(),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(25, 5, 25, 25),
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
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 4),
                            const Text(
                              'Welcome!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Create your account to get started',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 23),

                            _buildField(
                              controller: _nameController,
                              hint: 'Full Name',
                              icon: Icons.person_outline_rounded,
                              autofillHints: const [
                                AutofillHints.name,
                              ],
                              validator: (value) {
                                if (value == null ||
                                    value.trim().isEmpty) {
                                  return 'Please enter your full name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 13),

                            _buildField(
                              controller: _emailController,
                              hint: 'Email Address',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [
                                AutofillHints.email,
                              ],
                              validator: (value) {
                                final email = value?.trim() ?? '';

                                if (email.isEmpty) {
                                  return 'Please enter your email';
                                }

                                if (!RegExp(
                                  r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                ).hasMatch(email)) {
                                  return 'Enter a valid email address';
                                }

                                return null;
                              },
                            ),
                            const SizedBox(height: 13),

                            _buildPasswordField(
                              controller: _passwordController,
                              hint: 'Password',
                              obscure: _obscurePassword,
                              onToggle: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a password';
                                }

                                if (value.length < 8) {
                                  return 'Use at least 8 characters';
                                }

                                return null;
                              },
                            ),
                            const SizedBox(height: 13),

                            _buildPasswordField(
                              controller: _confirmPasswordController,
                              hint: 'Confirm Password',
                              obscure: _obscureConfirmPassword,
                              onToggle: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                              isLast: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please confirm your password';
                                }

                                if (value != _passwordController.text) {
                                  return 'Passwords do not match';
                                }

                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            SizedBox(
                              height: 54,
                              child: ElevatedButton(
                                onPressed:
                                    auth.isLoading ? null : _signup,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _cyan,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor:
                                      Colors.blueGrey,
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: auth.isLoading
                                    ? const SizedBox(
                                        width: 23,
                                        height: 23,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : const Text(
                                        'Register',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 18),

                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: Colors.white38,
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  child: Text(
                                    'or',
                                    style: TextStyle(
                                      color: _paleCyan,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: Colors.white38,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 17),

                            SizedBox(
                              height: 52,
                              child: OutlinedButton(
                                onPressed: auth.isLoading
                                    ? null
                                    : () {
                                        _showMessage(
                                          'Google sign-in must be '
                                          'connected to your login flow.',
                                        );
                                      },
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: _navy,
                                  side: BorderSide.none,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(30),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.g_mobiledata_rounded,
                                      color: Color(0xFF4285F4),
                                      size: 32,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Login with Google',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),

                            Wrap(
                              alignment: WrapAlignment.center,
                              children: [
                                const Text(
                                  'Already have an account? ',
                                  style: TextStyle(
                                    color: _paleCyan,
                                    fontSize: 14,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: auth.isLoading
                                      ? null
                                      : () {
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const LoginScreen(),
                                            ),
                                          );
                                        },
                                  child: const Text(
                                    'Login',
                                    style: TextStyle(
                                      color: _cyan,
                                      fontSize: 14,
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

class _HeaderWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cyanWave = Path()
      ..moveTo(0, size.height * 0.69)
      ..cubicTo(
        size.width * 0.28,
        size.height * 0.55,
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
      Paint()..color = _SignupScreenState._cyan,
    );

    final blueWave = Path()
      ..moveTo(0, size.height * 0.76)
      ..cubicTo(
        size.width * 0.27,
        size.height * 0.61,
        size.width * 0.45,
        size.height * 1.03,
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
      Paint()..color = _SignupScreenState._blue,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
