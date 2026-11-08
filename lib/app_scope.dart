import 'package:flutter/material.dart';

import 'core/download_manager.dart';

/// Inherited access to the shared download manager.
class TalosScope extends InheritedNotifier<DownloadManager> {
  const TalosScope({super.key, required DownloadManager manager, required super.child})
      : super(notifier: manager);

  static DownloadManager of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<TalosScope>();
    assert(scope != null, 'TalosScope is missing in the widget tree');
    return scope!.notifier!;
  }

  /// Non-listening access for one-off reads, safe in initState and callbacks.
  static DownloadManager read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<TalosScope>();
    assert(scope != null, 'TalosScope is missing in the widget tree');
    return scope!.notifier!;
  }
}
