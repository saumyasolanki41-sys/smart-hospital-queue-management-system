
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../viewmodels/auth_viewmodel.dart';
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

  // Replace with your Web application OAuth client ID.
  static const String _webClientId =
      'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com';

  static const Color _blue = Color(0xFF246F96);
  static const Color _cyan = Color(0xFF31CFDF);
  static const Color _pale = Color(0xFFBDEBF6);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = true}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Colors.red.shade700 : Colors.green.shade700,
      ),
    );
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthViewModel>();

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
      _showMessage(
        auth.error ?? 'Login failed. Please try again.',
      );
    }
  }

  Future<void> _loginWithGoogle() async {
    final auth = context.read<AuthViewModel>();

    FocusScope.of(context).unfocus();
    auth.clearError();

    try {
      final googleSignIn = GoogleSignIn.instance;

      if (!_googleInitialized) {
        if (_webClientId.startsWith('YOUR_')) {
          _showMessage(
            'Google OAuth is not configured. Add your Web '
            'application client ID in login_screen.dart.',
          );
          return;
        }

        await googleSignIn.initialize(
          serverClientId: _webClientId,
        );

        _googleInitialized = true;
      }

      final account = await googleSignIn.authenticate();

      final idToken = account.authentication.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw Exception(
          'Google did not return an ID token. Check your OAuth configuration.',
        );
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
        _showMessage(
          auth.error ?? 'Google login failed. Please try again.',
        );
      }
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        return;
      }

      _showMessage(
        'Google sign-in failed: ${error.description ?? error.code.name}. '
        'Check your OAuth client ID and Android SHA-1 configuration.',
      );
    } catch (error) {
      _showMessage(
        'Google login failed: ${error.toString()}',
      );
    }
  }

  void _showNotConnectedMessage(String feature) {
    _showMessage('$feature is not connected yet.');
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
        vertical: 20,
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
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0, -0.7),
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
                height: constraints.maxHeight * 0.35,
                child: const CustomPaint(
                  painter: LoginTopWavePainter(),
                ),
              ),
              Positioned(
                top: constraints.maxHeight * 0.31,
                left: 0,
                right: 0,
                bottom: 0,
                child: const ColoredBox(color: _blue),
              ),
              Positioned(
                top: constraints.maxHeight * 0.275,
                left: 0,
                right: 0,
                height: constraints.maxHeight * 0.10,
                child: const CustomPaint(
                  painter: LoginMiddleWavePainter(),
                ),
              ),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 12, 28, 20),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 2),
                            const Center(
                              child: LoginMedicalLogo(),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Login',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF35C4D0),
                                fontSize: 39,
                                fontWeight: FontWeight.w500,
                                letterSpacing: -0.4,
                              ),
                            ),
                            SizedBox(
                              height: constraints.maxHeight * 0.075,
                            ),
                            const Text(
                              'Welcome back!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 35,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Login to your account',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 23,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 25),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autocorrect: false,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                              ),
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
                              textInputAction: TextInputAction.done,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                              ),
                              onFieldSubmitted: (_) => _login(),
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
                                    color: const Color(0xFF75838B),
                                    size: 25,
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
                            const SizedBox(height: 9),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: auth.isLoading
                                    ? null
                                    : () => _showNotConnectedMessage(
                                          'Password recovery',
                                        ),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 5,
                                  ),
                                ),
                                child: const Text(
                                  'Forget password',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 56),
                            SizedBox(
                              height: 64,
                              child: ElevatedButton(
                                onPressed: auth.isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _cyan,
                                  disabledBackgroundColor:
                                      _cyan.withValues(alpha: 0.7),
                                  foregroundColor: Colors.white,
                                  elevation: 4,
                                  shadowColor:
                                      Colors.black.withValues(alpha: 0.22),
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
                                        'Login',
                                        style: TextStyle(
                                          fontSize: 25,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 58),
                            const Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: Color(0xFFD0EAF1),
                                    thickness: 1.3,
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
                                    thickness: 1.3,
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
                                    : _loginWithGoogle,
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF0F8FF),
                                  foregroundColor: const Color(0xFF81D8DC),
                                  side: const BorderSide(
                                    color: _cyan,
                                    width: 1.5,
                                  ),
                                  elevation: 3,
                                  shadowColor:
                                      Colors.black.withValues(alpha: 0.18),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                child: auth.isLoading
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.g_mobiledata,
                                            size: 34,
                                            color: Color(0xFF4285F4),
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Login with Google',
                                            style: TextStyle(
                                              fontSize: 21,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                            const SizedBox(height: 65),
                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                const Text(
                                  'Don’t have an account? ',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                TextButton(
                                  onPressed: auth.isLoading
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
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                  ),
                                  child: const Text(
                                    'Register',
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
            top: 38,
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

class LoginTopWavePainter extends CustomPainter {
  const LoginTopWavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final lightWave = Path()
      ..moveTo(0, size.height * 0.75)
      ..cubicTo(
        size.width * 0.25, size.height * 0.45,
        size.width * 0.38, size.height * 0.88,
        size.width * 0.60, size.height * 0.75,
      )
      ..cubicTo(
        size.width * 0.77, size.height * 0.63,
        size.width * 0.87, size.height * 0.40,
        size.width, size.height * 0.37,
      )
      ..lineTo(size.width, size.height * 0.65)
      ..cubicTo(
        size.width * 0.77, size.height * 0.90,
        size.width * 0.60, size.height,
        size.width * 0.43, size.height * 0.81,
      )
      ..cubicTo(
        size.width * 0.22, size.height * 0.59,
        size.width * 0.11, size.height * 0.61,
        0, size.height * 0.83,
      )
      ..close();

    canvas.drawPath(
      lightWave,
      Paint()..color = const Color(0xFF70C8D3),
    );

    final darkWave = Path()
      ..moveTo(0, size.height * 0.75)
      ..cubicTo(
        size.width * 0.23, size.height * 0.45,
        size.width * 0.38, size.height * 0.78,
        size.width * 0.58, size.height * 0.82,
      )
      ..cubicTo(
        size.width * 0.76, size.height * 0.91,
        size.width * 0.90, size.height * 0.61,
        size.width, size.height * 0.55,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      darkWave,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF246F96), Color(0xFF0B477A)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ).createShader(Offset.zero & size),
    );

    final line = Path()
      ..moveTo(0, size.height * 0.77)
      ..cubicTo(
        size.width * 0.23, size.height * 0.82,
        size.width * 0.28, size.height * 0.69,
        size.width * 0.48, size.height * 0.84,
      )
      ..cubicTo(
        size.width * 0.71, size.height,
        size.width * 0.86, size.height * 0.75,
        size.width, size.height * 0.57,
      );

    canvas.drawPath(
      line,
      Paint()
        ..color = const Color(0xFF9BF1F2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    canvas.drawCircle(
      Offset(size.width * 0.49, size.height * 0.84),
      5.5,
      Paint()..color = const Color(0xFF9BF1F2),
    );
  }

  @override
  bool shouldRepaint(covariant LoginTopWavePainter oldDelegate) => false;
}

class LoginMiddleWavePainter extends CustomPainter {
  const LoginMiddleWavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final wave = Path()
      ..moveTo(0, size.height * 0.15)
      ..cubicTo(
        size.width * 0.22, -size.height * 0.30,
        size.width * 0.39, size.height * 0.42,
        size.width * 0.62, size.height * 0.50,
      )
      ..cubicTo(
        size.width * 0.80, size.height * 0.58,
        size.width * 0.90, size.height * 0.25,
        size.width, 0,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      wave,
      Paint()..color = const Color(0xFF246F96),
    );

    final rightWave = Path()
      ..moveTo(size.width * 0.59, size.height * 0.50)
      ..cubicTo(
        size.width * 0.76, size.height * 0.12,
        size.width * 0.91, size.height * 0.03,
        size.width, 0,
      )
      ..lineTo(size.width, size.height * 0.45)
      ..cubicTo(
        size.width * 0.83, size.height * 0.76,
        size.width * 0.70, size.height * 0.67,
        size.width * 0.59, size.height * 0.50,
      )
      ..close();

    canvas.drawPath(
      rightWave,
      Paint()..color = const Color(0xFF70C8D3),
    );

    final line = Path()
      ..moveTo(0, size.height * 0.15)
      ..cubicTo(
        size.width * 0.20, size.height * 0.26,
        size.width * 0.35, -size.height * 0.04,
        size.width * 0.51, size.height * 0.44,
      )
      ..cubicTo(
        size.width * 0.74, size.height * 0.85,
        size.width * 0.90, size.height * 0.37,
        size.width, 0,
      );

    canvas.drawPath(
      line,
      Paint()
        ..color = const Color(0xFF9BF1F2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    canvas.drawCircle(
      Offset(size.width * 0.50, size.height * 0.44),
      5.5,
      Paint()..color = const Color(0xFF9BF1F2),
    );
  }

  @override
  bool shouldRepaint(covariant LoginMiddleWavePainter oldDelegate) => false;
}
