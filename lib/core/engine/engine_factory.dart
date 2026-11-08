import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'android_engine.dart';
import 'desktop_engine.dart';
import 'engine.dart';

TalosEngine createEngine() {
  if (defaultTargetPlatform == TargetPlatform.android) {
    return AndroidEngine();
  }
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    throw UnsupportedError('The download engine is not implemented on iOS yet');
  }
  return DesktopEngine();
}

/// Picks a writable default output directory. Android apps can only write
/// inside their own sandbox by default; desktop prefers the system downloads folder.
Future<String> defaultDownloadDirectory() async {
  if (defaultTargetPlatform == TargetPlatform.android) {
    final documents = await getApplicationDocumentsDirectory();
    return '${documents.path}${Platform.pathSeparator}Talos';
  }
  try {
    final downloads = await getDownloadsDirectory();
    if (downloads != null) return downloads.path;
  } catch (_) {
    // Fall through to the app-scoped fallback.
  }
  final documents = await getApplicationDocumentsDirectory();
  return '${documents.path}${Platform.pathSeparator}Talos';
}
