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
    // The public Downloads folder is the default on Android: API 28 and
    // older writes it directly; API 29+ copies through MediaStore after
    // the download. SAF or a custom path overrides either.
    final androidSdkInt = await TalosStorageBridge.androidSdkInt();
    final outputDir = settings.value.downloadFolder?.trim().isNotEmpty == true
        ? settings.value.downloadFolder!.trim()
        : await defaultDownloadDirectory(androidSdkInt: androidSdkInt);
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
      outputFilename: task.request.outputFilename,
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

    // Resolve a unique output filename before download. Every non-playlist
    // download must always run: when the target name already exists, Talos
    // writes "name(1).ext", "name(2).ext" and so on. The user asked for
    // unlimited repeats of the same video without any hidden deduplication.
    final effectiveRequest = (() {
      final typed = task.request.outputFilename?.trim();
      try {
        final dir = Directory(task.request.outputDir);
        if (typed != null && typed.isNotEmpty) {
          final unique = _uniqueFilename(dir, typed);
          if (unique == typed) return task.request;
          return task.request.copyWith(outputFilename: unique);
        }
        if (task.request.includePlaylist) return task.request;
        final base = _uniqueOutputTemplate(dir, _sanitizeFilenameComponent(task.title));
        return task.request.copyWith(outputFilename: '$base.%(ext)s');
      } catch (_) {
        // existsSync can fail on unusual paths (for example SAF content
        // URIs); fall back to the requested name unchanged.
        return task.request;
      }
    })();

    try {
      final dir = Directory(effectiveRequest.outputDir);
      if (!dir.existsSync()) dir.createSync(recursive: true);
    } catch (_) {
      // Output directory may not be creatable (e.g. user picked a read-only path).
    }

    final configuredFfmpeg = _settings.value.ffmpegPath.trim();
    final ffmpegAvailable = await _ffmpegAvailable(configuredFfmpeg);

    final session = _engine.download(
      effectiveRequest,
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

      // On Android, when the user picked a SAF folder, or nothing at all
      // (public Downloads/Talos is the default), copy the finished file
      // there. A failed copy fails the task instead of hiding the file in
      // private storage.
      final saf = _settings.value.downloadFolderSAF.trim();
      final plainSet = _settings.value.downloadFolder?.trim().isNotEmpty ?? false;
      final localPath = task.outputPath ?? '';
      int? deletedSize;
      if (Platform.isAndroid && localPath.isNotEmpty && !localPath.startsWith('content://')) {
        final displayName = localPath.split(Platform.pathSeparator).last;
        final localSize = await _fileSize(localPath);
        final directWrite = _outputDir == '/storage/emulated/0/Download/Talos';
        String? saved;
        if (saf.isNotEmpty) {
          saved = await TalosStorageBridge.copyToTree(localPath, displayName);
        } else if (!plainSet && !directWrite) {
          saved = await TalosStorageBridge.saveToDownloads(localPath, displayName);
        } else {
          saved = localPath; // Custom plain path or API 24-28 direct write.
        }
        if (saved == null) {
          task.status = TaskStatus.failed;
          task.error = saf.isNotEmpty
              ? 'The Talos folder is not writable in the selected storage. Re-pick the folder in Settings > Downloads, or clear it to go back to Downloads (default).'
              : 'Talos could not save the file into Downloads/Talos. Check that storage and notification access are granted, or pick a different folder in Settings > Downloads.';
          notifyListeners();
          await _maybeStopForeground();
          return;
        }
        if (saved != localPath) {
          try {
            await File(localPath).delete();
          } catch (_) {
            // Best effort; the file stays behind in the app sandbox.
          }
          task.outputPath = saved;
          deletedSize = localSize;
        }
      }

      final size = deletedSize ?? await _fileSize(task.outputPath);
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

  static String _uniqueFilename(Directory dir, String name) {
    final sep = dir.path.endsWith(Platform.pathSeparator) ? '' : Platform.pathSeparator;
    if (!File('${dir.path}$sep$name').existsSync()) return name;
    final dot = name.lastIndexOf('.');
    final base = dot >= 0 ? name.substring(0, dot) : name;
    final ext = dot >= 0 ? name.substring(dot) : '';
    for (var i = 1; i < 10000; i++) {
      final candidate = '$base($i)$ext';
      if (!File('${dir.path}$sep$candidate').existsSync()) return candidate;
    }
    return name;
  }

  /// Make a raw title safe for a file name, loosely matching yt-dlp's rules:
  /// path-unsafe characters become underscores, control characters go, the
  /// result is trimmed and length-capped.
  static String _sanitizeFilenameComponent(String title) {
    var s = title
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'[\x00-\x1f]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    // yt-dlp avoids trailing dots and spaces on Windows.
    while (s.endsWith('.') || s.endsWith(' ')) {
      s = s.substring(0, s.length - 1);
    }
    if (s.isEmpty) s = 'video';
    if (s.length > 120) s = s.substring(0, 120).trimRight();
    return s;
  }

  /// Find a base name that no file uses: "Title", "Title(1)", "Title(2)",
  /// "Title(3)" and so on. Any file with a matching prefix counts, whatever
  /// the extension.
  static String _uniqueOutputTemplate(Directory dir, String base) {
    if (!dir.existsSync()) return base;
    final taken = dir
        .listSync(followLinks: false)
        .whereType<File>()
        .map((f) => f.uri.pathSegments.isNotEmpty ? f.uri.pathSegments.last : f.path.split(Platform.pathSeparator).last)
        .toSet();
    bool used(String candidate) => taken.any((name) => name.startsWith('$candidate.'));
    if (!used(base)) return base;
    for (var i = 1; i < 10000; i++) {
      final candidate = '$base($i)';
      if (!used(candidate)) return candidate;
    }
    return base;
  }

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
