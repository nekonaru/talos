import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_scope.dart';
import '../core/app_info.dart';
import '../core/engine/models.dart';
import '../core/format.dart';
import '../core/history_store.dart';
import '../gen/app_localizations.dart';
import 'configure_screen.dart';
import 'player_screen.dart';
import '../widgets/section_label.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _urlController = TextEditingController();
  StreamSubscription<dynamic>? _intentSubscription;
  bool _busy = false;
  bool _settingUp = false;
  double _setupFraction = 0;
  String _setupPhase = '';
  String? _engineVersion;
  bool _engineReady = true;
  bool _sharedUrlApplied = false;

  @override
  void initState() {
    super.initState();
    _urlController.addListener(_onUrlChanged);
    _checkSharedIntent();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshEngine());
    WidgetsBinding.instance.addPostFrameCallback((_) => _detectClipboardUrl());
  }

  Future<void> _detectClipboardUrl() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text;
      if (text == null || !mounted) return;
      // A shared link always wins over clipboard content, even when the
      // clipboard read resolves after the intent event has arrived.
      if (_sharedUrlApplied || _urlController.text.isNotEmpty) return;
      final matches = RegExp(r'https?://\S+').allMatches(text).map((m) => m.group(0)!).where((u) => u.length > 10).toList();
      if (matches.isEmpty || !mounted) return;
      setState(() {
        _urlController.text = matches.join('\n');
        _urlController.selection = TextSelection.collapsed(offset: _urlController.text.length);
      });
    } catch (_) {
      // Clipboard is optional; silent fallback.
    }
  }

  List<String> _detectUrls(String text) {
    return RegExp(r'https?://\S+').allMatches(text).map((m) => m.group(0)!).where((u) => u.length > 10).toList();
  }

  Future<void> _saveCurrentLink() async {
    final l = AppLocalizations.of(context)!;
    final store = TalosScope.of(context).savedLinks;
    final text = _urlController.text.trim();
    if (text.isEmpty || !mounted) return;
    if (store.contains(text)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.linkAlreadySaved)));
      return;
    }
    await store.add(text);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.linkSaved)));
  }

  void _onUrlChanged() {
    if (mounted) setState(() {});
  }

  void _checkSharedIntent() {
    // Shared links only arrive on Android.
    if (!Platform.isAndroid) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      String? shared;
      try {
        shared = await const MethodChannel('id.nekonaru.talos/intent')
            .invokeMethod<String>('getInitialPendingUrl');
      } catch (_) {
        // Intent bridging is best effort; still subscribe for live shares.
      }
      if (!mounted) return;
      if (shared != null && shared.isNotEmpty) {
        _sharedUrlApplied = true;
        _urlController.text = shared;
        _urlController.selection = TextSelection.collapsed(offset: shared.length);
      }
      _intentSubscription = EventChannel('id.nekonaru.talos/intent/share')
          .receiveBroadcastStream()
          .listen((event) {
        if (event is String && event.isNotEmpty && mounted) {
          setState(() {
            _sharedUrlApplied = true;
            _urlController.text = event;
            _urlController.selection = TextSelection.collapsed(offset: event.length);
          });
        }
      }, onError: (_) {});
    });
  }

  @override
  void dispose() {
    _intentSubscription?.cancel();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _refreshEngine() async {
    try {
      final status = await TalosScope.of(context).engine.status();
      if (!mounted) return;
      setState(() {
        _engineReady = status.ready;
        _engineVersion = status.version;
      });
    } catch (_) {
      if (mounted) setState(() => _engineReady = false);
    }
  }

  /// Wrapper for the banner button. Unlike fetch/batch, the banner has no
  /// surrounding try/catch, so errors must be surfaced here to avoid an
  /// unhandled async error (for example on iOS or a failed download).
  Future<void> _setupEngineFromBanner() async {
    try {
      await _setupEngine();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyError(error))),
      );
    }
  }

  /// Sets up the engine and lets errors propagate so callers can show one
  /// friendly message instead of a raw error followed by a second one.
  Future<void> _setupEngine() async {
    setState(() => _settingUp = true);
    final manager = TalosScope.of(context);
    try {
      await manager.engine.ensureReady(onPhase: (phase, fraction) {
        if (!mounted) return;
        setState(() {
          _setupPhase = phase;
          _setupFraction = fraction;
        });
      });
      await _refreshEngine();
    } finally {
      if (mounted) setState(() => _settingUp = false);
    }
  }

  Future<void> _paste() async {
    ClipboardData? data;
    try {
      data = await Clipboard.getData(Clipboard.kTextPlain);
    } catch (_) {
      // Clipboard is best effort; a channel failure must not throw from onPressed.
      return;
    }
    if (!mounted) return;
    final text = data?.text?.trim();
    if (text != null && text.isNotEmpty) {
      _urlController.text = text;
      _urlController.selection = TextSelection.collapsed(offset: text.length);
    }
  }

  void _handleFetch() {
    final urls = _detectUrls(_urlController.text);
    if (urls.length > 1) {
      unawaited(_batchFetch());
    } else if (urls.length == 1) {
      // Pass the extracted URL so surrounding text or trailing punctuation
      // does not break the probe, matching the batch path.
      unawaited(_fetch(urls.first));
    }
  }

  Future<void> _batchFetch() async {
    final urls = _detectUrls(_urlController.text);
    if (urls.length < 2 || _busy) return;
    final l = AppLocalizations.of(context)!;
    final mode = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(l.batchFetchTitle),
        children: [
          ListTile(
            leading: const Icon(Icons.movie_outlined),
            title: Text(l.batchFetchVideo),
            onTap: () => Navigator.of(dialogContext).pop('video'),
          ),
          ListTile(
            leading: const Icon(Icons.music_note_outlined),
            title: Text(l.batchFetchAudio),
            onTap: () => Navigator.of(dialogContext).pop('audio'),
          ),
        ],
      ),
    );
    if (mode == null) return;
    final isAudio = mode == 'audio';
    if (!mounted) return;
    final manager = TalosScope.of(context);
    final settings = manager.settings.value;
    setState(() => _busy = true);
    try {
      // Ensure the engine is ready before probing. Errors are handled by the
      // outer catch so the user gets one clear message.
      if (!_engineReady) await _setupEngine();
      if (!mounted) return;
      final outputDir = isAudio
          ? (settings.audioFolder?.isNotEmpty == true ? settings.audioFolder! : manager.outputDirectory)
          : (settings.videoFolder?.isNotEmpty == true ? settings.videoFolder! : manager.outputDirectory);
      final support = await getApplicationSupportDirectory();
      final archivePath = settings.downloadArchive
          ? '${support.path}${Platform.pathSeparator}download_archive.txt'
          : '';
      var queued = 0;
      for (final url in urls) {
        try {
          final probe = await manager.engine.probe(url, proxy: settings.proxy);
          if (!mounted) return;
          await manager.enqueue(
            DownloadRequest(
              url: probe.webpageUrl,
              videoMode: !isAudio,
              outputDir: outputDir,
              maxHeight: isAudio ? null : (settings.defaultMaxHeight == 0 ? null : settings.defaultMaxHeight),
              audioFormat: isAudio ? settings.defaultAudioFormat : 'mp3',
              audioBitrate: isAudio ? settings.defaultAudioBitrate : '192',
              embedSubtitles: settings.embedSubtitles,
              embedMetadata: settings.embedMetadata,
              includePlaylist: probe.isPlaylist,
              filenameTemplate: settings.filenameTemplate,
              // Batch downloads must honour the same transport settings as a
              // single download, otherwise a configured proxy or cookies file
              // is silently dropped and every queued item fails.
              proxy: settings.proxy,
              rateLimit: settings.rateLimit,
              useAria2: settings.useAria2,
              concurrentFragments: settings.concurrentFragments,
              ffmpegPath: settings.ffmpegPath,
              sponsorBlockCategories: settings.sponsorBlockEnabled ? settings.sponsorBlockCategories : '',
              cookiesPath: settings.cookiesPath,
              subtitleLanguage: settings.subtitleLanguage,
              restrictFilenames: settings.restrictFilenames,
              cropArtwork: settings.cropArtwork,
              subtitleFormat: settings.subtitleFormat,
              forceIpv4: settings.forceIpv4,
              remuxContainer: settings.remuxContainer,
              maxFilesize: settings.maxFilesize,
              userAgent: settings.userAgent,
              formatSort: settings.formatSort,
              downloadSubtitles: settings.downloadSubtitles,
              autoSubtitle: settings.autoSubtitle,
              keepSubtitles: settings.keepSubtitles,
              downloadArchive: archivePath,
              clipStartSeconds: settings.clipStartSeconds,
              clipEndSeconds: settings.clipEndSeconds,
            ),
            title: probe.title,
            kind: isAudio ? HistoryKind.audio : HistoryKind.video,
            thumbnailUrl: probe.thumbnail,
          );
          queued++;
        } catch (_) {
          // Continue with the rest even if one URL fails.
        }
      }
      if (mounted) setState(_urlController.clear);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.batchQueued(queued, urls.length))),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyError(error))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _fetch(String url) async {
    if (url.isEmpty || _busy) return;
    setState(() => _busy = true);
    final manager = TalosScope.of(context);
    try {
      if (!_engineReady) await _setupEngine();
      if (!mounted) return;
      final probe = await manager.engine.probe(url, proxy: manager.settings.value.proxy);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ConfigureScreen(probe: probe)),
      );
    } catch (error) {
      if (!mounted) return;
      final message = _friendlyError(error);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _friendlyError(Object error) {
    final l = AppLocalizations.of(context)!;
    final text = '$error';
    for (final pattern in _errorPatterns) {
      final match = pattern.$1.firstMatch(text);
      if (match != null) return pattern.$2(l);
    }
    return text
        .replaceFirst('StateError: ', '')
        .replaceFirst('Exception: ', '')
        .replaceFirst('FormatException: ', '');
  }

  static final _errorPatterns = <(RegExp, String Function(AppLocalizations l))>[
    (RegExp(r'HTTP Error 403|403 Forbidden', caseSensitive: false), (l) => l.err403),
    (RegExp(r'Sign in|sign-in|not a bot', caseSensitive: false), (l) => l.errSignin),
    (RegExp(r'video is unavailable|This video is unavailable', caseSensitive: false), (l) => l.errUnavailable),
    (RegExp(r'Private video', caseSensitive: false), (l) => l.errPrivate),
    (RegExp(r'HTTP Error 404|404 Not Found', caseSensitive: false), (l) => l.err404),
    (RegExp(r'ffmpeg.*not found|ffmpeg.*required', caseSensitive: false), (l) => l.errFfmpeg),
    (RegExp(r'Live event is in progress', caseSensitive: false), (l) => l.errLive),
  ];

  Future<void> _openFile(HistoryEntry entry) async {
    // Finished downloads open in the built-in player.
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PlayerScreen(entry: entry)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final manager = TalosScope.of(context);
    final theme = Theme.of(context);
    final recent = manager.history.entries.take(4).toList();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
              children: [
                Text(
                  TalosInfo.appName.toUpperCase(),
                  style: theme.textTheme.displaySmall?.copyWith(letterSpacing: 10),
                ),
                const SizedBox(height: 4),
                Text(
                  TalosInfo.tagline.toUpperCase(),
                  style: theme.textTheme.bodySmall?.copyWith(letterSpacing: 2),
                ),
                const SizedBox(height: 16),
                Container(height: 2, width: 56, color: theme.colorScheme.primary),
                const SizedBox(height: 32),
                if (!_engineReady) _EngineBanner(
                  settingUp: _settingUp,
                  fraction: _setupFraction,
                  phase: _setupPhase,
                  unsupported: Theme.of(context).platform == TargetPlatform.iOS,
                  onSetup: () => unawaited(_setupEngineFromBanner()),
                ),
                if (!_engineReady) const SizedBox(height: 16),
                Builder(builder: (context) {
                  final url = _urlController.text.trim();
                  final detected = _detectUrls(url);
                  final isBatch = detected.length > 1;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _urlController,
                        keyboardType: TextInputType.url,
                        textInputAction: TextInputAction.go,
                        onSubmitted: (_) => _handleFetch(),
                        style: theme.textTheme.bodyLarge,
                        decoration: InputDecoration(
                          hintText: l.urlHint,
                          prefixIcon: const Icon(Icons.link),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_urlController.text.isNotEmpty)
                                IconButton(
                                  tooltip: l.clear,
                                  icon: const Icon(Icons.close),
                                  onPressed: () => setState(_urlController.clear),
                                ),
                              IconButton(
                                tooltip: l.paste,
                                icon: const Icon(Icons.content_paste_rounded),
                                onPressed: _paste,
                              ),
                              IconButton(
                                tooltip: l.saveLink,
                                icon: Icon(
                                    manager.savedLinks.contains(_urlController.text.trim())
                                        ? Icons.bookmark_added_rounded
                                        : Icons.bookmark_add_outlined,
                                  ),
                                  onPressed: _detectUrls(_urlController.text).isEmpty ? null : _saveCurrentLink,
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 52,
                        child: FilledButton.icon(
                          onPressed: (_busy || url.isEmpty) ? null : _handleFetch,
                          icon: _busy
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.south_east_rounded),
                          label: Text(_busy ? l.fetching : (isBatch ? l.fetchAll : l.fetch)),
                        ),
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 32),
                if (recent.isNotEmpty) ...[
                  SectionLabel(l.finished),
                  for (final entry in recent)
                    Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                          entry.kind == HistoryKind.audio ? Icons.music_note : Icons.movie_outlined,
                          color: theme.colorScheme.primary,
                        ),
                        title: Text(entry.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                          [formatDate(entry.dateMs), formatBytes(entry.sizeBytes)]
                              .where((s) => s.isNotEmpty)
                              .join('  ·  '),
                          style: theme.textTheme.bodySmall,
                        ),
                        trailing: const Icon(Icons.open_in_new, size: 18),
                        onTap: () => _openFile(entry),
                      ),
                    ),
                ],
                if (manager.savedLinks.entries.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  SectionLabel(l.savedLinks),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: manager.savedLinks.entries.length,
                    itemBuilder: (context, index) {
                    final link = manager.savedLinks.entries[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.bookmark_outlined),
                        title: Text(
                          link.text.split(RegExp(r'\s+')).first,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(formatDate(link.dateMs), style: theme.textTheme.bodySmall),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: l.openSaved,
                              icon: const Icon(Icons.open_in_new, size: 20),
                              onPressed: () {
                                final uri = Uri.tryParse(link.text.split(RegExp(r'\s+')).first);
                                if (uri != null && uri.hasScheme) unawaited(launchUrl(uri));
                              },
                            ),
                            IconButton(
                              tooltip: l.fetchSaved,
                              icon: const Icon(Icons.download_outlined, size: 20),
                              onPressed: () {
                                _urlController.text = link.text;
                                _handleFetch();
                              },
                            ),
                            IconButton(
                              tooltip: l.removeSaved,
                              icon: const Icon(Icons.delete_outline, size: 20),
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                await manager.savedLinks.remove(link.id);
                                if (!mounted) return;
                                setState(() {});
                                messenger.showSnackBar(
                                  SnackBar(content: Text(l.linkRemoved)),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                    },
                  ),
                ],
                if (_engineReady && _engineVersion != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    'yt-dlp $_engineVersion',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EngineBanner extends StatelessWidget {
  const _EngineBanner({
    required this.settingUp,
    required this.fraction,
    required this.phase,
    required this.unsupported,
    required this.onSetup,
  });

  final bool settingUp;
  final double fraction;
  final String phase;
  final bool unsupported;
  final VoidCallback onSetup;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.build_circle_outlined, color: theme.colorScheme.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(unsupported ? l.engineUnsupportedIos : l.engineMissing, style: theme.textTheme.bodyMedium),
                if (settingUp) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: phase == 'download' ? fraction : null),
                ],
              ],
            ),
          ),
          if (!unsupported) ...[
            const SizedBox(width: 12),
            FilledButton.tonal(
              onPressed: settingUp ? null : onSetup,
              child: Text(settingUp ? l.updatingEngine : l.installEngine),
            ),
          ],
        ],
      ),
    );
  }
}
