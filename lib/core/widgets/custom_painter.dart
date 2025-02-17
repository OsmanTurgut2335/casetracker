
import 'dart:math';

import 'package:flutter/material.dart';

class MyCustomPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.grey[400]!
      ..style = PaintingStyle.fill;

    final double radius = size.width / 1.5;

    canvas.drawArc(
      Rect.fromCircle(center: const Offset(0, 0), radius: radius),
      pi / 2,
      -pi / 2,
      true,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
