import 'package:flutter/material.dart';
import 'dart:math' as math;

class WavePainter extends CustomPainter {
  final double progress;
  final bool activo;

  WavePainter(this.progress, this.activo);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final width = size.width;
    final midHeight = size.height / 2;

    path.moveTo(0, midHeight);

    if (activo) {
      for (double i = 0; i <= width; i++) {
        final y = midHeight + math.sin((i / width * 2 * math.pi * 3) + (progress * 2 * math.pi)) * 10;
        path.lineTo(i, y);
      }
    } else {
      path.lineTo(width, midHeight);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.activo != activo;
}