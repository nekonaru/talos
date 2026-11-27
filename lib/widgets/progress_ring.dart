import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/motion.dart';

/// Small circular progress indicator with a percentage label. Used on task
/// cards where a full-width bar would compete with the title and actions.
class ProgressRing extends StatelessWidget {
  const ProgressRing({super.key, required this.value, this.size = 40});

  final double value;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clamped = value.clamp(0.0, 1.0);
    final percent = (clamped * 100).round();
    return Semantics(
      label: '$percent%',
      child: SizedBox(
        width: size,
        height: size,
        child: AnimatedSwitcher(
          duration: motionEnabled(context) ? TalosMotion.feedback : Duration.zero,
          child: Stack(
            key: ValueKey(percent),
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size.square(size),
                painter: _RingPainter(
                  fraction: clamped,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  foregroundColor: theme.colorScheme.primary,
                ),
              ),
              Text(
                '$percent%',
                style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.fraction,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final double fraction;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.12;
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: (size.width - stroke) / 2,
    );
    final background = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final foreground = Paint()
      ..color = foregroundColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke;
    canvas.drawCircle(rect.center, rect.width / 2, background);
    if (fraction <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * fraction,
      false,
      foreground,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.fraction != fraction ||
      oldDelegate.backgroundColor != backgroundColor ||
      oldDelegate.foregroundColor != foregroundColor;
}
