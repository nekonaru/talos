import 'package:flutter/material.dart';

/// Motion constants for Talos. Personality: Premium with a Corporate base.
/// Reduced motion is honored everywhere through [motionEnabled].
abstract final class TalosMotion {
  static const Duration feedback = Duration(milliseconds: 120);
  static const Duration standard = Duration(milliseconds: 220);
  static const Duration sheet = Duration(milliseconds: 320);
  static const Duration staggerStep = Duration(milliseconds: 40);
  static const int maxStaggerItems = 10;

  static const Curve standardCurve = Curves.easeOutCubic;
  static const Curve enterCurve = Curves.easeOut;
  static const Curve exitCurve = Curves.easeIn;
  static const Curve sheetCurve = Curves.easeOutCubic;
}

bool motionEnabled(BuildContext context) {
  final media = MediaQuery.maybeOf(context);
  return media == null || !media.disableAnimations;
}

Duration staggerDelay(BuildContext context, int index) {
  if (!motionEnabled(context)) return Duration.zero;
  final capped = index < TalosMotion.maxStaggerItems
      ? index
      : TalosMotion.maxStaggerItems - 1;
  return TalosMotion.staggerStep * capped;
}
