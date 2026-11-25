import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:talos/app.dart';
import 'package:talos/core/backup.dart';
import 'package:talos/core/command_template_store.dart';
import 'package:talos/core/download_manager.dart';
import 'package:talos/core/engine/desktop_engine.dart';
import 'package:talos/core/engine/command_builder.dart';
import 'package:talos/core/engine/engine.dart';
import 'package:talos/core/engine/models.dart';
import 'package:talos/core/engine/progress_parser.dart';
import 'package:talos/core/history_store.dart';
import 'package:talos/core/insights.dart';
import 'package:talos/core/preset_store.dart';
import 'package:talos/core/queue_store.dart';
import 'package:talos/core/saved_link_store.dart';
import 'package:talos/core/settings_store.dart';

class FakeSession implements TalosDownloadSession {
  FakeSession();

  final StreamController<EngineProgress> _controller =
      StreamController<EngineProgress>();
  final Completer<SessionOutcome> _outcome = Completer<SessionOutcome>();

  @override
  Stream<EngineProgress> get events => _controller.stream;

  @override
  Future<SessionOutcome> get outcome => _outcome.future;

  @override
  Stream<String>? get rawLog => const Stream<String>.empty();

  @override
  Future<void> cancel() async {
    if (!_controller.isClosed) await _controller.close();
    if (!_outcome.isCompleted) {
      _outcome.complete(SessionOutcome(error: 'cancelled'));
    }
  }

  void complete(String outputPath) {
    _controller.add(
      EngineProgress(fraction: 1, stage: 'download', outputPath: outputPath),
    );
    _controller.close();
    _outcome.complete(SessionOutcome(outputPath: outputPath));
  }

  void fail(String error) {
    _controller.close();
    _outcome.complete(SessionOutcome(error: error));
  }
}

class FlakyEngine extends FakeEngine {
  final List<SessionOutcome> outcomes;

  FlakyEngine(this.outcomes);

  final List<FakeSession> sessions = [];
  int _index = 0;

  @override
  TalosDownloadSession download(DownloadRequest request, {required bool ffmpegAvailable}) {
    final session = FakeSession();
    sessions.add(session);
    final outcome = outcomes[_index++];
    // Schedule completion so the manager can subscribe first.
    Future<void>.microtask(() {
      if (outcome.error != null) {
        session.fail(outcome.error!);
      } else {
        session.complete(outcome.outputPath ?? '/tmp/retry.mp4');
      }
    });
    return session;
  }
}

class FakeEngine implements TalosEngine {
  @override
  Future<EngineStatus> status() async => EngineStatus(
        ready: true,
        version: '2026.10.26',
        ffmpegPath: null,
        managed: true,
      );

  @override
  Future<void> ensureReady({
    void Function(String phase, double fraction)? onPhase,
    bool force = false,
    String channel = 'stable',
  }) async {}

  @override
  Future<MediaProbe> probe(String url, {String proxy = ''}) async => MediaProbe(
        title: 'Example video',
        webpageUrl: url,
        isPlaylist: false,
        uploader: 'Example channel',
        duration: const Duration(minutes: 3, seconds: 20),
      );

  DownloadRequest? lastRequest;
  FakeSession? lastSession;

  @override
  TalosDownloadSession download(
    DownloadRequest request, {
    required bool ffmpegAvailable,
  }) {
    lastRequest = request;
    lastSession = FakeSession();
    return lastSession!;
  }

  @override
  Stream<String> runCustomCommand(
    String template,
    String url, {
    String? workingDir,
  }) async* {
    yield 'ok';
  }
}

class FakePathProvider extends PathProviderPlatform {
  FakePathProvider() {
    root = Directory.systemTemp.createTempSync('talos_test').path;
  }

  late final String root;

  String _app(String name) => '$root${Platform.pathSeparator}$name';

  @override
  Future<String?> getApplicationSupportPath() async => _app('support');

  @override
  Future<String?> getApplicationDocumentsPath() async => _app('documents');

  @override
  Future<String?> getApplicationCachePath() async => _app('cache');

  @override
  Future<String?> getDownloadsPath() async => _app('downloads');

  @override
  Future<String?> getTemporaryPath() async => _app('temp');

  @override
  Future<String?> getLibraryPath() async => _app('library');

  @override
  Future<String?> getExternalStoragePath() async => _app('external');

