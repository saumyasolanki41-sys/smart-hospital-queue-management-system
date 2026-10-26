import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../controller/auth_controller.dart';
import 'otp_verification_screen.dart';
import 'signup_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _googleInitialized = false;
  bool _isGoogleLoading = false;
  bool _isLoginLoading = false;

  static const String _webClientId =
      '575895479049-o8m7g8o39db8013ctntip67uh96rit64.apps.googleusercontent.com';

  static const Color _blue = Color(0xFF246F96);
  static const Color _navy = Color(0xFF173B5E);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = true}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? Colors.red.shade700 : Colors.green.shade700,
        ),
      );
  }

  Future<void> _login() async {
    if (_isLoginLoading || _isGoogleLoading) return;

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoginLoading = true;
    });

    try {
      final auth = context.read<AuthController>();

      final success = await auth.login(
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
              isRegistration: false,
            ),
          ),
        );
      } else {
        debugPrint('Login failed: ${auth.error ?? 'No error details'}');

        _showMessage(
          'Login failed. Please check your credentials and try again.',
        );
      }
    } catch (error, stackTrace) {
      debugPrint('Login error: $error');
      debugPrintStack(stackTrace: stackTrace);

      _showMessage('Unable to login. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoginLoading = false;
        });
      }
    }
  }

  Future<void> _loginWithGoogle() async {
    if (_isGoogleLoading || _isLoginLoading) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isGoogleLoading = true;
    });

    try {
      final auth = context.read<AuthController>();
      auth.clearError();

      final googleSignIn = GoogleSignIn.instance;

      if (!_googleInitialized) {
        await googleSignIn.initialize(
          serverClientId: _webClientId,
        );
        _googleInitialized = true;
      }

      final account = await googleSignIn.authenticate();
      final idToken = account.authentication.idToken;

      if (idToken == null || idToken.isEmpty) {
        debugPrint('Google sign-in returned an empty ID token.');

        _showMessage(
          'Google sign-in could not be completed. Please try again.',
        );
        return;
      }

      if (!mounted) return;

      final success = await auth.loginWithGoogle(
        idToken: idToken,
      );

      if (!mounted) return;

      if (success) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const HomeScreen(),
          ),
          (route) => false,
        );
      } else {
        debugPrint(
          'Google authentication failed: '
          '${auth.error ?? 'No error details'}',
        );

        _showMessage(
          'Google login failed. Please try again.',
        );
      }
    } on GoogleSignInException catch (error, stackTrace) {
      debugPrint('Google sign-in exception: ${error.code}');
      debugPrintStack(stackTrace: stackTrace);

      if (error.code == GoogleSignInExceptionCode.canceled) {
        return;
      }

      _showMessage(
        'Google sign-in failed. Please try again.',
      );
    } catch (error, stackTrace) {
      debugPrint('Google login error: $error');
      debugPrintStack(stackTrace: stackTrace);

      _showMessage(
        'Google login failed. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }

  InputDecoration _inputDecoration({
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final isLoading =
        _isLoginLoading || _isGoogleLoading || auth.isLoading;

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
                        const LoginMedicalLogo(),
                        const SizedBox(height: 12),
                        const Text(
                          'Welcome back!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color.fromARGB(255, 11, 18, 26),
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Login to your account',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color.fromARGB(255, 37, 40, 43),
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 28),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          enabled: !isLoading,
                          style: const TextStyle(
                            color: _navy,
                            fontSize: 15,
                          ),
                          decoration: _inputDecoration(
                            label: 'Email',
                            hint: 'Enter your email',
                          ),
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
                        const SizedBox(height: 18),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          enabled: !isLoading,
                          style: const TextStyle(
                            color: _navy,
                            fontSize: 15,
                          ),
                          onFieldSubmitted: (_) => _login(),
                          decoration: _inputDecoration(
                            label: 'Password',
                            hint: 'Enter your password',
                            suffixIcon: IconButton(
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      setState(() {
                                        _obscurePassword =
                                            !_obscurePassword;
                                      });
                                    },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: const Color(0xFF718096),
                                size: 21,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password.';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: isLoading
                                ? null
                                : () => _showMessage(
                                      'Password recovery is not connected yet.',
                                    ),
                            style: TextButton.styleFrom(
                              foregroundColor:
                                  const Color.fromARGB(255, 11, 12, 26),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 0,
                                vertical: 8,
                              ),
                            ),
                            child: const Text(''),
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 14, 18, 33),
                              foregroundColor: Colors.white,
                              elevation: 1,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.3,
                                    ),
                                  )
                                : const Text(
                                    'Login',
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
                                  color: Color.fromARGB(255, 33, 35, 39),
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
                            onPressed: isLoading
                                ? null
                                : _loginWithGoogle,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: const Color(0xFFF3F5F8),
                              foregroundColor: _navy,
                              side: const BorderSide(
                                color: Color(0xFFE0E5EB),
                              ),
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.3,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
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
                              'New here? ',
                              style: TextStyle(
                                color: Color.fromARGB(255, 29, 31, 36),
                                fontSize: 14,
                              ),
                            ),
                            TextButton(
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const SignupScreen(),
                                        ),
                                      );
                                    },
                              style: TextButton.styleFrom(
                                foregroundColor:
                                    const Color.fromARGB(255, 15, 16, 32),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                              ),
                              child: const Text(
                                'Create account',
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

class LoginMedicalLogo extends StatelessWidget {
  const LoginMedicalLogo({super.key});

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
                  Color.fromARGB(255, 49, 160, 211),
                  Color.fromARGB(255, 42, 92, 167),
                  Color.fromARGB(255, 8, 64, 104),
                  Color.fromARGB(255, 7, 26, 52),
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
