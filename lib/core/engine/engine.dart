import 'dart:async';

import 'models.dart';

/// Outcome of a finished download session.
class SessionOutcome {
  SessionOutcome({this.outputPath, this.error});
  final String? outputPath;
  final String? error;
  bool get success => error == null;
}

/// A running download, streaming progress events.
abstract class TalosDownloadSession {
  Stream<EngineProgress> get events;

  /// Completes when the underlying process or task exits.
  Future<SessionOutcome> get outcome;

  /// Raw log lines from the engine, if available. Not all engines provide this.
  Stream<String>? get rawLog;

  Future<void> cancel();
}

/// Abstract download engine. Desktop uses a local yt-dlp process, Android
/// runs yt-dlp inside the app through Chaquopy.
abstract class TalosEngine {
  Future<EngineStatus> status();

  /// Downloads or repairs the managed engine if needed. [force] re-downloads
  /// even when a working engine is already present (desktop only).
  /// [channel] picks the yt-dlp release channel: `stable` or `nightly`.
  Future<void> ensureReady({void Function(String phase, double fraction)? onPhase, bool force = false, String channel = 'stable'});

  Future<MediaProbe> probe(String url, {String proxy = ''});

  TalosDownloadSession download(DownloadRequest request, {required bool ffmpegAvailable});

  /// Runs a user template and yields raw log lines.
  Stream<String> runCustomCommand(String template, String url, {String? workingDir});
}
