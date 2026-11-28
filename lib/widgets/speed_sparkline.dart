import 'package:flutter/material.dart';

import '../core/format.dart';

/// Tiny historical speed chart for a running task. Uses CustomPaint so it adds
/// no dependency and stays cheap even with frequent progress updates.
class SpeedSparkline extends StatelessWidget {
  const SpeedSparkline({super.key, required this.samples});

  final List<double> samples;

  @override
  Widget build(BuildContext context) {
    if (samples.length < 2) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final max = samples.reduce((a, b) => a > b ? a : b);
    if (max <= 0) return const SizedBox.shrink();
    return Semantics(
      label: formatSpeed(samples.last),
      child: SizedBox(
        width: 64,
        height: 20,
        child: CustomPaint(
          painter: _SparkPainter(
            values: samples,
            max: max,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter({required this.values, required this.max, required this.color});

  final List<double> values;
  final double max;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path();
    final step = size.width / (values.length - 1);
    for (var i = 0; i < values.length; i++) {
      final x = step * i;
      final y = size.height - (values[i] / max) * (size.height - 2) - 1;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SparkPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.max != max;
}
