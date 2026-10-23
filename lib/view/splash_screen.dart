
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controller/auth_controller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const Color navy = Color(0xFF0B477A);
  static const Color blue = Color(0xFF247BA3);
  static const Color cyan = Color(0xFF32B8C5);
  

  bool _checkingSession = true;
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      final auth = context.read<AuthController>();
      await auth.initialize();

      if (!mounted) return;

      if (auth.isLoggedIn) {
        await Future.delayed(const Duration(milliseconds: 500));

        if (!mounted) return;

        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (route) => false,
        );
        return;
      }
    } catch (error) {
      debugPrint('Session initialization failed: $error');
    }

    if (!mounted) return;

    setState(() {
      _checkingSession = false;
    });
  }

  void _openScreen(String route) {
    if (_navigating) return;

    setState(() {
      _navigating = true;
    });

    Navigator.pushNamed(context, route).then((_) {
      if (mounted) {
        setState(() {
          _navigating = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.0, -0.05),
                radius: 1.05,
                colors: [
                  Color(0xFFEAFBFF),
                  Color(0xFFD8F5FC),
                  Color(0xFFB6E8F5),
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: constraints.maxHeight * 0.25,
                  child: CustomPaint(
                    painter: TopWavePainter(
                      navy: navy,
                      blue: const Color(0xFF268BB5),
                      cyan: cyan,
                    ),
                  ),
                ),

                Positioned(
                  left: -35,
                  top: constraints.maxHeight * 0.24,
                  child: Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFF9DE7EB)
                          .withValues(alpha: 0.48),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                Positioned(
                  left: constraints.maxWidth * 0.13,
                  top: constraints.maxHeight * 0.24,
                  child: Container(
                    height: 17,
                    width: 17,
                    decoration: const BoxDecoration(
                      color: cyan,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: constraints.maxHeight * 0.29,
                  child: CustomPaint(
                    painter: BottomWavePainter(
                      navy: navy,
                      blue: blue,
                      cyan: cyan,
                    ),
                  ),
                ),

                SafeArea(
                  child: Column(
                    children: [
                      const Spacer(flex: 5),

                      const MedicalLogo(),

                      const SizedBox(height: 22),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: const TextSpan(
                              style: TextStyle(
                                fontSize: 40,
                                color: Color(0xFF164C78),
                                fontWeight: FontWeight.w300,
                                letterSpacing: -0.8,
                              ),
                              children: [
                                TextSpan(text: 'Smart '),
                                TextSpan(
                                  text: 'Hospital',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Queue Management System',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF31576E),
                              fontSize: 23,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 43),

                      const Text(
                        'Less waiting. More care.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF748A97),
                          fontSize: 16,
                          letterSpacing: 0.2,
                        ),
                      ),

                      const SizedBox(height: 24),

                      Container(
                        width: 36,
                        height: 3,
                        decoration: BoxDecoration(
                          color: const Color(0xFF79D1CC),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),

                      const Spacer(flex: 7),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: SizedBox(
                          width: double.infinity,
                          height: 64,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(35),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF073E68)
                                      .withValues(alpha: 0.28),
                                  blurRadius: 7,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _checkingSession || _navigating
                                  ? null
                                  : () => _openScreen('/signup'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3B91B5),
                                disabledBackgroundColor:
                                    const Color(0xFF3B91B5),
                                foregroundColor: Colors.white,
                                disabledForegroundColor: Colors.white70,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(35),
                                ),
                              ),
                              child: _checkingSession
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Get Started',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      Padding(
                        padding: const EdgeInsets.only(
                          left: 12,
                          right: 12,
                          bottom: 12,
                        ),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text(
                              'Already have an account?  ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            TextButton(
                              onPressed:
                                  _checkingSession || _navigating
                                      ? null
                                      : () => _openScreen('/login'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                disabledForegroundColor: Colors.white70,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 8,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class MedicalLogo extends StatelessWidget {
  const MedicalLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 174,
      height: 154,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ShaderMask(
            shaderCallback: (bounds) {
              return const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF35C6D0),
                  Color(0xFF078BAF),
                  Color(0xFF07528B),
                  Color(0xFF062F68),
                ],
                stops: [0.0, 0.34, 0.68, 1.0],
              ).createShader(bounds);
            },
            child: const Icon(
              Icons.favorite_rounded,
              size: 158,
              color: Colors.white,
            ),
          ),
          const Positioned(
            top: 50,
            child: Icon(
              Icons.add_rounded,
              size: 75,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class TopWavePainter extends CustomPainter {
  final Color navy;
  final Color blue;
  final Color cyan;

  TopWavePainter({
    required this.navy,
    required this.blue,
    required this.cyan,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final darkPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..cubicTo(
        size.width * 0.81,
        size.height * 0.52,
        size.width * 0.47,
        size.height * 0.83,
        0,
        size.height,
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

    final middlePath = Path()
      ..moveTo(0, size.height * 0.73)
      ..cubicTo(
        size.width * 0.30,
        size.height * 0.67,
        size.width * 0.55,
        size.height * 0.45,
        size.width * 0.74,
        0,
      )
      ..lineTo(size.width * 0.80, 0)
      ..cubicTo(
        size.width * 0.58,
        size.height * 0.55,
        size.width * 0.29,
        size.height * 0.82,
        0,
        size.height,
      )
      ..close();

    canvas.drawPath(
      middlePath,
      Paint()..color = cyan.withValues(alpha: 0.48),
    );

    final curve = Path()
      ..moveTo(0, size.height * 0.75)
      ..cubicTo(
        size.width * 0.32,
        size.height * 0.72,
        size.width * 0.46,
        size.height * 0.60,
        size.width * 0.60,
        size.height * 0.35,
      )
      ..cubicTo(
        size.width * 0.72,
        size.height * 0.13,
        size.width * 0.75,
        size.height * 0.08,
        size.width * 0.83,
        0,
      );

    canvas.drawPath(
      curve,
      Paint()
        ..color = const Color(0xFF9BF1F2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    canvas.drawCircle(
      Offset(size.width * 0.40, size.height * 0.58),
      5.5,
      Paint()..color = const Color(0xFF9BF1F2),
    );
  }

  @override
  bool shouldRepaint(covariant TopWavePainter oldDelegate) => false;
}

class BottomWavePainter extends CustomPainter {
  final Color navy;
  final Color blue;
  final Color cyan;

  BottomWavePainter({
    required this.navy,
    required this.blue,
    required this.cyan,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final darkPath = Path()
      ..moveTo(0, size.height * 0.72)
      ..cubicTo(
        size.width * 0.30,
        size.height * 0.57,
        size.width * 0.68,
        size.height * 0.12,
        size.width,
        size.height * 0.08,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      darkPath,
      Paint()..color = blue,
    );

    final upperWave = Path()
      ..moveTo(0, size.height * 0.54)
      ..cubicTo(
        size.width * 0.28,
        size.height * 0.80,
        size.width * 0.69,
        size.height * 0.12,
        size.width,
        size.height * 0.08,
      )
      ..lineTo(size.width, size.height * 0.27)
      ..cubicTo(
        size.width * 0.65,
        size.height * 0.33,
        size.width * 0.30,
        size.height * 0.94,
        0,
        size.height * 0.70,
      )
      ..close();

    canvas.drawPath(
      upperWave,
      Paint()..color = cyan.withValues(alpha: 0.48),
    );

    final curve = Path()
      ..moveTo(0, size.height * 0.54)
      ..cubicTo(
        size.width * 0.31,
        size.height * 0.88,
        size.width * 0.65,
        size.height * 0.18,
        size.width,
        size.height * 0.08,
      );

    canvas.drawPath(
      curve,
      Paint()
        ..color = const Color(0xFF9BF1F2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    canvas.drawCircle(
      Offset(size.width * 0.77, size.height * 0.25),
      5.5,
      Paint()..color = const Color(0xFF9BF1F2),
    );
  }

  @override
  bool shouldRepaint(covariant BottomWavePainter oldDelegate) => false;
}
