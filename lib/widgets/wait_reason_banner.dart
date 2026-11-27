import 'package:flutter/material.dart';

import '../core/design_tokens.dart';

/// Explains why the queue is not starting new downloads.
class WaitReasonBanner extends StatelessWidget {
  const WaitReasonBanner({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: message,
      child: Card(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            TalosSpacing.md,
            TalosSpacing.md,
            TalosSpacing.sm,
            TalosSpacing.md,
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: theme.colorScheme.primary),
              const SizedBox(width: TalosSpacing.md),
              Expanded(
                child: Text(message, style: theme.textTheme.bodySmall),
              ),
              if (actionLabel != null && onAction != null)
                TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ),
        ),
      ),
    );
  }
}
