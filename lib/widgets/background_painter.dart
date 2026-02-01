import 'package:flutter/material.dart';

/// Gaming-themed background painter extracted from the login screen
class BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Dark black background base
    final backgroundPaint = Paint()
      ..color = const Color(0xFF000000)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      backgroundPaint,
    );

    // Gaming neon grid pattern
    final gridPaint = Paint()
      ..color = const Color(0xFF00FFFF).withOpacity(0.03)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (int i = 0; i <= 20; i++) {
      final x = size.width * (i / 20);
      final y = size.height * (i / 20);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Gaming circuit board pattern
    final circuitPaint = Paint()
      ..color = const Color(0xFF00FF00).withOpacity(0.04)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final circuitPath = Path();
    circuitPath.moveTo(size.width * 0.1, size.height * 0.2);
    circuitPath.lineTo(size.width * 0.3, size.height * 0.2);
    circuitPath.lineTo(size.width * 0.3, size.height * 0.4);
    circuitPath.lineTo(size.width * 0.7, size.height * 0.4);
    circuitPath.lineTo(size.width * 0.7, size.height * 0.6);
    circuitPath.lineTo(size.width * 0.9, size.height * 0.6);
    canvas.drawPath(circuitPath, circuitPaint);

    // Gaming energy orbs with neon glow
    final orbPaint1 = Paint()
      ..color = const Color(0xFFFF0080).withOpacity(0.06)
      ..style = PaintingStyle.fill;
    final orbPaint2 = Paint()
      ..color = const Color(0xFF8000FF).withOpacity(0.05)
      ..style = PaintingStyle.fill;
    final orbPaint3 = Paint()
      ..color = const Color(0xFFFF8000).withOpacity(0.04)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
        Offset(size.width * 0.2, size.height * 0.2), 50, orbPaint1);
    canvas.drawCircle(
        Offset(size.width * 0.8, size.height * 0.7), 70, orbPaint2);
    canvas.drawCircle(
        Offset(size.width * 0.1, size.height * 0.8), 40, orbPaint3);
    canvas.drawCircle(
        Offset(size.width * 0.9, size.height * 0.1), 60, orbPaint1);

    // Gaming data streams
    final streamPaint = Paint()
      ..color = const Color(0xFF00FFFF).withOpacity(0.02)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 8; i++) {
      final x = size.width * (0.1 + i * 0.1);
      final height = size.height * (0.3 + (i % 3) * 0.2);
      canvas.drawLine(Offset(x, 0), Offset(x, height), streamPaint);
    }

    // Gaming power nodes
    final nodePaint = Paint()
      ..color = const Color(0xFFFF0000).withOpacity(0.08)
      ..style = PaintingStyle.fill;
    for (int i = 1; i < 5; i++) {
      for (int j = 1; j < 5; j++) {
        final x = size.width * (i / 5);
        final y = size.height * (j / 5);
        canvas.drawCircle(Offset(x, y), 8, nodePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
