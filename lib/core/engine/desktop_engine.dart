import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'command_builder.dart';
import 'engine.dart';
import 'models.dart';
import 'progress_parser.dart';

/// Runs yt-dlp as an external process on desktop platforms.
///
/// The engine binary is either detected on PATH or managed by the app:
/// downloaded once into the support directory and reused afterwards.
class DesktopEngine implements TalosEngine {
  static const _managedName = 'yt-dlp';

  Future<Directory> get _binDir async {
    final support = await getApplicationSupportDirectory();
    final dir = Directory('${support.path}${Platform.pathSeparator}bin');
    await dir.create(recursive: true);
    return dir;
  }

  Future<String?> _managedYtdlpPath() async {
    final dir = await _binDir;
    final name = Platform.isWindows ? '$_managedName.exe' : _managedName;
    final candidate = File('${dir.path}${Platform.pathSeparator}$name');
    return candidate.existsSync() ? candidate.path : null;
  }

  Future<String?> _onPath(String binary) async {
    try {
      final probe = Platform.isWindows ? 'where.exe' : 'which';
      final result = await Process.run(probe, [binary]);
      if (result.exitCode == 0) {
        final first = result.stdout.toString().split(RegExp(r'\r?\n')).first.trim();
        if (first.isNotEmpty && File(first).existsSync()) return first;
      }
    } catch (_) {
      // Binary lookup is best effort.
    }
    return null;
  }

  Future<String?> ytdlpPath() async => (await _managedYtdlpPath()) ?? (await _onPath(_managedName));

  Future<String?> ffmpegPath(String configured) async {
    if (configured.trim().isNotEmpty && File(configured.trim()).existsSync()) {
      return configured.trim();
    }
    return _onPath('ffmpeg');
  }

  Future<String?> _versionOf(String binary) async {
    try {
      final result = await Process.run(binary, ['--version'])
          .timeout(const Duration(seconds: 20));
      if (result.exitCode == 0) {
        final out = result.stdout.toString().trim();
        if (out.isNotEmpty) return out;
      }
    } catch (_) {
      // Not runnable.
    }
    return null;
  }

  @override
  Future<EngineStatus> status() async {
    final ytdlp = await ytdlpPath();
    final version = ytdlp == null ? null : await _versionOf(ytdlp);
    final ffmpeg = await ffmpegPath('');
    return EngineStatus(
      ready: version != null,
      version: version,
      ffmpegPath: ffmpeg,
      managed: ytdlp != null && ytdlp.contains('${Platform.pathSeparator}bin${Platform.pathSeparator}'),
    );
  }

  /// Fetches a small text resource, failing hard when unavailable.
  Future<String> _fetchString(String url) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      request.headers.set('user-agent', 'Talos/0.1');
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('Download failed with status ${response.statusCode}', uri: Uri.parse(url));
      }
      final sink = StringBuffer();
      await response.transform(utf8.decoder).forEach(sink.write);
      return sink.toString();
    } finally {
      client.close();
    }
  }

  /// Finds the expected sha256 for [asset] in a SHA2-256SUMS body.
  static String? expectedHashFor(String sumsBody, String asset) {
    for (final rawLine in sumsBody.split(RegExp(r'\r?\n'))) {
      final parts = rawLine.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2 && parts.last == asset) {
        return parts.first.toLowerCase();
      }
    }
    return null;
  }

  /// Downloads [asset] from the latest GitHub release and verifies its SHA-256
  /// against the release checksums file. Fails closed on any mismatch.
  Future<void> _downloadVerified(String asset, File target, void Function(double fraction)? onPhase) async {
    final sums = await _fetchString('https://github.com/yt-dlp/yt-dlp/releases/latest/download/SHA2-256SUMS');
    final expected = expectedHashFor(sums, asset);
    if (expected == null) {
      throw StateError('Checksum for $asset not found in SHA2-256SUMS');
    }

    final client = HttpClient();
    try {
      final url = 'https://github.com/yt-dlp/yt-dlp/releases/latest/download/$asset';
      final request = await client.getUrl(Uri.parse(url));
      request.headers.set('user-agent', 'Talos/0.1');
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('Download failed with status ${response.statusCode}', uri: Uri.parse(url));
      }
      final total = response.contentLength;
      var received = 0;
      final builder = BytesBuilder(copy: false);
      await for (final chunk in response) {
        builder.add(chunk);
        received += chunk.length;
        if (total > 0) onPhase?.call(received / total);
      }
      final bytes = builder.takeBytes();
      final digest = sha256.convert(bytes).toString();
      if (digest != expected) {
        throw StateError('Checksum mismatch for $asset');
      }
      await target.writeAsBytes(bytes);
    } finally {
      client.close();
    }
  }

  @override
  Future<void> ensureReady({void Function(String phase, double fraction)? onPhase, bool force = false}) async {
    if (!force) {
      final path = await ytdlpPath();
      if (path != null && await _versionOf(path) != null) {
        return;
      }
    }
    final dir = await _binDir;
    final asset = switch (defaultTargetPlatform) {
      TargetPlatform.windows => 'yt-dlp.exe',
      TargetPlatform.macOS => 'yt-dlp_macos',
      _ => 'yt-dlp',
    };
    final target = File('${dir.path}${Platform.pathSeparator}${Platform.isWindows ? 'yt-dlp.exe' : 'yt-dlp'}');

    onPhase?.call('download', 0);
    await _downloadVerified(asset, target, (fraction) => onPhase?.call('download', fraction));

    if (!Platform.isWindows) {
      await Process.run('chmod', ['+x', target.path]);
    }
    onPhase?.call('verify', 1);
    final version = await _versionOf(target.path);
    if (version == null) {
      await target.delete().catchError((_) => target);
      throw const FileSystemException('Downloaded engine failed to start');
    }
  }

  @override
  Future<MediaProbe> probe(String url, {String proxy = ''}) async {
    final binary = await ytdlpPath();
    if (binary == null) {
      throw const FileSystemException('yt-dlp is not available');
    }
    final args = CommandBuilder.probeArgs(url, proxy: proxy.isEmpty ? null : proxy);
    final result = await Process.run(binary, args)
        .timeout(const Duration(seconds: 120));
    if (result.exitCode != 0) {
      final stderr = result.stderr.toString().trim();
      throw StateError(stderr.isNotEmpty ? stderr : 'yt-dlp exited with code ${result.exitCode}');
    }
    return parseProbeJson(result.stdout.toString());
  }

  @override
  TalosDownloadSession download(DownloadRequest request, {required bool ffmpegAvailable}) {
    return _DesktopDownloadSession(this, request, ffmpegAvailable: ffmpegAvailable);
  }

  @override
  Stream<String> runCustomCommand(String template, String url, {String? workingDir}) async* {
    final binary = await ytdlpPath();
    if (binary == null) {
      yield 'yt-dlp is not available. Set it up from Settings first.';
      return;
    }
    final args = CommandBuilder.customCommandArgs(template, url);
    if (args.isEmpty) {
      yield 'The command template is empty.';
      return;
    }
    final process = await Process.start(binary, args, workingDirectory: workingDir);
    final stdout = process.stdout.transform(utf8.decoder).transform(const LineSplitter());
    final stderr = process.stderr.transform(utf8.decoder).transform(const LineSplitter());
    yield* StreamGroup.merge([stdout, stderr]);
  }
}

