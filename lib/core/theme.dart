import 'package:flutter/material.dart';

/// Warm bronze-on-shadow palette for Talos.
///
/// The identity is built from the bronze giant of Crete: a dark, warm
/// background, a single bronze accent, and type that leans inscriptional
/// for headings and plain for body text.
class TalosPalette {
  const TalosPalette({
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.ink,
    required this.inkMuted,
    required this.accent,
    required this.accentDeep,
    required this.outline,
  });

  final Color background;
  final Color surface;
  final Color surfaceRaised;
  final Color ink;
  final Color inkMuted;
  final Color accent;
  final Color accentDeep;
  final Color outline;

  static const TalosPalette dark = TalosPalette(
    background: Color(0xFF161311),
    surface: Color(0xFF1E1A17),
    surfaceRaised: Color(0xFF28231F),
    ink: Color(0xFFEDE6DA),
    inkMuted: Color(0xFFA79C8E),
    accent: Color(0xFFD09A5B),
    accentDeep: Color(0xFF8A5A2B),
    outline: Color(0xFF3A342E),
  );

  static const TalosPalette light = TalosPalette(
    background: Color(0xFFF5F1E8),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFECE7DB),
    ink: Color(0xFF241F1A),
    inkMuted: Color(0xFF6F665B),
    accent: Color(0xFF9C6B30),
    accentDeep: Color(0xFF6E4A1F),
    outline: Color(0xFFD8D2C4),
  );
}

/// Selectable accent hues. Persisted by name in settings.
enum TalosAccent {
  bronze(Color(0xFFD09A5B), Color(0xFF8A5A2B)),
  laurel(Color(0xFF7A9B57), Color(0xFF4C6131)),
  aegean(Color(0xFF5E8FB9), Color(0xFF2F4E6B)),
  oxblood(Color(0xFFA85454), Color(0xFF6B2C2C)),
  marble(Color(0xFFB9B3A4), Color(0xFF6E675A));

  const TalosAccent(this.dark, this.deep);
  final Color dark;
  final Color deep;
}

class TalosTheme {
  const TalosTheme._();

  static ThemeData build({
    required Brightness brightness,
    required TalosAccent accent,
  }) {
    final palette = brightness == Brightness.dark ? TalosPalette.dark : TalosPalette.light;
    final base = ThemeData(brightness: brightness, useMaterial3: true);
    final accentMain = brightness == Brightness.dark ? accent.dark : accent.deep;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: accentMain,
      brightness: brightness,
      primary: accentMain,
      surface: palette.surface,
    );

    final textTheme = brightness == Brightness.dark
        ? buildTextTheme(TalosPalette.dark.ink, TalosPalette.dark.inkMuted)
        : buildTextTheme(TalosPalette.light.ink, TalosPalette.light.inkMuted);

    return base.copyWith(
      colorScheme: colorScheme.copyWith(
        surface: palette.surface,
        onSurface: palette.ink,
        surfaceContainerHighest: palette.surfaceRaised,
        outlineVariant: palette.outline,
      ),
      scaffoldBackgroundColor: palette.background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        foregroundColor: palette.ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: palette.surface,
        indicatorColor: accentMain.withValues(alpha: 0.22),
        iconTheme: WidgetStatePropertyAll(IconThemeData(color: palette.inkMuted)),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontFamily: 'Inter', fontSize: 12, color: palette.inkMuted),
        ),
      ),
      navigationRailTheme: const NavigationRailThemeData(),
      cardTheme: CardThemeData(
        color: palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: palette.outline),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(color: palette.outline, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surfaceRaised,
        hintStyle: TextStyle(color: palette.inkMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accentMain, width: 1.6),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: palette.surfaceRaised,
        side: BorderSide(color: palette.outline),
        labelStyle: TextStyle(color: palette.ink),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.surfaceRaised,
        contentTextStyle: TextStyle(color: palette.ink),
        behavior: SnackBarBehavior.floating,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: palette.inkMuted,
        textColor: palette.ink,
      ),
    );
  }

  static TextTheme buildTextTheme(Color ink, Color muted) {
    return TextTheme(
      displaySmall: TextStyle(fontFamily: 'Marcellus', fontSize: 34, color: ink, height: 1.15),
      headlineMedium: TextStyle(fontFamily: 'Marcellus', fontSize: 26, color: ink),
      titleLarge: TextStyle(fontFamily: 'Marcellus', fontSize: 20, color: ink),
      titleMedium: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600, color: ink),
      bodyLarge: TextStyle(fontFamily: 'Inter', fontSize: 16, color: ink),
      bodyMedium: TextStyle(fontFamily: 'Inter', fontSize: 14, color: ink),
      bodySmall: TextStyle(fontFamily: 'Inter', fontSize: 12, color: muted),
      labelLarge: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: ink),
    );
  }
}
