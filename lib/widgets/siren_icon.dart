import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Custom vector Siren icon precisely matching the user's reference design:
/// - Rounded pill base
/// - Upright dome siren housing
/// - Inner reflection gloss arc
/// - 7 radiating light burst rays (0°, 30°, 60°, 90°, 120°, 150°, 180°)
class SirenIcon extends StatelessWidget {
  final Color color;
  final double size;
  final double? strokeWidth;

  const SirenIcon({
    super.key,
    required this.color,
    this.size = 28.0,
    this.strokeWidth,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SirenPainter(
          color: color,
          strokeWidth: strokeWidth ?? (size * 0.082).clamp(1.5, 4.5),
        ),
      ),
    );
  }
}

class _SirenPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  const _SirenPainter({
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // 1. Base pill (rounded rectangle)
    final baseRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.22, h * 0.76, w * 0.78, h * 0.86),
      Radius.circular(w * 0.05),
    );
    canvas.drawRRect(baseRect, paint);

    // 2. Siren Dome
    final domePath = Path()
      ..moveTo(w * 0.31, h * 0.76)
      ..lineTo(w * 0.31, h * 0.52)
      ..arcToPoint(
        Offset(w * 0.69, h * 0.52),
        radius: Radius.circular(w * 0.19),
        clockwise: true,
      )
      ..lineTo(w * 0.69, h * 0.76);
    canvas.drawPath(domePath, paint);

    // 3. Inner reflection gloss arc
    final glossPath = Path()
      ..moveTo(w * 0.51, h * 0.40)
      ..arcToPoint(
        Offset(w * 0.63, h * 0.54),
        radius: Radius.circular(w * 0.13),
        clockwise: true,
      );
    canvas.drawPath(glossPath, paint);

    // 4. 7 Radiating Light Rays (0°, 30°, 60°, 90°, 120°, 150°, 180°)
    final cx = w * 0.50;
    final cy = h * 0.52;
    final rInner = w * 0.29;
    final rOuter = w * 0.41;

    for (int i = 0; i <= 6; i++) {
      final angle = (i * 30.0) * math.pi / 180.0;
      final x1 = cx + rInner * math.cos(angle);
      final y1 = cy - rInner * math.sin(angle); // negative y goes upwards
      final x2 = cx + rOuter * math.cos(angle);
      final y2 = cy - rOuter * math.sin(angle);
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SirenPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}
