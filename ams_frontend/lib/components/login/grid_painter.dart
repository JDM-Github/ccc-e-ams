import 'package:flutter/material.dart';

class GridPainter extends CustomPainter {
  final Brightness brightness;

  const GridPainter({this.brightness = Brightness.dark});

  @override
  void paint(Canvas canvas, Size size) {
    final isDark = brightness == Brightness.dark;

    final gridPaint = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.04) : const Color(0xFF1B3769).withOpacity(0.05)
      ..strokeWidth = 1;

    const spacing = 48.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Diagonal accent lines — blue tint both modes, opacity varies
    final accentPaint = Paint()
      ..color = const Color(0xFF2563EB).withOpacity(isDark ? 0.08 : 0.04)
      ..strokeWidth = 1;

    for (double i = -size.height; i < size.width; i += 80) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), accentPaint);
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) => oldDelegate.brightness != brightness;
}
