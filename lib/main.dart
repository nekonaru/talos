import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'core/background_service.dart';
import 'core/download_manager.dart';
import 'core/storage_bridge.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initForegroundTask();
  final manager = await DownloadManager.create();
  unawaited(_maybeAutoUpdateEngine(manager));
  unawaited(_promptFirstLaunchPermissions());
  runApp(TalosApp(manager: manager));
}

/// Ask for the permissions Talos needs right away on a fresh install:
/// POST_NOTIFICATIONS on Android 13+ and WRITE_EXTERNAL_STORAGE on
/// Android 7-9. A no-op on every later launch and off Android.
Future<void> _promptFirstLaunchPermissions() async {
  if (!Platform.isAndroid) return;
  try {
    await TalosStorageBridge.requestFirstLaunchPermissions();
  } catch (_) {
    // Best effort; notifications and downloads work either way.
  }
}

/// Quietly checks for a managed engine update when the user opted in.
/// Never blocks startup, never shows anything on failure.
Future<void> _maybeAutoUpdateEngine(DownloadManager manager) async {
  if (!manager.settings.value.autoUpdateEngine) return;
  try {
    final support = await getApplicationSupportDirectory();
    final marker = File('${support.path}${Platform.pathSeparator}engine_update_check');
    final now = DateTime.now().millisecondsSinceEpoch;
    if (await marker.exists()) {
      final last = int.tryParse((await marker.readAsString()).trim()) ?? 0;
      const week = Duration(days: 7);
      if (week.inMilliseconds > now - last) return;
    }
    await manager.engine.ensureReady(force: true, channel: manager.settings.value.engineChannel);
    await marker.writeAsString(now.toString());
  } catch (_) {
    // Auto update is best effort.
  }
}
