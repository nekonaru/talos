import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_scope.dart';
import '../core/app_info.dart';
import '../core/format.dart';
import '../core/history_store.dart';
import '../gen/app_localizations.dart';
import 'configure_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _urlController.addListener(_onUrlChanged);
    _checkSharedIntent();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshEngine());
  }

  void _onUrlChanged() {
    if (mounted) setState(() {});
  }

  void _checkSharedIntent() {
    // Shared links only arrive on Android.
    if (!Platform.isAndroid) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final shared = await const MethodChannel('id.nekonaru.talos/intent')
            .invokeMethod<String>('getInitialPendingUrl');
        if (shared != null && shared.isNotEmpty && mounted) {
          _urlController.text = shared;
          _urlController.selection = TextSelection.collapsed(offset: shared.length);
        }
        _intentSubscription = EventChannel('id.nekonaru.talos/intent/share')
            .receiveBroadcastStream()
            .listen((event) {
          if (event is String && event.isNotEmpty && mounted) {
            setState(() {
              _urlController.text = event;
              _urlController.selection = TextSelection.collapsed(offset: event.length);
            });
          }
        }, onError: (_) {});
      } catch (_) {
        // Intent bridging is best effort.
      }
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
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => _settingUp = false);
    }
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text != null && text.isNotEmpty) {
      _urlController.text = text;
      _urlController.selection = TextSelection.collapsed(offset: text.length);
    }
  }

  Future<void> _fetch() async {
    final url = _urlController.text.trim();
    if (url.isEmpty || _busy) return;
    setState(() => _busy = true);
    final manager = TalosScope.of(context);
    // Ensure the engine is installed before trying to probe.
    if (!_engineReady) {
      try {
        await _setupEngine();
      } catch (_) {
        // Error surfaces in the banner; stop here.
        if (mounted) setState(() => _busy = false);
        return;
      }
    }
    try {
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
    final l = AppLocalizations.of(context)!;
    try {
      await launchUrl(Uri.file(entry.filePath), mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.unknownError)));
    }
  }

  Future<void> _saveFile(BuildContext context, HistoryEntry entry) async {
    final scaffold = ScaffoldMessenger.of(context);
    try {
      await SharePlus.instance.share(
        ShareParams(files: [XFile(entry.filePath)]),
      );
    } catch (_) {
      if (!context.mounted) return;
      scaffold.showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.shareFailed)));
    }
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
                  style: theme.textTheme.bodySmall?.copyWith(letterSpacing: 3.2),
                ),
                const SizedBox(height: 16),
                Container(height: 2, width: 56, color: theme.colorScheme.primary),
                const SizedBox(height: 32),
                if (!_engineReady) _EngineBanner(
                  settingUp: _settingUp,
                  fraction: _setupFraction,
                  phase: _setupPhase,
                  onSetup: _setupEngine,
                ),
                if (!_engineReady) const SizedBox(height: 16),
                TextField(
                  controller: _urlController,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.go,
                  onSubmitted: (_) => _fetch(),
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
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: (_busy || _urlController.text.trim().isEmpty) ? null : _fetch,
                    icon: _busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.south_east_rounded),
                    label: Text(_busy ? l.fetching : l.fetch),
                  ),
                ),
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
                        onTap: () => (Platform.isAndroid || Platform.isIOS) ? _saveFile(context, entry) : _openFile(entry),
                      ),
                    ),
                ],
                if (_engineReady && _engineVersion != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    'yt-dlp $_engineVersion',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
    required this.onSetup,
  });

  final bool settingUp;
  final double fraction;
  final String phase;
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
                Text(l.engineMissing, style: theme.textTheme.bodyMedium),
                if (settingUp) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: phase == 'download' ? fraction : null),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.tonal(
            onPressed: settingUp ? null : onSetup,
            child: Text(settingUp ? l.updatingEngine : l.installEngine),
          ),
        ],
      ),
    );
  }
}