  @override
  Future<List<String>?> getExternalCachePaths() async => [_app('externalCache')];

  @override
  Future<List<String>?> getExternalStoragePaths({StorageDirectory? type}) async => [
        _app('external'),
      ];
}

void main() {
  setUp(() {
    // Each test gets its own empty support directory.
    PathProviderPlatform.instance = FakePathProvider();
  });

  setUpAll(() {
    DownloadManager.ffmpegProbeOverride = (_) async => true;
  });

  testWidgets('app boots into home and reaches the downloads tab', (tester) async {
    late final DownloadManager manager;
    await tester.runAsync(() async {
      manager = await DownloadManager.create(engine: FakeEngine());
    });

    await tester.pumpWidget(TalosApp(manager: manager, showIntro: false));
    await tester.pumpAndSettle();

    expect(find.text('TALOS'), findsOneWidget);

    await tester.tap(find.text('Downloads'));
    await tester.pumpAndSettle();
    expect(find.text('Nothing here yet'), findsOneWidget);
  });

  testWidgets('private mode skips history', (tester) async {
    final engine = FakeEngine();
    late final DownloadManager manager;
    await tester.runAsync(() async {
      manager = await DownloadManager.create(engine: engine);
      await manager.settings.mutate((s) => s.copyWith(privateMode: true));
    });

    await tester.pumpWidget(TalosApp(manager: manager, showIntro: false));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'https://example.invalid/watch?v=abc');
    await tester.pump();
    await tester.tap(find.text('Fetch'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Download'));
    await tester.pumpAndSettle();

    // Filename resolution is async so a large output folder cannot block the
    // UI isolate. Pump the test binding so that I/O can complete.
    for (var i = 0; i < 100 && engine.lastSession == null; i++) {
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
    }
    expect(engine.lastSession, isNotNull);
    await tester.runAsync(() async {
      engine.lastSession!.complete('/tmp/example.mp4');
      for (var i = 0; i < 50 && manager.tasks.isNotEmpty; i++) {
        await Future.delayed(const Duration(milliseconds: 20));
      }
    });
    await tester.pump();

    expect(manager.history.entries, isEmpty);
  });

  testWidgets('fetch configures and enqueues a download', (tester) async {
    final engine = FakeEngine();
    late final DownloadManager manager;
    await tester.runAsync(() async {
      manager = await DownloadManager.create(engine: engine);
    });

    await tester.pumpWidget(TalosApp(manager: manager, showIntro: false));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'https://example.invalid/watch?v=abc');
    await tester.pump();
    await tester.tap(find.text('Fetch'));
    await tester.pumpAndSettle();

    expect(find.text('Example video'), findsOneWidget);
    await tester.tap(find.text('Download'));
    await tester.pumpAndSettle();

    // Filename resolution is async so a large output folder cannot block the
    // UI isolate. Pump the test binding so that I/O can complete.
    for (var i = 0; i < 100 && engine.lastSession == null; i++) {
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
    }
    expect(engine.lastSession, isNotNull);
    await tester.runAsync(() async {
      engine.lastSession!.complete('/tmp/example.mp4');
      for (var i = 0; i < 50 && manager.history.entries.isEmpty; i++) {
        await Future.delayed(const Duration(milliseconds: 20));
      }
    });
    await tester.pump();

    expect(manager.history.entries, hasLength(1));
    expect(manager.history.entries.first.title, 'Example video');
  });

  testWidgets('custom output filename dedupes against the existing file', (tester) async {
    final engine = FakeEngine();
    final outDir = Directory.systemTemp.createTempSync('talos_out');
    File('${outDir.path}${Platform.pathSeparator}clip.mp4').writeAsStringSync('already here');
    late final DownloadManager manager;
    await tester.runAsync(() async {
      manager = await DownloadManager.create(engine: engine);
      await manager.enqueue(
        DownloadRequest(
          url: 'https://example.invalid/a',
          videoMode: true,
          outputDir: outDir.path,
          outputFilename: 'clip.mp4',
        ),
        title: 'Clip',
        kind: HistoryKind.video,
      );
      for (var i = 0; i < 100 && engine.lastRequest == null; i++) {
        await Future.delayed(const Duration(milliseconds: 20));
      }
    });

    expect(engine.lastRequest, isNotNull);
    expect(engine.lastRequest!.outputFilename, 'clip(1).mp4');
  });

  testWidgets('repeated download of the same video gets a fresh unique name', (tester) async {
    final engine = FakeEngine();
    final outDir = Directory.systemTemp.createTempSync('talos_dup');
    File('${outDir.path}${Platform.pathSeparator}Example video.mp4').writeAsStringSync('first download');
    late final DownloadManager manager;
    await tester.runAsync(() async {
      manager = await DownloadManager.create(engine: engine);
      await manager.enqueue(
        DownloadRequest(
          url: 'https://example.invalid/a',
          videoMode: true,
          outputDir: outDir.path,
          includePlaylist: false,
        ),
        title: 'Example video',
        kind: HistoryKind.video,
      );
      for (var i = 0; i < 100 && engine.lastRequest == null; i++) {
        await Future.delayed(const Duration(milliseconds: 20));
      }
    });

    expect(engine.lastRequest, isNotNull);
    expect(engine.lastRequest!.outputFilename, 'Example video(1).%(ext)s');
  });

  testWidgets('first download of a video uses the plain title template', (tester) async {
    final engine = FakeEngine();
    final outDir = Directory.systemTemp.createTempSync('talos_first');
    late final DownloadManager manager;
    await tester.runAsync(() async {
      manager = await DownloadManager.create(engine: engine);
      await manager.enqueue(
        DownloadRequest(
          url: 'https://example.invalid/b',
          videoMode: true,
          outputDir: outDir.path,
          includePlaylist: false,
        ),
        title: 'Fresh clip',
        kind: HistoryKind.video,
      );
      for (var i = 0; i < 100 && engine.lastRequest == null; i++) {
        await Future.delayed(const Duration(milliseconds: 20));
      }
    });

    expect(engine.lastRequest, isNotNull);
    expect(engine.lastRequest!.outputFilename, 'Fresh clip.%(ext)s');
  });

  testWidgets('retry targets the configured per-type folder', (tester) async {
    final engine = FakeEngine();
    late final DownloadManager manager;
    await tester.runAsync(() async {
      manager = await DownloadManager.create(engine: engine);
      await manager.settings.mutate((s) => s.copyWith(videoFolder: 'vfolder', audioFolder: 'afolder'));
      await manager.enqueue(
        DownloadRequest(url: 'https://example.invalid/a', videoMode: false, outputDir: 'ignored'),
        title: 'Example audio',
        kind: HistoryKind.audio,
      );
      final task = manager.tasks.single;
      await manager.retry(task);
    });

    final retried = manager.tasks.first;
    expect(retried.request.outputDir, 'afolder');
  });

  HistoryEntry entry(
    String id, {
    required int dateMs,
    int? sizeBytes,
    String title = 'Item',
    HistoryKind kind = HistoryKind.video,
    bool favorite = false,
  }) {
    return HistoryEntry(
      id: id,
      title: title,
      url: 'https://example.invalid/$id',
      filePath: '/tmp/$id.mp4',
      kind: kind,
      dateMs: dateMs,
      sizeBytes: sizeBytes,
      favorite: favorite,
    );
  }

  test('sortedHistory orders by newest and oldest', () {
    final entries = [
      entry('a', dateMs: 100),
      entry('b', dateMs: 300),
      entry('c', dateMs: 200),
    ];
    expect(sortedHistory(entries, 'newest').map((e) => e.id).toList(), ['b', 'c', 'a']);
    expect(sortedHistory(entries, 'oldest').map((e) => e.id).toList(), ['a', 'c', 'b']);
  });

  test('sortedHistory handles sizes, titles and an unknown sort', () {
    final entries = [
      entry('a', dateMs: 100, sizeBytes: 500, title: 'beta'),
      entry('b', dateMs: 300, sizeBytes: null, title: 'Alpha'),
      entry('c', dateMs: 200, sizeBytes: 1000, title: 'charlie'),
    ];
    expect(sortedHistory(entries, 'largest').map((e) => e.id).toList(), ['c', 'a', 'b']);
    expect(sortedHistory(entries, 'smallest').map((e) => e.id).toList(), ['b', 'a', 'c']);
    expect(sortedHistory(entries, 'title').map((e) => e.id).toList(), ['b', 'a', 'c']);
    expect(sortedHistory(entries, 'bogus').map((e) => e.id).toList(), ['b', 'c', 'a']);
  });

  test('removeMany removes only matching ids and persists', () async {
    final store = await HistoryStore.load();
    await store.add(entry('a', dateMs: 1));
    await store.add(entry('b', dateMs: 2));
    await store.add(entry('c', dateMs: 3));
    await store.removeMany(['a', 'c', 'missing']);
    expect(store.entries.map((e) => e.id).toList(), ['b']);
    final reloaded = await HistoryStore.load();
    expect(reloaded.entries.map((e) => e.id).toList(), ['b']);
    await store.removeMany([]);
    expect(store.entries, hasLength(1));
  });

  test('a malformed history row does not discard the valid ones', () async {
    final support = await getApplicationSupportDirectory();
    await support.create(recursive: true);
    final file = File('${support.path}${Platform.pathSeparator}history.json');
    await file.writeAsString(jsonEncode([
      entry('a', dateMs: 100).toJson(),
      {'title': 'no id here'},
      entry('b', dateMs: 200).toJson(),
    ]));
    final store = await HistoryStore.load();
    expect(store.entries.map((e) => e.id).toList(), ['b', 'a']);
  });

  test('progress parser tolerates malformed numbers', () {
    expect(
      () => parseYtdlpLine('[download]  10.0% of 1.2.3MiB at 1.2.3MiB/s ETA 00:12'),
      returnsNormally,
    );
  });

  test('clear flags reset nullable settings fields', () async {
    final store = await SettingsStore.load();
    await store.mutate((s) => s.copyWith(
          videoFolder: 'v',
          audioFolder: 'a',
          customCommandDirectory: 'c',
          clipStartSeconds: 5,
          clipEndSeconds: 10,
        ));
    expect(store.value.videoFolder, 'v');
    expect(store.value.clipEndSeconds, 10);
    await store.mutate((s) => s.copyWith(
          clearVideoFolder: true,
          clearAudioFolder: true,
          clearCustomCommandDirectory: true,
          clearClipRange: true,
        ));
    expect(store.value.videoFolder, isNull);
    expect(store.value.audioFolder, isNull);
    expect(store.value.customCommandDirectory, isNull);
    expect(store.value.clipStartSeconds, isNull);
    expect(store.value.clipEndSeconds, isNull);
  });

  test('embedSubtitles switch controls --embed-subs', () {
    DownloadRequest request({required bool embedSubtitles}) => DownloadRequest(
          url: 'https://example.invalid/a',
          videoMode: true,
          outputDir: 'out',
          downloadSubtitles: true,
          embedSubtitles: embedSubtitles,
        );
    final withEmbed = CommandBuilder.downloadArgs(request(embedSubtitles: true), ffmpegAvailable: true);
    final withoutEmbed = CommandBuilder.downloadArgs(request(embedSubtitles: false), ffmpegAvailable: true);
    expect(withEmbed, contains('--embed-subs'));
    expect(withoutEmbed, isNot(contains('--embed-subs')));
    // Without ffmpeg, never embed regardless of the switch.
    final noFfmpeg = CommandBuilder.downloadArgs(request(embedSubtitles: true), ffmpegAvailable: false);
    expect(noFfmpeg, isNot(contains('--embed-subs')));
  });

  test('settings normalization rejects stale dropdown values', () async {
    final support = await getApplicationSupportDirectory();
    await support.create(recursive: true);
    final file = File('${support.path}${Platform.pathSeparator}settings.json');
    await file.writeAsString(jsonEncode({
      'themeMode': 'old-removed-theme',
      'defaultMaxHeight': 9999,
      'defaultAudioFormat': 'wav',
      'concurrentFragments': 7,
      'remuxContainer': 'avi',
      'engineChannel': 'experimental',
    }));
    final store = await SettingsStore.load();
    expect(store.value.themeMode, 'system');
    expect(store.value.defaultMaxHeight, 720);
    expect(store.value.defaultAudioFormat, 'mp3');
    expect(store.value.concurrentFragments, 4);
    expect(store.value.remuxContainer, '');
    expect(store.value.engineChannel, 'stable');
  });

  test('clip sections are well formed and ffmpeg-gated', () {
    DownloadRequest clip({int? start, int? end}) => DownloadRequest(
          url: 'https://example.invalid/a',
          videoMode: true,
          outputDir: 'out',
          clipStartSeconds: start,
          clipEndSeconds: end,
        );
    final startOnly = CommandBuilder.downloadArgs(clip(start: 10), ffmpegAvailable: true);
    expect(startOnly, contains('--download-sections'));
    expect(startOnly[startOnly.indexOf('--download-sections') + 1], '*10-inf');
    final endOnly = CommandBuilder.downloadArgs(clip(end: 30), ffmpegAvailable: true);
    expect(endOnly[endOnly.indexOf('--download-sections') + 1], '*0-30');
    final both = CommandBuilder.downloadArgs(clip(start: 10, end: 30), ffmpegAvailable: true);
    expect(both[both.indexOf('--download-sections') + 1], '*10-30');
    // Without ffmpeg the section flag is omitted instead of failing at runtime.
    final noFfmpeg = CommandBuilder.downloadArgs(clip(start: 10), ffmpegAvailable: false);
    expect(noFfmpeg, isNot(contains('--download-sections')));
  });

  test('saved links dedupe, persist and skip malformed rows', () async {
    final support = await getApplicationSupportDirectory();
    await support.create(recursive: true);
    final file = File('${support.path}${Platform.pathSeparator}saved_links.json');
    await file.writeAsString(jsonEncode([
      {'id': 'x', 'text': 'https://example.invalid/old', 'dateMs': 1},
      {'text': 'no id'},
    ]));
    final store = await SavedLinkStore.load();
    expect(store.entries, hasLength(1));
    await store.add('https://example.invalid/new');
    await store.add('https://example.invalid/new');
    expect(store.entries, hasLength(2));
    final reloaded = await SavedLinkStore.load();
    expect(reloaded.entries, hasLength(2));
    await store.remove(reloaded.entries.first.id);
    expect(store.entries, hasLength(1));
  });

  test('presets persist, replace by name and skip malformed rows', () async {
    final support = await getApplicationSupportDirectory();
    await support.create(recursive: true);
    final file = File('${support.path}${Platform.pathSeparator}presets.json');
    await file.writeAsString(jsonEncode([
      {'id': 'x'},
      {'name': 'no id', 'videoMode': true},
    ]));
    final store = await PresetStore.load();
    expect(store.entries, isEmpty);
    const preset = DownloadPreset(
      id: 'a',
      name: 'Audio',
      videoMode: false,
      maxHeight: 0,
      audioFormat: 'mp3',
      audioBitrate: '320',
      embedSubtitles: false,
      embedMetadata: true,
    );
    await store.add(preset);
    await store.add(DownloadPreset(id: 'b', name: 'audio', videoMode: false, maxHeight: 0,
        audioFormat: 'flac', audioBitrate: '192', embedSubtitles: false, embedMetadata: false));
    expect(store.entries, hasLength(1));
    final reloaded = await PresetStore.load();
    expect(reloaded.entries, hasLength(1));
    expect(reloaded.entries.first.name, 'audio');
    await store.clear();
    expect(store.entries, isEmpty);
  });

  test('insights audio share is zero when total size is zero', () {
    final stats = buildInsights([
      entry('v1', dateMs: 1, sizeBytes: null),
      entry('v2', dateMs: 2, sizeBytes: 0),
    ]);
    expect(stats.totalBytes, 0);
    expect(stats.videoShare, 0);
    expect(stats.audioShare, 0);
  });

  test('insights aggregates counts, sizes and activity', () {
    final now = DateTime(2026, 11, 22, 12);
    final entries = [
      entry('a', dateMs: now.millisecondsSinceEpoch, sizeBytes: 100, favorite: true),
      entry('b', dateMs: now.subtract(const Duration(days: 1)).millisecondsSinceEpoch, sizeBytes: 300, kind: HistoryKind.audio),
      entry('c', dateMs: now.subtract(const Duration(days: 10)).millisecondsSinceEpoch, sizeBytes: 600),
      entry('d', dateMs: 0, sizeBytes: null),
    ];
    final stats = buildInsights(entries, now: now);
    expect(stats.totalCount, 4);
    expect(stats.videoCount, 3);
    expect(stats.audioCount, 1);
    expect(stats.favoriteCount, 1);
    expect(stats.totalBytes, 1000);
    expect(stats.todayCount, 1);
    expect(stats.weekCount, 2);
    expect(stats.monthCount, 3);
    expect(stats.last7Days.reduce((a, b) => a + b), 2);
    expect(stats.largest.first.id, 'c');
    expect(stats.oldestDayMs, entries[2].dateMs);
  });

  testWidgets('queue starts the first visible task after one finishes', (tester) async {
    final engine = FakeEngine();
    late final DownloadManager manager;
    await tester.runAsync(() async {
      manager = await DownloadManager.create(engine: engine);
      for (final name in ['A', 'B', 'C']) {
        await manager.enqueue(
          DownloadRequest(
            url: 'https://example.invalid/${name.toLowerCase()}',
            videoMode: true,
            outputDir: 'out',
          ),
          title: name,
          kind: HistoryKind.video,
        );
        if (name == 'A') {
          for (var i = 0; i < 100 && engine.lastSession == null; i++) {
            await Future.delayed(const Duration(milliseconds: 10));
          }
        }
      }
      // A is running and B, C are queued. Finish A so the pump picks next.
      engine.lastSession!.complete('/tmp/a.mp4');
      for (var i = 0; i < 200; i++) {
        final running = manager.tasks.where((t) => t.status == TaskStatus.running).toList();
        if (running.length == 1 && running.first.title == 'B') break;
        await Future.delayed(const Duration(milliseconds: 10));
      }
    });
    final running = manager.tasks.where((t) => t.status == TaskStatus.running).toList();
    expect(running, hasLength(1));
    expect(running.first.title, 'B');
  });

  test('download args place an end-of-options marker before the URL', () {
    final request = DownloadRequest(
      url: '-dangerous-option',
      videoMode: true,
      outputDir: '/downloads',
    );
    final args = CommandBuilder.downloadArgs(request, ffmpegAvailable: false);
    expect(args[args.length - 2], '--');
    expect(args.last, '-dangerous-option');
    expect(CommandBuilder.probeArgs('-evil', proxy: ''), contains('--'));
  });

  test('custom headers are passed one per line', () {
    final request = DownloadRequest(
      url: 'https://example.invalid/watch?v=h',
      videoMode: true,
      outputDir: '/downloads',
      customHeaders: 'Referer: https://example.invalid/\r\nX-Test: 1\n\n',
    );
    final args = CommandBuilder.downloadArgs(request, ffmpegAvailable: false);
    expect(args, containsAllInOrder([
      '--add-headers', 'Referer: https://example.invalid/',
      '--add-headers', 'X-Test: 1',
    ]));
    expect(args.where((a) => a == '--add-headers'), hasLength(2));
  });

  test('tokenizeArgs keeps Windows path backslashes literal', () {
    expect(
      CommandBuilder.tokenizeArgs(r'--cookies C:\Users\me\cookies.txt {url}'),
      ['--cookies', r'C:\Users\me\cookies.txt', '{url}'],
    );
    expect(CommandBuilder.tokenizeArgs(r'a\ b'), ['a b']);
  });

  test('backup export and restore round trip all local data', () async {
    final manager = await DownloadManager.create(engine: FakeEngine());
    await manager.settings.mutate((s) => s.copyWith(accent: 'aegean'));
    await manager.savedLinks.add('https://example.invalid/saved');
    await manager.presets.add(const DownloadPreset(
      id: 'p1',
      name: 'Preset',
      videoMode: true,
      maxHeight: 720,
      audioFormat: 'mp3',
      audioBitrate: '192',
      embedSubtitles: false,
      embedMetadata: true,
    ));
    await manager.history.add(HistoryEntry(
      id: 'h1',
      title: 'Backup item',
      url: 'https://example.invalid/watch?v=1',
      filePath: '/tmp/item.mp4',
      kind: HistoryKind.video,
      dateMs: 1234,
      sizeBytes: 99,
    ));
    // Establish an explicit empty command file so load() does not seed defaults.
    await CommandTemplateStore.replaceAll([]);
    final commandStore = await CommandTemplateStore.load();
    await commandStore.add(CommandTemplate(id: 'c1', name: 'Cmd', args: '{url}'));

    final json = await TalosBackup.exportJson(manager);
    final decoded = jsonDecode(json) as Map<String, dynamic>;
    expect(decoded['format'], TalosBackup.format);
    expect((decoded['history'] as List).length, 1);
    expect((decoded['savedLinks'] as List).length, 1);
    expect(decoded['queue'], isA<List>());

    await manager.settings.mutate((s) => s.copyWith(accent: 'marble'));
    await manager.history.clear();
    await manager.savedLinks.clear();
    await manager.presets.clear();
    await CommandTemplateStore.replaceAll([]);

    await TalosBackup.restoreJson(manager, json);
    expect(manager.settings.value.accent, 'aegean');
    expect(manager.history.entries, hasLength(1));
    expect(manager.history.entries.first.title, 'Backup item');
    expect(manager.savedLinks.entries, hasLength(1));
    expect(manager.presets.entries, hasLength(1));
    final commands = await CommandTemplateStore.load();
    expect(commands.templates, hasLength(1));
    expect(commands.templates.first.name, 'Cmd');
  });

  test('auto retry re-runs a transient failure once', () async {
    final engine = FlakyEngine([
      SessionOutcome(error: 'network error'),
      SessionOutcome(outputPath: '/tmp/retry.mp4'),
    ]);
    final manager = await DownloadManager.create(engine: engine);
    await manager.settings.mutate(
      (s) => s.copyWith(autoRetryAttempts: 1, privateMode: false),
    );
    DownloadManager.retryDelayBase = const Duration(milliseconds: 10);
    await manager.enqueue(
      DownloadRequest(
        url: 'https://example.invalid/watch?v=retry',
        videoMode: true,
        outputDir: 'out',
      ),
      title: 'Retry',
      kind: HistoryKind.video,
    );
    for (var i = 0; i < 200 && engine.sessions.length < 2; i++) {
      await Future.delayed(const Duration(milliseconds: 10));
    }
    expect(engine.sessions, hasLength(2));
    for (var i = 0; i < 200 && manager.history.entries.isEmpty; i++) {
      await Future.delayed(const Duration(milliseconds: 10));
    }
    expect(manager.history.entries, hasLength(1));
    // The history row is written just before the task is removed. Wait for
    // both states so a slow filesystem cannot make this test flaky.
    for (var i = 0; i < 200 && manager.tasks.isNotEmpty; i++) {
      await Future.delayed(const Duration(milliseconds: 10));
    }
    expect(manager.tasks, isEmpty);
    DownloadManager.retryDelayBase = const Duration(seconds: 2);
  });

  test('download request survives a JSON round trip', () {
    final original = DownloadRequest(
      url: 'https://example.invalid/watch?v=q',
      videoMode: false,
      outputDir: '/downloads',
      audioFormat: 'flac',
      audioBitrate: '320',
      proxy: 'http://proxy:8080',
      rateLimit: '5M',
      subtitleLanguage: 'id',
      formatSelector: 'bestaudio',
      downloadSubtitles: false,
      keepSubtitles: true,
      clipStartSeconds: 10,
      clipEndSeconds: 30,
      outputFilename: 'Song(1).flac',
    );
    final restored = DownloadRequest.fromJson(original.toJson());
    expect(restored.url, original.url);
    expect(restored.outputDir, original.outputDir);
    expect(restored.audioFormat, 'flac');
    expect(restored.proxy, 'http://proxy:8080');
    expect(restored.formatSelector, 'bestaudio');
    expect(restored.clipStartSeconds, 10);
    expect(restored.clipEndSeconds, 30);
    expect(restored.outputFilename, 'Song(1).flac');
    expect(restored.keepSubtitles, isTrue);
  });

  test('queue store restores pending downloads on startup', () async {
    await QueueStore.save([
      QueuedDownload(
        id: 'restored',
        title: 'Restored item',
        url: 'https://example.invalid/watch?v=restored',
        kind: HistoryKind.audio,
        request: DownloadRequest(
          url: 'https://example.invalid/watch?v=restored',
          videoMode: false,
          outputDir: 'out',
          audioFormat: 'opus',
        ),
        attempts: 1,
      ),
    ]);
    final loaded = await QueueStore.load();
    expect(loaded, hasLength(1));
    expect(loaded.first.title, 'Restored item');
    expect(loaded.first.attempts, 1);

    final manager = await DownloadManager.create(
      engine: FakeEngine(),
      restoreQueue: true,
    );
    expect(manager.tasks, hasLength(1));
    expect(manager.tasks.first.title, 'Restored item');
    expect(manager.tasks.first.request.audioFormat, 'opus');
    await manager.resetAll();
    await QueueStore.save([]);
  });

  test('desktop engine selects standalone release assets', () {
    final original = debugDefaultTargetPlatformOverride;
    try {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      expect(DesktopEngine.engineAsset(), 'yt-dlp_linux');
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      expect(DesktopEngine.engineAsset(), 'yt-dlp.exe');
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      expect(DesktopEngine.engineAsset(), 'yt-dlp_macos');
    } finally {
      debugDefaultTargetPlatformOverride = original;
    }
  });

  test('pause holds the queue and resume starts it again', () async {
    final engine = FakeEngine();
    final manager = await DownloadManager.create(engine: engine);
    await manager.setQueuePaused(true);
    await manager.enqueue(
      DownloadRequest(
        url: 'https://example.invalid/watch?v=pause',
        videoMode: true,
        outputDir: 'out',
      ),
      title: 'Paused item',
      kind: HistoryKind.video,
    );
    await Future.delayed(const Duration(milliseconds: 50));
    expect(engine.lastSession, isNull);
    expect(manager.tasks.single.stage, 'queuePaused');

    await manager.setQueuePaused(false);
    for (var i = 0; i < 200 && engine.lastSession == null; i++) {
      await Future.delayed(const Duration(milliseconds: 10));
    }
    expect(engine.lastSession, isNotNull);
    await manager.resetAll();
  });

  test('wifi only pauses the queue until WiFi returns', () async {
    final engine = FakeEngine();
    final manager = await DownloadManager.create(engine: engine);
    await manager.settings.mutate((s) => s.copyWith(wifiOnly: true));
    DownloadManager.wifiRetryDelay = const Duration(milliseconds: 10);
    DownloadManager.wifiProbeOverride = () async => false;
    try {
      await manager.enqueue(
        DownloadRequest(
          url: 'https://example.invalid/watch?v=wifi',
          videoMode: true,
          outputDir: 'out',
        ),
        title: 'WiFi item',
        kind: HistoryKind.video,
      );
      await Future.delayed(const Duration(milliseconds: 50));
      expect(engine.lastSession, isNull);
      expect(manager.tasks.single.stage, 'waitingForWifi');

      DownloadManager.wifiProbeOverride = () async => true;
      manager.kickQueue();
      for (var i = 0; i < 200 && engine.lastSession == null; i++) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
      expect(engine.lastSession, isNotNull);
    } finally {
      DownloadManager.wifiProbeOverride = null;
      DownloadManager.wifiRetryDelay = const Duration(seconds: 30);
      await manager.resetAll();
    }
  });

  test('history CSV export escapes special characters', () async {
    final store = await HistoryStore.load();
    await store.clear();
    await store.add(HistoryEntry(
      id: 'csv',
      title: 'A, "quoted" title',
      url: 'https://example.invalid/watch?v=csv',
      filePath: '/tmp/a,b.mp4',
      kind: HistoryKind.video,
      dateMs: 123,
      sizeBytes: 42,
      favorite: true,
    ));
    final csv = store.exportCsv();
    expect(csv, contains('title,url,kind,filePath,sizeBytes,dateMs,favorite'));
    expect(csv, contains('"A, ""quoted"" title"'));
    expect(csv, contains('"/tmp/a,b.mp4"'));
    expect(csv.trim().split('\n'), hasLength(2));
    await store.clear();
  });

  test('history retention drops only old rows', () async {
    final store = await HistoryStore.load();
    await store.clear();
    final now = DateTime.now().millisecondsSinceEpoch;
    await store.add(HistoryEntry(
      id: 'old',
      title: 'Old',
      url: 'https://example.invalid/old',
      filePath: '/tmp/old',
      kind: HistoryKind.video,
      dateMs: now - const Duration(days: 40).inMilliseconds,
    ));
    await store.add(HistoryEntry(
      id: 'new',
      title: 'New',
      url: 'https://example.invalid/new',
      filePath: '/tmp/new',
      kind: HistoryKind.video,
      dateMs: now,
    ));
    await store.pruneBefore(now - const Duration(days: 30).inMilliseconds);
    expect(store.entries, hasLength(1));
    expect(store.entries.first.id, 'new');
    final reloaded = await HistoryStore.load();
    expect(reloaded.entries, hasLength(1));
    await store.clear();
  });

  test('backup rejects foreign payloads', () async {
    final manager = await DownloadManager.create(engine: FakeEngine());
    expect(
      () => TalosBackup.restoreJson(manager, '{"format":"other"}'),
      throwsA(isA<FormatException>()),
    );
  });
}
