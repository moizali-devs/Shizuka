import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shizuka/core/design_tokens.dart';

class EnsoCircle extends StatelessWidget {
  const EnsoCircle({
    super.key,
    this.size = 120,
    this.color = ShizukaTokens.textSecondary,
    this.strokeWidth = 6.0,
  });

  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _EnsoPainter(color: color, strokeWidth: strokeWidth),
      ),
    );
  }
}

class _EnsoPainter extends CustomPainter {
  const _EnsoPainter({required this.color, required this.strokeWidth});

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = (size.width - strokeWidth) / 2;

    const startAngle = math.pi * 0.6; // ~108° — lower-left
    const sweepAngle = math.pi * 1.7; // ~306° sweep, open gap at top

    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);

    final gradient = SweepGradient(
      startAngle: startAngle,
      endAngle: startAngle + sweepAngle,
      colors: [
        color.withValues(alpha: 0.0),
        color.withValues(alpha: 0.8),
        color,
        color.withValues(alpha: 0.45),
      ],
      stops: const [0, 0.08, 0.5, 1],
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(_EnsoPainter old) =>
      old.color != color || old.strokeWidth != strokeWidth;
}
