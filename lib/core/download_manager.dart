import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'background_service.dart';
import 'history_store.dart';
import 'settings_store.dart';
import 'engine/engine.dart';
import 'engine/engine_factory.dart';
import 'engine/models.dart';
import 'storage_bridge.dart';

class DownloadTask {
  DownloadTask({
    required this.id,
    required this.title,
    required this.url,
    required this.kind,
    required this.request,
  });

  final String id;
  final String title;
  final String url;
  final HistoryKind kind;
  final DownloadRequest request;

  TaskStatus status = TaskStatus.queued;
  double progress = 0;
  String stage = 'queued';
  int? downloadedBytes;
  int? totalBytes;
  double? speedBytesPerSecond;
  double? etaSeconds;
  int? playlistIndex;
  int? playlistCount;
  String? outputPath;
  String? error;
  final List<String> log = [];
}

/// Sequential download queue. One task runs at a time so engine output is
/// unambiguous and sites are not hammered with parallel requests.
class DownloadManager extends ChangeNotifier {
  DownloadManager._(this._engine, this._history, this._settings, this._outputDir);

  final TalosEngine _engine;
  final HistoryStore _history;
  final SettingsStore _settings;
  final String _outputDir;

  static Future<DownloadManager> create({TalosEngine? engine}) async {
    final settings = await SettingsStore.load();
    final outputDir = settings.value.downloadFolder?.trim().isNotEmpty == true
        ? settings.value.downloadFolder!.trim()
        : await defaultDownloadDirectory();
    // Reconcile the persisted SAF tree URI against the native side: if the
    // bridge no longer finds it (folder deleted, grant revoked), clear it so
    // downloads fall back to app-private storage instead of silently failing.
    if (Platform.isAndroid) {
      final bridgeUri = await TalosStorageBridge.treeUri();
      if ((bridgeUri ?? '').isEmpty && settings.value.downloadFolderSAF.isNotEmpty) {
        await settings.mutate(
          (s) => s.copyWith(downloadFolderSAF: ''),
        );
      }
    }
    final manager = DownloadManager._(engine ?? createEngine(), await HistoryStore.load(), settings, outputDir);
    return manager;
  }

  SettingsStore get settings => _settings;
  HistoryStore get history => _history;
  TalosEngine get engine => _engine;
  String get outputDirectory => _settings.value.downloadFolder?.trim().isNotEmpty == true
      ? _settings.value.downloadFolder!.trim()
      : _outputDir;

  final List<DownloadTask> _tasks = [];
  TalosDownloadSession? _activeSession;
  bool _pumping = false;

  List<DownloadTask> get tasks => List.unmodifiable(_tasks);
  List<DownloadTask> get activeTasks =>
      _tasks.where((t) => t.status == TaskStatus.running || t.status == TaskStatus.queued).toList();
  List<DownloadTask> get finishedTasks =>
      _tasks.where((t) => t.status != TaskStatus.running && t.status != TaskStatus.queued).toList();

  Future<void> enqueue(DownloadRequest request, {required String title, required HistoryKind kind}) async {
    final task = DownloadTask(
      id: DateTime.now().microsecondsSinceEpoch.toRadixString(16),
      title: title,
      url: request.url,
      kind: kind,
      request: request,
    );
    _tasks.insert(0, task);
    notifyListeners();
    unawaited(_pump());
  }

  Future<void> cancel(DownloadTask task) async {
    if (task.status == TaskStatus.queued) {
      task.status = TaskStatus.cancelled;
      notifyListeners();
      return;
    }
    await _activeSession?.cancel();
  }

  Future<void> retry(DownloadTask task) async {
    final configured = task.request.videoMode
        ? _settings.value.videoFolder
        : _settings.value.audioFolder;
    final outputDir = configured?.trim().isNotEmpty == true ? configured!.trim() : outputDirectory;
    final rebuilt = DownloadRequest(
      url: task.request.url,
      videoMode: task.request.videoMode,
      outputDir: outputDir,
      maxHeight: task.request.maxHeight,
      audioFormat: task.request.audioFormat,
      audioBitrate: task.request.audioBitrate,
      embedSubtitles: task.request.embedSubtitles,
      embedMetadata: task.request.embedMetadata,
      filenameTemplate: task.request.filenameTemplate,
      proxy: task.request.proxy,
      rateLimit: task.request.rateLimit,
      useAria2: task.request.useAria2,
      concurrentFragments: task.request.concurrentFragments,
      playlistItems: task.request.playlistItems,
      includePlaylist: task.request.includePlaylist,
      ffmpegPath: task.request.ffmpegPath,
      sponsorBlockCategories: task.request.sponsorBlockCategories,
      cookiesPath: task.request.cookiesPath,
      subtitleLanguage: task.request.subtitleLanguage,
      formatSelector: task.request.formatSelector,
      restrictFilenames: task.request.restrictFilenames,
      downloadArchive: task.request.downloadArchive,
      cropArtwork: task.request.cropArtwork,
      subtitleFormat: task.request.subtitleFormat,
      clipStartSeconds: task.request.clipStartSeconds,
      clipEndSeconds: task.request.clipEndSeconds,
      forceIpv4: task.request.forceIpv4,
      remuxContainer: task.request.remuxContainer,
      maxFilesize: task.request.maxFilesize,
      userAgent: task.request.userAgent,
      formatSort: task.request.formatSort,
      downloadSubtitles: task.request.downloadSubtitles,
      autoSubtitle: task.request.autoSubtitle,
      keepSubtitles: task.request.keepSubtitles,
    );
    _tasks.remove(task);
    await enqueue(rebuilt, title: task.title, kind: task.kind);
  }