class _DesktopDownloadSession implements TalosDownloadSession {
  _DesktopDownloadSession(this._engine, this._request, {required this.ffmpegAvailable}) {
    _start();
  }

  final DesktopEngine _engine;
  final DownloadRequest _request;
  final bool ffmpegAvailable;

  final _controller = StreamController<EngineProgress>.broadcast();
  final _outcomeCompleter = Completer<SessionOutcome>();
  Process? _process;
  bool _cancelled = false;
  String? _lastOutputPath;
  final _stderrTail = <String>[];

  @override
  Stream<EngineProgress> get events => _controller.stream;

  @override
  Future<SessionOutcome> get outcome => _outcomeCompleter.future;

  Future<void> _start() async {
    final binary = await _engine.ytdlpPath();
    if (binary == null) {
      _finish(SessionOutcome(error: 'yt-dlp is not available'));
      return;
    }
    final args = CommandBuilder.downloadArgs(_request, ffmpegAvailable: ffmpegAvailable);
    try {
      _process = await Process.start(binary, args);
    } catch (error) {
      _finish(SessionOutcome(error: 'Failed to start yt-dlp: $error'));
      return;
    }

    _process!.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(_handleLine);
    _process!.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      _stderrTail.add(line);
      if (_stderrTail.length > 30) _stderrTail.removeAt(0);
    });

    final code = await _process!.exitCode;
    if (_cancelled) {
      _finish(SessionOutcome(error: 'cancelled', outputPath: _lastOutputPath));
    } else if (code == 0) {
      _finish(SessionOutcome(outputPath: _lastOutputPath));
    } else {
      final detail = _stderrTail.isNotEmpty ? _stderrTail.last : 'yt-dlp exited with code $code';
      _finish(SessionOutcome(error: detail, outputPath: _lastOutputPath));
    }
  }

  void _handleLine(String line) {
    final parsed = parseYtdlpLine(line);
    if (parsed == null) return;
    if (parsed.outputPath != null) _lastOutputPath = parsed.outputPath;
    if (!_controller.isClosed) _controller.add(parsed);
  }

  void _finish(SessionOutcome outcome) {
    if (!_controller.isClosed) _controller.close();
    if (!_outcomeCompleter.isCompleted) _outcomeCompleter.complete(outcome);
  }

  @override
  Future<void> cancel() async {
    _cancelled = true;
    _process?.kill();
  }
}

/// Minimal stream merge to avoid an extra dependency for log output.
class StreamGroup {
  static Stream<String> merge(List<Stream<String>> streams) async* {
    final controller = StreamController<String>();
    var open = streams.length;
    for (final stream in streams) {
      stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: () {
          open--;
          if (open == 0) controller.close();
        },
      );
    }
    yield* controller.stream;
  }
}
