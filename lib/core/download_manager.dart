import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'background_service.dart';
import 'history_store.dart';
import 'preset_store.dart';
import 'quiet_hours.dart';
import 'queue_store.dart';
import 'saved_link_store.dart';
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
    this.thumbnailUrl,
  });

  final String id;
  final String title;
  final String url;
  final HistoryKind kind;
  final DownloadRequest request;
  final String? thumbnailUrl;

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

  /// All files reported by the engine. A playlist merge produces one output
  /// per entry, so saving only [outputPath] would orphan the other items.
  final List<String> outputPaths = [];
  String? error;
  final List<String> log = [];

  /// Set when the user cancels while the task is running but before an engine
  /// session exists yet. [_run] checks this before starting the download so a
  /// tap on Cancel during the setup window is never silently ignored.
  bool cancelRequested = false;

  /// Number of automatic retries already used by the queue. A manual Retry
  /// creates a fresh task, so this always starts at zero.
  int attempts = 0;
}

/// Error codes resolved to localized text by the UI. Kept as constants so a
/// failed task stores a stable code rather than a hardcoded English message.
const String kErrSafNotWritable = 'talos.err.safNotWritable';
const String kErrSaveToDownloads = 'talos.err.saveToDownloads';

/// Sequential download queue. One task runs at a time so engine output is
/// unambiguous and sites are not hammered with parallel requests.
class DownloadManager extends ChangeNotifier {
  DownloadManager._(this._engine, this._history, this._settings, this._outputDir, this.savedLinks, this.presets);

  final TalosEngine _engine;
  final HistoryStore _history;
  final SettingsStore _settings;
  String _outputDir;

  /// Shared so Home, Configure and Reset all see one source of truth.
  final SavedLinkStore savedLinks;
  final PresetStore presets;

