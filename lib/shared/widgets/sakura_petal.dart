import 'package:flutter/material.dart';
import 'package:shizuka/core/design_tokens.dart';

class SakuraPetal extends StatelessWidget {
  const SakuraPetal({
    super.key,
    this.size = 80,
    this.color = ShizukaTokens.primary,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size * 0.55, size),
      painter: _SakuraPetalPainter(color: color),
    );
  }
}

class _SakuraPetalPainter extends CustomPainter {
  const _SakuraPetalPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(w / 2, 0)
      ..cubicTo(w * 0.95, h * 0.1, w, h * 0.6, w / 2, h)
      ..cubicTo(0, h * 0.6, w * 0.05, h * 0.1, w / 2, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SakuraPetalPainter old) => old.color != color;
}
