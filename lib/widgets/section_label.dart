import 'package:flutter/material.dart';

/// Section heading used above settings and forms. Same look everywhere.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.bodySmall?.copyWith(letterSpacing: 2.4),
      ),
    );
  }
}
