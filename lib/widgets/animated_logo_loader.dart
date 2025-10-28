import 'package:a2abrokerapp/constants.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedLogoLoader extends StatefulWidget {
  final double size;
  final String assetPath; // e.g. "assets/collabrix_logo.png"

  const AnimatedLogoLoader({
    super.key,
    required this.assetPath,
    this.size = 110,
  });

  @override
  State<AnimatedLogoLoader> createState() => _AnimatedLogoLoaderState();
}

class _AnimatedLogoLoaderState extends State<AnimatedLogoLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: widget.size,
        width: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 🔹 Rotating thin grey ring
            AnimatedBuilder(
              animation: _controller,
              builder: (_, __) {
                return Transform.rotate(
                  angle: _controller.value * 2 * math.pi,
                  child: CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: _ThinRotatingRingPainter(),
                  ),
                );
              },
            ),

            // 🔹 Elevated circular logo
            Container(
              height: widget.size * 0.68,
              width: widget.size * 0.68,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: kPrimaryColor.withOpacity(0.25),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.hardEdge,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Image.asset(
                  widget.assetPath,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 🎨 Painter for thin, elegant rotating ring
class _ThinRotatingRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = SweepGradient(
        colors: [
          kPrimaryColor.withOpacity(0.3),
          kPrimaryColor.withOpacity(0.5),
          kPrimaryColor.withOpacity(0.4),
          kPrimaryColor.withOpacity(0.3)
        ],
        stops: const [0.0, 0.4, 0.7, 1.0],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2),
        radius: size.width / 2,
      ))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: size.width / 2.2,
    );

    // Draw ¾ ring instead of full circle for subtle movement
    canvas.drawArc(rect, 0, math.pi * 1.6, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
