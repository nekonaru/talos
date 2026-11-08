import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Thin wrapper over the Android foreground service.
/// Used to keep downloads running while the app is in the background.
/// No-ops on other platforms.

@pragma('vm:entry-point')
void talosForegroundCallback() {
  FlutterForegroundTask.setTaskHandler(_TalosTaskHandler());
}

class _TalosTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}

void initForegroundTask() {
  if (!Platform.isAndroid) return;
  FlutterForegroundTask.initCommunicationPort();
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'talos_downloads',
      channelName: 'Talos',
      channelDescription: 'Keeps downloads running while you use other apps',
      onlyAlertOnce: true,
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: false,
      playSound: false,
    ),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.repeat(1000),
      autoRunOnBoot: false,
      allowWakeLock: true,
      allowWifiLock: true,
    ),
  );
}

Future<void> requestTalosNotificationPermission() async {
  if (!Platform.isAndroid) return;
  final permission = await FlutterForegroundTask.checkNotificationPermission();
  if (permission != NotificationPermission.granted) {
    await FlutterForegroundTask.requestNotificationPermission();
  }
}

Future<void> ensureForegroundService({required String text}) async {
  if (!Platform.isAndroid) return;
  final running = await FlutterForegroundTask.isRunningService;
  if (running) {
    await FlutterForegroundTask.updateService(
      notificationTitle: 'Talos',
      notificationText: text,
    );
    return;
  }
  try {
    await FlutterForegroundTask.startService(
      serviceId: 256,
      notificationTitle: 'Talos',
      notificationText: text,
      callback: talosForegroundCallback,
    );
  } catch (_) {
    // A download must never fail because the service could not start.
  }
}

Future<void> stopForegroundService() async {
  if (!Platform.isAndroid) return;
  try {
    await FlutterForegroundTask.stopService();
  } catch (_) {
    // Stopping is best effort.
  }
}
