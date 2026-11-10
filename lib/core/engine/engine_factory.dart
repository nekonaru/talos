import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'android_engine.dart';
import 'desktop_engine.dart';
import 'engine.dart';
import 'models.dart';

TalosEngine createEngine() {
  if (defaultTargetPlatform == TargetPlatform.android) {
    return AndroidEngine();
  }
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return const UnsupportedEngine();
  }
  return DesktopEngine();
}

/// Reports the engine as unavailable instead of crashing startup.
/// iOS has no subprocess or Chaquopy path yet.
class UnsupportedEngine implements TalosEngine {
  const UnsupportedEngine();

  static const _message = 'The download engine is not yet available on iOS';

  @override
  Future<EngineStatus> status() async =>
      EngineStatus(ready: false, version: null, ffmpegPath: null, managed: false);

  @override
  Future<void> ensureReady({
    void Function(String phase, double fraction)? onPhase,
    bool force = false,
    String channel = 'stable',
  }) async =>
      throw UnsupportedError(_message);

  @override
  Future<MediaProbe> probe(String url, {String proxy = ''}) async => throw UnsupportedError(_message);

  @override
  TalosDownloadSession download(DownloadRequest request, {required bool ffmpegAvailable}) =>
      _UnsupportedSession();

  @override
  Stream<String> runCustomCommand(String template, String url, {String? workingDir}) async* {
    yield _message;
  }
}

class _UnsupportedSession implements TalosDownloadSession {
  static const _message = 'The download engine is not yet available on iOS';

  @override
  Stream<EngineProgress> get events => const Stream.empty();

  @override
  Future<SessionOutcome> get outcome async => SessionOutcome(error: _message);

  @override
  Stream<String>? get rawLog => null;

  @override
  Future<void> cancel() async {}
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