  void removeTask(DownloadTask task) {
    if (task.status == TaskStatus.running || task.status == TaskStatus.queued) return;
    _tasks.remove(task);
    notifyListeners();
  }

  void clearFinished() {
    _tasks.removeWhere((t) => t.status != TaskStatus.running && t.status != TaskStatus.queued);
    notifyListeners();
  }

  Future<void> _pump() async {
    if (_pumping) return;
    _pumping = true;
    try {
      while (true) {
        DownloadTask? next;
        for (final task in _tasks.reversed) {
          if (task.status == TaskStatus.queued) next = task;
        }
        if (next == null) break;
        await _run(next);
      }
    } finally {
      _pumping = false;
    }
  }

  Future<void> _run(DownloadTask task) async {
    task.status = TaskStatus.running;
    task.stage = 'starting';
    notifyListeners();

    if (_settings.value.downloadNotification) {
      await requestTalosNotificationPermission();
      await ensureForegroundService(text: task.title);
    }

    try {
      final dir = Directory(task.request.outputDir);
      if (!dir.existsSync()) dir.createSync(recursive: true);
    } catch (_) {
      // Output directory may not be creatable (e.g. user picked a read-only path).
    }

    final configuredFfmpeg = _settings.value.ffmpegPath.trim();
    final ffmpegAvailable = await _ffmpegAvailable(configuredFfmpeg);

    final session = _engine.download(
      task.request,
      ffmpegAvailable: ffmpegAvailable,
    );
    _activeSession = session;
    final rawSubscription = session.rawLog?.listen((line) {
      if (task.log.length < 500) task.log.add(line);
    });
    final subscription = session.events.listen((event) {
      if (event.error != null) {
        task.error = event.error;
        return;
      }
      if (event.fraction != null) task.progress = event.fraction!.clamp(0, 1);
      if (event.stage != null) task.stage = event.stage!;
      if (event.downloadedBytes != null) task.downloadedBytes = event.downloadedBytes;
      if (event.totalBytes != null) task.totalBytes = event.totalBytes;
      if (event.speedBytesPerSecond != null) task.speedBytesPerSecond = event.speedBytesPerSecond;
      if (event.etaSeconds != null) task.etaSeconds = event.etaSeconds;
      if (event.playlistIndex != null) task.playlistIndex = event.playlistIndex;
      if (event.playlistCount != null) task.playlistCount = event.playlistCount;
      if (event.outputPath != null) task.outputPath = event.outputPath;
      notifyListeners();
    });

    final outcome = await session.outcome;
    await subscription.cancel();
    await rawSubscription?.cancel();
    _activeSession = null;

    if (outcome.error == null) {
      task.outputPath = outcome.outputPath ?? task.outputPath;

      // When the user picked a SAF folder in Settings, copy the resulting
      // file there. If the copy fails, treat the task as failed so the user
      // sees it instead of finding a hidden file in private storage.
      final saf = _settings.value.downloadFolderSAF.trim();
      if (Platform.isAndroid && saf.isNotEmpty && (task.outputPath?.isNotEmpty ?? false)) {
        final localPath = task.outputPath!;
        final displayName = localPath.split(Platform.pathSeparator).last;
        final uri = await TalosStorageBridge.copyToTree(localPath, displayName);
        if (uri != null) {
          try {
            await File(localPath).delete();
          } catch (_) {
            // Best effort; the file stays behind in the app sandbox.
          }
          task.outputPath = uri;
        } else {
          task.status = TaskStatus.failed;
          task.error = 'Talos folder is not writable in the selected storage. Re-pick the folder in Settings > Downloads, or clear it to use app private storage.';
          notifyListeners();
          await _maybeStopForeground();
          return;
        }
      }

      final size = await _fileSize(task.outputPath);
      if (!_settings.value.privateMode) {
        await _history.add(HistoryEntry(
          id: task.id,
          title: task.title,
          url: task.url,
          filePath: task.outputPath ?? '',
          kind: task.kind,
          dateMs: DateTime.now().millisecondsSinceEpoch,
          sizeBytes: size,
        ));
      }
      // Completed work moves to the Finished tab via history.
      _tasks.remove(task);
    } else if (outcome.error == 'cancelled') {
      task.status = TaskStatus.cancelled;
    } else {
      task.status = TaskStatus.failed;
      task.error = outcome.error;
    }
    notifyListeners();
    await _maybeStopForeground();
  }

  Future<void> _maybeStopForeground() async {
    final busy = _tasks.any((t) =>
        t.status == TaskStatus.running || t.status == TaskStatus.queued);
    if (!busy) await stopForegroundService();
  }

  @visibleForTesting
  static Future<bool> Function(String configured)? ffmpegProbeOverride;

  Future<bool> _ffmpegAvailable(String configured) async {
    final override = ffmpegProbeOverride;
    if (override != null) return override(configured);
    if (configured.isNotEmpty) return File(configured).existsSync();
    if (Platform.isAndroid || Platform.isIOS) return false;
    try {
      final probe = Platform.isWindows ? 'where.exe' : 'which';
      final result = await Process.run(probe, ['ffmpeg']);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  Future<int?> _fileSize(String? path) async {
    if (path == null || path.isEmpty) return null;
    try {
      final file = File(path);
      if (await file.exists()) return await file.length();
    } catch (_) {
      // Size is nice to have, not critical.
    }
    return null;
  }
}
