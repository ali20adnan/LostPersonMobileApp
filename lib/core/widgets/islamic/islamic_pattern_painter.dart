import 'dart:math';
import 'package:flutter/material.dart';

/// Draws a repeating 8-pointed star geometric Islamic pattern.
/// Used as a subtle background overlay on screens and cards.
class IslamicPatternPainter extends CustomPainter {
  final Color color;
  final double cellSize;

  IslamicPatternPainter({
    required this.color,
    this.cellSize = 60,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final cols = (size.width / cellSize).ceil() + 1;
    final rows = (size.height / cellSize).ceil() + 1;

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final cx = col * cellSize;
        final cy = row * cellSize;
        _drawEightPointStar(canvas, Offset(cx, cy), cellSize * 0.35, paint);
      }
    }
  }

  void _drawEightPointStar(
      Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    const points = 8;
    final innerRadius = radius * 0.45;

    for (int i = 0; i < points * 2; i++) {
      final angle = (i * pi / points) - pi / 2;
      final r = i.isEven ? radius : innerRadius;
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant IslamicPatternPainter old) =>
      old.color != color || old.cellSize != cellSize;
}

/// A widget that renders a subtle Islamic geometric pattern overlay.
class IslamicPatternOverlay extends StatelessWidget {
  final Color? color;
  final double opacity;
  final double cellSize;
  final Widget? child;

  const IslamicPatternOverlay({
    super.key,
    this.color,
    this.opacity = 0.05,
    this.cellSize = 60,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final patternColor = color ??
        (isDark ? Colors.white.withValues(alpha: opacity) : Colors.black.withValues(alpha: opacity));

    return CustomPaint(
      painter: IslamicPatternPainter(
        color: patternColor,
        cellSize: cellSize,
      ),
      child: child,
    );
  }
}
