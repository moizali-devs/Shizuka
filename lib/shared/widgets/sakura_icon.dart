import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shizuka/core/design_tokens.dart';

class SakuraIcon extends StatelessWidget {
  const SakuraIcon({
    super.key,
    this.size = 48,
    this.color = ShizukaTokens.primary,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _SakuraIconPainter(color: color)),
    );
  }
}

class _SakuraIconPainter extends CustomPainter {
  const _SakuraIconPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final petalLength = size.width * 0.38;
    final petalWidth = size.width * 0.20;
    final petalOffset = size.width * 0.22;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (var i = 0; i < 5; i++) {
      final angle = i * 2 * math.pi / 5 - math.pi / 2;
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(angle);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(0, -petalOffset),
          width: petalWidth * 2,
          height: petalLength * 2,
        ),
        paint,
      );
      canvas.restore();
    }

    // Center dot
    canvas.drawCircle(
      Offset(cx, cy),
      size.width * 0.1,
      paint..color = ShizukaTokens.primaryDark,
    );
  }

  @override
  bool shouldRepaint(_SakuraIconPainter old) => old.color != color;
}
