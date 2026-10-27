
import 'dart:async';
import 'package:flutter/material.dart';

class IntroSplashScreen extends StatefulWidget {
  const IntroSplashScreen({super.key});

  @override
  State<IntroSplashScreen> createState() =>
      _IntroSplashScreenState();
}

class _IntroSplashScreenState extends State<IntroSplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        '/get-started',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FBFD),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 126, 211, 232),
              Color(0xFFB1E8F3),
              Color(0xFFE8F8FC),
              Colors.white,
              Color(0xFFDDF4F9),
              Color.fromARGB(255, 126, 211, 232),
            ],
            stops: [0.0, 0.16, 0.32, 0.55, 0.78, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 175,
                  height: 175,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.72),
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
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) {
                          return const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFB1EAF5),
                              Color.fromARGB(255, 126, 211, 232),
                              Color(0xFF4FAFCB),
                              Color(0xFF267D98),
                            ],
                          ).createShader(bounds);
                        },
                        child: const Icon(
                          Icons.favorite_rounded,
                          size: 125,
                          color: Colors.white,
                        ),
                      ),
                      const Positioned(
                        top: 48,
                        child: Icon(
                          Icons.add_rounded,
                          size: 58,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                const Text(
                  'Smart Hospital',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF173B4D),
                    letterSpacing: 0.8,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'Your Health, Our Priority',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF267D98),
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 45),

                const SizedBox(
                  height: 25,
                  width: 25,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Color.fromARGB(255, 126, 211, 232),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
