import 'package:flutter/material.dart';

import 'core/download_manager.dart';

/// Inherited access to the shared download manager.
///
/// Rebuilds dependents when the manager, the settings store, or the
/// history store changes, so screens that read `settings.value` or
/// `history.entries` during build always reflect the latest values.
class TalosScope extends InheritedNotifier<Listenable> {
  TalosScope({super.key, required DownloadManager manager, required super.child})
      : _manager = manager,
        super(notifier: Listenable.merge([manager, manager.settings, manager.history]));

  final DownloadManager _manager;

  static DownloadManager of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<TalosScope>();
    assert(scope != null, 'TalosScope is missing in the widget tree');
    return scope!._manager;
  }

  /// Non-listening access for one-off reads, safe in initState and callbacks.
  static DownloadManager read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<TalosScope>();
    assert(scope != null, 'TalosScope is missing in the widget tree');
    return scope!._manager;
  }
}
