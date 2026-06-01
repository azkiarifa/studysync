import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ProgressPainter extends CustomPainter {
  final double progress; // Value from 0.0 to 1.0
  final Color trackColor;
  final List<Color> progressColors;
  final double strokeWidth;

  ProgressPainter({
    required this.progress,
    this.trackColor = const Color(0xFFE2E8F0),
    this.progressColors = const [AppColors.primary, AppColors.secondary],
    this.strokeWidth = 12.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - (strokeWidth / 2);

    // Draw background track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Draw active progress
    if (progress > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      final activePaint = Paint()
        ..shader = SweepGradient(
          colors: progressColors,
          startAngle: -pi / 2,
          endAngle: 3 * pi / 2,
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      // Rotate canvas to start drawing arc from the top (-pi/2)
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(-pi / 2);
      canvas.translate(-center.dx, -center.dy);
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        0.0,
        2 * pi * progress,
        false,
        activePaint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant ProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColors != progressColors ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
