import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:talos/app.dart';
import 'package:talos/core/download_manager.dart';
import 'package:talos/core/engine/engine.dart';
import 'package:talos/core/engine/models.dart';

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
  }) async {}

  @override
  Future<MediaProbe> probe(String url, {String proxy = ''}) async => MediaProbe(
        title: 'Example video',
        webpageUrl: url,
        isPlaylist: false,
        uploader: 'Example channel',
        duration: const Duration(minutes: 3, seconds: 20),
      );

  FakeSession? lastSession;

  @override
  TalosDownloadSession download(
    DownloadRequest request, {
    required bool ffmpegAvailable,
  }) {
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
  setUpAll(() {
    // Tests must never hit the network for fonts or spawn real processes.
    GoogleFonts.config.allowRuntimeFetching = false;
    DownloadManager.ffmpegProbeOverride = (_) async => true;
    PathProviderPlatform.instance = FakePathProvider();
  });

  testWidgets('app boots into home and reaches the downloads tab', (tester) async {
    late final DownloadManager manager;
    await tester.runAsync(() async {
      manager = await DownloadManager.create(engine: FakeEngine());
    });

    await tester.pumpWidget(TalosApp(manager: manager));
    await tester.pumpAndSettle();

    expect(find.text('TALOS'), findsOneWidget);

    await tester.tap(find.text('Downloads'));
    await tester.pumpAndSettle();
    expect(find.text('Nothing here yet'), findsOneWidget);
  });

  testWidgets('fetch configures and enqueues a download', (tester) async {
    final engine = FakeEngine();
    late final DownloadManager manager;
    await tester.runAsync(() async {
      manager = await DownloadManager.create(engine: engine);
    });

    await tester.pumpWidget(TalosApp(manager: manager));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'https://example.invalid/watch?v=abc');
    await tester.tap(find.text('Fetch'));
    await tester.pumpAndSettle();

    expect(find.text('Example video'), findsOneWidget);
    await tester.tap(find.text('Download'));
    await tester.pumpAndSettle();

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
}
