import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shizuka/core/design_tokens.dart';
import 'package:shizuka/shared/widgets/sakura_petal.dart';

class WashiBackground extends StatelessWidget {
  const WashiBackground({
    super.key,
    required this.child,
    this.showSakura = true,
  });

  final Widget child;
  final bool showSakura;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Cream base with warm radial gradient
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topCenter,
              radius: 1.4,
              colors: [Color(0xFFFFF8F0), ShizukaTokens.background],
            ),
          ),
        ),
        // Subtle grain overlay
        CustomPaint(painter: _GrainPainter()),
        // Sakura petal watermarks
        if (showSakura) ...[
          Positioned(
            right: -20,
            top: 100,
            child: Opacity(
              opacity: 0.045,
              child: Transform.rotate(
                angle: 0.3,
                child: const SakuraPetal(size: 120),
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: 220,
            child: Opacity(
              opacity: 0.04,
              child: Transform.rotate(
                angle: -0.5,
                child: const SakuraPetal(size: 90),
              ),
            ),
          ),
          Positioned(
            right: 50,
            bottom: 120,
            child: Opacity(
              opacity: 0.035,
              child: Transform.rotate(
                angle: 0.8,
                child: const SakuraPetal(size: 70),
              ),
            ),
          ),
        ],
        child,
      ],
    );
  }
}

class _GrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final paint = Paint()..color = const Color(0x05000000);
    for (var i = 0; i < 600; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
        rng.nextDouble() * 0.8 + 0.2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_GrainPainter old) => false;
}
