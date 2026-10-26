import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/auth_controller.dart';
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

  static const Color _navy = Color(0xFF173B5E);
  static const Color _blue = Color(0xFF246F96);

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
        backgroundColor:
            isError ? Colors.red.shade700 : Colors.green.shade700,
      ),
    );
  }

  Future<void> _signup() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthController>();
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
    required String label,
    required String hint,
    Widget? suffixIcon,
  }) {
    const borderColor = Color(0xFFD6DEE8);

    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(
        color: Color(0xFF60758A),
        fontSize: 14,
      ),
      hintStyle: const TextStyle(
        color: Color(0xFF929EAA),
        fontSize: 15,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 17,
      ),
      suffixIcon: suffixIcon,
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(
          color: borderColor,
          width: 1.2,
        ),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(
          color: _blue,
          width: 1.6,
        ),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(
          color: Colors.redAccent,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
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
        label: label,
        hint: hint,
        suffixIcon: suffixIcon,
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
    bool isLast = false,
  }) {
    return _buildField(
      controller: controller,
      label: label,
      hint: hint,
      obscureText: obscure,
      textInputAction:
          isLast ? TextInputAction.done : TextInputAction.next,
      validator: validator,
      autofillHints: const [AutofillHints.newPassword],
      suffixIcon: IconButton(
        onPressed: onToggle,
        icon: Icon(
          obscure
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          color: const Color(0xFF718096),
          size: 21,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return Scaffold(
      backgroundColor: Colors.white,
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
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(
                    24,
                    28,
                    24,
                    24,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.97),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF315B91)
                            .withValues(alpha: 0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SignupMedicalLogo(),
                        const SizedBox(height: 12),
                        const Text(
                          'Create Account',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF0B121A),
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Create your account to get started',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF25282B),
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 28),

                        _buildField(
                          controller: _nameController,
                          label: 'Full Name',
                          hint: 'Enter your full name',
                          autofillHints: const [AutofillHints.name],
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Please enter your full name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),

                        _buildField(
                          controller: _emailController,
                          label: 'Email',
                          hint: 'Enter your email',
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
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
                        const SizedBox(height: 18),

                        _buildPasswordField(
                          controller: _passwordController,
                          label: 'Password',
                          hint: 'Enter your password',
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
                        const SizedBox(height: 18),

                        _buildPasswordField(
                          controller: _confirmPasswordController,
                          label: 'Confirm Password',
                          hint: 'Re-enter your password',
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
                        const SizedBox(height: 22),

                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed:
                                auth.isLoading ? null : _signup,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 14, 18, 33),
                              foregroundColor: Colors.white,
                              elevation: 1,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                              ),
                            ),
                            child: auth.isLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.3,
                                    ),
                                  )
                                : const Text(
                                    'Create Account',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 22),

                        const Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: Color(0xFFDDE3EA),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                'Or continue with',
                                style: TextStyle(
                                  color: Color(0xFF212327),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: Color(0xFFDDE3EA),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        SizedBox(
                          height: 50,
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
                              backgroundColor:
                                  const Color(0xFFF3F5F8),
                              foregroundColor: _navy,
                              side: const BorderSide(
                                color: Color(0xFFE0E5EB),
                              ),
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.g_mobiledata,
                                  size: 30,
                                  color: Color(0xFF4285F4),
                                ),
                                SizedBox(width: 7),
                                Text(
                                  'Sign in with Google',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),

                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text(
                              'Already have an account? ',
                              style: TextStyle(
                                color: Color(0xFF1D1F24),
                                fontSize: 14,
                              ),
                            ),
                            TextButton(
                              onPressed: auth.isLoading
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
                              style: TextButton.styleFrom(
                                foregroundColor: const Color.fromARGB(255, 5, 7, 26),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                              ),
                              child: const Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
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
        ),
      ),
    );
  }
}

class SignupMedicalLogo extends StatelessWidget {
  const SignupMedicalLogo({super.key});

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
                  Color.fromARGB(255, 49, 162, 211),
                  Color.fromARGB(255, 31, 67, 137),
                  Color.fromARGB(255, 6, 36, 57),
                  Color.fromARGB(255, 6, 23, 46),
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