  static Future<DownloadManager> create({TalosEngine? engine, bool restoreQueue = false}) async {
    // Start all independent loads at once. Each store reads a JSON file and
    // resolves the support directory; awaiting them sequentially delayed the
    // first frame by the sum of those round trips.
    final settingsFuture = SettingsStore.load();
    final historyFuture = HistoryStore.load();
    final savedFuture = SavedLinkStore.load();
    final presetFuture = PresetStore.load();
    final sdkFuture = TalosStorageBridge.androidSdkInt();
    final treeFuture = Platform.isAndroid
        ? TalosStorageBridge.treeUri()
        : Future<String?>.value(null);

    final settings = await settingsFuture;
    final androidSdkInt = await sdkFuture;
    // The public Downloads folder is the default on Android: API 28 and
    // older writes it directly; API 29+ copies through MediaStore after
    // the download. SAF or a custom path overrides either.
    final outputDir = settings.value.downloadFolder?.trim().isNotEmpty == true
        ? settings.value.downloadFolder!.trim()
        : await defaultDownloadDirectory(androidSdkInt: androidSdkInt);
    // Reconcile the persisted SAF tree URI against the native side: if the
    // bridge no longer finds it (folder deleted, grant revoked), clear it so
    // downloads fall back to app-private storage instead of silently failing.
    if (Platform.isAndroid) {
      try {
        final bridgeUri = await treeFuture;
        if ((bridgeUri ?? '').isEmpty && settings.value.downloadFolderSAF.isNotEmpty) {
          await settings.mutate(
            (s) => s.copyWith(downloadFolderSAF: ''),
          );
        }
      } catch (_) {
        // A transient channel error must not discard the user's folder choice.
      }
    }
    final history = await historyFuture;
    final retention = settings.value.historyRetentionDays;
    if (retention > 0) {
      final cutoff = DateTime.now()
          .subtract(Duration(days: retention))
          .millisecondsSinceEpoch;
      await history.pruneBefore(cutoff);
    }
    final manager = DownloadManager._(
      engine ?? createEngine(),
      history,
      settings,
      outputDir,
      await savedFuture,
      await presetFuture,
    );
    if (restoreQueue) {
      for (final saved in await QueueStore.load()) {
        manager._tasks.add(DownloadTask(
          id: saved.id,
          title: saved.title,
          url: saved.url,
          kind: saved.kind,
          request: saved.request,
          thumbnailUrl: saved.thumbnailUrl,
        )..attempts = saved.attempts);
      }
      if (manager._tasks.isNotEmpty) unawaited(manager._pump());
    }
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
  int _resetGeneration = 0;
  DateTime? _lastProgressNotify;
  Timer? _progressNotifyTimer;
  Timer? _wifiRetryTimer;
  Timer? _quietRetryTimer;
  Timer? _batteryRetryTimer;

  List<DownloadTask> get tasks => List.unmodifiable(_tasks);
  List<DownloadTask> get activeTasks =>
      _tasks.where((t) => t.status == TaskStatus.running || t.status == TaskStatus.queued).toList();
  List<DownloadTask> get finishedTasks =>
      _tasks.where((t) => t.status != TaskStatus.running && t.status != TaskStatus.queued).toList();

  Future<void> enqueue(DownloadRequest request, {required String title, required HistoryKind kind, String? thumbnailUrl}) async {
    final task = DownloadTask(
      id: DateTime.now().microsecondsSinceEpoch.toRadixString(16),
      title: title,
      url: request.url,
      kind: kind,
      request: request,
      thumbnailUrl: thumbnailUrl,
    );
    _tasks.add(task);
    notifyListeners();
    unawaited(_persistQueue());
    unawaited(_pump());
  }

  Future<void> cancel(DownloadTask task) async {
    if (task.status == TaskStatus.queued) {
      task.status = TaskStatus.cancelled;
      notifyListeners();
      await _persistQueue();
      // Cancelling the last queued task can leave no work for the pump, so
      // stop the foreground service here as well.
      await _maybeStopForeground();
      return;
    }
    // Only a running task maps to the active session. Cancelling a failed,
    // cancelled or completed task must not kill an unrelated download.
    if (task.status != TaskStatus.running) return;
    // Record the intent immediately. The session may be null during setup or
    // already cleared during post-processing, so the flag is the reliable
    // signal in both windows.
    task.cancelRequested = true;
    if (_activeSession == null) {
      // No live process to stop; finalize synchronously so the UI reflects it
      // and no history row is written later.
      task.status = TaskStatus.cancelled;
      notifyListeners();
    }
    await _activeSession?.cancel();
  }

  Future<void> retry(DownloadTask task) async {
    final configured = task.request.videoMode
        ? _settings.value.videoFolder
        : _settings.value.audioFolder;
    final outputDir = configured?.trim().isNotEmpty == true ? configured!.trim() : outputDirectory;
    // Copying from the stored request keeps every field, so future options
    // are never accidentally dropped when a task is retried.
    final rebuilt = task.request.copyWith(outputDir: outputDir);
    _tasks.remove(task);
    await enqueue(rebuilt, title: task.title, kind: task.kind, thumbnailUrl: task.thumbnailUrl);
  }

  void removeTask(DownloadTask task) {
    if (task.status == TaskStatus.running || task.status == TaskStatus.queued) return;
    _tasks.remove(task);
    notifyListeners();
    unawaited(_persistQueue());
  }

  void clearFinished() {
    _tasks.removeWhere((t) => t.status != TaskStatus.running && t.status != TaskStatus.queued);
    notifyListeners();
    unawaited(_persistQueue());
  }

  /// Cancels active work and removes every task. Used by "Reset all data";
  /// the generation bump makes any in-flight [_run] skip writing history
  /// after the reset, so a cancelled download cannot repopulate the list.
  /// Restores the default download directory after settings are reset.
  Future<void> refreshOutputDirectory() async {
    final sdk = await TalosStorageBridge.androidSdkInt();
    _outputDir = await defaultDownloadDirectory(androidSdkInt: sdk);
    notifyListeners();
  }

  Future<void> resetAll() async {
    _resetGeneration++;
    for (final task in _tasks) {
      task.cancelRequested = true;
    }
    await _activeSession?.cancel();
    _activeSession = null;
    _wifiRetryTimer?.cancel();
    _wifiRetryTimer = null;
    _quietRetryTimer?.cancel();
    _quietRetryTimer = null;
    _batteryRetryTimer?.cancel();
    _batteryRetryTimer = null;
    _tasks.clear();
    notifyListeners();
    await _persistQueue();
    await stopForegroundService();
  }

  /// Marks a task cancelled when a stop was requested before the engine
  /// session ever started. No file or history row exists at this point.
  Future<void> _finishCancelledBeforeStart(DownloadTask task) async {
    task.status = TaskStatus.cancelled;
    task.stage = 'cancelled';
    notifyListeners();
    await _persistQueue();
    await _maybeStopForeground();
  }

  /// Finalize a task cancelled after the engine reported success but before
  /// post-processing finished. No history row is written in this case.
  Future<void> _cancelAfterOutcome(DownloadTask task) async {
    task.status = TaskStatus.cancelled;
    task.stage = 'cancelled';
    notifyListeners();
    await _persistQueue();
    await _maybeStopForeground();
  }

  /// Move a task to a new position in the queue. Indices refer to the
  /// queued/running order shown by the Active tab, i.e. only tasks whose
  /// status is not completed. [newIndex] is the final insertion index
  /// (the same semantics Flutter's onReorderItem uses), so it already
  /// accounts for the removed item.
  void reorder(int oldIndex, int newIndex) {
    final visible = _tasks.where((t) => t.status != TaskStatus.completed).toList();
    if (oldIndex < 0 || oldIndex >= visible.length) return;
    final moved = visible.removeAt(oldIndex);
    if (newIndex < 0) newIndex = 0;
    if (newIndex > visible.length) newIndex = visible.length;
    visible.insert(newIndex, moved);
    // Rebuild internal order: keep visibility-ordered tasks ahead of
    // completed ones (finished tasks are not shown in Active anyway).
    final completed = _tasks.where((t) => t.status == TaskStatus.completed).toList();
    _tasks
      ..clear()
      ..addAll(visible)
      ..addAll(completed);
    notifyListeners();
    unawaited(_persistQueue());
  }

  /// Progress events can arrive many times per second. Coalesce them so the
  /// whole widget tree is not rebuilt on every line of yt-dlp output.
  void _notifyProgress() {
    final now = DateTime.now();
    final elapsed = _lastProgressNotify == null
        ? 1000
        : now.difference(_lastProgressNotify!).inMilliseconds;
    if (elapsed >= 100) {
      _lastProgressNotify = now;
      notifyListeners();
      return;
    }
    _progressNotifyTimer ??= Timer(Duration(milliseconds: 100 - elapsed), () {
      _progressNotifyTimer = null;
      _lastProgressNotify = DateTime.now();
      notifyListeners();
    });
  }

  /// Pauses starting new downloads. The task already running is allowed to
  /// finish; only the head of the queue is held back.
  Future<void> setQueuePaused(bool paused) async {
    await _settings.mutate((s) => s.copyWith(queuePaused: paused));
    if (!paused) kickQueue();
  }

  /// Cancels every task that has not started yet. Running tasks are untouched.
  Future<void> clearQueued() async {
    final pending = _tasks.where((t) => t.status == TaskStatus.queued).toSet();
    if (pending.isEmpty) return;
    // No queued work remains, so pending gate timers have nothing to recheck.
    _wifiRetryTimer?.cancel();
    _wifiRetryTimer = null;
    _quietRetryTimer?.cancel();
    _quietRetryTimer = null;
    _batteryRetryTimer?.cancel();
    _batteryRetryTimer = null;
    for (final task in pending) {
      task.status = TaskStatus.cancelled;
      task.stage = 'cancelled';
    }
    _tasks.removeWhere(pending.contains);
    notifyListeners();
    await _persistQueue();
    await _maybeStopForeground();
  }

  /// Called when a setting that affects the queue changes, for example when
  /// WiFi-only is turned off while downloads are waiting for a network.
  void kickQueue() {
    _wifiRetryTimer?.cancel();
    _wifiRetryTimer = null;
    _quietRetryTimer?.cancel();
    _quietRetryTimer = null;
    _batteryRetryTimer?.cancel();
    _batteryRetryTimer = null;
    if (!_pumping) unawaited(_pump());
  }

  @override
  void dispose() {
    _progressNotifyTimer?.cancel();
    _wifiRetryTimer?.cancel();
    _quietRetryTimer?.cancel();
    _batteryRetryTimer?.cancel();
    super.dispose();
  }

  Future<void> _pump() async {
    if (_pumping) return;
    _pumping = true;
    try {
      while (true) {
        DownloadTask? next;
        for (final task in _tasks) {
          if (task.status == TaskStatus.queued) {
            next = task;
            // Tasks are stored in display order. Take the first queued one so
            // drag-to-reorder actually controls which download starts next.
            break;
          }
        }
        if (next == null) break;
        if (_settings.value.queuePaused) {
          next.stage = 'queuePaused';
          notifyListeners();
          break;
        }
        if (_settings.value.quietHoursEnabled) {
          final now = nowOverride != null ? nowOverride!() : DateTime.now();
          final active = isWithinQuietHours(
            now,
            _settings.value.quietStartHour,
            _settings.value.quietEndHour,
          );
          if (!active) {
            next.stage = 'quietHours';
            notifyListeners();
            _quietRetryTimer?.cancel();
            _quietRetryTimer = Timer(quietRetryDelay, () {
              _quietRetryTimer = null;
              if (!_pumping) unawaited(_pump());
            });
            break;
          }
        }
        if (_settings.value.batterySaverEnabled) {
          final threshold = _settings.value.batteryThreshold;
          final low = batteryProbeOverride != null
              ? await batteryProbeOverride!(threshold)
              : await TalosStorageBridge.isBatteryLow(threshold);
          // A null result means the native bridge is unavailable. Allow the
          // download instead of stranding the queue on an unknown state.
          if (low == true) {
            next.stage = 'batteryLow';
            notifyListeners();
            _batteryRetryTimer?.cancel();
            _batteryRetryTimer = Timer(batteryRetryDelay, () {
              _batteryRetryTimer = null;
              if (!_pumping) unawaited(_pump());
            });
            break;
          }
        }
        if (_settings.value.wifiOnly) {
          final onWifi = wifiProbeOverride != null
              ? await wifiProbeOverride!()
              : await TalosStorageBridge.isOnWifi();
          // A null result means the bridge is unavailable or the platform has
          // no WiFi concept. Allow the download rather than blocking forever.
          if (onWifi == false) {
            // Pause the queue instead of failing the task. Downloads resume
            // automatically when WiFi returns, without losing progress state.
            next.stage = 'waitingForWifi';
            notifyListeners();
            _wifiRetryTimer?.cancel();
            _wifiRetryTimer = Timer(wifiRetryDelay, () {
              _wifiRetryTimer = null;
              if (!_pumping) unawaited(_pump());
            });
            break;
          }
        }
        await _run(next);
        // Transient failures can be retried automatically. Stable storage
        // errors and explicit cancellation are never retried.
        if (next.status == TaskStatus.failed &&
            !next.cancelRequested &&
            next.attempts < _settings.value.autoRetryAttempts &&
            _retryable(next.error)) {
          final generation = _resetGeneration;
          next.attempts++;
          next.stage = 'retrying';
          next.error = null;
          next.status = TaskStatus.queued;
          _tasks.remove(next);
          _tasks.insert(0, next);
          notifyListeners();
          await _persistQueue();
          // Linear backoff keeps the delay predictable: 2s, 4s, 6s.
          await Future.delayed(retryDelayBase * next.attempts);
          if (generation != _resetGeneration) break;
        }
      }
    } finally {
      _pumping = false;
    }
  }

  Future<void> _run(DownloadTask task) async {
    final generation = _resetGeneration;
    // Progress coalescing state belongs to one task only. A timer left over
    // from the previous download must not fire after this task starts.
    _progressNotifyTimer?.cancel();
    _progressNotifyTimer = null;
    _lastProgressNotify = null;
    task.status = TaskStatus.running;
    task.stage = 'starting';
    notifyListeners();
    unawaited(_persistQueue());

    if (_settings.value.downloadNotification) {
      await requestTalosNotificationPermission();
      await ensureForegroundService(text: task.title);
    }
    if (task.cancelRequested || generation != _resetGeneration) {
      await _finishCancelledBeforeStart(task);
      return;
    }

    // Resolve a unique output filename before download. Every non-playlist
    // download must always run: when the target name already exists, Talos
    // writes "name(1).ext", "name(2).ext" and so on. The user asked for
    // unlimited repeats of the same video without any hidden deduplication.
    DownloadRequest effectiveRequest = task.request;
    final typed = task.request.outputFilename?.trim();
    try {
      final dir = Directory(task.request.outputDir);
      if (typed != null && typed.isNotEmpty) {
        final unique = await _uniqueFilename(dir, typed);
        if (unique != typed) {
          effectiveRequest = task.request.copyWith(outputFilename: unique);
        }
      } else if (!task.request.includePlaylist) {
        // Listing runs asynchronously so a large Downloads folder does not
        // freeze the UI while a download is being enqueued.
        final base = await _uniqueOutputTemplate(dir, _sanitizeFilenameComponent(task.title));
        effectiveRequest = task.request.copyWith(outputFilename: '$base.%(ext)s');
      }
    } catch (_) {
      // Directory access can fail on unusual paths (for example SAF content
      // URIs); fall back to the requested name unchanged.
    }

    try {
      final dir = Directory(effectiveRequest.outputDir);
      if (!dir.existsSync()) dir.createSync(recursive: true);
    } catch (_) {
      // Output directory may not be creatable (e.g. user picked a read-only path).
    }

    final configuredFfmpeg = _settings.value.ffmpegPath.trim();
    final ffmpegAvailable = await _ffmpegAvailable(configuredFfmpeg);
    if (task.cancelRequested || generation != _resetGeneration) {
      await _finishCancelledBeforeStart(task);
      return;
    }

    final session = _engine.download(
      effectiveRequest,
      ffmpegAvailable: ffmpegAvailable,
    );
    // A cancel may have arrived while download() was starting the process.
    if (task.cancelRequested || generation != _resetGeneration) {
      await session.cancel();
      await _finishCancelledBeforeStart(task);
      return;
    }
    _activeSession = session;
    final rawSubscription = session.rawLog?.listen((line) {
      if (task.log.length < 500) task.log.add(line);
    });
    final subscription = session.events.listen((event) {
      if (event.error != null) {
        task.error = event.error;
        notifyListeners();
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
      if (event.outputPath != null) {
        task.outputPath = event.outputPath;
        if (!task.outputPaths.contains(event.outputPath)) {
          task.outputPaths.add(event.outputPath!);
        }
      }
      _notifyProgress();
    });

    final outcome = await session.outcome;
    await subscription.cancel();
    await rawSubscription?.cancel();
    // A stale run resuming after a reset+re-enqueue must not clear the newer
    // session's reference.
    if (identical(_activeSession, session)) _activeSession = null;

    // A reset or a cancel that arrived while the engine was finishing (there
    // are several awaits below) invalidates all post-processing.
    if (generation != _resetGeneration || task.cancelRequested) {
      task.status = TaskStatus.cancelled;
      notifyListeners();
      await _maybeStopForeground();
      return;
    }

    if (outcome.error == null) {
      // A transient ERROR line from a recovered playlist item must not leave
      // a stale error on a successful task.
      task.error = null;
      if (outcome.outputPath != null && !task.outputPaths.contains(outcome.outputPath)) {
        task.outputPaths.add(outcome.outputPath!);
      }
      if (task.outputPaths.isEmpty && task.outputPath != null) {
        task.outputPaths.add(task.outputPath!);
      }

      final saf = _settings.value.downloadFolderSAF.trim();
      // A plain per-type folder the user chose is authoritative: the file is
      // already there and must not be relocated into Downloads/Talos.
      final requestedDir = task.request.outputDir.trim();
      final plainSet = requestedDir.isNotEmpty &&
          !requestedDir.startsWith('content://') &&
          requestedDir != _outputDir;
      final directWrite = _outputDir == '/storage/emulated/0/Download/Talos';
      final savedPaths = <String>[];
      final copiedPaths = <String>[];
      final sizes = <int?>[];

      for (final localPath in task.outputPaths) {
        // A cancel can arrive while the engine is finishing or while a file
        // is being copied. Never write history for a cancelled task.
        if (task.cancelRequested || generation != _resetGeneration) {
          for (final copied in copiedPaths) {
            await TalosStorageBridge.deleteDownloadedFile(copied);
          }
          await _cancelAfterOutcome(task);
          return;
        }
        var workingPath = localPath;
        if (Platform.isAndroid && localPath.isNotEmpty && !localPath.startsWith('content://') && !plainSet) {
          final displayName = localPath.split(Platform.pathSeparator).last;
          final localSize = await _fileSize(localPath);
          if (task.cancelRequested || generation != _resetGeneration) {
            for (final copied in copiedPaths) {
              await TalosStorageBridge.deleteDownloadedFile(copied);
            }
            await _cancelAfterOutcome(task);
            return;
          }
          String? saved;
          if (saf.isNotEmpty) {
            saved = await TalosStorageBridge.copyToTree(localPath, displayName);
          } else if (!directWrite) {
            saved = await TalosStorageBridge.saveToDownloads(localPath, displayName);
          } else {
            saved = localPath; // API 24-28 direct write.
          }
          if (task.cancelRequested || generation != _resetGeneration) {
            if (saved != null && saved != localPath) {
              await TalosStorageBridge.deleteDownloadedFile(saved);
            }
            for (final copied in copiedPaths) {
              await TalosStorageBridge.deleteDownloadedFile(copied);
            }
            await _cancelAfterOutcome(task);
            return;
          }
          if (saved == null) {
            task.status = TaskStatus.failed;
            task.error = saf.isNotEmpty ? kErrSafNotWritable : kErrSaveToDownloads;
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
            workingPath = saved;
            copiedPaths.add(saved);
            sizes.add(localSize);
          } else {
            sizes.add(localSize);
          }
        } else {
          sizes.add(await _fileSize(workingPath));
        }
        savedPaths.add(workingPath);
      }

      if (generation != _resetGeneration || task.cancelRequested) {
        for (final copied in copiedPaths) {
          await TalosStorageBridge.deleteDownloadedFile(copied);
        }
        await _cancelAfterOutcome(task);
        return;
      }
      if (!_settings.value.privateMode) {
        for (var i = 0; i < savedPaths.length; i++) {
          await _history.add(HistoryEntry(
            id: savedPaths.length == 1 ? task.id : '${task.id}-$i',
            title: task.title,
            url: task.url,
            filePath: savedPaths[i],
            kind: task.kind,
            dateMs: DateTime.now().millisecondsSinceEpoch,
            sizeBytes: i < sizes.length ? sizes[i] : null,
            thumbnailUrl: task.thumbnailUrl,
          ));
        }
      }
      task.outputPath = savedPaths.isNotEmpty ? savedPaths.last : null;
      task.outputPaths
        ..clear()
        ..addAll(savedPaths);
      // Completed work moves to the Finished tab via history.
      _tasks.remove(task);
    } else if (outcome.error == 'cancelled') {
      task.status = TaskStatus.cancelled;
    } else {
      task.status = TaskStatus.failed;
      task.error = outcome.error;
    }
    notifyListeners();
    await _persistQueue();
    await _maybeStopForeground();
  }

  /// Saves pending and running work. Running tasks are restored as queued,
  /// which resumes them after a process kill with their request intact.
  Future<void> _persistQueue() async {
    await QueueStore.save([
      for (final task in _tasks)
        if (task.status == TaskStatus.queued || task.status == TaskStatus.running)
          QueuedDownload(
            id: task.id,
            title: task.title,
            url: task.url,
            kind: task.kind,
            request: task.request,
            thumbnailUrl: task.thumbnailUrl,
            attempts: task.attempts,
          ),
    ]);
  }

  static bool _retryable(String? error) {
    if (error == null || error == 'cancelled') return false;
    if (error == kErrSafNotWritable || error == kErrSaveToDownloads) return false;
    return true;
  }

  Future<void> _maybeStopForeground() async {
    final busy = _tasks.any((t) =>
        t.status == TaskStatus.running || t.status == TaskStatus.queued);
    if (!busy) await stopForegroundService();
  }

  @visibleForTesting
  static Future<bool> Function(String configured)? ffmpegProbeOverride;

  @visibleForTesting
  static Duration retryDelayBase = const Duration(seconds: 2);

  @visibleForTesting
  static Future<bool?> Function()? wifiProbeOverride;

  @visibleForTesting
  static Duration wifiRetryDelay = const Duration(seconds: 30);

  @visibleForTesting
  static DateTime Function()? nowOverride;

  @visibleForTesting
  static Duration quietRetryDelay = const Duration(minutes: 1);

  @visibleForTesting
  static Future<bool?> Function(int threshold)? batteryProbeOverride;

  @visibleForTesting
  static Duration batteryRetryDelay = const Duration(minutes: 1);

  static Future<String> _uniqueFilename(Directory dir, String name) async {
    final sep = dir.path.endsWith(Platform.pathSeparator) ? '' : Platform.pathSeparator;
    if (!await File('${dir.path}$sep$name').exists()) return name;
    final dot = name.lastIndexOf('.');
    final base = dot >= 0 ? name.substring(0, dot) : name;
    final ext = dot >= 0 ? name.substring(dot) : '';
    for (var i = 1; i < 1000; i++) {
      final candidate = '$base($i)$ext';
      if (!await File('${dir.path}$sep$candidate').exists()) return candidate;
    }
    // Never fall back to an occupied name. A time-based suffix keeps repeated
    // saves working even after hundreds of collisions.
    return '$base(${DateTime.now().microsecondsSinceEpoch})$ext';
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
  static Future<String> _uniqueOutputTemplate(Directory dir, String base) async {
    if (!await dir.exists()) return base;
    final taken = <String>{};
    await for (final entity in dir.list(followLinks: false)) {
      if (entity is! File) continue;
      taken.add(
        entity.uri.pathSegments.isNotEmpty
            ? entity.uri.pathSegments.last
            : entity.path.split(Platform.pathSeparator).last,
      );
    }
    bool used(String candidate) => taken.any((name) => name.startsWith('$candidate.'));
    if (!used(base)) return base;
    for (var i = 1; i < 1000; i++) {
      final candidate = '$base($i)';
      if (!used(candidate)) return candidate;
    }
    return '$base(${DateTime.now().microsecondsSinceEpoch})';
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
