import 'dart:async';
import 'package:flutter/material.dart';

class IntroSplashScreen extends StatefulWidget {
  const IntroSplashScreen({super.key});

  @override
  State<IntroSplashScreen> createState() => _IntroSplashScreenState();
}

class _IntroSplashScreenState extends State<IntroSplashScreen>
    with SingleTickerProviderStateMixin {
  static const Color navy = Color(0xFF0B477A);
  static const Color blue = Color(0xFF247BA3);
  static const Color cyan = Color(0xFF32B8C5);

  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _scale = Tween<double>(
      begin: 0.78,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _controller.forward();

    _timer = Timer(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/get-started');
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
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
                  child: Center(
                    child: FadeTransition(
                      opacity: _fade,
                      child: ScaleTransition(
                        scale: _scale,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Spacer(flex: 5),
                            const MedicalLogo(),
                            const SizedBox(height: 22),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text.rich(
                                  TextSpan(
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
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 40,
                                    color: Color(0xFF164C78),
                                    fontWeight: FontWeight.w300,
                                    letterSpacing: -0.8,
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
                            const SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(blue),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Preparing your care experience',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF31576E),
                                fontSize: 13,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const Spacer(flex: 2),
                          ],
                        ),
                      ),
                    ),
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
