import 'package:flutter/material.dart';

/// Shared visual tokens. Values are intentionally small in number so every
/// screen can use the same rhythm without inventing new spacing or radii.
abstract final class TalosSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Android guidance is 48dp, iOS is 44pt. Use the larger value by default.
  static const double touchTarget = 48;
}

abstract final class TalosRadius {
  static const double chip = 8;
  static const double card = 12;
  static const double sheet = 16;
}

abstract final class TalosStatusColors {
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFB26A00);
  static const Color error = Color(0xFFC62828);
  static const Color info = Color(0xFF3F6FA8);
  static const Color waiting = Color(0xFF7A6A55);
}
