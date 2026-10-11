import 'dart:math' as math;

import 'package:flutter/material.dart';

class CountRing extends StatelessWidget {
  const CountRing({
    super.key,
    required this.progress,
    required this.trackColor,
    required this.valueColor,
    required this.fillColor,
    this.size = 280,
    this.stroke = 14,
    this.child,
  });

  final double progress;
  final Color trackColor;
  final Color valueColor;
  final Color fillColor;
  final double size;
  final double stroke;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: CountRingPainter(
          progress: progress,
          trackColor: trackColor,
          valueColor: valueColor,
          fillColor: fillColor,
          stroke: stroke,
        ),
        child: Padding(
          padding: EdgeInsets.all(stroke + 10),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class CountRingPainter extends CustomPainter {
  const CountRingPainter({
    required this.progress,
    required this.trackColor,
    required this.valueColor,
    required this.fillColor,
    required this.stroke,
  });

  final double progress;
  final Color trackColor;
  final Color valueColor;
  final Color fillColor;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - stroke) / 2;
    canvas.drawCircle(
      center,
      radius - stroke * 0.2,
      Paint()..color = fillColor,
    );

    final arc = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      arc,
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt,
    );

    final clamped = progress.clamp(0.0, 1.0);
    if (clamped <= 0) return;
    canvas.drawArc(
      arc,
      -math.pi / 2,
      math.pi * 2 * clamped,
      false,
      Paint()
        ..color = valueColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(CountRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.valueColor != valueColor ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.stroke != stroke;
  }
}
