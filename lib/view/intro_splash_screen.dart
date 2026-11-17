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
    const darkTeal = Color(0xFF174A5B);
    const primaryTeal = Color(0xFF267D98);
    const lightBlue = Color(0xFF7ED3E8);

    return Scaffold(
      backgroundColor: const Color(0xFFF1FBFE),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF7ED3E8),
              Color(0xFFB8EAF3),
              Color(0xFFEAF8FB),
              Color(0xFFF1FBFE),
              Colors.white,
            ],
            stops: [0.0, 0.20, 0.43, 0.72, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 185,
                  height: 185,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: primaryTeal.withValues(alpha: 0.25),
                        blurRadius: 30,
                        spreadRadius: 3,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Image.asset(
                        'lib/assets/heart_logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                const Text(
                  'Smart Hospital',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: darkTeal,
                    letterSpacing: 0.8,
                  ),
                ),

                const SizedBox(height: 9),

                const Text(
                  'Less Waiting, More Care',
                  style: TextStyle(
                    fontSize: 15,
                    color: primaryTeal,
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 45),

                const SizedBox(
                  height: 25,
                  width: 25,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: lightBlue,
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
