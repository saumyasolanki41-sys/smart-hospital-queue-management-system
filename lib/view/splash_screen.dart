
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    String destination = '/login';

    try {
      final auth = context.read<AuthViewModel>();
      final isLoggedIn = await auth.restoreSession();

      if (!mounted) return;

      destination = isLoggedIn ? '/home' : '/login';
    } catch (error, stackTrace) {
      debugPrint('Session restoration failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      destination = '/login';
    }

    if (!mounted) return;

    try {
      await Navigator.of(context).pushNamedAndRemoveUntil(
        destination,
        (route) => false,
      );
    } catch (error) {
      debugPrint('Navigation failed: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFEFFFFF),
                  Color(0xFFDDF8FA),
                  Color(0xFFC5F0F5),
                ],
              ),
            ),
          ),
          Positioned(
            top: -80,
            left: -70,
            right: -50,
            child: ClipPath(
              clipper: TopWaveClipper(),
              child: Container(
                height: 350,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF1479A4),
                      Color(0xFF45B7C8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -50,
            right: -50,
            child: ClipPath(
              clipper: BottomWaveClipper(),
              child: Container(
                height: 420,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF0D426D),
                      Color(0xFF147FA3),
                      Color(0xFF46C4CE),
                    ],
                    begin: Alignment.bottomRight,
                    end: Alignment.topLeft,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 4),
                SizedBox(
                  width: 150,
                  height: 140,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.favorite,
                        size: 145,
                        color: Color(0xFFB5F0F3),
                      ),
                      ShaderMask(
                        shaderCallback: (bounds) =>
                            const LinearGradient(
                          colors: [
                            Color(0xFF28B9C7),
                            Color(0xFF12527D),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: const Icon(
                          Icons.favorite,
                          size: 130,
                          color: Colors.white,
                        ),
                      ),
                      const Icon(
                        Icons.add,
                        size: 78,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 37,
                      color: Color(0xFF174B78),
                      letterSpacing: -1,
                    ),
                    children: [
                      TextSpan(
                        text: 'Smart ',
                        style: TextStyle(
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      TextSpan(
                        text: 'Hospital',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Queue Management System',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    color: Color(0xFF285B80),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 55),
                const Text(
                  'Less waiting. More care.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF69889B),
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  width: 48,
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xFF45BFC8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const Spacer(flex: 5),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color(0xFF32C9D7),
                  ),
                  strokeWidth: 4,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Starting...',
                  style: TextStyle(
                    fontSize: 17,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 45),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TopWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    path.lineTo(0, size.height * 0.05);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height * 0.10);

    path.cubicTo(
      size.width * 0.75,
      size.height * 0.55,
      size.width * 0.35,
      size.height * 0.85,
      0,
      size.height,
    );

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant TopWaveClipper oldClipper) => false;
}

class BottomWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    path.moveTo(0, size.height * 0.45);

    path.cubicTo(
      size.width * 0.35,
      size.height * 0.75,
      size.width * 0.65,
      size.height * 0.05,
      size.width,
      size.height * 0.10,
    );

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant BottomWaveClipper oldClipper) => false;
}
