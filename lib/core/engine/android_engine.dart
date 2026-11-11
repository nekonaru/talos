import 'dart:async';

import 'package:flutter/services.dart';

import 'command_builder.dart';
import 'engine.dart';
import 'models.dart';
import 'progress_parser.dart';

/// Runs yt-dlp inside the Android app through Chaquopy.
///
/// Raw yt-dlp output lines are forwarded over an EventChannel and parsed
/// here with the same parser used for desktop subprocesses.
class AndroidEngine implements TalosEngine {
  AndroidEngine() {
    _events = const EventChannel('id.nekonaru.talos/engine/events')
        .receiveBroadcastStream()
        .map((event) => Map<String, dynamic>.from(event as Map))
        .asBroadcastStream();
  }

  static const _method = MethodChannel('id.nekonaru.talos/engine');
  late final Stream<Map<String, dynamic>> _events;

  @override
  Future<EngineStatus> status() async {
    try {
      final raw = await _method.invokeMethod<Map>('status');
      final map = raw?.cast<String, dynamic>() ?? {};
      return EngineStatus(
        ready: map['ready'] == true,
        version: map['version'] as String?,
        ffmpegPath: null,
        managed: true,
      );
    } on PlatformException {
      return EngineStatus(ready: false, version: null, ffmpegPath: null, managed: true);
    }
  }

  @override
  Future<void> ensureReady({void Function(String phase, double fraction)? onPhase, bool force = false, String channel = 'stable'}) async {
    onPhase?.call('verify', 1);
    await _method.invokeMethod<bool>('setup');
  }

  @override
  Future<MediaProbe> probe(String url, {String proxy = ''}) async {
    final raw = await _method.invokeMethod<String>('probe', {'url': url, 'proxy': proxy});
    if (raw == null || raw.isEmpty) {
      throw const FormatException('Engine returned no data');
    }
    return parseProbeJson(raw);
  }

  @override
  TalosDownloadSession download(DownloadRequest request, {required bool ffmpegAvailable}) {
    // The embedded Android runtime merges separate streams with the bundled
    // FFmpegKit instead of a spawnable ffmpeg binary.
    final args = CommandBuilder.downloadArgs(request, ffmpegAvailable: false);
    final session = _AndroidDownloadSession(this, args, merge: !ffmpegAvailable && request.videoMode);
    session.start();
    return session;
  }

  @override
  Stream<String> runCustomCommand(String template, String url, {String? workingDir}) async* {
    final output = await _method.invokeMethod<String>('custom', {'template': template, 'url': url});
    yield output ?? '';
  }
}

class _AndroidDownloadSession implements TalosDownloadSession {
  _AndroidDownloadSession(this._engine, this._args, {this._merge = false}) {
    _taskId = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
  }

  final AndroidEngine _engine;
  final List<String> _args;
  final bool _merge;
  late final String _taskId;

  final _controller = StreamController<EngineProgress>.broadcast();
  final _rawController = StreamController<String>.broadcast();
  final _outcomeCompleter = Completer<SessionOutcome>();
  StreamSubscription<Map<String, dynamic>>? _subscription;
  String? _lastOutputPath;
  String? _lastError;

  @override
  Stream<EngineProgress> get events => _controller.stream;

  @override
  Future<SessionOutcome> get outcome => _outcomeCompleter.future;

  @override
  Stream<String>? get rawLog => _rawController.stream;

  Future<void> start() async {
    _subscription = _engine._events.listen(_handleEvent);
    try {
      await AndroidEngine._method.invokeMethod<void>('start', {
        'taskId': _taskId,
        'args': _args,
        'merge': _merge,
      });
    } on PlatformException catch (e) {
      _finish(SessionOutcome(error: e.message ?? 'Engine failed to start'));
    }
  }

  void _handleEvent(Map<String, dynamic> event) {
    if (event['taskId'] != _taskId) return;
    switch (event['event'] as String?) {
      case 'line':
        final rawLine = event['line'] as String?;
        if (rawLine == null) break;
        if (_rawController.hasListener) _rawController.add(rawLine);
        final parsed = parseYtdlpLine(rawLine);
        if (parsed == null) break;
        if (parsed.outputPath != null) _lastOutputPath = parsed.outputPath;
        if (parsed.error != null) _lastError = parsed.error;
        _controller.add(parsed);
      case 'done':
        _finish(SessionOutcome(outputPath: _lastOutputPath));
      case 'error':
        final message = (event['message'] as String?) ?? _lastError ?? 'Download failed';
        _finish(SessionOutcome(error: message, outputPath: _lastOutputPath));
      case 'cancelled':
        _finish(SessionOutcome(error: 'cancelled', outputPath: _lastOutputPath));
    }
  }

  void _finish(SessionOutcome outcome) {
    _subscription?.cancel();
    if (!_controller.isClosed) _controller.close();
    if (!_rawController.isClosed) _rawController.close();
    if (!_outcomeCompleter.isCompleted) _outcomeCompleter.complete(outcome);
  }

  @override
  Future<void> cancel() async {
    await AndroidEngine._method.invokeMethod<void>('cancel', {'taskId': _taskId});
  }
}
