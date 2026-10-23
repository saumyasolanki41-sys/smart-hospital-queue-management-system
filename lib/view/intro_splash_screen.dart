
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
      backgroundColor: const Color(0xFF1479A4),
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.favorite_rounded,
              size: 120,
              color: Colors.white,
            ),
            const Icon(
              Icons.add_rounded,
              size: 55,
              color: Color(0xFF1479A4),
            ),
          ],
        ),
      ),
    );
  }
}
