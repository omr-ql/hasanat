import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:hasanat/models/count_history.dart';
import 'package:hasanat/theme/app_theme.dart';

class DualLineChart extends StatelessWidget {
  const DualLineChart({
    super.key,
    required this.buckets,
    required this.axisMax,
  });

  final List<ChartBucket> buckets;
  final int axisMax;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        height: 220,
        width: double.infinity,
        child: CustomPaint(
          painter: _DualLinePainter(
            buckets: buckets,
            axisMax: axisMax,
            ink: palette.ink,
            blue: palette.blue,
            muted: palette.muted,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _DualLinePainter extends CustomPainter {
  const _DualLinePainter({
    required this.buckets,
    required this.axisMax,
    required this.ink,
    required this.blue,
    required this.muted,
  });

  final List<ChartBucket> buckets;
  final int axisMax;
  final Color ink;
  final Color blue;
  final Color muted;

  @override
  void paint(Canvas canvas, Size size) {
    const gutterLeft = 36.0;
    const gutterBottom = 22.0;
    const gutterTop = 8.0;
    const gutterRight = 4.0;
    final plot = Rect.fromLTRB(
      gutterLeft,
      gutterTop,
      math.max(gutterLeft + 1, size.width - gutterRight),
      math.max(gutterTop + 1, size.height - gutterBottom),
    );

    for (var step = 0; step <= 4; step++) {
      final value = axisMax * (4 - step) ~/ 4;
      final y = plot.top + plot.height * step / 4;
      _paintLabel(
        canvas,
        formatAxisTick(value),
        Offset(0, y - 7),
        32,
        muted,
        const TextStyle(fontFamily: 'Jakarta', fontSize: 11, height: 1),
        TextAlign.right,
      );
    }

    if (buckets.isEmpty) return;

    final current = <Offset>[];
    final previous = <Offset>[];
    for (var index = 0; index < buckets.length; index++) {
      final x = buckets.length == 1
          ? plot.center.dx
          : plot.left + plot.width * index / (buckets.length - 1);
      current.add(_point(plot, x, buckets[index].current));
      previous.add(_point(plot, x, buckets[index].previous));
    }

    _stroke(canvas, previous, blue, 2.2);
    _stroke(canvas, current, ink, 2.6);

    var lastLabel = -48.0;
    for (var index = 0; index < buckets.length; index++) {
      final label = buckets[index].label;
      if (label.isEmpty) continue;
      final x = current[index].dx;
      if (x - lastLabel < 36) continue;
      lastLabel = x;
      _paintAxisLabel(
        canvas,
        label,
        x,
        plot,
        muted,
      );
    }
  }

  Offset _point(Rect plot, double x, int value) {
    final max = axisMax <= 0 ? 1 : axisMax;
    final t = (value / max).clamp(0, 1).toDouble();
    return Offset(x, plot.bottom - plot.height * t);
  }

  void _stroke(Canvas canvas, List<Offset> points, Color color, double width) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    if (points.length == 1) {
      canvas.drawCircle(points.first, width, paint..style = PaintingStyle.fill);
      return;
    }
    final path = Path()..addPolygon(_smooth(points), false);
    canvas.drawPath(path, paint);
  }

  List<Offset> _smooth(List<Offset> points) {
    if (points.length < 3) return points;
    final sampled = <Offset>[points.first];
    for (var index = 0; index < points.length - 1; index++) {
      final p0 = points[index == 0 ? index : index - 1];
      final p1 = points[index];
      final p2 = points[index + 1];
      final p3 = points[index + 2 < points.length ? index + 2 : index + 1];
      for (var step = 1; step <= 12; step++) {
        sampled.add(_catmull(p0, p1, p2, p3, step / 12));
      }
    }
    return sampled;
  }

  Offset _catmull(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
    final t2 = t * t;
    final t3 = t2 * t;
    final y =
        0.5 *
        ((2 * p1.dy) +
            (-p0.dy + p2.dy) * t +
            (2 * p0.dy - 5 * p1.dy + 4 * p2.dy - p3.dy) * t2 +
            (-p0.dy + 3 * p1.dy - 3 * p2.dy + p3.dy) * t3);
    final x =
        0.5 *
        ((2 * p1.dx) +
            (-p0.dx + p2.dx) * t +
            (2 * p0.dx - 5 * p1.dx + 4 * p2.dx - p3.dx) * t2 +
            (-p0.dx + 3 * p1.dx - 3 * p2.dx + p3.dx) * t3);
    final low = math.min(p1.dy, p2.dy);
    final high = math.max(p1.dy, p2.dy);
    return Offset(x, y.clamp(low, high));
  }

  void _paintAxisLabel(
    Canvas canvas,
    String text,
    double x,
    Rect plot,
    Color color,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontFamilyFallback: const ['Jakarta'],
          fontSize: 11,
          height: 1,
          color: color,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
      maxLines: 1,
    )..layout();
    var dx = x - painter.width / 2;
    if (dx < plot.left) dx = plot.left;
    if (dx + painter.width > plot.right) dx = plot.right - painter.width;
    painter.paint(canvas, Offset(dx, plot.bottom + 6));
  }

  void _paintLabel(
    Canvas canvas,
    String text,
    Offset offset,
    double width,
    Color color,
    TextStyle style,
    TextAlign align,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style.copyWith(color: color)),
      textDirection: ui.TextDirection.ltr,
      textAlign: align,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: width);
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(_DualLinePainter oldDelegate) {
    if (oldDelegate.axisMax != axisMax ||
        oldDelegate.ink != ink ||
        oldDelegate.blue != blue ||
        oldDelegate.buckets.length != buckets.length) {
      return true;
    }
    for (var index = 0; index < buckets.length; index++) {
      final next = buckets[index];
      final previous = oldDelegate.buckets[index];
      if (next.current != previous.current ||
          next.previous != previous.previous ||
          next.label != previous.label) {
        return true;
      }
    }
    return false;
  }
}
