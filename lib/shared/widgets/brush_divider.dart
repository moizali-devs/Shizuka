import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shizuka/core/design_tokens.dart';

class BrushDivider extends StatelessWidget {
  const BrushDivider({
    super.key,
    this.widthFraction = 0.8,
    this.color = ShizukaTokens.textSecondary,
  });

  final double widthFraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 16,
      width: double.infinity,
      child: CustomPaint(
        painter: _BrushDividerPainter(
          widthFraction: widthFraction,
          color: color,
        ),
      ),
    );
  }
}

class _BrushDividerPainter extends CustomPainter {
  const _BrushDividerPainter({
    required this.widthFraction,
    required this.color,
  });

  final double widthFraction;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final lineWidth = size.width * widthFraction;
    final startX = (size.width - lineWidth) / 2;
    final midY = size.height / 2;

    final gradient = LinearGradient(
      colors: [
        Colors.transparent,
        color.withValues(alpha: 0.5),
        color.withValues(alpha: 0.5),
        Colors.transparent,
      ],
      stops: const [0, 0.15, 0.85, 1],
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(startX, 0, lineWidth, size.height),
      )
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Wavy path using quadratic beziers
    const segCount = 6;
    final segWidth = lineWidth / segCount;
    final path = Path()..moveTo(startX, midY);

    for (var i = 0; i < segCount; i++) {
      final x0 = startX + i * segWidth;
      final x1 = x0 + segWidth;
      final sign = i.isEven ? 1.0 : -1.0;
      path.quadraticBezierTo(x0 + segWidth / 2, midY + sign * 1.5, x1, midY);
    }
    canvas.drawPath(path, paint);

    // Ink speckles
    final rng = math.Random(7);
    final specklePaint = Paint()..color = color.withValues(alpha: 0.3);
    for (var i = 0; i < 2; i++) {
      final sx = startX + lineWidth * (0.3 + rng.nextDouble() * 0.4);
      final sy = midY + (rng.nextDouble() - 0.5) * 6;
      canvas.drawCircle(
        Offset(sx, sy),
        rng.nextDouble() * 1.5 + 0.5,
        specklePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_BrushDividerPainter old) =>
      old.widthFraction != widthFraction || old.color != color;
}
