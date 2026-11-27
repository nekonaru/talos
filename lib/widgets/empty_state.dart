import 'package:flutter/material.dart';

import '../core/design_tokens.dart';
import '../core/motion.dart';

/// Consistent empty state with one clear next action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: '$title. $message',
      child: AnimatedOpacity(
        opacity: 1,
        duration: motionEnabled(context) ? TalosMotion.standard : Duration.zero,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(TalosSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 48, color: theme.colorScheme.primary),
                const SizedBox(height: TalosSpacing.lg),
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: TalosSpacing.sm),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: TalosSpacing.lg),
                  FilledButton.tonal(
                    onPressed: onAction,
                    child: Text(actionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
