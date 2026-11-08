import 'package:flutter/material.dart';

import 'app.dart';
import 'core/background_service.dart';
import 'core/download_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initForegroundTask();
  final manager = await DownloadManager.create();
  runApp(TalosApp(manager: manager));
}
