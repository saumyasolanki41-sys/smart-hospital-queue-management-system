import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  static const Color _primary = Color.fromARGB(255, 126, 211, 232);
  static const Color _deepBlue = Color(0xFF267D98);
  static const Color _muted = Color(0xFF527786);
  static const Color _darkText = Color(0xFF173B4D);

  Future<void> _navigate(BuildContext context, String route) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await navigator.pushNamed(route);
    } catch (error, stackTrace) {
      debugPrint('Navigation failed for $route: $error');
      debugPrintStack(stackTrace: stackTrace);

      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Unable to open this page. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
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
              Color.fromARGB(255, 126, 211, 232),
              Color.fromARGB(255, 160, 225, 237),
              Color(0xFFE8F8FC),
              Colors.white,
              Color(0xFFDDF4F9),
              Color.fromARGB(255, 126, 211, 232),
            ],
            stops: [0.0, 0.16, 0.32, 0.55, 0.78, 1.0],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _primary.withValues(alpha: 0.85),
                      const Color(0xFFB1E8F3).withValues(alpha: 0.55),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  SizedBox(
                    width: 125,
                    height: 125,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 125,
                          height: 125,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF267D98)
                                    .withValues(alpha: 0.20),
                                blurRadius: 25,
                                spreadRadius: 3,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                        ),
                        ShaderMask(
                          shaderCallback: (bounds) =>
                              const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFB1EAF5),
                              Color.fromARGB(255, 126, 211, 232),
                              Color(0xFF267D98),
                            ],
                          ).createShader(bounds),
                          child: const Icon(
                            Icons.favorite_rounded,
                            size: 125,
                            color: Colors.white,
                          ),
                        ),
                        const Icon(
                          Icons.add_rounded,
                          size: 60,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Smart',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'sans-serif',
                      color: _deepBlue,
                      height: 1,
                    ),
                  ),
                  const Text(
                    'Hospital.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'sans-serif',
                      color: _darkText,
                      letterSpacing: -1.5,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Less waiting. More care.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                      color: _muted,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const Spacer(flex: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => _navigate(context, '/signup'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _deepBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Register',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(
                          fontSize: 14,
                          color: _muted,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _navigate(context, '/login'),
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _deepBlue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
